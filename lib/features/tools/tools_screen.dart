import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/constants/api_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../data/providers/auth_provider.dart';
import '../../data/services/api_service.dart';
import '../shared/widgets/app_button.dart';
import '../shared/widgets/app_sidebar_drawer.dart';

class ToolsScreen extends StatefulWidget {
  const ToolsScreen({
    super.key,
  });

  @override
  State<ToolsScreen> createState() => _ToolsScreenState();
}

class _ToolsScreenState extends State<ToolsScreen> {
  String _activeTab = 'humanizer';

  final TextEditingController _textController = TextEditingController();

  String _result = '';

  String? _error;

  bool _isLoading = false;

  double? _plagiarismPercent;

  String _selectedLanguage = 'Indonesia';
  String _selectedHumanMode = 'basic';
  String _selectedPlagService = 'turnitin';
  File? _selectedPlagFile;

  // Plagiarism author fields
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _whatsappController = TextEditingController();
  bool _excludeBibliography = false;
  bool _excludeQuotes = false;

  final List<String> _languages = ['Indonesia', 'English'];
  final List<String> _humanModes = ['basic', 'advanced'];

  @override
  void dispose() {
    _textController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _whatsappController.dispose();
    super.dispose();
  }

  // ==========================================================
  // TAB
  // ==========================================================

  void _changeTab(String tab) {
    if (_isLoading) {
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _activeTab = tab;
      _result = '';
      _error = null;
      _plagiarismPercent = null;
      _selectedPlagFile = null;
    });
  }

  // ==========================================================
  // PROCESS
  // ==========================================================

  Future<void> _processText() async {
    if (_activeTab == 'humanize') {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Humanize AI akan segera tersedia.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      return;
    }

    final text = _textController.text.trim();
    // Capture context-dependent values before any await
    final authUser = context.read<AuthProvider>().user;

    if (_activeTab != 'plagiarism' && text.isEmpty) {
      setState(() {
        _error = 'Teks tidak boleh kosong.';
      });

      return;
    }

    if (_activeTab == 'plagiarism' &&
        text.isEmpty &&
        _selectedPlagFile == null) {
      setState(() {
        _error = 'Masukkan teks atau upload file dokumen.';
      });
      return;
    }

    if (_isLoading) {
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true;
      _error = null;
      _result = '';
      _plagiarismPercent = null;
    });

    try {
      dynamic data;

      switch (_activeTab) {
        case 'humanizer':
          setState(() {
            _isLoading = false;
            _error = 'Fitur Humanizer AI akan segera rilis! (Coming Soon)';
          });
          return;

        case 'plagiarism':
          final userNameParts =
              (authUser?.name ?? 'Mahasiswa PintarAja').trim().split(' ');
          final firstName =
              userNameParts.isNotEmpty ? userNameParts.first : 'Mahasiswa';
          final lastName = userNameParts.length > 1
              ? userNameParts.sublist(1).join(' ')
              : 'PintarAja';
          final phone = (authUser?.phone != null && authUser!.phone!.isNotEmpty)
              ? authUser.phone!
              : '081234567890';

          File fileToUpload;
          if (_selectedPlagFile != null) {
            fileToUpload = _selectedPlagFile!;
          } else {
            final tempDir = await Directory.systemTemp.createTemp('plag');
            fileToUpload = File('${tempDir.path}/dokumen_cek.txt');
            await fileToUpload.writeAsString(text);
          }

          data = await ApiService.instance.postMultipart(
            ApiConstants.plagiarism,
            fields: {
              'service_type': _selectedPlagService,
              'author_first_name': firstName,
              'author_last_name': lastName,
              'whatsapp_phone': phone,
              'channel': 'quota',
              'method': 'quota',
              'phone': phone,
            },
            files: {
              'documents[]': fileToUpload,
            },
            timeout: const Duration(seconds: 120),
          );
          break;

        case 'paraphrase':
        default:
          setState(() {
            _isLoading = false;
            _error = 'Paraphrase sudah tersedia di menu terpisah.';
          });
          return;
      }

      if (!mounted) {
        return;
      }

      if (_activeTab == 'plagiarism') {
        final report = _extractText(
          data,
          const [
            'report',
            'result',
            'content',
            'text',
            'message',
          ],
        );

        final percent = _extractDouble(
          data,
          const [
            'percent',
            'percentage',
            'plagiarism_percent',
            'plagiarismPercentage',
            'score',
          ],
        );

        setState(() {
          _result = report.isEmpty ? 'Pengecekan selesai.' : report;

          _plagiarismPercent = percent ?? 0;
        });
      } else {
        final result = _extractText(
          data,
          const [
            'result',
            'humanized_text',
            'content',
            'text',
            'output',
            'answer',
          ],
        );

        if (result.isEmpty) {
          setState(() {
            _error = 'AI tidak mengembalikan hasil.';
          });
        } else {
          setState(() {
            _result = result;
          });
        }
      }

      // Refresh saldo token setelah
      // penggunaan AI Tools.
      await context.read<AuthProvider>().refreshUser();

      if (!mounted) {
        return;
      }
    } on ApiException catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _error = e.message;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

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

  String _extractText(
    dynamic data,
    List<String> keys,
  ) {
    if (data == null) {
      return '';
    }

    if (data is String) {
      return data.trim();
    }

    if (data is! Map) {
      return '';
    }

    for (final key in keys) {
      final value = data[key];

      if (value == null) {
        continue;
      }

      final text = value.toString().trim();

      if (text.isNotEmpty) {
        return text;
      }
    }

    final nested = data['data'];

    if (nested is Map) {
      return _extractText(
        nested,
        keys,
      );
    }

    return '';
  }

  // ==========================================================
  // EXTRACT DOUBLE
  // ==========================================================

  double? _extractDouble(
    dynamic data,
    List<String> keys,
  ) {
    if (data is! Map) {
      return null;
    }

    for (final key in keys) {
      final value = data[key];

      if (value == null) {
        continue;
      }

      if (value is num) {
        return value.toDouble();
      }

      final parsed = double.tryParse(
        value.toString(),
      );

      if (parsed != null) {
        return parsed;
      }
    }

    final nested = data['data'];

    if (nested is Map) {
      return _extractDouble(
        nested,
        keys,
      );
    }

    return null;
  }

  // ==========================================================
  // CLEAR
  // ==========================================================

  void _clearText() {
    FocusScope.of(context).unfocus();

    _textController.clear();

    setState(() {
      _result = '';
      _error = null;
      _plagiarismPercent = null;
    });
  }

  // ==========================================================
  // COPY
  // ==========================================================

  Future<void> _copyResult() async {
    if (_result.trim().isEmpty) {
      return;
    }

    await Clipboard.setData(
      ClipboardData(
        text: _result,
      ),
    );

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text(
            'Hasil berhasil disalin.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  // ==========================================================
  // TOKEN
  // ==========================================================

  void _showTokenInfo() {
    final auth = context.read<AuthProvider>();
    final tokenBalance = auth.tokenBalance;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          decoration: BoxDecoration(
            color: AppTheme.getSurface(ctx),
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
                      color: AppTheme.getBorder(ctx),
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Token & Top Up',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: AppTheme.textPrimary)),
                  IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(ctx)),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
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
                        offset: const Offset(0, 4)),
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
                    const SizedBox(height: 6),
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
                                color: Colors.white.withValues(alpha: 0.7),
                                fontSize: 14)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      drawer: const AppSidebarDrawer(),
      backgroundColor: AppTheme.backgroundApp,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundApp,
        elevation: 0,
        leading: IconButton(
          onPressed: () {
            Scaffold.of(context).openDrawer();
          },
          icon: const Icon(
            Icons.menu_rounded,
            color: AppTheme.textPrimary,
          ),
        ),
        title: const Text(
          'AI Tools',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 19,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          _TokenChip(
            balance: auth.tokenBalance,
            onTap: _showTokenInfo,
          ),
          const SizedBox(
            width: 8,
          ),
        ],
      ),
      body: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.fromLTRB(
          16,
          12,
          16,
          30,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTabSelector(),
            const SizedBox(
              height: 16,
            ),
            _buildOptionsConfig(),
            const SizedBox(
              height: 10,
            ),
            _buildInputTitle(),
            const SizedBox(
              height: 9,
            ),
            _buildInputField(),
            if (_error != null) ...[
              const SizedBox(
                height: 10,
              ),
              _ErrorBox(
                message: _error!,
              ),
            ],
            const SizedBox(
              height: 18,
            ),
            _buildActionButton(),
            if (_plagiarismPercent != null) ...[
              const SizedBox(
                height: 22,
              ),
              _buildPlagiarismCard(),
            ],
            if (_result.isNotEmpty) ...[
              const SizedBox(
                height: 22,
              ),
              _buildResultSection(),
            ],
            const SizedBox(
              height: 30,
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================
  // OPTIONS CONFIG
  // ==========================================================

  Widget _buildOptionsConfig() {
    if (_activeTab == 'humanize') {
      return Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.surfaceLight,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.borderLight),
        ),
        child: const Row(
          children: [
            Icon(Icons.info_outline_rounded, color: AppTheme.primary, size: 18),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Fitur Humanize AI akan membuat teks terdeteksi 100% buatan manusia.',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
              ),
            ),
          ],
        ),
      );
    }

    if (_activeTab == 'plagiarism') {
      return Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.surfaceLight,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.borderLight),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Pilih Layanan:',
                style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ChoiceChip(
                    label: const Center(
                        child: Text('Turnitin Check',
                            style: TextStyle(
                                fontSize: 12, fontWeight: FontWeight.bold))),
                    selected: _selectedPlagService == 'turnitin',
                    selectedColor: AppTheme.primary,
                    labelStyle: TextStyle(
                        color: _selectedPlagService == 'turnitin'
                            ? Colors.white
                            : AppTheme.textPrimary),
                    onSelected: (val) {
                      if (val)
                        setState(() => _selectedPlagService = 'turnitin');
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ChoiceChip(
                    label: const Center(
                        child: Text('Drillbot Check',
                            style: TextStyle(
                                fontSize: 12, fontWeight: FontWeight.bold))),
                    selected: _selectedPlagService == 'drillbot',
                    selectedColor: AppTheme.primary,
                    labelStyle: TextStyle(
                        color: _selectedPlagService == 'drillbot'
                            ? Colors.white
                            : AppTheme.textPrimary),
                    onSelected: (val) {
                      if (val)
                        setState(() => _selectedPlagService = 'drillbot');
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            const Text('Data Penulis:',
                style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _firstNameController,
                    style: const TextStyle(
                        fontSize: 12.5, color: AppTheme.textPrimary),
                    decoration: InputDecoration(
                      hintText: 'Nama Depan',
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 10),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _lastNameController,
                    style: const TextStyle(
                        fontSize: 12.5, color: AppTheme.textPrimary),
                    decoration: InputDecoration(
                      hintText: 'Nama Belakang',
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 10),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _whatsappController,
              keyboardType: TextInputType.phone,
              style:
                  const TextStyle(fontSize: 12.5, color: AppTheme.textPrimary),
              decoration: InputDecoration(
                hintText: 'No WhatsApp (08xxxxxxxx)',
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    _selectedPlagFile != null
                        ? 'Dokumen: ${_selectedPlagFile!.path.split(Platform.pathSeparator).last}'
                        : 'Upload Dokumen (PDF/Doc/Txt):',
                    style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () async {
                    final res = await FilePicker.platform.pickFiles(
                      type: FileType.custom,
                      allowedExtensions: ['pdf', 'doc', 'docx', 'txt'],
                    );
                    if (res != null && res.files.single.path != null) {
                      setState(() {
                        _selectedPlagFile = File(res.files.single.path!);
                      });
                    }
                  },
                  icon: const Icon(Icons.upload_file_rounded, size: 16),
                  label: Text(
                      _selectedPlagFile != null ? 'Ganti File' : 'Upload File'),
                  style: OutlinedButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Text('Pengaturan Pengecualian:',
                style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold)),
            Row(
              children: [
                Checkbox(
                  value: _excludeBibliography,
                  activeColor: AppTheme.primary,
                  onChanged: (v) =>
                      setState(() => _excludeBibliography = v ?? true),
                ),
                const Text('Abaikan Daftar Pustaka',
                    style:
                        TextStyle(fontSize: 11, color: AppTheme.textPrimary)),
                const SizedBox(width: 8),
                Checkbox(
                  value: _excludeQuotes,
                  activeColor: AppTheme.primary,
                  onChanged: (v) => setState(() => _excludeQuotes = v ?? true),
                ),
                const Text('Abaikan Kutipan',
                    style:
                        TextStyle(fontSize: 11, color: AppTheme.textPrimary)),
              ],
            ),
            const Divider(height: 16),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Biaya Pengecekan Plagiarisme:',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary)),
                  Text('Rp 22.000 / file',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primary)),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('Bahasa: ',
                  style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600)),
              const SizedBox(width: 8),
              ..._languages.map((lang) {
                final selected = lang == _selectedLanguage;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: InkWell(
                    onTap: () => setState(() => _selectedLanguage = lang),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color:
                            selected ? AppTheme.primary : AppTheme.surfaceMuted,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(lang,
                          style: TextStyle(
                              color: selected
                                  ? Colors.white
                                  : AppTheme.textPrimary,
                              fontSize: 11,
                              fontWeight: FontWeight.w600)),
                    ),
                  ),
                );
              }),
            ],
          ),
          const SizedBox(height: 10),
          const Text('Mode:',
              style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _humanModes.map((m) {
                final selected = m == _selectedHumanMode;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    label: Text(m),
                    selected: selected,
                    selectedColor: AppTheme.primary,
                    labelStyle: TextStyle(
                        color: selected ? Colors.white : AppTheme.textPrimary,
                        fontSize: 11),
                    onSelected: (val) {
                      if (val) {
                        setState(() {
                          _selectedHumanMode = m;
                        });
                      }
                    },
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // TAB SELECTOR
  // ==========================================================

  Widget _buildTabSelector() {
    return SizedBox(
      width: double.infinity,
      child: Row(
        children: [
          Expanded(
            child: _ToolTabButton(
              label: 'Humanizer',
              active: _activeTab == 'humanizer',
              isSoon: true,
              onTap: () => _changeTab('humanizer'),
            ),
          ),
          const SizedBox(width: 7),
          Expanded(
            child: _ToolTabButton(
              label: 'Plagiarism',
              active: _activeTab == 'plagiarism',
              onTap: () => _changeTab('plagiarism'),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // INPUT TITLE
  // ==========================================================

  Widget _buildInputTitle() {
    String title;

    if (_activeTab == 'plagiarism') {
      title = 'Masukkan Teks yang Mau Dicek';
    } else {
      title = 'Masukkan Teks Asli';
    }

    return Text(
      title,
      style: const TextStyle(
        color: AppTheme.textPrimary,
        fontWeight: FontWeight.w600,
        fontSize: 14,
      ),
    );
  }

  // ==========================================================
  // INPUT FIELD
  // ==========================================================

  Widget _buildInputField() {
    final hint = _activeTab == 'plagiarism'
        ? 'Tempelkan artikel atau tugas kamu di sini...'
        : 'Tulis atau tempel teks kamu di sini...';

    return TextField(
      controller: _textController,
      maxLines: 9,
      minLines: 7,
      textInputAction: TextInputAction.newline,
      style: const TextStyle(
        color: AppTheme.textPrimary,
        fontSize: 13.5,
        height: 1.5,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(
          color: AppTheme.textMuted,
        ),
        filled: true,
        fillColor: AppTheme.surfaceLight,
        contentPadding: const EdgeInsets.all(
          16,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(
            18,
          ),
          borderSide: const BorderSide(
            color: AppTheme.borderLight,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(
            18,
          ),
          borderSide: const BorderSide(
            color: AppTheme.primary,
            width: 1.4,
          ),
        ),
        suffixIcon: _textController.text.isNotEmpty
            ? IconButton(
                onPressed: _clearText,
                tooltip: 'Hapus teks',
                icon: const Icon(
                  Icons.close_rounded,
                  size: 19,
                  color: AppTheme.textMuted,
                ),
              )
            : null,
      ),
      onChanged: (_) {
        if (!mounted) {
          return;
        }

        setState(() {});
      },
    );
  }

  // ==========================================================
  // ACTION BUTTON
  // ==========================================================

  Widget _buildActionButton() {
    return SizedBox(
      width: double.infinity,
      child: AppButton(
        label: _getButtonLabel(),
        isLoading: _isLoading,
        onPressed: _isLoading ? null : _processText,
        gradient: _getButtonGradient(),
      ),
    );
  }

  // ==========================================================
  // BUTTON LABEL
  // ==========================================================

  String _getButtonLabel() {
    switch (_activeTab) {
      case 'plagiarism':
        return 'Periksa Plagiarisme';

      case 'humanizer':
      default:
        return 'Humanize Teks';
    }
  }

  // ==========================================================
  // BUTTON GRADIENT
  // ==========================================================

  LinearGradient _getButtonGradient() {
    if (_activeTab == 'plagiarism') {
      return const LinearGradient(
        colors: [
          Color(0xFFFC5C7D),
          Color(0xFF6A3093),
        ],
      );
    }

    return const LinearGradient(
      colors: [
        Color(0xFF11998E),
        Color(0xFF38EF7D),
      ],
    );
  }

  // ==========================================================
  // PLAGIARISM CARD
  // ==========================================================

  Widget _buildPlagiarismCard() {
    final percent = _plagiarismPercent ?? 0;

    final suspicious = percent > 20;

    final cardColor = suspicious
        ? AppTheme.error.withValues(
            alpha: 0.08,
          )
        : AppTheme.success.withValues(
            alpha: 0.08,
          );

    final borderColor = suspicious ? AppTheme.error : AppTheme.success;

    final icon =
        suspicious ? Icons.warning_amber_rounded : Icons.check_circle_outline;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(
        15,
      ),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(
          16,
        ),
        border: Border.all(
          color: borderColor,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: borderColor,
            size: 25,
          ),
          const SizedBox(
            width: 12,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Indikasi Plagiarisme',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(
                  height: 4,
                ),
                Text(
                  suspicious
                      ? 'Teks terindikasi memiliki kemiripan sebesar ${percent.toStringAsFixed(1)}%.'
                      : 'Teks memiliki indikasi kemiripan yang rendah (${percent.toStringAsFixed(1)}%).',
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(
            width: 8,
          ),
          Text(
            '${percent.toStringAsFixed(1)}%',
            style: TextStyle(
              color: borderColor,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // RESULT
  // ==========================================================

  Widget _buildResultSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Hasil Proses AI',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ),
            IconButton(
              tooltip: 'Salin',
              onPressed: _copyResult,
              icon: const Icon(
                Icons.copy_rounded,
                color: AppTheme.textMuted,
                size: 19,
              ),
            ),
            IconButton(
              tooltip: 'Hapus hasil',
              onPressed: () {
                setState(() {
                  _result = '';
                });
              },
              icon: const Icon(
                Icons.delete_outline_rounded,
                color: AppTheme.textMuted,
                size: 20,
              ),
            ),
          ],
        ),
        const SizedBox(
          height: 8,
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(
            16,
          ),
          decoration: BoxDecoration(
            color: AppTheme.surfaceLight,
            borderRadius: BorderRadius.circular(
              16,
            ),
            border: Border.all(
              color: AppTheme.borderLight,
            ),
          ),
          child: SelectableText(
            _result,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 13.5,
              height: 1.6,
            ),
          ),
        ),
      ],
    );
  }
}

// ============================================================
// TOOL TAB BUTTON
// ============================================================

class _ToolTabButton extends StatelessWidget {
  final String label;
  final bool active;
  final bool isSoon;
  final VoidCallback onTap;

  const _ToolTabButton({
    required this.label,
    required this.active,
    this.isSoon = false,
    required this.onTap,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(
        20,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(
          20,
        ),
        child: Ink(
          height: 42,
          decoration: BoxDecoration(
            color: active ? AppTheme.primary : AppTheme.surfaceLight,
            borderRadius: BorderRadius.circular(
              20,
            ),
            border: Border.all(
              color: active ? AppTheme.primary : AppTheme.borderLight,
            ),
          ),
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: active ? Colors.white : AppTheme.textSecondary,
                    fontSize: 11.5,
                    fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
                if (isSoon) ...[
                  const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 5, vertical: 1.5),
                    decoration: BoxDecoration(
                      color: active ? Colors.white24 : Colors.grey.shade400,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'SOON',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// ERROR BOX
// ============================================================

class _ErrorBox extends StatelessWidget {
  final String message;

  const _ErrorBox({
    required this.message,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(
        11,
      ),
      decoration: BoxDecoration(
        color: AppTheme.error.withValues(
          alpha: 0.08,
        ),
        borderRadius: BorderRadius.circular(
          12,
        ),
        border: Border.all(
          color: AppTheme.error.withValues(
            alpha: 0.22,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: AppTheme.error,
            size: 18,
          ),
          const SizedBox(
            width: 8,
          ),
          Expanded(
            child: Text(
              message,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppTheme.error,
                fontSize: 11.5,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// TOKEN CHIP
// ============================================================

class _TokenChip extends StatelessWidget {
  final int balance;
  final VoidCallback onTap;

  const _TokenChip({
    required this.balance,
    required this.onTap,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(
        20,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(
          20,
        ),
        child: Container(
          constraints: const BoxConstraints(
            maxWidth: 82,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: 9,
            vertical: 6,
          ),
          decoration: BoxDecoration(
            color: AppTheme.surfaceMuted,
            borderRadius: BorderRadius.circular(
              20,
            ),
            border: Border.all(
              color: AppTheme.borderLight,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.diamond_rounded,
                color: Color(0xFFF59E0B),
                size: 15,
              ),
              const SizedBox(
                width: 5,
              ),
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
