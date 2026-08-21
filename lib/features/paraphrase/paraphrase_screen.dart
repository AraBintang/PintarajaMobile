import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import '../../core/constants/api_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../data/providers/auth_provider.dart';
import '../../data/providers/chat_provider.dart';
import '../../data/services/storage_service.dart';
import '../shared/widgets/app_sidebar_drawer.dart';
import '../shared/widgets/payment_sheet.dart';

class ParaphraseScreen extends StatefulWidget {
  const ParaphraseScreen({super.key});

  @override
  State<ParaphraseScreen> createState() => _ParaphraseScreenState();
}

class _ParaphraseScreenState extends State<ParaphraseScreen> {
  final TextEditingController _textController = TextEditingController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  String _selectedMode = 'standard';
  String _selectedLanguage = 'Indonesia';
  String _result = '';
  String? _error;
  bool _isLoading = false;
  int? _selectedProviderId;

  static const List<Map<String, String>> _modes = [
    {'id': 'standard', 'label': 'Standard'},
    {'id': 'fluency', 'label': 'Fluency'},
    {'id': 'formal', 'label': 'Formal'},
    {'id': 'creative', 'label': 'Creative'},
    {'id': 'academic', 'label': 'Academic'},
    {'id': 'simple', 'label': 'Simple'},
  ];

  static const List<Map<String, String>> _languages = [
    {'id': 'id', 'label': 'Indonesia'},
    {'id': 'en', 'label': 'English'},
  ];

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  String get _languageCode =>
      _languages.firstWhere((l) => l['label'] == _selectedLanguage)['id']!;

  // ==========================================================
  // FILE UPLOAD
  // ==========================================================

  Future<void> _uploadDocument() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['txt', 'doc', 'docx'],
    );

    if (result == null || result.files.isEmpty) return;

    final file = result.files.first;
    String text = '';

    if (file.path != null) {
      final f = File(file.path!);
      if (await f.exists()) {
        text = await f.readAsString();
      }
    } else if (file.bytes != null) {
      text = utf8.decode(file.bytes!);
    }

    if (!mounted) return;

    if (text.isNotEmpty) {
      setState(() {
        _textController.text = text;
      });
    } else {
      setState(() {
        _error = 'Gagal membaca isi dokumen.';
      });
    }
  }

  // ==========================================================
  // PARAPHRASE
  // ==========================================================

  // Helper: perform one paraphrase HTTP call and return the response.
  Future<http.Response> _doParaphraseRequest(
      String text, int? providerId) async {
    final token = StorageService.getToken();
    final body = <String, dynamic>{
      'text': text,
      'mode': _selectedMode,
      'language': _languageCode,
    };
    if (providerId != null) body['providerId'] = providerId;

    return http.post(
      Uri.parse(ApiConstants.paraphrase),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode(body),
    );
  }

  Future<void> _paraphrase() async {
    final text = _textController.text.trim();

    if (text.isEmpty) {
      setState(() {
        _error = 'Teks tidak boleh kosong.';
      });
      return;
    }

    if (_isLoading) return;

    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true;
      _error = null;
      _result = '';
    });

    try {
      // --- First attempt with current provider ---
      int? providerId = _selectedProviderId;
      http.Response response = await _doParaphraseRequest(text, providerId);

      if (!mounted) return;

      // --- Fallback on 402 / 429 ---
      if (response.statusCode == 402 || response.statusCode == 429) {
        final providers = context.read<ChatProvider>().aiProviders.toList();

        // Build ordered list of fallback candidates (exclude failed provider).
        final candidates =
            providers.where((p) => p.id != providerId && !p.isLimited).toList();

        for (final candidate in candidates) {
          response = await _doParaphraseRequest(text, candidate.id);

          if (!mounted) return;

          // If this candidate succeeded, use it as the effective provider.
          if (response.statusCode != 402 &&
              response.statusCode != 429 &&
              response.statusCode != 500) {
            break;
          }
        }
      }

      if (!mounted) return;

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body);
        final paraphrased = _extractText(data, [
          'result',
          'paraphrased_text',
          'content',
          'text',
          'output',
          'answer',
        ]);

        if (paraphrased.isEmpty) {
          setState(() {
            _error = 'AI tidak mengembalikan hasil.';
          });
        } else {
          setState(() {
            _result = paraphrased;
          });
        }
      } else {
        String msg = 'Gagal memproses teks. Coba lagi.';
        try {
          final body = jsonDecode(response.body);
          if (body is Map && body['message'] != null) {
            msg = body['message'].toString();
          }
        } catch (_) {}
        setState(() {
          _error = msg;
        });
      }

      if (!mounted) return;
      await context.read<AuthProvider>().refreshUser();
    } on SocketException {
      if (!mounted) return;
      setState(() {
        _error = 'Tidak ada koneksi internet.';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Gagal memproses teks. Coba lagi.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // ==========================================================
  // EXTRACT TEXT
  // ==========================================================

  String _extractText(dynamic data, List<String> keys) {
    if (data == null) return '';
    if (data is String) return data.trim();
    if (data is! Map) return '';

    for (final key in keys) {
      final value = data[key];
      if (value == null) continue;
      final text = value.toString().trim();
      if (text.isNotEmpty) return text;
    }

    final nested = data['data'];
    if (nested is Map) return _extractText(nested, keys);

    return '';
  }

  // ==========================================================
  // COPY RESULT
  // ==========================================================

  Future<void> _copyResult() async {
    if (_result.trim().isEmpty) return;

    await Clipboard.setData(ClipboardData(text: _result));

    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('Hasil berhasil disalin.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppTheme.getBg(context),
      drawer: const AppSidebarDrawer(),
      appBar: AppBar(
        backgroundColor: AppTheme.getBg(context),
        elevation: 0,
        leading: Builder(
          builder: (ctx) => IconButton(
            icon:
                Icon(Icons.menu_rounded, color: AppTheme.getTextColor(context)),
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
        title: Text(
          'Paraphrase',
          style: TextStyle(
            color: AppTheme.getTextColor(context),
            fontWeight: FontWeight.w700,
            fontSize: 17,
          ),
        ),
        centerTitle: false,
        actions: [
          _TokenChip(
            balance: auth.tokenBalance,
            onTap: _showTokenDialog,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLanguageSelector(),
              const SizedBox(height: 12),
              _buildModeSelector(),
              const SizedBox(height: 16),
              _buildInputField(),
              const SizedBox(height: 10),
              _buildUploadButton(),
              if (_error != null) ...[
                const SizedBox(height: 10),
                _buildErrorBox(),
              ],
              const SizedBox(height: 16),
              _buildParaphraseButton(),
              if (_result.isNotEmpty) ...[
                const SizedBox(height: 22),
                _buildResultSection(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // LANGUAGE SELECTOR
  // ==========================================================

  Widget _buildLanguageSelector() {
    return Row(
      children: [
        Text(
          'Bahasa: ',
          style: TextStyle(
            color: AppTheme.getTextSecondary(context),
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 6),
        ..._languages.map((lang) {
          final selected = lang['label'] == _selectedLanguage;
          return Padding(
            padding: const EdgeInsets.only(right: 6),
            child: ChoiceChip(
              label: Text(lang['label']!),
              selected: selected,
              selectedColor: AppTheme.primary,
              labelStyle: TextStyle(
                color: selected ? Colors.white : AppTheme.getTextColor(context),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              onSelected: (val) {
                if (val) setState(() => _selectedLanguage = lang['label']!);
              },
            ),
          );
        }),
      ],
    );
  }

  // ==========================================================
  // MODE SELECTOR
  // ==========================================================

  Widget _buildModeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Mode:',
          style: TextStyle(
            color: AppTheme.getTextSecondary(context),
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: _modes.map((m) {
              final selected = m['id'] == _selectedMode;
              return Padding(
                padding: const EdgeInsets.only(right: 6),
                child: ChoiceChip(
                  label: Text(m['label']!),
                  selected: selected,
                  selectedColor: AppTheme.primary,
                  labelStyle: TextStyle(
                    color: selected
                        ? Colors.white
                        : AppTheme.getTextColor(context),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                  onSelected: (val) {
                    if (val) setState(() => _selectedMode = m['id']!);
                  },
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  // ==========================================================
  // INPUT FIELD
  // ==========================================================

  Widget _buildInputField() {
    return TextField(
      controller: _textController,
      maxLines: 10,
      minLines: 6,
      textInputAction: TextInputAction.newline,
      style: TextStyle(
        color: AppTheme.getTextColor(context),
        fontSize: 13.5,
        height: 1.5,
      ),
      decoration: InputDecoration(
        hintText: 'Masukkan teks yang ingin diparaphrase...',
        hintStyle: TextStyle(color: AppTheme.getTextSecondary(context)),
        filled: true,
        fillColor: AppTheme.getSurface(context),
        contentPadding: const EdgeInsets.all(16),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: AppTheme.getBorder(context)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AppTheme.primary, width: 1.4),
        ),
        suffixIcon: _textController.text.isNotEmpty
            ? IconButton(
                onPressed: () {
                  FocusScope.of(context).unfocus();
                  _textController.clear();
                  setState(() {
                    _result = '';
                    _error = null;
                  });
                },
                tooltip: 'Hapus teks',
                icon: Icon(
                  Icons.close_rounded,
                  size: 19,
                  color: AppTheme.getTextSecondary(context),
                ),
              )
            : null,
      ),
      onChanged: (_) {
        if (mounted) setState(() {});
      },
    );
  }

  // ==========================================================
  // UPLOAD BUTTON
  // ==========================================================

  Widget _buildUploadButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _isLoading ? null : _uploadDocument,
        icon: const Icon(Icons.upload_file_rounded, size: 18),
        label: const Text('Upload Dokumen'),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }

  // ==========================================================
  // ERROR BOX
  // ==========================================================

  Widget _buildErrorBox() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: AppTheme.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.error.withValues(alpha: 0.22)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline_rounded,
              color: AppTheme.error, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _error!,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  color: AppTheme.error, fontSize: 12, height: 1.35),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // PARAPHRASE BUTTON
  // ==========================================================

  Widget _buildParaphraseButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isLoading ? null : _paraphrase,
        icon: _isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2.5, color: Colors.white),
              )
            : const Icon(Icons.swap_horiz_rounded, size: 20),
        label: Text(
          _isLoading ? 'Memproses...' : 'Paraphrase Teks',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppTheme.surfaceMuted,
          disabledForegroundColor: AppTheme.textMuted,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: _isLoading ? 0 : 2,
        ),
      ),
    );
  }

  // ==========================================================
  // RESULT SECTION
  // ==========================================================

  Widget _buildResultSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Hasil Paraphrase',
                style: TextStyle(
                  color: AppTheme.getTextColor(context),
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ),
            IconButton(
              tooltip: 'Salin',
              onPressed: _copyResult,
              icon: Icon(Icons.copy_rounded,
                  color: AppTheme.getTextSecondary(context), size: 19),
            ),
            IconButton(
              tooltip: 'Hapus hasil',
              onPressed: () {
                setState(() {
                  _result = '';
                });
              },
              icon: Icon(Icons.delete_outline_rounded,
                  color: AppTheme.getTextSecondary(context), size: 20),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.getSurface(context),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.getBorder(context)),
          ),
          child: SelectableText(
            _result,
            style: TextStyle(
              color: AppTheme.getTextColor(context),
              fontSize: 13.5,
              height: 1.6,
            ),
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {
              setState(() {
                _result = '';
                _error = null;
              });
              _textController.clear();
              FocusScope.of(context).unfocus();
            },
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Paraphrase Lagi'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ),
      ],
    );
  }

  // ==========================================================
  // TOKEN INFO
  // ==========================================================

  void _showTokenDialog() {
    final authProvider = context.read<AuthProvider>();
    final tokenBalance = authProvider.tokenBalance;

    int selectedCoins = 50;
    final TextEditingController coinsController =
        TextEditingController(text: '50');

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            final bottomPadding = MediaQuery.of(context).viewInsets.bottom;
            final pricePerCoin = 1000;
            final totalPrice = selectedCoins * pricePerCoin;

            return Padding(
              padding: EdgeInsets.only(bottom: bottomPadding),
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                decoration: BoxDecoration(
                  color: AppTheme.getSurface(context),
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                              color: AppTheme.getBorder(context),
                              borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Token & Top Up',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: AppTheme.getTextColor(context))),
                          IconButton(
                              icon: const Icon(Icons.close_rounded),
                              onPressed: () => Navigator.pop(ctx)),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Sisa Token Card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppTheme.primary,
                              AppTheme.primary.withValues(alpha: 0.8)
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primary.withValues(alpha: 0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Sisa Token Anda',
                                style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.85),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600)),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.diamond_rounded,
                                    color: Color(0xFFFCD34D), size: 24),
                                const SizedBox(width: 8),
                                Text('$tokenBalance',
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 28,
                                        fontWeight: FontWeight.w800)),
                                const SizedBox(width: 4),
                                Text('token',
                                    style: TextStyle(
                                        color:
                                            Colors.white.withValues(alpha: 0.7),
                                        fontSize: 14)),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Top Up Section
                      Text('Top Up Token',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: AppTheme.getTextColor(context))),
                      const SizedBox(height: 4),
                      Text('Harga: Rp $pricePerCoin / token',
                          style: const TextStyle(
                              color: AppTheme.textSecondary, fontSize: 12)),
                      const SizedBox(height: 10),

                      // Preset Amount Buttons
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [10, 50, 100, 500, 1000].map((amount) {
                          final isSelected = selectedCoins == amount;
                          return GestureDetector(
                            onTap: () {
                              setModalState(() {
                                selectedCoins = amount;
                                coinsController.text = '$amount';
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppTheme.primary
                                    : AppTheme.surfaceMuted,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: isSelected
                                        ? AppTheme.primary
                                        : AppTheme.borderLight),
                              ),
                              child: Text('$amount',
                                  style: TextStyle(
                                      color: isSelected
                                          ? Colors.white
                                          : AppTheme.textPrimary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13)),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 10),

                      // Custom Amount
                      TextField(
                        controller: coinsController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Jumlah Token (Min. 10)',
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12)),
                          prefixIcon: const Icon(Icons.diamond_rounded),
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 12),
                        ),
                        onChanged: (val) {
                          final parsed = int.tryParse(val);
                          if (parsed != null) {
                            setModalState(() => selectedCoins = parsed);
                          }
                        },
                      ),
                      const SizedBox(height: 10),

                      // Total Price
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Total Harga:',
                                style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.textSecondary,
                                    fontSize: 13)),
                            Text('Rp ${totalPrice.toStringAsFixed(0)}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    color: AppTheme.primary,
                                    fontSize: 16)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Top Up Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            elevation: 2,
                          ),
                          onPressed: selectedCoins < 10
                              ? null
                              : () async {
                                  Navigator.pop(ctx);
                                  final auth = context.read<AuthProvider>();
                                  final phone =
                                      auth.user?.phone?.isNotEmpty == true
                                          ? auth.user!.phone!
                                          : '08123456789';

                                  await PaymentSelectionSheet.processDirectQris(
                                    this.context,
                                    amount: totalPrice,
                                    coins: selectedCoins,
                                    phone: phone,
                                  );

                                  await auth.refreshUser();
                                },
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.qr_code_2_rounded, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                  'Bayar via QRIS - Rp ${totalPrice.toStringAsFixed(0)}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ==========================================================
  // MODEL SELECTOR
  // ==========================================================

  void _showModelSelector() {
    final providers = context.read<ChatProvider>().aiProviders;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          decoration: BoxDecoration(
            color: AppTheme.getSurface(context),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppTheme.getBorder(context),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Pilih Model AI',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _buildProviderTile(
                ctx: ctx,
                id: null,
                label: 'Auto',
                subtitle: 'Pilih model secara otomatis',
                isSelected: _selectedProviderId == null,
                isLimited: false,
              ),
              if (providers.isNotEmpty) ...[
                const Divider(height: 12),
                ...providers.map(
                  (p) => _buildProviderTile(
                    ctx: ctx,
                    id: p.id,
                    label: p.displayName,
                    subtitle: p.code,
                    isSelected: _selectedProviderId == p.id,
                    isLimited: p.isLimited,
                  ),
                ),
              ] else
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    'Tidak ada model tersedia.',
                    style: TextStyle(
                      color: AppTheme.getTextSecondary(context),
                      fontSize: 13,
                    ),
                  ),
                ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProviderTile({
    required BuildContext ctx,
    required int? id,
    required String label,
    required String subtitle,
    required bool isSelected,
    required bool isLimited,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      leading: CircleAvatar(
        radius: 18,
        backgroundColor: isSelected
            ? AppTheme.primary.withValues(alpha: 0.12)
            : AppTheme.surfaceMuted,
        child: Icon(
          isSelected ? Icons.check_rounded : Icons.smart_toy_outlined,
          size: 18,
          color: isSelected ? AppTheme.primary : AppTheme.getTextSecondary(ctx),
        ),
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color:
                    isSelected ? AppTheme.primary : AppTheme.getTextColor(ctx),
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
          if (isLimited)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Limit',
                style: TextStyle(
                  color: AppTheme.error,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(color: AppTheme.getTextSecondary(ctx), fontSize: 12),
      ),
      onTap: isLimited
          ? null
          : () {
              setState(() => _selectedProviderId = id);
              Navigator.pop(ctx);
            },
    );
  }
}

// ============================================================
// TOKEN CHIP
// ============================================================

class _TokenChip extends StatelessWidget {
  final int balance;
  final VoidCallback onTap;

  const _TokenChip({required this.balance, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 82),
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
          decoration: BoxDecoration(
            color: AppTheme.surfaceMuted,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.borderLight),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.diamond_rounded,
                  color: Color(0xFFF59E0B), size: 15),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  '$balance',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// MODEL SELECTOR BUTTON
// ============================================================

class _ModelSelectorButton extends StatelessWidget {
  final int? selectedProviderId;
  final VoidCallback onTap;

  const _ModelSelectorButton({
    required this.selectedProviderId,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Resolve display label from ChatProvider.
    final providers = context.watch<ChatProvider>().aiProviders;
    final selected = selectedProviderId == null
        ? null
        : providers.where((p) => p.id == selectedProviderId).firstOrNull;
    final label = selected?.displayName ?? 'Auto';

    return TextButton.icon(
      onPressed: onTap,
      icon: Icon(
        Icons.smart_toy_outlined,
        size: 16,
        color: AppTheme.getTextSecondary(context),
      ),
      label: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppTheme.getTextSecondary(context),
        ),
      ),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: AppTheme.getBorder(context)),
        ),
      ),
    );
  }
}
