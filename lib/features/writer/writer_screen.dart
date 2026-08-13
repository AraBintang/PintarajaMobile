// ============================================================
// WRITER SCREEN — AI Writer
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/constants/api_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../data/providers/auth_provider.dart';
import '../../data/services/api_service.dart';

class WriterScreen extends StatefulWidget {
  const WriterScreen({super.key});

  @override
  State<WriterScreen> createState() =>
      _WriterScreenState();
}

class _WriterScreenState
    extends State<WriterScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final _topicCtrl =
      TextEditingController();

  String _selectedType = 'Essay';
  String _selectedTone = 'Formal';

  String _result = '';

  bool _isLoading = false;

  String? _error;

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

    _tabController =
        TabController(
      length: 2,
      vsync: this,
    );

    _topicCtrl.addListener(() {
      if (!mounted) {
        return;
      }

      setState(() {
        _charCount =
            _topicCtrl.text.length;
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _topicCtrl.dispose();

    super.dispose();
  }

  // ==========================================================
  // GENERATE
  // ==========================================================

  Future<void> _generate() async {
    final topic =
        _topicCtrl.text.trim();

    if (topic.isEmpty) {
      setState(() {
        _error =
            'Topik tidak boleh kosong.';
      });

      return;
    }

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
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _result =
            data['result'] ??
            data['content'] ??
            data['text'] ??
            '';
      });

      // Refresh token setelah
      // pemakaian Writer.
      await context
          .read<AuthProvider>()
          .refreshUser();
    } on ApiException catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _error = e.message;
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
          AppTheme.bgLight,

      appBar: AppBar(
        backgroundColor:
            AppTheme.bgLight,
        elevation: 0,

        leading:
            IconButton(
          icon:
              const Icon(
            Icons
                .arrow_back_ios_new_rounded,
            color:
                AppTheme.textPrimary,
          ),
          onPressed:
              () =>
                  Navigator.pop(
            context,
          ),
        ),

        title:
            const Text(
          'Writer',
          style:
              TextStyle(
            fontWeight:
                FontWeight.bold,
            fontSize:
                18,
            color:
                AppTheme.textPrimary,
          ),
        ),

        actions: [
          _TokenChip(
            balance:
                auth.tokenBalance,
            onTap: () {
              _showTokenInfo(
                context,
              );
            },
          ),

          const SizedBox(
            width: 8,
          ),

          IconButton(
            icon:
                const Icon(
              Icons
                  .workspace_premium_rounded,
              color:
                  AppTheme.primary,
            ),
            onPressed: () {},
          ),

          const SizedBox(
            width: 4,
          ),
        ],
      ),

      body:
          Column(
        children: [
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
  // NEW WRITE
  // ==========================================================

  Widget _buildNewWriteTab() {
    return SingleChildScrollView(
      padding:
          const EdgeInsets.all(
        20,
      ),
      child:
          Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Container(
            padding:
                const EdgeInsets
                    .symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            decoration:
                BoxDecoration(
              color:
                  AppTheme.bgSurface,
              borderRadius:
                  BorderRadius.circular(
                16,
              ),
              border:
                  Border.all(
                color:
                    AppTheme.divider,
              ),
            ),
            child:
                Column(
              children: [
                TextField(
                  controller:
                      _topicCtrl,
                  maxLength:
                      100,
                  maxLines:
                      4,
                  style:
                      const TextStyle(
                    color:
                        AppTheme.textPrimary,
                    fontSize:
                        14,
                  ),
                  buildCounter:
                      (
                    context, {
                    required
                        currentLength,
                    required
                        isFocused,
                    maxLength,
                  }) =>
                          null,
                  decoration:
                      const InputDecoration(
                    hintText:
                        'Tuliskan topik atau judul...',
                    hintStyle:
                        TextStyle(
                      color:
                          AppTheme.textMuted,
                    ),
                    filled:
                        false,
                    border:
                        InputBorder
                            .none,
                    enabledBorder:
                        InputBorder
                            .none,
                    focusedBorder:
                        InputBorder
                            .none,
                    contentPadding:
                        EdgeInsets
                            .zero,
                  ),
                ),

                Align(
                  alignment:
                      Alignment
                          .bottomRight,
                  child:
                      Text(
                    '$_charCount/100',
                    style:
                        const TextStyle(
                      color:
                          AppTheme
                              .textMuted,
                      fontSize:
                          11,
                    ),
                  ),
                ),
              ],
            ),
          ),

          if (_error != null) ...[
            const SizedBox(
              height: 8,
            ),
            Text(
              _error!,
              style:
                  const TextStyle(
                color:
                    AppTheme.error,
                fontSize:
                    12,
              ),
            ),
          ],

          const SizedBox(
            height: 24,
          ),

          const Text(
            'Pilih jenis tulisan',
            style:
                TextStyle(
              color:
                  AppTheme.textPrimary,
              fontWeight:
                  FontWeight.w600,
              fontSize:
                  14,
            ),
          ),

          const SizedBox(
            height: 12,
          ),

          SizedBox(
            height:
                40,
            child:
                ListView.builder(
              scrollDirection:
                  Axis.horizontal,
              itemCount:
                  _types.length,
              itemBuilder:
                  (
                _,
                index,
              ) {
                final type =
                    _types[index];

                final selected =
                    type ==
                        _selectedType;

                return GestureDetector(
                  onTap:
                      () {
                    setState(
                      () {
                        _selectedType =
                            type;
                      },
                    );
                  },
                  child:
                      Container(
                    margin:
                        const EdgeInsets
                            .only(
                      right: 10,
                    ),
                    padding:
                        const EdgeInsets
                            .symmetric(
                      horizontal:
                          18,
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
                                  .bgSurface,
                      borderRadius:
                          BorderRadius.circular(
                        20,
                      ),
                      border:
                          Border.all(
                        color:
                            selected
                                ? Colors
                                    .transparent
                                : AppTheme
                                    .divider,
                      ),
                    ),
                    child:
                        Center(
                      child:
                          Text(
                        type,
                        style:
                            TextStyle(
                          color:
                              selected
                                  ? Colors
                                      .white
                                  : AppTheme
                                      .textSecondary,
                          fontWeight:
                              selected
                                  ? FontWeight
                                      .bold
                                  : FontWeight
                                      .normal,
                          fontSize:
                              13,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(
            height: 24,
          ),

          const Text(
            'Nada tulisan',
            style:
                TextStyle(
              color:
                  AppTheme.textPrimary,
              fontWeight:
                  FontWeight.w600,
              fontSize:
                  14,
            ),
          ),

          const SizedBox(
            height: 12,
          ),

          SizedBox(
            height:
                40,
            child:
                ListView.builder(
              scrollDirection:
                  Axis.horizontal,
              itemCount:
                  _tones.length,
              itemBuilder:
                  (
                _,
                index,
              ) {
                final tone =
                    _tones[index];

                final selected =
                    tone ==
                        _selectedTone;

                return GestureDetector(
                  onTap:
                      () {
                    setState(
                      () {
                        _selectedTone =
                            tone;
                      },
                    );
                  },
                  child:
                      Container(
                    margin:
                        const EdgeInsets
                            .only(
                      right: 10,
                    ),
                    padding:
                        const EdgeInsets
                            .symmetric(
                      horizontal:
                          22,
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
                                  .bgSurface,
                      borderRadius:
                          BorderRadius.circular(
                        20,
                      ),
                      border:
                          Border.all(
                        color:
                            selected
                                ? Colors
                                    .transparent
                                : AppTheme
                                    .divider,
                      ),
                    ),
                    child:
                        Center(
                      child:
                          Text(
                        tone,
                        style:
                            TextStyle(
                          color:
                              selected
                                  ? Colors
                                      .white
                                  : AppTheme
                                      .textSecondary,
                          fontWeight:
                              selected
                                  ? FontWeight
                                      .bold
                                  : FontWeight
                                      .normal,
                          fontSize:
                              13,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(
            height: 32,
          ),

          GestureDetector(
            onTap:
                _isLoading
                    ? null
                    : _generate,
            child:
                Container(
              width:
                  double.infinity,
              height:
                  52,
              decoration:
                  BoxDecoration(
                gradient:
                    AppTheme
                        .primaryGradient,
                borderRadius:
                    BorderRadius.circular(
                  16,
                ),
                boxShadow: [
                  BoxShadow(
                    color:
                        AppTheme
                            .primary
                            .withValues(
                      alpha:
                          0.30,
                    ),
                    blurRadius:
                        15,
                    offset:
                        const Offset(
                      0,
                      5,
                    ),
                  ),
                ],
              ),
              child:
                  Center(
                child:
                    _isLoading
                        ? const CircularProgressIndicator(
                            color:
                                Colors.white,
                          )
                        : const Text(
                            'Buat Sekarang ✨',
                            style:
                                TextStyle(
                              color:
                                  Colors.white,
                              fontWeight:
                                  FontWeight
                                      .bold,
                              fontSize:
                                  15,
                            ),
                          ),
              ),
            ),
          ),

          if (_result.isNotEmpty) ...[
            const SizedBox(
              height: 28,
            ),

            Row(
              children: [
                const Text(
                  'Hasil Tulisan',
                  style:
                      TextStyle(
                    color:
                        AppTheme
                            .textPrimary,
                    fontWeight:
                        FontWeight.bold,
                    fontSize:
                        15,
                  ),
                ),

                const Spacer(),

                IconButton(
                  icon:
                      const Icon(
                    Icons.copy,
                    color:
                        AppTheme
                            .textSecondary,
                    size:
                        18,
                  ),
                  onPressed:
                      () {
                    Clipboard
                        .setData(
                      ClipboardData(
                        text:
                            _result,
                      ),
                    );

                    ScaffoldMessenger
                        .of(
                      context,
                    ).showSnackBar(
                      const SnackBar(
                        content:
                            Text(
                          'Hasil disalin!',
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),

            const SizedBox(
              height: 8,
            ),

            Container(
              width:
                  double.infinity,
              padding:
                  const EdgeInsets
                      .all(
                16,
              ),
              decoration:
                  BoxDecoration(
                color:
                    AppTheme
                        .bgSurface,
                borderRadius:
                    BorderRadius.circular(
                  16,
                ),
                border:
                    Border.all(
                  color:
                      AppTheme
                          .divider,
                ),
              ),
              child:
                  SelectableText(
                _result,
                style:
                    const TextStyle(
                  color:
                      AppTheme
                          .textPrimary,
                  fontSize:
                      13,
                  height:
                      1.6,
                ),
              ),
            ),
          ],

          const SizedBox(
            height: 40,
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // MY FILES
  // ==========================================================

  Widget _buildMyFilesTab() {
    return const Center(
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
            height: 12,
          ),
          Text(
            'Belum Ada File',
            style:
                TextStyle(
              color:
                  AppTheme.textPrimary,
              fontWeight:
                  FontWeight.bold,
            ),
          ),
          SizedBox(
            height: 4,
          ),
          Text(
            'Hasil tulisan kamu akan tersimpan di sini.',
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
    );
  }

  void _showTokenInfo(
    BuildContext context,
  ) {
    final auth =
        context.read<AuthProvider>();

    showDialog<void>(
      context:
          context,
      builder:
          (_) =>
              AlertDialog(
        backgroundColor:
            AppTheme
                .bgSurface,
        title:
            const Text(
          'Token PintarAja',
          style:
              TextStyle(
            color:
                AppTheme
                    .textPrimary,
          ),
        ),
        content:
            Text(
          'Saldo token kamu: ${auth.tokenBalance}',
          style:
              const TextStyle(
            color:
                AppTheme
                    .textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed:
                () =>
                    Navigator.pop(
              context,
            ),
            child:
                const Text(
              'Tutup',
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
    return GestureDetector(
      onTap:
          onTap,
      child:
          Container(
        padding:
            const EdgeInsets
                .symmetric(
          horizontal: 9,
          vertical: 6,
        ),
        decoration:
            BoxDecoration(
          color:
              AppTheme
                  .surfaceMuted,
          borderRadius:
              BorderRadius.circular(
            20,
          ),
          border:
              Border.all(
            color:
                AppTheme
                    .borderLight,
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
              width: 5,
            ),
            Text(
              '$balance',
              style:
                  const TextStyle(
                color:
                    AppTheme
                        .textPrimary,
                fontSize:
                    11,
                fontWeight:
                    FontWeight
                        .w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}