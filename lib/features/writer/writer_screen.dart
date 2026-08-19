// ============================================================
// PINTARAJA — WRITER SCREEN
// AI Writer — Fase 5 Fix
// Responsive Android 720x1520
// ============================================================

import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:provider/provider.dart';


import '../../core/constants/api_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../data/providers/auth_provider.dart';
import '../../data/providers/chat_provider.dart';
import '../../data/services/api_service.dart';
import '../shared/widgets/app_sidebar_drawer.dart';

class WriterScreen extends StatefulWidget {
  const WriterScreen({
    super.key,
  });

  @override
  State<WriterScreen> createState() {
    return _WriterScreenState();
  }
}

class _WriterScreenState extends State<WriterScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  final TextEditingController _topicController =
      TextEditingController();

  final ScrollController _scrollController =
      ScrollController();

  String _selectedType = 'Essay';
  String _selectedTone = 'Formal';
  String _selectedPaper = 'Standard Academic';
  String _selectedLanguage = 'Bahasa Indonesia';
  String _selectedAiModel = 'GPT-4o';
  int _paragraphCount = 3;
  int _maxWords = 500;
  final TextEditingController _instructionsController = TextEditingController();

  String _result = '';
  String? _error;

  bool _isLoading = false;

  int _charCount = 0;

  List<Map<String, dynamic>> _myFiles = [];
  Map<String, dynamic>? _storageQuota;
  bool _isLoadingFiles = false;
  bool _isUploadingFile = false;
  String? _filesError;

  final List<String> _types = [
    'Essay',
    'Artikel Akademik',
    'Blog Post',
    'Makalah / Skripsi',
    'Jurnal Ilmiah',
    'Ringkasan Buku',
    'Surat Formal',
    'Lainnya',
  ];

  final List<String> _tones = [
    'Formal',
    'Netral',
    'Santai',
    'Ilmiah',
    'Kreatif',
    'Persuasif',
  ];

  final List<String> _papers = [
    'Standard Academic',
    'APA 7th Edition',
    'MLA 9th Edition',
    'IEEE Format',
    'Chicago Manual',
  ];

  final List<String> _languages = [
    'Bahasa Indonesia',
    'English (US)',
    'English (UK)',
    'Jawa',
    'Sunda',
  ];

  final List<String> _aiModels = [
    'GPT-4o',
    'Gemini 1.5 Pro',
    'Claude 3.5 Sonnet',
    'DeepSeek R1',
  ];

  // Maksimum ukuran file upload: 10MB
  static const int _maxFileSizeBytes = 10 * 1024 * 1024;

  @override
  void initState() {
    super.initState();

    _tabController = TabController(
      length: 2,
      vsync: this,
    );

    _tabController.addListener(_handleTabChanged);

    _topicController.addListener(
      _handleTopicChanged,
    );
  }

  void _handleTabChanged() {
    if (_tabController.indexIsChanging && _tabController.index == 1) {
      _loadMyFiles();
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChanged);
    _topicController.removeListener(
      _handleTopicChanged,
    );

    _topicController.dispose();
    _scrollController.dispose();
    _tabController.dispose();

    super.dispose();
  }

  // ==========================================================
  // LOAD & MANAGE FILES
  // ==========================================================

  Future<void> _loadMyFiles() async {
    setState(() {
      _isLoadingFiles = true;
      _filesError = null;
    });

    try {
      final data = await ApiService.instance.get(ApiConstants.writerFiles);
      if (data is Map) {
        final rawFiles = data['files'];
        final quotaData = data['quota'];
        if (rawFiles is List) {
          _myFiles = List<Map<String, dynamic>>.from(
            rawFiles.whereType<Map>().map((e) => Map<String, dynamic>.from(e)),
          );
        }
        if (quotaData is Map) {
          _storageQuota = Map<String, dynamic>.from(quotaData);
        }
      }
    } on ApiException catch (e) {
      _filesError = e.message;
    } catch (_) {
      _filesError = 'Gagal memuat daftar file.';
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingFiles = false;
        });
      }
    }
  }

  int _resolveWriterProviderId(ChatProvider chatProvider) {
    final selectedId = chatProvider.selectedProviderId;

    if (selectedId != null &&
        selectedId > 0 &&
        chatProvider.aiProviders.any((provider) => provider.id == selectedId)) {
      return selectedId;
    }

    for (final provider in chatProvider.aiProviders) {
      final code = provider.code.toLowerCase();
      final model = provider.model.toLowerCase();

      if (code.contains('gpt') || model.contains('gpt')) {
        return provider.id;
      }
    }

    if (chatProvider.aiProviders.isNotEmpty) {
      return chatProvider.aiProviders.first.id;
    }

    return 1;
  }

  Future<File?> _resolvePickedFile(PlatformFile file) async {
    // Prioritaskan path langsung
    if (file.path != null && file.path!.isNotEmpty) {
      final f = File(file.path!);
      if (await f.exists()) return f;
    }

    // Fallback ke bytes kalau path tidak tersedia (web/beberapa device)
    if (file.bytes != null && file.bytes!.isNotEmpty) {
      final tempDir = await Directory.systemTemp.createTemp('pintaraja_writer_');
      final tempFile = File('${tempDir.path}/${file.name}');
      await tempFile.writeAsBytes(file.bytes!);
      return tempFile;
    }

    return null;
  }

  Future<void> _uploadFile() async {
    final chatProvider = context.read<ChatProvider>();
    final providerId = _resolveWriterProviderId(chatProvider);

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'txt', 'md'],
      // withData: true agar bytes tersedia di semua device Android
      withData: true,
    );

    if (result == null || result.files.isEmpty) {
      return;
    }

    final selectedFile = result.files.first;

    // Validasi ekstensi
    final extension = selectedFile.extension?.toLowerCase();
    const allowedExtensions = {'pdf', 'doc', 'docx', 'txt', 'md'};

    if (extension == null || !allowedExtensions.contains(extension)) {
      if (!mounted) return;
      setState(() {
        _filesError = 'Format tidak didukung. Gunakan PDF, DOC, DOCX, TXT, atau MD.';
      });
      return;
    }

    // Validasi ukuran file (max 10MB)
    final fileSize = selectedFile.size;
    if (fileSize > _maxFileSizeBytes) {
      if (!mounted) return;
      setState(() {
        final sizeMb = (fileSize / (1024 * 1024)).toStringAsFixed(1);
        _filesError = 'File terlalu besar (${sizeMb}MB). Maksimum 10MB.';
      });
      return;
    }

    final file = await _resolvePickedFile(selectedFile);

    if (file == null) {
      if (!mounted) return;
      setState(() {
        _filesError = 'File tidak dapat dibaca. Coba file lain.';
      });
      return;
    }

    setState(() {
      _isUploadingFile = true;
      _filesError = null;
    });

    try {
      await ApiService.instance.postMultipart(
        ApiConstants.writerUploadFile,
        fields: {
          'providerId': providerId.toString(),
        },
        files: {
          'file': file,
        },
        timeout: const Duration(seconds: 120),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('✅ File berhasil diunggah!'),
            behavior: SnackBarBehavior.floating,
          ),
        );

      await _loadMyFiles();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _filesError = e.message;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _filesError = 'Gagal mengunggah file. Pastikan koneksi internet stabil.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingFile = false;
        });
      }
    }
  }

  Future<void> _deleteFile(Map<String, dynamic> fileData) async {
    final fileId = fileData['fileId']?.toString();
    final vectorStoreId = fileData['vectorStoreId']?.toString();
    final providerId = fileData['providerId'] ?? 1;

    if (fileId == null || vectorStoreId == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceLight,
        title: const Text('Hapus File',
            style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w700)),
        content: Text(
            'Apakah kamu yakin ingin menghapus ${fileData['name'] ?? 'file ini'}?',
            style: const TextStyle(color: AppTheme.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Hapus', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await ApiService.instance.deleteWithBody(
        ApiConstants.writerDeleteFile,
        {
          'providerId': providerId,
          'fileId': fileId,
          'vectorStoreId': vectorStoreId,
        },
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('File berhasil dihapus.'),
            behavior: SnackBarBehavior.floating,
          ),
        );

      await _loadMyFiles();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menghapus file: ${e.message}')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal menghapus file.')),
      );
    }
  }

  // ==========================================================
  // TOPIC
  // ==========================================================

  void _handleTopicChanged() {
    if (!mounted) {
      return;
    }

    setState(() {
      _charCount =
          _topicController.text.length;
    });
  }

  // ==========================================================
  // GENERATE
  // ==========================================================

  Future<void> _generate() async {
    final topic =
        _topicController.text.trim();

    if (topic.isEmpty) {
      setState(() {
        _error =
            'Topik tidak boleh kosong.';
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
    });

    try {
      final chatProvider = context.read<ChatProvider>();
      final providerId = _resolveWriterProviderId(chatProvider);

      final extraInst = _instructionsController.text.trim();
      final promptMessage = '''
Tolong buatkan artikel/tulisan jenis "$_selectedType" dengan ketentuan berikut:
- Format Paper: $_selectedPaper
- Nada Tulisan: $_selectedTone
- Bahasa: $_selectedLanguage
- Model AI: $_selectedAiModel
- Target Panjang: $_paragraphCount paragraf (Maksimal $_maxWords kata)
${extraInst.isNotEmpty ? '- Instruksi Tambahan: $extraInst\n' : ''}
Topik utama:
$topic
''';

      final data =
          await ApiService.instance.post(
        ApiConstants.writer,
        {
          'providerId': providerId,
          'message': promptMessage,
        },
        timeout:
            const Duration(
          seconds: 120,
        ),
      );

      if (!mounted) {
        return;
      }

      final result =
          _extractWriterResult(
        data,
      );

      if (result.isEmpty) {
        setState(() {
          _error =
              'Writer tidak mengembalikan hasil tulisan.';
        });

        return;
      }

      setState(() {
        _result = result;
      });

      await context
          .read<AuthProvider>()
          .refreshUser();

      if (!mounted) {
        return;
      }

      _scrollToResult();
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
        _error =
            'Gagal membuat tulisan. Coba lagi.';
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
  // EXTRACT RESULT
  // ==========================================================

  String _extractWriterResult(
    dynamic data,
  ) {
    if (data is String) {
      return _cleanHtmlFormatting(data.trim());
    }

    if (data is Map) {
      final candidates = [
        data['result'],
        data['content'],
        data['text'],
        data['output'],
        data['answer'],
        data['message'],
      ];

      for (final value in candidates) {
        if (value == null) {
          continue;
        }

        final text =
            value.toString().trim();

        if (text.isNotEmpty) {
          return _cleanHtmlFormatting(text);
        }
      }

      final nested =
          data['data'];

      if (nested is Map) {
        return _extractWriterResult(
          nested,
        );
      }
    }

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

    // Convert bold HTML to Markdown
    clean = clean.replaceAll(RegExp(r'<\s*b\s*>', caseSensitive: false), '**');
    clean = clean.replaceAll(RegExp(r'<\s*/\s*b\s*>', caseSensitive: false), '**');
    clean = clean.replaceAll(RegExp(r'<\s*strong\s*>', caseSensitive: false), '**');
    clean = clean.replaceAll(RegExp(r'<\s*/\s*strong\s*>', caseSensitive: false), '**');

    // Convert italic HTML to Markdown
    clean = clean.replaceAll(RegExp(r'<\s*i\s*>', caseSensitive: false), '*');
    clean = clean.replaceAll(RegExp(r'<\s*/\s*i\s*>', caseSensitive: false), '*');
    clean = clean.replaceAll(RegExp(r'<\s*em\s*>', caseSensitive: false), '*');
    clean = clean.replaceAll(RegExp(r'<\s*/\s*em\s*>', caseSensitive: false), '*');

    // Convert list items
    clean = clean.replaceAll(RegExp(r'<\s*li\s*>', caseSensitive: false), '\n• ');
    clean = clean.replaceAll(RegExp(r'<\s*/\s*li\s*>', caseSensitive: false), '');
    clean = clean.replaceAll(RegExp(r'<\s*/?ul\s*>', caseSensitive: false), '\n');
    clean = clean.replaceAll(RegExp(r'<\s*/?ol\s*>', caseSensitive: false), '\n');

    // Strip remaining HTML tags
    clean = clean.replaceAll(RegExp(r'<[^>]+>'), '');

    // Normalize multiple blank lines
    clean = clean.replaceAll(RegExp(r'\n{3,}'), '\n\n');

    return clean.trim();
  }

  // ==========================================================
  // SCROLL
  // ==========================================================

  void _scrollToResult() {
    WidgetsBinding.instance
        .addPostFrameCallback(
      (_) {
        if (!_scrollController.hasClients) {
          return;
        }

        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration:
              const Duration(
            milliseconds: 350,
          ),
          curve:
              Curves.easeOut,
        );
      },
    );
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
          content:
              Text(
            'Hasil berhasil disalin.',
          ),
          behavior:
              SnackBarBehavior.floating,
        ),
      );
  }

  // ==========================================================
  // CLEAR
  // ==========================================================

  void _clearWriter() {
    FocusScope.of(context).unfocus();

    _topicController.clear();

    setState(() {
      _selectedType = 'Essay';
      _selectedTone = 'Formal';
      _result = '';
      _error = null;
      _charCount = 0;
    });
  }

  // ==========================================================
  // TOKEN
  // ==========================================================

  void _showTokenInfo() {
    final auth =
        context.read<AuthProvider>();

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor:
              AppTheme.surfaceLight,
          title:
              const Text(
            'Token PintarAja',
            style:
                TextStyle(
              color:
                  AppTheme.textPrimary,
              fontWeight:
                  FontWeight.w700,
            ),
          ),
          content:
              Text(
            'Saldo token kamu: ${auth.tokenBalance}',
            style:
                const TextStyle(
              color:
                  AppTheme.textSecondary,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(
                  dialogContext,
                ).pop();
              },
              child:
                  const Text(
                'Tutup',
              ),
            ),
          ],
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
    final auth =
        context.watch<AuthProvider>();

    return Scaffold(
      drawer: const AppSidebarDrawer(),
      backgroundColor:
          AppTheme.backgroundApp,
      appBar:
          AppBar(
        backgroundColor:
            AppTheme.backgroundApp,
        elevation:
            0,
        leading: Builder(
          builder: (drawerContext) => IconButton(
            onPressed: () {
              Scaffold.of(drawerContext).openDrawer();
            },
            icon: const Icon(
              Icons.menu_rounded,
              color: AppTheme.textPrimary,
            ),
            tooltip: 'Menu Sidebar',
          ),
        ),
        title:
            const Text(
          'AI Writer',
          style:
              TextStyle(
            color:
                AppTheme.textPrimary,
            fontSize:
                19,
            fontWeight:
                FontWeight.w700,
          ),
        ),
        actions: [
          _TokenChip(
            balance:
                auth.tokenBalance,
            onTap:
                _showTokenInfo,
          ),
          const SizedBox(
            width:
                12,
          ),
        ],
      ),
      body:
          Column(
        children: [
          _buildTabs(),
          Expanded(
            child:
                TabBarView(
              controller:
                  _tabController,
              children: [
                _buildNewWriteTab(),
                _buildMyFilesTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // TABS
  // ==========================================================

  Widget _buildTabs() {
    return Container(
      decoration:
          const BoxDecoration(
        border:
            Border(
          bottom:
              BorderSide(
            color:
                AppTheme.borderLight,
          ),
        ),
      ),
      child:
          TabBar(
        controller:
            _tabController,
        indicatorColor:
            AppTheme.primary,
        indicatorWeight:
            3,
        labelColor:
            AppTheme.textPrimary,
        unselectedLabelColor:
            AppTheme.textSecondary,
        dividerColor:
            Colors.transparent,
        tabs:
            const [
          Tab(
            text:
                'Tulis Baru',
          ),
          Tab(
            text:
                'File Saya',
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // NEW WRITE
  // ==========================================================

  Widget _buildNewWriteTab() {
    return SingleChildScrollView(
      controller: _scrollController,
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTopicCard(),

          if (_error != null) ...[
            const SizedBox(height: 10),
            _ErrorBox(message: _error!),
          ],

          const SizedBox(height: 18),

          _buildDropdownCard(
            label: 'Jenis Tulisan',
            value: _selectedType,
            options: _types,
            onChanged: (v) => setState(() => _selectedType = v),
          ),

          const SizedBox(height: 14),

          _buildDropdownCard(
            label: 'Paper Selection (Format)',
            value: _selectedPaper,
            options: _papers,
            onChanged: (v) => setState(() => _selectedPaper = v),
          ),

          const SizedBox(height: 14),

          _buildDropdownCard(
            label: 'Bahasa (Language)',
            value: _selectedLanguage,
            options: _languages,
            onChanged: (v) => setState(() => _selectedLanguage = v),
          ),

          const SizedBox(height: 14),

          _buildDropdownCard(
            label: 'Model AI Engine',
            value: _selectedAiModel,
            options: _aiModels,
            onChanged: (v) => setState(() => _selectedAiModel = v),
          ),

          const SizedBox(height: 14),

          _buildDropdownCard(
            label: 'Nada Tulisan (Tone)',
            value: _selectedTone,
            options: _tones,
            onChanged: (v) => setState(() => _selectedTone = v),
          ),

          const SizedBox(height: 18),

          _buildSliderConfig(),

          const SizedBox(height: 16),

          _buildInstructionsInput(),

          const SizedBox(height: 24),

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
    );
  }

  Widget _buildDropdownCard({
    required String label,
    required String value,
    required List<String> options,
    required ValueChanged<String> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionLabel(text: label),
        const SizedBox(height: 6),
        InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () {
            showModalBottomSheet<void>(
              context: context,
              backgroundColor: AppTheme.surfaceLight,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              builder: (ctx) => Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text('Pilih $label', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textPrimary)),
                  ),
                  const Divider(height: 1),
                  Flexible(
                    child: ListView(
                      shrinkWrap: true,
                      children: options.map((opt) => ListTile(
                        title: Text(opt, style: TextStyle(fontWeight: opt == value ? FontWeight.bold : FontWeight.normal, color: AppTheme.textPrimary)),
                        trailing: opt == value ? const Icon(Icons.check_rounded, color: AppTheme.primary) : null,
                        onTap: () {
                          onChanged(opt);
                          Navigator.pop(ctx);
                        },
                      )).toList(),
                    ),
                  ),
                ],
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppTheme.surfaceLight,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.borderLight),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(value, style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600, fontSize: 13.5)),
                const Icon(Icons.keyboard_arrow_down_rounded, color: AppTheme.textSecondary),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSliderConfig() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const _SectionLabel(text: 'Jumlah Paragraf'),
            Text('$_paragraphCount Paragraf', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary, fontSize: 13)),
          ],
        ),
        Slider(
          value: _paragraphCount.toDouble(),
          min: 1,
          max: 10,
          divisions: 9,
          activeColor: AppTheme.primary,
          onChanged: (v) => setState(() => _paragraphCount = v.toInt()),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const _SectionLabel(text: 'Maksimal Kata'),
            Text('$_maxWords Kata', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary, fontSize: 13)),
          ],
        ),
        Slider(
          value: _maxWords.toDouble(),
          min: 100,
          max: 3000,
          divisions: 29,
          activeColor: AppTheme.primary,
          onChanged: (v) => setState(() => _maxWords = v.toInt()),
        ),
      ],
    );
  }

  Widget _buildInstructionsInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionLabel(text: 'Instruksi Tambahan (Opsional)'),
        const SizedBox(height: 6),
        TextField(
          controller: _instructionsController,
          maxLines: 2,
          style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
          decoration: InputDecoration(
            hintText: 'Misal: Sertakan contoh kasus di Indonesia & kutipan jurnal...',
            hintStyle: const TextStyle(color: AppTheme.textMuted, fontSize: 12.5),
            fillColor: AppTheme.surfaceLight,
            filled: true,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppTheme.borderLight)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppTheme.borderLight)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppTheme.primary)),
          ),
        ),
      ],
    );
  }

  // ==========================================================
  // TOPIC CARD
  // ==========================================================

  Widget _buildTopicCard() {
    return Container(
      width:
          double.infinity,
      padding:
          const EdgeInsets.fromLTRB(
        14,
        12,
        14,
        8,
      ),
      decoration:
          BoxDecoration(
        color:
            AppTheme.surfaceLight,
        borderRadius:
            BorderRadius.circular(
          18,
        ),
        border:
            Border.all(
          color:
              AppTheme.borderLight,
        ),
      ),
      child:
          Column(
        children: [
          TextField(
            controller:
                _topicController,
            maxLength:
                100,
            maxLines:
                5,
            minLines:
                4,
            textInputAction:
                TextInputAction.newline,
            style:
                const TextStyle(
              color:
                  AppTheme.textPrimary,
              fontSize:
                  14,
              height:
                  1.5,
            ),
            decoration:
                const InputDecoration(
              hintText:
                  'Tuliskan topik atau judul...',
              hintStyle:
                  TextStyle(
                color:
                    AppTheme.textMuted,
              ),
              border:
                  InputBorder.none,
              enabledBorder:
                  InputBorder.none,
              focusedBorder:
                  InputBorder.none,
              filled:
                  false,
              contentPadding:
                  EdgeInsets.zero,
              counterText:
                  '',
            ),
          ),

          Row(
            children: [
              Expanded(
                child:
                    Text(
                  _charCount >=
                          100
                      ? 'Batas maksimum tercapai'
                      : 'Maksimal 100 karakter',
                  maxLines:
                      1,
                  overflow:
                      TextOverflow
                          .ellipsis,
                  style:
                      const TextStyle(
                    color:
                        AppTheme.textMuted,
                    fontSize:
                        10,
                  ),
                ),
              ),
              Text(
                '$_charCount/100',
                style:
                    TextStyle(
                  color:
                      _charCount >=
                              100
                          ? AppTheme.primary
                          : AppTheme.textMuted,
                  fontSize:
                      10.5,
                  fontWeight:
                      FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }


  // ==========================================================
  // GENERATE BUTTON
  // ==========================================================


  Widget _buildGenerateButton() {
    return SizedBox(
      width:
          double.infinity,
      height:
          52,
      child:
          Material(
        color:
            Colors.transparent,
        borderRadius:
            BorderRadius.circular(
          16,
        ),
        child:
            Ink(
          decoration:
              BoxDecoration(
            gradient:
                _isLoading
                    ? null
                    : AppTheme
                        .primaryGradient,
            color:
                _isLoading
                    ? AppTheme
                        .surfaceMuted
                    : null,
            borderRadius:
                BorderRadius.circular(
              16,
            ),
          ),
          child:
              InkWell(
            onTap:
                _isLoading
                    ? null
                    : _generate,
            borderRadius:
                BorderRadius.circular(
              16,
            ),
            child:
                Center(
              child:
                  _isLoading
                      ? const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.2,
                                color: AppTheme.primary,
                              ),
                            ),
                            SizedBox(width: 10),
                            Text(
                              'Sedang membuat...',
                              style: TextStyle(
                                color: AppTheme.textSecondary,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        )
                      : const Text(
                          'Buat Sekarang ✨',
                          style:
                              TextStyle(
                            color:
                                Colors.white,
                            fontWeight:
                                FontWeight.w700,
                            fontSize:
                                14.5,
                          ),
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
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child:
                  Text(
                'Hasil Tulisan',
                style:
                    TextStyle(
                  color:
                      AppTheme.textPrimary,
                  fontWeight:
                      FontWeight.w700,
                  fontSize:
                      15,
                ),
              ),
            ),

            // Tombol Regenerate
            IconButton(
              tooltip:
                  'Buat Ulang',
              onPressed:
                  _isLoading ? null : _generate,
              icon:
                  const Icon(
                Icons.refresh_rounded,
                color:
                    AppTheme.primary,
                size:
                    19,
              ),
            ),

            IconButton(
              tooltip:
                  'Salin',
              onPressed:
                  _copyResult,
              icon:
                  const Icon(
                Icons.copy_rounded,
                color:
                    AppTheme
                        .textSecondary,
                size:
                    18,
              ),
            ),

            IconButton(
              tooltip:
                  'Bersihkan',
              onPressed:
                  _clearWriter,
              icon:
                  const Icon(
                Icons
                    .delete_outline_rounded,
                color:
                    AppTheme
                        .textSecondary,
                size:
                    19,
              ),
            ),
          ],
        ),

        const SizedBox(
          height:
              7,
        ),

        // FIX: Gunakan flutter_markdown untuk render hasil
        Container(
          width:
              double.infinity,
          padding:
              const EdgeInsets.all(
            16,
          ),
          decoration:
              BoxDecoration(
            color:
                AppTheme.surfaceLight,
            borderRadius:
                BorderRadius.circular(
              16,
            ),
            border:
                Border.all(
              color:
                  AppTheme.borderLight,
            ),
          ),
          child: MarkdownBody(
            data: _result,
            selectable: true,
            styleSheet: MarkdownStyleSheet(
              p: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 13.5,
                height: 1.65,
              ),
              strong: const TextStyle(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 13.5,
              ),
              em: const TextStyle(
                color: AppTheme.textPrimary,
                fontStyle: FontStyle.italic,
                fontSize: 13.5,
              ),
              h1: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
              h2: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
              h3: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 14.5,
                fontWeight: FontWeight.w700,
              ),
              listBullet: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 13.5,
              ),
              blockquote: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 13.5,
                fontStyle: FontStyle.italic,
              ),
              code: const TextStyle(
                color: AppTheme.primary,
                fontSize: 12.5,
                backgroundColor: Color(0xFFF1F5F9),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ==========================================================
  // MY FILES
  // ==========================================================

  Widget _buildMyFilesTab() {
    if (_isLoadingFiles && _myFiles.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
    }

    final limit = _storageQuota?['limit'] ?? 524288000;
    final used = _storageQuota?['used'] ?? 0;
    final double usedMb = (used / (1024 * 1024));
    final double limitMb = (limit / (1024 * 1024));
    final double progress = limit > 0 ? (used / limit).clamp(0.0, 1.0) : 0.0;

    return RefreshIndicator(
      onRefresh: _loadMyFiles,
      color: AppTheme.primary,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Storage Quota Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surfaceLight,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.borderLight),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Penyimpanan Dokumen AI',
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      '${usedMb.toStringAsFixed(1)}MB / ${limitMb.toStringAsFixed(0)}MB',
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    backgroundColor: AppTheme.surfaceMuted,
                    color: AppTheme.primary,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Max upload per file: 10MB • Format: PDF, DOC, DOCX, TXT, MD',
                  style: TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 10.5,
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _isUploadingFile ? null : _uploadFile,
                    icon: _isUploadingFile
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primary),
                          )
                        : const Icon(Icons.upload_file_rounded, size: 18, color: AppTheme.primary),
                    label: Text(
                      _isUploadingFile ? 'Mengunggah...' : 'Upload Dokumen Baru',
                      style: const TextStyle(fontWeight: FontWeight.w600, color: AppTheme.primary),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppTheme.primary),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),

          if (_filesError != null) ...[
            const SizedBox(height: 14),
            _ErrorBox(message: _filesError!),
          ],

          const SizedBox(height: 20),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'File Saya (${_myFiles.length})',
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
              IconButton(
                onPressed: _isLoadingFiles ? null : _loadMyFiles,
                icon: _isLoadingFiles
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primary),
                      )
                    : const Icon(Icons.refresh_rounded, color: AppTheme.textSecondary, size: 20),
              ),
            ],
          ),

          const SizedBox(height: 8),

          if (_myFiles.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
              decoration: BoxDecoration(
                color: AppTheme.surfaceLight,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.borderLight),
              ),
              child: const Column(
                children: [
                  Icon(Icons.folder_open_rounded, color: AppTheme.textMuted, size: 48),
                  SizedBox(height: 12),
                  Text(
                    'Belum Ada Dokumen',
                    style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w700),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Upload file PDF/Doc untuk dijadikan referensi AI Writer.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                  ),
                ],
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _myFiles.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final file = _myFiles[index];
                final fileName = file['name']?.toString() ?? 'File';
                final fileSize = () {
                  final raw = file['size'];
                  if (raw == null) return '0';
                  final bytes = raw is num ? raw : num.tryParse(raw.toString()) ?? 0;
                  return (bytes / 1024).toStringAsFixed(1);
                }();
                final fileStatus = file['status']?.toString() ?? 'ready';

                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceLight,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppTheme.borderLight),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.description_rounded, color: AppTheme.primary, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              fileName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppTheme.textPrimary,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Row(
                              children: [
                                Text(
                                  '$fileSize KB',
                                  style: const TextStyle(
                                    color: AppTheme.textMuted,
                                    fontSize: 11,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: fileStatus == 'ready'
                                        ? Colors.green.withValues(alpha: 0.1)
                                        : Colors.orange.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    fileStatus.toUpperCase(),
                                    style: TextStyle(
                                      color: fileStatus == 'ready' ? Colors.green : Colors.orange,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => _deleteFile(file),
                        icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                        tooltip: 'Hapus file',
                      ),
                    ],
                  ),
                );
              },
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
  final dynamic balance;
  final VoidCallback onTap;

  const _TokenChip({
    required this.balance,
    required this.onTap,
  });

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
            const Icon(
              Icons.diamond_rounded,
              color: Color(0xFFF59E0B),
              size: 14,
            ),
            const SizedBox(width: 4),
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
    );
  }
}

// ============================================================
// SECTION LABEL
// ============================================================

class _SectionLabel
    extends StatelessWidget {
  final String text;

  const _SectionLabel({
    required this.text,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Text(
      text,
      style:
          const TextStyle(
        color:
            AppTheme.textPrimary,
        fontWeight:
            FontWeight.w600,
        fontSize:
            14,
      ),
    );
  }
}

// ============================================================
// ERROR BOX
// ============================================================

class _ErrorBox
    extends StatelessWidget {
  final String message;

  const _ErrorBox({
    required this.message,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      width:
          double.infinity,
      padding:
          const EdgeInsets.all(
        12,
      ),
      decoration:
          BoxDecoration(
        color:
            AppTheme.error.withValues(
          alpha: 0.09,
        ),
        borderRadius:
            BorderRadius.circular(
          12,
        ),
        border:
            Border.all(
          color:
              AppTheme.error.withValues(
            alpha: 0.25,
          ),
        ),
      ),
      child:
          Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color:
                AppTheme.error,
            size:
                16,
          ),
          const SizedBox(
            width: 8,
          ),
          Expanded(
            child:
                Text(
              message,
              style:
                  const TextStyle(
                color:
                    AppTheme.error,
                fontSize:
                    12.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// SKELETON LINE — Loading placeholder
// ============================================================

class _SkeletonLine extends StatefulWidget {
  final double width;
  final double height;

  const _SkeletonLine({
    required this.width,
    required this.height,
  });

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