// ============================================================
// PINTARAJA — WRITER SCREEN
// AI Writer
// Responsive Android 720x1520
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/constants/api_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../data/providers/auth_provider.dart';
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

    _topicController.addListener(
      _handleTopicChanged,
    );
  }

  @override
  void dispose() {
    _topicController.removeListener(
      _handleTopicChanged,
    );

    _topicController.dispose();
    _scrollController.dispose();
    _tabController.dispose();

    super.dispose();
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
      final data =
          await ApiService.instance.post(
        ApiConstants.writer,
        {
          'topic': topic,
          'type':
              _selectedType.toLowerCase(),
          'tone':
              _selectedTone.toLowerCase(),
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
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
      });
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
          return text;
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
            Navigator.of(context).pop();
          },
          icon:
              const Icon(
            Icons.arrow_back_rounded,
            color:
                AppTheme.textPrimary,
          ),
        ),
        title:
            const Text(
          'Writer',
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
    return const Center(
      child:
          SingleChildScrollView(
        padding:
            EdgeInsets.symmetric(
          horizontal:
              30,
        ),
        child:
            Column(
          mainAxisSize:
              MainAxisSize.min,
          children: [
            Icon(
              Icons
                  .folder_open_rounded,
              color:
                  AppTheme.textMuted,
              size:
                  48,
            ),
            SizedBox(
              height:
                  12,
            ),
            Text(
              'Belum Ada File',
              textAlign:
                  TextAlign.center,
              style:
                  TextStyle(
                color:
                    AppTheme.textPrimary,
                fontWeight:
                    FontWeight.w700,
              ),
            ),
            SizedBox(
              height:
                  5,
            ),
            Text(
              'Hasil tulisan kamu akan tersimpan di sini.',
              textAlign:
                  TextAlign.center,
              style:
                  TextStyle(
                color:
                    AppTheme
                        .textSecondary,
                fontSize:
                    12,
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