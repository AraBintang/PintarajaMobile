import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import '../../core/constants/api_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../data/providers/auth_provider.dart';
import '../../data/providers/chat_provider.dart';
import '../../data/services/storage_service.dart';
import '../shared/widgets/app_sidebar_drawer.dart';
import '../shared/widgets/payment_sheet.dart';

class WriterScreen extends StatefulWidget {
  const WriterScreen({super.key});

  @override
  State<WriterScreen> createState() => _WriterScreenState();
}

class _WriterScreenState extends State<WriterScreen> {
  final TextEditingController _topicController = TextEditingController();
  final TextEditingController _instructionsController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  int? _selectedProviderId;

  String _result = '';
  String? _error;
  bool _isLoading = false;
  int _charCount = 0;

  final List<Map<String, String>> _history = [];

  // File upload state
  File? _attachedFile;
  String? _attachedFileName;

  static const int _maxCharacters = 12000;

  @override
  void initState() {
    super.initState();
    _topicController.addListener(_handleTopicChanged);
    _loadHistory();
  }

  @override
  void dispose() {
    _topicController.removeListener(_handleTopicChanged);
    _topicController.dispose();
    _instructionsController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _handleTopicChanged() {
    if (!mounted) return;
    setState(() {
      _charCount = _topicController.text.length;
    });
  }

  // ==========================================================
  // HISTORY (SERVER)
  // ==========================================================

  Future<void> _loadHistory() async {
    try {
      final token = StorageService.getToken();
      if (token == null || token.isEmpty) return;

      final response = await http
          .get(
            Uri.parse(ApiConstants.writer),
            headers: {
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 20));

      if (response.statusCode < 200 || response.statusCode >= 300) return;
      if (!mounted) return;

      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      final docs = decoded is Map ? decoded['documents'] : null;
      if (docs is! List) return;

      final items = <Map<String, String>>[];
      for (final doc in docs) {
        if (doc is! Map) continue;

        String topic = doc['title']?.toString() ?? '';
        final input = doc['input']?.toString() ?? '';

        if (topic.isEmpty || topic == 'Untitled') {
          final match = RegExp(r'Topik:\s*(.+)').firstMatch(input);
          if (match != null) topic = match.group(1)?.trim() ?? '';
        }

        items.add({
          'topic': topic,
          'result': doc['result']?.toString() ?? '',
          'time': doc['lastEdited']?.toString() ?? '',
        });
      }

      setState(() {
        _history
          ..clear()
          ..addAll(items);
      });
    } catch (_) {
      // History tetap kosong bila gagal dimuat.
    }
  }

  Future<void> _saveToServerHistory(String topic, String result) async {
    try {
      final userId = context.read<AuthProvider>().user?.id ?? 0;
      final token = StorageService.getToken();

      if (userId <= 0 || token == null || token.isEmpty) return;

      await http
          .post(
            Uri.parse(ApiConstants.documents),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({
              'userId': userId,
              'workbookId': 0,
              'name': topic,
              'fullPrompt': 'Topik: $topic',
              'result': result,
            }),
          )
          .timeout(const Duration(seconds: 20));
    } catch (_) {
      // Penyimpanan history bersifat best-effort.
    }
  }

  int _resolveWriterProviderId(ChatProvider chatProvider) {
    if (_selectedProviderId != null &&
        _selectedProviderId! > 0 &&
        chatProvider.aiProviders.any((p) => p.id == _selectedProviderId)) {
      return _selectedProviderId!;
    }
    return chatProvider.selectedProviderId ??
        (chatProvider.aiProviders.isNotEmpty
            ? chatProvider.aiProviders.first.id
            : 1);
  }

  // ==========================================================
  // FILE UPLOAD
  // ==========================================================

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['txt', 'doc', 'docx', 'pdf'],
      withData: true,
    );

    if (result == null || result.files.isEmpty) return;

    final picked = result.files.first;
    final ext = picked.extension?.toLowerCase();
    const allowed = {'txt', 'doc', 'docx', 'pdf'};
    if (ext == null || !allowed.contains(ext)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Format tidak didukung. Gunakan TXT, DOC, DOCX, atau PDF.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    const maxBytes = 10 * 1024 * 1024;
    if (picked.size > maxBytes) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'File terlalu besar (${(picked.size / (1024 * 1024)).toStringAsFixed(1)}MB). Maksimum 10MB.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    File? file;
    if (picked.path != null && picked.path!.isNotEmpty) {
      file = File(picked.path!);
      if (!await file.exists()) file = null;
    }
    file ??= await _writeTempFile(picked);

    if (file == null) return;
    setState(() {
      _attachedFile = file;
      _attachedFileName = picked.name;
    });
  }

  Future<File?> _writeTempFile(PlatformFile file) async {
    if (file.bytes == null || file.bytes!.isEmpty) return null;
    final tempDir = await Directory.systemTemp.createTemp('pintaraja_writer_');
    final tempFile = File('${tempDir.path}/${file.name}');
    await tempFile.writeAsBytes(file.bytes!);
    return tempFile;
  }

  void _removeAttachedFile() {
    setState(() {
      _attachedFile = null;
      _attachedFileName = null;
    });
  }

  Future<void> _uploadAttachedFile(int providerId) async {
    if (_attachedFile == null) return;
    try {
      final token = StorageService.getToken();
      final uri = Uri.parse(ApiConstants.writerUploadFile);
      final request = http.MultipartRequest('POST', uri)
        ..headers['Authorization'] = 'Bearer $token'
        ..fields['providerId'] = providerId.toString()
        ..files.add(
            await http.MultipartFile.fromPath('file', _attachedFile!.path));

      final response =
          await request.send().timeout(const Duration(seconds: 120));
      final body = await response.stream.bytesToString();

      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (!mounted) return;
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(
                content: Text('File berhasil diunggah!'),
                behavior: SnackBarBehavior.floating),
          );
        _removeAttachedFile();
      } else {
        final decoded = jsonDecode(body);
        throw Exception(decoded['message'] ?? 'Gagal mengunggah file.');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Gagal upload file: $e'),
            behavior: SnackBarBehavior.floating),
      );
    }
  }

  // ==========================================================
  // GENERATE
  // ==========================================================

  Future<void> _generate() async {
    final topic = _topicController.text.trim();
    if (topic.isEmpty) {
      setState(() => _error = 'Topik tidak boleh kosong.');
      return;
    }
    if (_isLoading) return;

    FocusScope.of(context).unfocus();

    final chatProvider = context.read<ChatProvider>();
    final providerId = _resolveWriterProviderId(chatProvider);

    final provider =
        chatProvider.aiProviders.where((p) => p.id == providerId).firstOrNull;
    if (provider != null && provider.quota.isExhausted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
                'Kuota ${provider.displayName} untuk hari ini sudah habis.'),
            backgroundColor: AppTheme.warning,
            behavior: SnackBarBehavior.floating,
          ),
        );
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
      _result = '';
    });

    // Upload attached file first if present
    if (_attachedFile != null) {
      await _uploadAttachedFile(providerId);
      if (_attachedFile != null) {
        // Upload failed, abort generation
        if (mounted) {
          setState(() {
            _isLoading = false;
            _error = 'File upload gagal. Generasi dibatalkan.';
          });
        }
        return;
      }
    }

    try {
      final extraInst = _instructionsController.text.trim();
      final promptMessage = '''
Topik: $topic
${extraInst.isNotEmpty ? 'Instruksi Tambahan: $extraInst' : ''}
''';

      final token = StorageService.getToken();
      if (token == null || token.isEmpty) {
        throw Exception('Sesi login tidak ditemukan.');
      }

      final response = await http
          .post(
            Uri.parse(ApiConstants.writer),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json, text/event-stream',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({
              'providerId': providerId,
              'message': promptMessage,
            }),
          )
          .timeout(const Duration(seconds: 120));

      if (!mounted) return;

      if (response.statusCode < 200 || response.statusCode >= 300) {
        final body = response.body;
        try {
          final decoded = jsonDecode(body);
          throw Exception(decoded['message'] ??
              decoded['error'] ??
              'Gagal membuat tulisan.');
        } catch (_) {
          if (body.isNotEmpty) throw Exception(body);
          throw Exception('Gagal membuat tulisan. (${response.statusCode})');
        }
      }

      final raw = utf8.decode(response.bodyBytes);
      final result = _parseWriterResponse(raw);

      if (result.isEmpty) {
        setState(() => _error = 'Writer tidak mengembalikan hasil tulisan.');
        return;
      }

      setState(() {
        _result = result;
        _history.insert(0, {
          'topic': topic,
          'result': result,
          'time': DateTime.now().toString(),
        });
      });

      await _saveToServerHistory(topic, result);

      await context.read<AuthProvider>().refreshUser();

      if (!mounted) return;
      _scrollToResult();
    } on Exception catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Gagal membuat tulisan. Coba lagi.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ==========================================================
  // PARSE RESPONSE (JSON or SSE)
  // ==========================================================

  String _parseWriterResponse(String raw) {
    final response = raw.trim();
    if (response.isEmpty) return '';

    // Try normal JSON
    try {
      final data = jsonDecode(response);
      final text = _extractTextFromJson(data);
      if (text.isNotEmpty) return _cleanHtmlFormatting(text);
    } catch (_) {}

    // Try SSE
    final buffer = StringBuffer();
    final lines = response.split(RegExp(r'\r?\n'));
    for (final rawLine in lines) {
      final line = rawLine.trim();
      if (!line.startsWith('data:')) continue;
      final payload = line.substring(5).trim();
      if (payload.isEmpty || payload == '[DONE]') continue;
      try {
        final data = jsonDecode(payload);
        final text = _extractTextFromJson(data);
        if (text.isNotEmpty) buffer.write(text);
      } catch (_) {
        buffer.write(payload);
      }
    }

    final sseResult = buffer.toString().trim();
    if (sseResult.isNotEmpty) return _cleanHtmlFormatting(sseResult);

    return _cleanHtmlFormatting(response);
  }

  String _extractTextFromJson(dynamic data) {
    if (data is String) return data;
    if (data is! Map) return '';

    final keys = [
      'result',
      'content',
      'text',
      'output',
      'answer',
      'message',
      'response',
      'delta'
    ];
    for (final key in keys) {
      final value = data[key];
      if (value is String && value.trim().isNotEmpty) return value;
    }

    final choices = data['choices'];
    if (choices is List && choices.isNotEmpty) {
      final first = choices.first;
      if (first is Map) {
        final msg = first['message'];
        if (msg is Map && msg['content'] is String) return msg['content'];
        final delta = first['delta'];
        if (delta is Map && delta['content'] is String) return delta['content'];
        if (first['text'] is String) return first['text'];
      }
    }

    final nested = data['data'];
    if (nested is Map) return _extractTextFromJson(nested);

    return '';
  }

  String _cleanHtmlFormatting(String raw) {
    if (raw.isEmpty) return raw;
    String clean = raw;
    clean = clean.replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n');
    clean = clean.replaceAll(RegExp(r'</p\s*>', caseSensitive: false), '\n\n');
    clean = clean.replaceAll(RegExp(r'<p[^>]*>', caseSensitive: false), '');
    clean = clean.replaceAll(RegExp(r'</div\s*>', caseSensitive: false), '\n');
    clean = clean.replaceAll(RegExp(r'<div[^>]*>', caseSensitive: false), '');
    clean = clean.replaceAll(RegExp(r'<\s*b\s*>', caseSensitive: false), '**');
    clean =
        clean.replaceAll(RegExp(r'<\s*/\s*b\s*>', caseSensitive: false), '**');
    clean =
        clean.replaceAll(RegExp(r'<\s*strong\s*>', caseSensitive: false), '**');
    clean = clean.replaceAll(
        RegExp(r'<\s*/\s*strong\s*>', caseSensitive: false), '**');
    clean = clean.replaceAll(RegExp(r'<\s*i\s*>', caseSensitive: false), '*');
    clean =
        clean.replaceAll(RegExp(r'<\s*/\s*i\s*>', caseSensitive: false), '*');
    clean = clean.replaceAll(RegExp(r'<\s*em\s*>', caseSensitive: false), '*');
    clean =
        clean.replaceAll(RegExp(r'<\s*/\s*em\s*>', caseSensitive: false), '*');
    clean =
        clean.replaceAll(RegExp(r'<\s*li\s*>', caseSensitive: false), '\n- ');
    clean = clean.replaceAll(RegExp(r'<\s*/?li\s*>', caseSensitive: false), '');
    clean =
        clean.replaceAll(RegExp(r'<\s*/?ul\s*>', caseSensitive: false), '\n');
    clean =
        clean.replaceAll(RegExp(r'<\s*/?ol\s*>', caseSensitive: false), '\n');
    clean = clean.replaceAll(RegExp(r'<[^>]+>'), '');
    clean = clean.replaceAll(RegExp(r'\n{3,}'), '\n\n');
    return clean.trim();
  }

  // ==========================================================
  // PROMPT LIBRARY
  // ==========================================================

  Future<void> _showPromptLibrary() async {
    showDialog(
      context: context,
      builder: (_) => _PromptLibraryDialog(
        onInsert: (content) {
          // Prompt library mengisi text box INSTRUKSI TAMBAHAN.
          _instructionsController.text = content;
          _instructionsController.selection = TextSelection.fromPosition(
            TextPosition(offset: _instructionsController.text.length),
          );
        },
      ),
    );
  }

  // ==========================================================
  // SCROLL
  // ==========================================================

  void _scrollToResult() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOut,
      );
    });
  }

  // ==========================================================
  // COPY
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
            behavior: SnackBarBehavior.floating),
      );
  }

  // ==========================================================
  // CLEAR
  // ==========================================================

  void _clearWriter() {
    FocusScope.of(context).unfocus();
    _topicController.clear();
    setState(() {
      _result = '';
      _error = null;
      _charCount = 0;
      _attachedFile = null;
      _attachedFileName = null;
    });
  }

  // ==========================================================
  // TOKEN INFO
  // ==========================================================

  void _showTokenDialog() {
    final authProvider = context.read<AuthProvider>();
    final tokenBalance = authProvider.tokenBalance;
    final minCoins = authProvider.topupMinCoins;
    final pricePerCoin = 1000.0;
    final priceLabel = pricePerCoin % 1 == 0
        ? pricePerCoin.toInt().toString()
        : pricePerCoin.toStringAsFixed(2);

    int selectedCoins = minCoins > 50 ? minCoins : 50;
    final TextEditingController coinsController =
        TextEditingController(text: '$selectedCoins');

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            final bottomPadding = MediaQuery.of(context).viewInsets.bottom;
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
                      Text('Harga: Rp $priceLabel / token',
                          style: const TextStyle(
                              color: AppTheme.textSecondary, fontSize: 12)),
                      const SizedBox(height: 10),

                      // Preset Amount Buttons
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          ...[10, 50, 100, 500, 1000]
                              .where((amount) => amount >= minCoins)
                              .map((amount) {
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
                          }),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Custom Amount
                      TextField(
                        controller: coinsController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Jumlah Token (Min. $minCoins)',
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
                          onPressed: selectedCoins < minCoins
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
                                    amount: totalPrice.round(),
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

  void _showHistoryPopup() {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: AppTheme.surfaceLight,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxHeight: 600),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('History AI Writer',
                      style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 17)),
                  IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(ctx)),
                ],
              ),
              const SizedBox(height: 12),
              if (_history.isEmpty)
                const Expanded(
                    child: Center(
                        child: Text('Belum ada history.',
                            style: TextStyle(color: AppTheme.textMuted))))
              else
                Expanded(
                  child: ListView.separated(
                    itemCount: _history.length,
                    separatorBuilder: (_, __) => const Divider(),
                    itemBuilder: (context, index) {
                      final item = _history[index];
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(item['topic'] ?? '',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 14)),
                        subtitle: Text(item['result'] ?? '',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12)),
                        onTap: () {
                          setState(() {
                            _topicController.text = item['topic'] ?? '';
                            _result = item['result'] ?? '';
                          });
                          Navigator.pop(ctx);
                        },
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final chatProvider = context.watch<ChatProvider>();
    final providers = chatProvider.aiProviders;

    return Scaffold(
      drawer: const AppSidebarDrawer(),
      backgroundColor: AppTheme.backgroundApp,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundApp,
        elevation: 0,
        leading: Builder(
          builder: (drawerContext) => IconButton(
            onPressed: () => Scaffold.of(drawerContext).openDrawer(),
            icon: const Icon(Icons.menu_rounded, color: AppTheme.textPrimary),
            tooltip: 'Menu Sidebar',
          ),
        ),
        title: const Text(
          'AI Writer',
          style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 19,
              fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.history_rounded,
                color: AppTheme.textSecondary),
            tooltip: 'History Prompt',
            onPressed: _showHistoryPopup,
          ),
          _TokenChip(balance: auth.tokenBalance, onTap: _showTokenDialog),
          const SizedBox(width: 12),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildGradientHeader(),
                  const SizedBox(height: 18),
                  if (providers.isNotEmpty) ...[
                    _buildModelSelector(providers),
                    const SizedBox(height: 18),
                  ],
                  _buildInputArea(),
                  const SizedBox(height: 16),
                  if (_error != null) ...[
                    _ErrorBox(message: _error!),
                    const SizedBox(height: 16),
                  ],
                  _buildGenerateButton(),
                  if (_isLoading) ...[
                    const SizedBox(height: 28),
                    _buildLoadingSkeleton(),
                  ],
                  if (_result.isNotEmpty && !_isLoading) ...[
                    const SizedBox(height: 28),
                    _buildResultCard(),
                  ],
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // GRADIENT HEADER
  // ==========================================================

  Widget _buildGradientHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            AppTheme.primary,
            AppTheme.accent,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.edit_note_rounded,
                    color: Colors.white, size: 24),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI Writer',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Tulis artikel, esai, atau makalah dengan bantuan AI',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // MODEL SELECTOR (Horizontal Chips)
  // ==========================================================

  Widget _buildModelSelector(List<AiProvider> providers) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionLabel(text: 'Model AI'),
        const SizedBox(height: 8),
        SizedBox(
          height: 38,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: providers.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final provider = providers[index];
              final isSelected = _selectedProviderId == provider.id;
              final isExhausted = provider.quota.isExhausted;
              final quota = provider.quota;

              return ChoiceChip(
                label: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      provider.displayName,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.w600,
                        color: isSelected ? Colors.white : AppTheme.textPrimary,
                      ),
                    ),
                    if (quota.hasLimit)
                      Text(
                        'Limit: ${quota.remaining}/${quota.limit}',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: isExhausted
                              ? (isSelected ? Colors.white70 : AppTheme.warning)
                              : (isSelected
                                  ? Colors.white70
                                  : AppTheme.textMuted),
                        ),
                      ),
                  ],
                ),
                selected: isSelected,
                onSelected: isExhausted
                    ? (_) {
                        ScaffoldMessenger.of(context)
                          ..hideCurrentSnackBar()
                          ..showSnackBar(
                            SnackBar(
                              content: Text(
                                  'Kuota ${provider.displayName} untuk hari ini sudah habis. Sisa: ${quota.remaining}'),
                              backgroundColor: AppTheme.warning,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                      }
                    : (_) => setState(() => _selectedProviderId = provider.id),
                selectedColor: AppTheme.primary,
                backgroundColor: AppTheme.surfaceLight,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(
                    color: isSelected
                        ? AppTheme.primary
                        : (isExhausted
                            ? AppTheme.warning
                            : AppTheme.borderLight),
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                showCheckmark: false,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              );
            },
          ),
        ),
      ],
    );
  }

  // ==========================================================
  // INPUT AREA
  // ==========================================================

  Widget _buildInputArea() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Topik Box
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.surfaceLight,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppTheme.borderLight),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Attached file chip
              if (_attachedFileName != null) ...[
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: AppTheme.primary.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.description_rounded,
                          size: 16, color: AppTheme.primary),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          _attachedFileName!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.textPrimary,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                      const SizedBox(width: 4),
                      GestureDetector(
                        onTap: _removeAttachedFile,
                        child: const Icon(Icons.close_rounded,
                            size: 16, color: AppTheme.textMuted),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
              ],

              // Text input
              TextField(
                controller: _topicController,
                maxLength: _maxCharacters,
                maxLines: 6,
                minLines: 4,
                textInputAction: TextInputAction.newline,
                style: const TextStyle(
                    color: AppTheme.textPrimary, fontSize: 14, height: 1.5),
                decoration: const InputDecoration(
                  hintText: 'Tuliskan topik atau judul tulisan...',
                  hintStyle: TextStyle(color: AppTheme.textMuted),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  filled: false,
                  contentPadding: EdgeInsets.zero,
                  counterText: '',
                ),
              ),

              // Character counter
              Row(
                children: [
                  // Attachment button
                  GestureDetector(
                    onTap: _isLoading ? null : _pickFile,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceMuted,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.attach_file_rounded,
                        size: 18,
                        color: _isLoading
                            ? AppTheme.textMuted
                            : AppTheme.textSecondary,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '/',
                    style: TextStyle(
                      color: _charCount >= _maxCharacters
                          ? AppTheme.warning
                          : AppTheme.textMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Instruksi Tambahan Box
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppTheme.surfaceLight,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppTheme.borderLight),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(
                    left: 14, right: 14, top: 14, bottom: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Instruksi Tambahan',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    GestureDetector(
                      onTap: _showPromptLibrary,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.library_books_rounded,
                                color: AppTheme.primary, size: 16),
                            const SizedBox(width: 6),
                            const Text(
                              'Prompt Library',
                              style: TextStyle(
                                color: AppTheme.primary,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              TextField(
                controller: _instructionsController,
                maxLines: 4,
                minLines: 2,
                style:
                    const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                decoration: const InputDecoration(
                  hintText:
                      'Contoh: Gunakan bahasa yang santai dan mudah dipahami...',
                  hintStyle:
                      TextStyle(color: AppTheme.textMuted, fontSize: 12.5),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  filled: false,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ==========================================================
  // GENERATE BUTTON
  // ==========================================================

  Widget _buildGenerateButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: BoxDecoration(
            gradient: _isLoading ? null : AppTheme.primaryGradient,
            color: _isLoading ? AppTheme.surfaceMuted : null,
            borderRadius: BorderRadius.circular(16),
          ),
          child: InkWell(
            onTap: _isLoading ? null : _generate,
            borderRadius: BorderRadius.circular(16),
            child: Center(
              child: _isLoading
                  ? const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2.2, color: AppTheme.primary),
                        ),
                        SizedBox(width: 10),
                        Text(
                          'Sedang membuat...',
                          style: TextStyle(
                              color: AppTheme.textSecondary,
                              fontWeight: FontWeight.w600,
                              fontSize: 14),
                        ),
                      ],
                    )
                  : const Text(
                      'Buat Sekarang',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 15),
                    ),
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // LOADING SKELETON
  // ==========================================================

  Widget _buildLoadingSkeleton() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SkeletonLine(width: double.infinity, height: 14),
          SizedBox(height: 10),
          _SkeletonLine(width: double.infinity, height: 14),
          SizedBox(height: 10),
          _SkeletonLine(width: 240, height: 14),
          SizedBox(height: 18),
          _SkeletonLine(width: double.infinity, height: 14),
          SizedBox(height: 10),
          _SkeletonLine(width: double.infinity, height: 14),
          SizedBox(height: 10),
          _SkeletonLine(width: 180, height: 14),
          SizedBox(height: 18),
          _SkeletonLine(width: double.infinity, height: 14),
          SizedBox(height: 10),
          _SkeletonLine(width: 200, height: 14),
        ],
      ),
    );
  }

  // ==========================================================
  // RESULT
  // ==========================================================

  Widget _buildResultCard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Hasil Tulisan',
                style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 15),
              ),
            ),
            IconButton(
              tooltip: 'Buat Ulang',
              onPressed: _isLoading ? null : _generate,
              icon: const Icon(Icons.refresh_rounded,
                  color: AppTheme.primary, size: 19),
            ),
            IconButton(
              tooltip: 'Salin',
              onPressed: _copyResult,
              icon: const Icon(Icons.copy_rounded,
                  color: AppTheme.textSecondary, size: 18),
            ),
            IconButton(
              tooltip: 'Bersihkan',
              onPressed: _clearWriter,
              icon: const Icon(Icons.delete_outline_rounded,
                  color: AppTheme.textSecondary, size: 19),
            ),
          ],
        ),
        const SizedBox(height: 7),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.surfaceLight,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.borderLight),
          ),
          child: SizedBox(
            height: 350,
            child: SingleChildScrollView(
              child: MarkdownBody(
            data: _result,
            selectable: true,
            styleSheet: MarkdownStyleSheet(
              p: const TextStyle(
                  color: AppTheme.textPrimary, fontSize: 13.5, height: 1.65),
              strong: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 13.5),
              em: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontStyle: FontStyle.italic,
                  fontSize: 13.5),
              h1: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700),
              h2: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700),
              h3: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700),
              listBullet:
                  const TextStyle(color: AppTheme.textPrimary, fontSize: 13.5),
              blockquote: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 13.5,
                  fontStyle: FontStyle.italic),
              code: const TextStyle(
                  color: AppTheme.primary,
                  fontSize: 12.5,
                  backgroundColor: Color(0xFFF1F5F9)),
            ),
          ),
        ),
      ],
    );
  }
}

// ============================================================
// PROMPT LIBRARY DIALOG
// ============================================================

class _PromptLibraryDialog extends StatefulWidget {
  final ValueChanged<String> onInsert;

  const _PromptLibraryDialog({required this.onInsert});

  @override
  State<_PromptLibraryDialog> createState() => _PromptLibraryDialogState();
}

class _PromptLibraryDialogState extends State<_PromptLibraryDialog> {
  List<Map<String, dynamic>> _prompts = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPrompts();
  }

  Future<void> _loadPrompts() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final token = StorageService.getToken();
      final response = await http.get(
        Uri.parse(ApiConstants.prompts),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('Gagal memuat prompt library.');
      }

      final decoded = jsonDecode(response.body);
      final data = decoded is Map ? decoded['data'] : decoded;
      if (data is List) {
        _prompts = data
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      }
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppTheme.surfaceLight,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxHeight: 500),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Prompt Library',
                  style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 17),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded,
                      color: AppTheme.textSecondary),
                  onPressed: () => Navigator.pop(context),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Text(
              'Pilih prompt untuk dimasukkan ke topik',
              style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
            ),
            const SizedBox(height: 14),
            if (_isLoading)
              const Expanded(
                child: Center(
                  child: CircularProgressIndicator(color: AppTheme.primary),
                ),
              )
            else if (_error != null)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline,
                          color: AppTheme.error, size: 36),
                      const SizedBox(height: 10),
                      Text(_error!,
                          style: const TextStyle(
                              color: AppTheme.error, fontSize: 13),
                          textAlign: TextAlign.center),
                      const SizedBox(height: 12),
                      TextButton(
                          onPressed: _loadPrompts,
                          child: const Text('Coba Lagi')),
                    ],
                  ),
                ),
              )
            else if (_prompts.isEmpty)
              const Expanded(
                child: Center(
                  child: Text('Belum ada prompt tersedia.',
                      style:
                          TextStyle(color: AppTheme.textMuted, fontSize: 13)),
                ),
              )
            else
              Expanded(
                child: ListView.separated(
                  itemCount: _prompts.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final prompt = _prompts[index];
                    final title = prompt['name']?.toString() ?? 'Prompt';
                    final content = prompt['value']?.toString() ?? '';

                    return InkWell(
                      onTap: () {
                        widget.onInsert(content);
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context)
                          ..hideCurrentSnackBar()
                          ..showSnackBar(
                            const SnackBar(
                              content: Text('Prompt berhasil ditambahkan!'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceMuted,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.borderLight),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppTheme.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.lightbulb_rounded,
                                  color: AppTheme.primary, size: 18),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    title,
                                    style: const TextStyle(
                                      color: AppTheme.textPrimary,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                    ),
                                  ),
                                  if (content.isNotEmpty) ...[
                                    const SizedBox(height: 3),
                                    Text(
                                      content.length > 100
                                          ? '${content.substring(0, 100)}...'
                                          : content,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                          color: AppTheme.textSecondary,
                                          fontSize: 11.5),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.arrow_forward_ios_rounded,
                                size: 14, color: AppTheme.textMuted),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// TOKEN CHIP
// ============================================================

class _TokenChip extends StatelessWidget {
  final dynamic balance;
  final VoidCallback onTap;

  const _TokenChip({required this.balance, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 80),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: AppTheme.surfaceMuted,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.borderLight),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.diamond_rounded,
                color: Color(0xFFF59E0B), size: 14),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                '$balance',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 11,
                    fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// SECTION LABEL
// ============================================================

class _SectionLabel extends StatelessWidget {
  final String text;

  const _SectionLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
          color: AppTheme.textPrimary,
          fontWeight: FontWeight.w600,
          fontSize: 14),
    );
  }
}

// ============================================================
// ERROR BOX
// ============================================================

class _ErrorBox extends StatelessWidget {
  final String message;

  const _ErrorBox({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.error.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.error.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline_rounded,
              color: AppTheme.error, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(message,
                style: const TextStyle(color: AppTheme.error, fontSize: 12.5)),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// SKELETON LINE
// ============================================================

class _SkeletonLine extends StatefulWidget {
  final double width;
  final double height;

  const _SkeletonLine({required this.width, required this.height});

  @override
  State<_SkeletonLine> createState() => _SkeletonLineState();
}

class _SkeletonLineState extends State<_SkeletonLine>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.3, end: 0.8).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: AppTheme.borderLight.withValues(alpha: _anim.value),
          borderRadius: BorderRadius.circular(6),
        ),
      ),
    );
  }
}




