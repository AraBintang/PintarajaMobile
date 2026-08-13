// ============================================================
// PINTARAJA — AI TOOLS SCREEN
// Paraphrase + Humanizer + Plagiarism
// Responsive Android 720x1520
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/constants/api_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../data/providers/auth_provider.dart';
import '../../data/services/api_service.dart';
import '../shared/widgets/app_button.dart';

class ToolsScreen extends StatefulWidget {
  const ToolsScreen({
    super.key,
  });

  @override
  State<ToolsScreen> createState() =>
      _ToolsScreenState();
}

class _ToolsScreenState
    extends State<ToolsScreen> {
  String _activeTab = 'paraphrase';

  final TextEditingController _textController =
      TextEditingController();

  String _result = '';

  String? _error;

  bool _isLoading = false;

  double? _plagiarismPercent;

  @override
  void dispose() {
    _textController.dispose();
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
    });
  }

  // ==========================================================
  // PROCESS
  // ==========================================================

  Future<void> _processText() async {
    final text =
        _textController.text.trim();

    if (text.isEmpty) {
      setState(() {
        _error =
            'Teks tidak boleh kosong.';
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
          data =
              await ApiService.instance.post(
            ApiConstants.humanizer,
            {
              'text': text,
            },
            timeout:
                const Duration(
              seconds: 120,
            ),
          );
          break;

        case 'plagiarism':
          data =
              await ApiService.instance.post(
            ApiConstants.plagiarism,
            {
              'text': text,
            },
            timeout:
                const Duration(
              seconds: 120,
            ),
          );
          break;

        case 'paraphrase':
        default:
          data =
              await ApiService.instance.post(
            ApiConstants.paraphrase,
            {
              'text': text,
            },
            timeout:
                const Duration(
              seconds: 120,
            ),
          );
          break;
      }

      if (!mounted) {
        return;
      }

      if (_activeTab ==
          'plagiarism') {
        final report =
            _extractText(
          data,
          const [
            'report',
            'result',
            'content',
            'text',
            'message',
          ],
        );

        final percent =
            _extractDouble(
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
          _result = report.isEmpty
              ? 'Pengecekan selesai.'
              : report;

          _plagiarismPercent =
              percent ?? 0;
        });
      } else {
        final result =
            _extractText(
          data,
          _activeTab ==
                  'paraphrase'
              ? const [
                  'result',
                  'paraphrased_text',
                  'content',
                  'text',
                  'output',
                  'answer',
                ]
              : const [
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
            _error =
                'AI tidak mengembalikan hasil.';
          });
        } else {
          setState(() {
            _result = result;
          });
        }
      }

      // Refresh saldo token setelah
      // penggunaan AI Tools.
      await context
          .read<AuthProvider>()
          .refreshUser();

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
        _error =
            'Gagal memproses teks. Coba lagi.';
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
      final value =
          data[key];

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
      final value =
          data[key];

      if (value == null) {
        continue;
      }

      if (value is num) {
        return value.toDouble();
      }

      final parsed =
          double.tryParse(
        value.toString(),
      );

      if (parsed != null) {
        return parsed;
      }
    }

    final nested =
        data['data'];

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
          title: const Text(
            'Token PintarAja',
            style: TextStyle(
              color:
                  AppTheme.textPrimary,
              fontWeight:
                  FontWeight.w700,
            ),
          ),
          content: Text(
            'Saldo token kamu: ${auth.tokenBalance}',
            style: const TextStyle(
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
      appBar: AppBar(
        backgroundColor:
            AppTheme.backgroundApp,
        elevation: 0,
        leading: IconButton(
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
          'AI Tools',
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
            width: 8,
          ),
        ],
      ),
      body:
          SingleChildScrollView(
        keyboardDismissBehavior:
            ScrollViewKeyboardDismissBehavior.onDrag,
        padding:
            const EdgeInsets.fromLTRB(
          16,
          12,
          16,
          30,
        ),
        child:
            Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            _buildTabSelector(),

            const SizedBox(
              height: 22,
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
                message:
                    _error!,
              ),
            ],

            const SizedBox(
              height: 18,
            ),

            _buildActionButton(),

            if (_plagiarismPercent !=
                null) ...[
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
  // TAB SELECTOR
  // ==========================================================

  Widget _buildTabSelector() {
    return SizedBox(
      width:
          double.infinity,
      child:
          Row(
        children: [
          Expanded(
            child:
                _ToolTabButton(
              label:
                  'Paraphrase',
              active:
                  _activeTab ==
                      'paraphrase',
              onTap:
                  () =>
                      _changeTab(
                'paraphrase',
              ),
            ),
          ),

          const SizedBox(
            width: 7,
          ),

          Expanded(
            child:
                _ToolTabButton(
              label:
                  'Humanizer',
              active:
                  _activeTab ==
                      'humanizer',
              onTap:
                  () =>
                      _changeTab(
                'humanizer',
              ),
            ),
          ),

          const SizedBox(
            width: 7,
          ),

          Expanded(
            child:
                _ToolTabButton(
              label:
                  'Plagiarism',
              active:
                  _activeTab ==
                      'plagiarism',
              onTap:
                  () =>
                      _changeTab(
                'plagiarism',
              ),
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

    if (_activeTab ==
        'plagiarism') {
      title =
          'Masukkan Teks yang Mau Dicek';
    } else if (_activeTab ==
        'humanizer') {
      title =
          'Masukkan Teks Asli';
    } else {
      title =
          'Masukkan Teks Asli';
    }

    return Text(
      title,
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

  // ==========================================================
  // INPUT FIELD
  // ==========================================================

  Widget _buildInputField() {
    final hint =
        _activeTab ==
                'plagiarism'
            ? 'Tempelkan artikel atau tugas kamu di sini...'
            : 'Tulis atau tempel teks kamu di sini...';

    return TextField(
      controller:
          _textController,
      maxLines:
          9,
      minLines:
          7,
      textInputAction:
          TextInputAction.newline,
      style:
          const TextStyle(
        color:
            AppTheme.textPrimary,
        fontSize:
            13.5,
        height:
            1.5,
      ),
      decoration:
          InputDecoration(
        hintText:
            hint,
        hintStyle:
            const TextStyle(
          color:
              AppTheme.textMuted,
        ),
        filled:
            true,
        fillColor:
            AppTheme.surfaceLight,
        contentPadding:
            const EdgeInsets.all(
          16,
        ),
        enabledBorder:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(
            18,
          ),
          borderSide:
              const BorderSide(
            color:
                AppTheme.borderLight,
          ),
        ),
        focusedBorder:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(
            18,
          ),
          borderSide:
              const BorderSide(
            color:
                AppTheme.primary,
            width:
                1.4,
          ),
        ),
        suffixIcon:
            _textController.text
                    .isNotEmpty
                ? IconButton(
                    onPressed:
                        _clearText,
                    tooltip:
                        'Hapus teks',
                    icon:
                        const Icon(
                      Icons
                          .close_rounded,
                      size:
                          19,
                      color:
                          AppTheme
                              .textMuted,
                    ),
                  )
                : null,
      ),
      onChanged:
          (_) {
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
      width:
          double.infinity,
      child:
          AppButton(
        label:
            _getButtonLabel(),
        isLoading:
            _isLoading,
        onPressed:
            _isLoading
                ? null
                : _processText,
        gradient:
            _getButtonGradient(),
      ),
    );
  }

  // ==========================================================
  // BUTTON LABEL
  // ==========================================================

  String _getButtonLabel() {
    switch (_activeTab) {
      case 'humanizer':
        return 'Humanize Teks ✨';

      case 'plagiarism':
        return 'Periksa Plagiarisme 🔍';

      case 'paraphrase':
      default:
        return 'Paraphrase Teks 🔄';
    }
  }

  // ==========================================================
  // BUTTON GRADIENT
  // ==========================================================

  LinearGradient _getButtonGradient() {
    if (_activeTab ==
        'humanizer') {
      return const LinearGradient(
        colors: [
          Color(0xFF11998E),
          Color(0xFF38EF7D),
        ],
      );
    }

    if (_activeTab ==
        'plagiarism') {
      return const LinearGradient(
        colors: [
          Color(0xFFFC5C7D),
          Color(0xFF6A3093),
        ],
      );
    }

    return AppTheme.primaryGradient;
  }

  // ==========================================================
  // PLAGIARISM CARD
  // ==========================================================

  Widget _buildPlagiarismCard() {
    final percent =
        _plagiarismPercent ??
            0;

    final suspicious =
        percent > 20;

    final cardColor =
        suspicious
            ? AppTheme.error
                .withValues(
                alpha:
                    0.08,
              )
            : AppTheme.success
                .withValues(
                alpha:
                    0.08,
              );

    final borderColor =
        suspicious
            ? AppTheme.error
            : AppTheme.success;

    final icon =
        suspicious
            ? Icons.warning_amber_rounded
            : Icons.check_circle_outline;

    return Container(
      width:
          double.infinity,
      padding:
          const EdgeInsets.all(
        15,
      ),
      decoration:
          BoxDecoration(
        color:
            cardColor,
        borderRadius:
            BorderRadius.circular(
          16,
        ),
        border:
            Border.all(
          color:
              borderColor,
        ),
      ),
      child:
          Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color:
                borderColor,
            size:
                25,
          ),

          const SizedBox(
            width: 12,
          ),

          Expanded(
            child:
                Column(
              crossAxisAlignment:
                  CrossAxisAlignment
                      .start,
              children: [
                const Text(
                  'Indikasi Plagiarisme',
                  style:
                      TextStyle(
                    color:
                        AppTheme
                            .textPrimary,
                    fontWeight:
                        FontWeight.w700,
                    fontSize:
                        13,
                  ),
                ),

                const SizedBox(
                  height: 4,
                ),

                Text(
                  suspicious
                      ? 'Teks terindikasi memiliki kemiripan sebesar ${percent.toStringAsFixed(1)}%.'
                      : 'Teks memiliki indikasi kemiripan yang rendah (${percent.toStringAsFixed(1)}%).',
                  style:
                      const TextStyle(
                    color:
                        AppTheme
                            .textSecondary,
                    fontSize:
                        12,
                    height:
                        1.35,
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
            style:
                TextStyle(
              color:
                  borderColor,
              fontSize:
                  16,
              fontWeight:
                  FontWeight.w800,
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
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child:
                  Text(
                'Hasil Proses AI',
                style:
                    TextStyle(
                  color:
                      AppTheme
                          .textPrimary,
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
                        .textMuted,
                size:
                    19,
              ),
            ),

            IconButton(
              tooltip:
                  'Hapus hasil',
              onPressed: () {
                setState(() {
                  _result =
                      '';
                });
              },
              icon:
                  const Icon(
                Icons
                    .delete_outline_rounded,
                color:
                    AppTheme
                        .textMuted,
                size:
                    20,
              ),
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
                  13.5,
              height:
                  1.6,
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

class _ToolTabButton
    extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _ToolTabButton({
    required this.label,
    required this.active,
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
            Ink(
          height:
              42,
          decoration:
              BoxDecoration(
            color:
                active
                    ? AppTheme.primary
                    : AppTheme.surfaceLight,
            borderRadius:
                BorderRadius.circular(
              20,
            ),
            border:
                Border.all(
              color:
                  active
                      ? AppTheme.primary
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
                  TextOverflow
                      .ellipsis,
              style:
                  TextStyle(
                color:
                    active
                        ? Colors.white
                        : AppTheme
                            .textSecondary,
                fontSize:
                    11.5,
                fontWeight:
                    active
                        ? FontWeight.w700
                        : FontWeight.w500,
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
            AppTheme.error
                .withValues(
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
              AppTheme.error
                  .withValues(
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
                Icons.diamond_rounded,
                color:
                    Color(0xFFF59E0B),
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