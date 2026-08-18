// ============================================================
// PINTARAJA — WRITER SCREEN
// AI Writer
// Responsive Android 720x1520
// ============================================================

import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/constants/api_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../data/providers/auth_provider.dart';
import '../../data/providers/chat_provider.dart';
import '../../data/services/api_service.dart';

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
    'Article',
    'Blog Post',
    'Lainnya',
  ];

  final List<String> _tones = [
    'Formal',
    'Netral',
    'Santai',
  ];

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
    if (file.path != null && file.path!.isNotEmpty) {
      return File(file.path!);
    }

    if (file.bytes == null || file.bytes!.isEmpty) {
      return null;
    }

    final tempDir = await Directory.systemTemp.createTemp('pintaraja_writer_');
    final tempFile = File('${tempDir.path}/${file.name}');
    await tempFile.writeAsBytes(file.bytes!);
    return tempFile;
  }

  Future<void> _uploadFile() async {
    final chatProvider = context.read<ChatProvider>();
    final providerId = _resolveWriterProviderId(chatProvider);

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'txt', 'md'],
      withData: false,
    );

    if (result == null || result.files.isEmpty) {
      return;
    }

    final selectedFile = result.files.first;
    final extension = selectedFile.extension?.toLowerCase();
    final allowedExtensions = {'pdf', 'doc', 'docx', 'txt', 'md'};

    if (extension == null || !allowedExtensions.contains(extension)) {
      if (!mounted) return;
      setState(() {
        _filesError = 'Format file tidak didukung. Gunakan PDF, DOC, DOCX, TXT, atau MD.';
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
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('File berhasil diunggah!')),
      );

      await _loadMyFiles();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _filesError = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _filesError = 'Gagal mengunggah file. Pastikan file valid.';
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
        title: const Text('Hapus File', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w700)),
        content: Text('Apakah kamu yakin ingin menghapus ${fileData['name'] ?? 'file ini'}?', style: const TextStyle(color: AppTheme.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Hapus', style: TextStyle(color: Colors.red))),
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

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('File berhasil dihapus.')),
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

      final promptMessage =
          'Tolong buatkan $_selectedType dengan nada $_selectedTone tentang topik berikut:\n\n$topic';

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
      return data.trim();
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
    clean = clean.replaceAll(RegExp(r'<\s*/?\s*ul\s*>', caseSensitive: false), '\n');
    clean = clean.replaceAll(RegExp(r'<\s*/?\s*ol\s*>', caseSensitive: false), '\n');

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
  // INFO
  // ==========================================================

  void _showWriterInfo(
    String title,
    String message,
  ) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor:
              AppTheme.surfaceLight,
          title:
              Text(
            title,
            style:
                const TextStyle(
              color:
                  AppTheme.textPrimary,
              fontWeight:
                  FontWeight.w700,
            ),
          ),
          content:
              Text(
            message,
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
      backgroundColor:
          AppTheme.backgroundApp,
      appBar:
          AppBar(
        backgroundColor:
            AppTheme.backgroundApp,
        elevation:
            0,
        leading:
            IconButton(
          onPressed: () {
            Scaffold.of(context).openDrawer();
          },
          icon:
              const Icon(
            Icons.menu_rounded,
            color:
                AppTheme.textPrimary,
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
                8,
          ),
          IconButton(
            tooltip:
                'Membership',
            onPressed: () {
              _showWriterInfo(
                'Membership',
                'Fitur membership akan kita sambungkan dengan backend.',
              );
            },
            icon:
                const Icon(
              Icons
                  .workspace_premium_rounded,
              color:
                  AppTheme.primary,
            ),
          ),
          const SizedBox(
            width:
                4,
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
      controller:
          _scrollController,
      keyboardDismissBehavior:
          ScrollViewKeyboardDismissBehavior.onDrag,
      padding:
          const EdgeInsets.fromLTRB(
        16,
        18,
        16,
        30,
      ),
      child:
          Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          _buildTopicCard(),

          if (_error != null) ...[
            const SizedBox(
              height:
                  10,
            ),
            _ErrorBox(
              message:
                  _error!,
            ),
          ],

          const SizedBox(
            height:
                22,
          ),

          const _SectionLabel(
            text:
                'Pilih jenis tulisan',
          ),

          const SizedBox(
            height:
                10,
          ),

          _buildTypeSelector(),

          const SizedBox(
            height:
                22,
          ),

          const _SectionLabel(
            text:
                'Nada tulisan',
          ),

          const SizedBox(
            height:
                10,
          ),

          _buildToneSelector(),

          const SizedBox(
            height:
                28,
          ),

          _buildGenerateButton(),

          if (_result.isNotEmpty) ...[
            const SizedBox(
              height:
                  28,
            ),
            _buildResultCard(),
          ],

          const SizedBox(
            height:
                40,
          ),
        ],
      ),
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
  // TYPE
  // ==========================================================

  Widget _buildTypeSelector() {
    return SizedBox(
      height:
          43,
      child:
          ListView.separated(
        scrollDirection:
            Axis.horizontal,
        physics:
            const BouncingScrollPhysics(),
        itemCount:
            _types.length,
        separatorBuilder:
            (_, __) =>
                const SizedBox(
          width:
              8,
        ),
        itemBuilder:
            (
          context,
          index,
        ) {
          final type =
              _types[index];

          return _ChoiceChip(
            label:
                type,
            selected:
                type ==
                    _selectedType,
            onTap:
                () {
              setState(() {
                _selectedType =
                    type;
              });
            },
          );
        },
      ),
    );
  }

  // ==========================================================
  // TONE
  // ==========================================================

  Widget _buildToneSelector() {
    return SizedBox(
      height:
          43,
      child:
          ListView.separated(
        scrollDirection:
            Axis.horizontal,
        physics:
            const BouncingScrollPhysics(),
        itemCount:
            _tones.length,
        separatorBuilder:
            (_, __) =>
                const SizedBox(
          width:
              8,
        ),
        itemBuilder:
            (
          context,
          index,
        ) {
          final tone =
              _tones[index];

          return _ChoiceChip(
            label:
                tone,
            selected:
                tone ==
                    _selectedTone,
            onTap:
                () {
              setState(() {
                _selectedTone =
                    tone;
              });
            },
          );
        },
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
                      ? const SizedBox(
                          width:
                              22,
                          height:
                              22,
                          child:
                              CircularProgressIndicator(
                            strokeWidth:
                                2.4,
                            color:
                                Colors.white,
                          ),
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
          child:
              SelectableText(
            _result,
            style:
                const TextStyle(
              color:
                  AppTheme.textPrimary,
              fontSize:
                  13,
              height:
                  1.6,
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
                onPressed: _loadMyFiles,
                icon: const Icon(Icons.refresh_rounded, color: AppTheme.textSecondary, size: 20),
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
                final fileSize = (file['size'] is num) ? ((file['size'] as num) / 1024).toStringAsFixed(1) : '0';
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
                            Text(
                              '$fileSize KB • ${fileStatus.toUpperCase()}',
                              style: const TextStyle(
                                color: AppTheme.textMuted,
                                fontSize: 11,
                              ),
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
// CHOICE CHIP
// ============================================================

class _ChoiceChip
    extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ChoiceChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Material(
      color:
          Colors.transparent,
      borderRadius:
          BorderRadius.circular(
        22,
      ),
      child:
          InkWell(
        onTap:
            onTap,
        borderRadius:
            BorderRadius.circular(
          22,
        ),
        child:
            Ink(
          padding:
              const EdgeInsets
                  .symmetric(
            horizontal:
                17,
          ),
          decoration:
              BoxDecoration(
            gradient:
                selected
                    ? AppTheme
                        .primaryGradient
                    : null,
            color:
                selected
                    ? null
                    : AppTheme
                        .surfaceLight,
            borderRadius:
                BorderRadius.circular(
              22,
            ),
            border:
                Border.all(
              color:
                  selected
                      ? Colors.transparent
                      : AppTheme
                          .borderLight,
            ),
          ),
          child:
              Center(
            child:
                Text(
              label,
              maxLines:
                  1,
              overflow:
                  TextOverflow.ellipsis,
              style:
                  TextStyle(
                color:
                    selected
                        ? Colors.white
                        : AppTheme
                            .textSecondary,
                fontWeight:
                    selected
                        ? FontWeight.w700
                        : FontWeight.w500,
                fontSize:
                    12.5,
              ),
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
        11,
      ),
      decoration:
          BoxDecoration(
        color:
            AppTheme.error.withValues(
          alpha:
              0.08,
        ),
        borderRadius:
            BorderRadius.circular(
          12,
        ),
        border:
            Border.all(
          color:
              AppTheme.error.withValues(
            alpha:
                0.22,
          ),
        ),
      ),
      child:
          Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons
                .error_outline_rounded,
            color:
                AppTheme.error,
            size:
                18,
          ),
          const SizedBox(
            width:
                8,
          ),
          Expanded(
            child:
                Text(
              message,
              maxLines:
                  4,
              overflow:
                  TextOverflow.ellipsis,
              style:
                  const TextStyle(
                color:
                    AppTheme.error,
                fontSize:
                    11.5,
                height:
                    1.35,
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

class _TokenChip
    extends StatelessWidget {
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
      color:
          Colors.transparent,
      borderRadius:
          BorderRadius.circular(
        20,
      ),
      child:
          InkWell(
        onTap:
            onTap,
        borderRadius:
            BorderRadius.circular(
          20,
        ),
        child:
            Container(
          constraints:
              const BoxConstraints(
            maxWidth:
                82,
          ),
          padding:
              const EdgeInsets
                  .symmetric(
            horizontal:
                9,
            vertical:
                6,
          ),
          decoration:
              BoxDecoration(
            color:
                AppTheme.surfaceMuted,
            borderRadius:
                BorderRadius.circular(
              20,
            ),
            border:
                Border.all(
              color:
                  AppTheme.borderLight,
            ),
          ),
          child:
              Row(
            mainAxisSize:
                MainAxisSize.min,
            children: [
              const Icon(
                Icons
                    .diamond_rounded,
                color:
                    Color(
                  0xFFF59E0B,
                ),
                size:
                    15,
              ),
              const SizedBox(
                width:
                    5,
              ),
              Flexible(
                child:
                    Text(
                  '$balance',
                  maxLines:
                      1,
                  overflow:
                      TextOverflow.ellipsis,
                  style:
                      const TextStyle(
                    color:
                        AppTheme
                            .textPrimary,
                    fontSize:
                        11,
                    fontWeight:
                        FontWeight.w700,
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