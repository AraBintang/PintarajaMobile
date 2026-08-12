// ============================================================
// TOOLS SCREEN — AI Tools Grid & Actions
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/api_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../data/services/api_service.dart';
import '../shared/widgets/app_button.dart';
// import '../shared/widgets/app_text_field.dart';

class ToolsScreen extends StatefulWidget {
  const ToolsScreen({super.key});

  @override
  State<ToolsScreen> createState() => _ToolsScreenState();
}

class _ToolsScreenState extends State<ToolsScreen> {
  String _activeTab = 'paraphrase'; // paraphrase, humanizer, plagiarism

  final _textCtrl = TextEditingController();
  String _result = '';
  bool _isLoading = false;
  String? _error;

  // Plagiarism specific
  double? _plagiarismPercent;

  @override
  void dispose() {
    _textCtrl.dispose();
    super.dispose();
  }

  void _changeTab(String tab) {
    setState(() {
      _activeTab = tab;
      _result = '';
      _error = null;
      _plagiarismPercent = null;
    });
  }

  Future<void> _processText() async {
    final text = _textCtrl.text.trim();
    if (text.isEmpty) {
      setState(() => _error = 'Teks tidak boleh kosong');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
      _result = '';
      _plagiarismPercent = null;
    });

    try {
      if (_activeTab == 'paraphrase') {
        final data = await ApiService.instance.post(ApiConstants.paraphrase, {'text': text});
        setState(() {
          _result = data['result'] ?? data['paraphrased_text'] ?? data['text'] ?? '';
        });
      } else if (_activeTab == 'humanizer') {
        final data = await ApiService.instance.post(ApiConstants.humanizer, {'text': text});
        setState(() {
          _result = data['result'] ?? data['humanized_text'] ?? data['text'] ?? '';
        });
      } else if (_activeTab == 'plagiarism') {
        final data = await ApiService.instance.post(ApiConstants.plagiarism, {'text': text});
        setState(() {
          _result = data['report'] ?? 'Pengecekan selesai.';
          _plagiarismPercent = double.tryParse(data['percent']?.toString() ?? '0') ?? 0;
        });
      }
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      appBar: AppBar(
        backgroundColor: AppTheme.bgLight,
        elevation: 0,
        title: const Text('AI Tools', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tab Selector
            Row(
              children: [
                _buildTabButton('Paraphrase', 'paraphrase'),
                const SizedBox(width: 8),
                _buildTabButton('Humanizer', 'humanizer'),
                const SizedBox(width: 8),
                _buildTabButton('Plagiarism', 'plagiarism'),
              ],
            ),
            const SizedBox(height: 24),

            // Input Field
            Text(
              _activeTab == 'plagiarism' ? 'Masukkan Teks yang Mau Dicek' : 'Masukkan Teks Asli',
              style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _textCtrl,
              maxLines: 8,
              style: const TextStyle(color: AppTheme.textPrimary),
              decoration: InputDecoration(
                hintText: _activeTab == 'plagiarism'
                    ? 'Tempelkan artikel atau tugas kamu di sini...'
                    : 'Tulis atau tempel teks kamu di sini...',
                hintStyle: const TextStyle(color: AppTheme.textMuted),
                errorText: _error,
                filled: true,
                fillColor: AppTheme.bgSurface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide(color: AppTheme.divider),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide(color: AppTheme.divider),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide(color: AppTheme.primary, width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Action Button
            AppButton(
              label: _getButtonLabel(),
              isLoading: _isLoading,
              onPressed: _processText,
              gradient: _getButtonGradient(),
            ),

            // Plagiarism Result Badge
            if (_plagiarismPercent != null) ...[
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _plagiarismPercent! > 20
                      ? AppTheme.error.withOpacity(0.1)
                      : AppTheme.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _plagiarismPercent! > 20 ? AppTheme.error : AppTheme.success,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _plagiarismPercent! > 20 ? Icons.warning_amber_rounded : Icons.check_circle_outline,
                      color: _plagiarismPercent! > 20 ? AppTheme.error : AppTheme.success,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Indikasi Plagiarisme',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Teks terindikasi plagiat sebesar ${_plagiarismPercent!.toStringAsFixed(1)}%',
                            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Result Field
            if (_result.isNotEmpty) ...[
              const SizedBox(height: 24),
              Row(
                children: [
                  const Text(
                    'Hasil Proses AI',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.copy, color: AppTheme.textMuted, size: 20),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: _result));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Hasil disalin ke clipboard!')),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.bgSurface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.divider),
                ),
                child: SelectableText(
                  _result,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 14,
                    height: 1.6,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildTabButton(String label, String tab) {
    final active = _activeTab == tab;
    return Expanded(
      child: GestureDetector(
        onTap: () => _changeTab(tab),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: active ? AppTheme.primary : AppTheme.bgSurface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: active ? AppTheme.primary : AppTheme.divider),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: active ? Colors.white : AppTheme.textSecondary,
                fontSize: 12,
                fontWeight: active ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ),
      ),
    );
  }

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

  LinearGradient _getButtonGradient() {
    if (_activeTab == 'humanizer') {
      return const LinearGradient(colors: [Color(0xFF11998E), Color(0xFF38EF7D)]);
    } else if (_activeTab == 'plagiarism') {
      return const LinearGradient(colors: [Color(0xFFFC5C7D), Color(0xFF6A3093)]);
    }
    return AppTheme.primaryGradient;
  }
}
