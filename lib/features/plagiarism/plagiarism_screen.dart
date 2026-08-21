// ============================================================
// PINTARAJA — PLAGIARISM SCREEN
// Full-featured Plagiarism Check: Turnitin & Drillbot
// Upload files, author data, exclusions, payment
// ============================================================

import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/api_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../data/providers/auth_provider.dart';
import '../../data/services/api_service.dart';
import '../shared/widgets/payment_sheet.dart';

import '../shared/widgets/app_sidebar_drawer.dart';

class PlagiarismScreen extends StatefulWidget {
  const PlagiarismScreen({super.key});

  @override
  State<PlagiarismScreen> createState() => _PlagiarismScreenState();
}

class _PlagiarismScreenState extends State<PlagiarismScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _whatsappController = TextEditingController();

  String _selectedService = 'turnitin';
  final List<File> _uploadedFiles = [];
  bool _excludeBiography = true;
  bool _excludeQuotedText = false;
  bool _excludeSmallMatches = false;
  bool _isUploading = false;
  String? _error;
  bool _orderSuccess = false;

  static const int _maxFileSizeMB = 50;
  static const int _minFiles = 1;
  static const int _maxFiles = 3;
  static const int _pricePerFile = 22000;

  @override
  void initState() {
    super.initState();
    _prefillFromProfile();
  }

  void _prefillFromProfile() {
    final user = context.read<AuthProvider>().user;
    if (user != null) {
      final nameParts = user.name.trim().split(' ');
      _firstNameController.text = nameParts.isNotEmpty ? nameParts.first : '';
      _lastNameController.text =
          nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';
      _whatsappController.text = user.phone ?? '';
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _whatsappController.dispose();
    super.dispose();
  }

  Future<void> _pickFiles() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'txt'],
      allowMultiple: true,
      withData: true,
    );

    if (result == null || result.files.isEmpty) return;

    for (final file in result.files) {
      if (_uploadedFiles.length >= 3) {
        if (!mounted) return;
        setState(() {
          _error = 'Maksimal 3 file yang dapat diupload.';
        });
        break;
      }

      final sizeMB = file.size / (1024 * 1024);
      if (sizeMB > _maxFileSizeMB) {
        if (!mounted) return;
        setState(() {
          _error =
              'File ${file.name} terlalu besar (${sizeMB.toStringAsFixed(1)}MB). Maksimum 50MB.';
        });
        continue;
      }

      if (file.path != null) {
        final f = File(file.path!);
        if (await f.exists()) {
          setState(() {
            _error = null;
            _uploadedFiles.add(f);
          });
        }
      } else if (file.bytes != null) {
        final tempDir = await Directory.systemTemp.createTemp('plagiarism_');
        final tempFile = File('${tempDir.path}/${file.name}');
        await tempFile.writeAsBytes(file.bytes!);
        setState(() {
          _error = null;
          _uploadedFiles.add(tempFile);
        });
      }
    }
  }

  void _removeFile(int index) {
    setState(() {
      _uploadedFiles.removeAt(index);
    });
  }

  int get _totalPrice => _uploadedFiles.length * _pricePerFile;

  Future<void> _submitOrder() async {
    if (_uploadedFiles.length < _minFiles) {
      setState(() {
        _error = 'Minimal upload $_minFiles file untuk pengecekan.';
      });
      return;
    }

    if (_firstNameController.text.trim().isEmpty ||
        _lastNameController.text.trim().isEmpty) {
      setState(() {
        _error = 'Nama penulis harus diisi.';
      });
      return;
    }

    if (_whatsappController.text.trim().isEmpty) {
      setState(() {
        _error = 'Nomor WhatsApp harus diisi.';
      });
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() {
      _isUploading = true;
      _error = null;
    });

    try {
      final filesMap = <String, File>{};
      for (int i = 0; i < _uploadedFiles.length; i++) {
        filesMap['documents[$i]'] = _uploadedFiles[i];
      }

      await ApiService.instance.postMultipart(
        ApiConstants.plagiarism,
        fields: {
          'service_type': _selectedService,
          'author_first_name': _firstNameController.text.trim(),
          'author_last_name': _lastNameController.text.trim(),
          'whatsapp_phone': _whatsappController.text.trim(),
          'exclude_biography': _excludeBiography ? '1' : '0',
          'exclude_quoted_text': _excludeQuotedText ? '1' : '0',
          'exclude_small_matches': _excludeSmallMatches ? '1' : '0',
          'channel': 'topup',
          'method': 'topup',
          'phone': _whatsappController.text.trim(),
        },
        files: filesMap,
        timeout: const Duration(seconds: 180),
      );

      if (!mounted) return;

      await context.read<AuthProvider>().refreshUser();

      setState(() {
        _orderSuccess = true;
        _isUploading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _isUploading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Gagal mengirim order. Pastikan koneksi internet stabil.';
        _isUploading = false;
      });
    }
  }

  void _proceedToPayment() {
    Navigator.pop(context);
    PaymentSelectionSheet.show(
      context,
      itemTitle:
          'Pengecekan Plagiarisme (${_selectedService.toUpperCase()}) - ${_uploadedFiles.length} file',
      amount: _totalPrice,
      onPaymentSuccess: () async {
        await context.read<AuthProvider>().refreshUser();
        if (mounted) {
          setState(() => _orderSuccess = true);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_orderSuccess) {
      return _buildSuccessView();
    }

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppTheme.getBg(context),
      drawer: const AppSidebarDrawer(),
      appBar: AppBar(
        backgroundColor: AppTheme.getBg(context),
        elevation: 0,
        leading: Builder(
          builder: (drawerContext) => IconButton(
            icon:
                Icon(Icons.menu_rounded, color: AppTheme.getTextColor(context)),
            onPressed: () => Scaffold.of(drawerContext).openDrawer(),
          ),
        ),
        title: Text(
          'Cek Plagiarisme',
          style: TextStyle(
              color: AppTheme.getTextColor(context),
              fontWeight: FontWeight.w700,
              fontSize: 17),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildServiceHeader(),
              const SizedBox(height: 18),
              _buildServiceSelector(),
              const SizedBox(height: 18),
              _buildFileUploadSection(),
              if (_error != null) ...[
                const SizedBox(height: 12),
                _buildErrorBox(),
              ],
              const SizedBox(height: 18),
              _buildAuthorSection(),
              const SizedBox(height: 18),
              _buildExclusionSection(),
              const SizedBox(height: 18),
              _buildPaymentSummary(),
              const SizedBox(height: 16),
              _buildSubmitButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessView() {
    return Scaffold(
      backgroundColor: AppTheme.getBg(context),
      appBar: AppBar(
        backgroundColor: AppTheme.getBg(context),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Order Dikirim',
            style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                    color: AppTheme.success.withValues(alpha: 0.12),
                    shape: BoxShape.circle),
                child: const Icon(Icons.check_circle_rounded,
                    color: AppTheme.success, size: 44),
              ),
              const SizedBox(height: 20),
              const Text('Order Berhasil Dikirim!',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary)),
              const SizedBox(height: 8),
              Text(
                'Pengecekan plagiarisme ${_selectedService.toUpperCase()} kamu sedang diproses. Hasil akan dikirim ke WhatsApp kamu.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: AppTheme.textSecondary, fontSize: 13, height: 1.5),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('Kembali',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildServiceHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primary.withValues(alpha: 0.08),
            AppTheme.primary.withValues(alpha: 0.03)
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.plagiarism_outlined,
                color: AppTheme.primary, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Deteksi Plagiarisme',
                    style: TextStyle(
                        color: AppTheme.getTextColor(context),
                        fontWeight: FontWeight.w700,
                        fontSize: 14)),
                const SizedBox(height: 3),
                Text('Periksa keaslian dokumen kamu dengan database global.',
                    style: TextStyle(
                        color: AppTheme.getTextSecondary(context),
                        fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Pilih Layanan',
            style: TextStyle(
                color: AppTheme.getTextColor(context),
                fontWeight: FontWeight.w700,
                fontSize: 14)),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _ServiceCard(
                title: 'Turnitin Check',
                subtitle: 'Database akademik global',
                icon: Icons.school_rounded,
                isSelected: _selectedService == 'turnitin',
                onTap: () => setState(() => _selectedService = 'turnitin'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _ServiceCard(
                title: 'Drillbot Check',
                subtitle: 'AI-powered detection',
                icon: Icons.smart_toy_rounded,
                isSelected: _selectedService == 'drillbot',
                onTap: () => setState(() => _selectedService = 'drillbot'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFileUploadSection() {
    final maxSizeMB = _maxFileSizeMB;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Upload Dokumen',
                style: TextStyle(
                    color: AppTheme.getTextColor(context),
                    fontWeight: FontWeight.w700,
                    fontSize: 14)),
            Text('${_uploadedFiles.length} file',
                style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600)),
          ],
        ),
        const SizedBox(height: 4),
        Text(
            'Minimal $_minFiles file, maksimal 3 file. Maks $maxSizeMB MB per file. Format: PDF, DOC, DOCX, TXT',
            style: TextStyle(
                color: AppTheme.getTextSecondary(context), fontSize: 11)),
        const SizedBox(height: 10),

        // File List
        if (_uploadedFiles.isNotEmpty) ...[
          ...List.generate(_uploadedFiles.length, (index) {
            final file = _uploadedFiles[index];
            final fileName = file.path.split(Platform.pathSeparator).last;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                  color: AppTheme.getSurface(context),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.borderLight)),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8)),
                    child: const Icon(Icons.description_rounded,
                        color: AppTheme.primary, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(fileName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600)),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded,
                        size: 18, color: AppTheme.textMuted),
                    onPressed: () => _removeFile(index),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 8),
        ],

        // Upload Button
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _isUploading ? null : _pickFiles,
            icon: const Icon(Icons.cloud_upload_rounded,
                size: 18, color: AppTheme.primary),
            label: Text(
                _uploadedFiles.isEmpty
                    ? 'Pilih File Dokumen'
                    : 'Tambah File Lagi',
                style: const TextStyle(
                    fontWeight: FontWeight.w600, color: AppTheme.primary)),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppTheme.primary),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorBox() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: AppTheme.error.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.error.withValues(alpha: 0.25))),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline_rounded,
              color: AppTheme.error, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(_error!,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: AppTheme.error, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _buildAuthorSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Data Penulis',
            style: TextStyle(
                color: AppTheme.getTextColor(context),
                fontWeight: FontWeight.w700,
                fontSize: 14)),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _firstNameController,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  hintText: 'Nama Depan',
                  isDense: true,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _lastNameController,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  hintText: 'Nama Belakang',
                  isDense: true,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _whatsappController,
          keyboardType: TextInputType.phone,
          decoration: InputDecoration(
            hintText: 'No. WhatsApp (08xxxxxxxxxx)',
            prefixIcon: const Icon(Icons.chat_rounded, size: 20),
            isDense: true,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }

  Widget _buildExclusionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Pengaturan Pengecualian',
            style: TextStyle(
                color: AppTheme.getTextColor(context),
                fontWeight: FontWeight.w700,
                fontSize: 14)),
        const SizedBox(height: 4),
        Text('Pilih bagian yang ingin dikecualikan dari pengecekan',
            style: TextStyle(
                color: AppTheme.getTextSecondary(context), fontSize: 11)),
        const SizedBox(height: 10),
        _ExclusionCheckbox(
          value: _excludeBiography,
          title: 'Biografi Teks',
          subtitle: 'Sumber yang dikutip dari daftar pustaka',
          onChanged: (v) => setState(() => _excludeBiography = v ?? true),
        ),
        _ExclusionCheckbox(
          value: _excludeQuotedText,
          title: 'Teks yang Dikutip',
          subtitle: 'Paragraf dengan tanda kutip langsung',
          onChanged: (v) => setState(() => _excludeQuotedText = v ?? false),
        ),
        _ExclusionCheckbox(
          value: _excludeSmallMatches,
          title: 'Small Matches',
          subtitle: 'Kecocokan kata pendek (<5 kata)',
          onChanged: (v) => setState(() => _excludeSmallMatches = v ?? false),
        ),
      ],
    );
  }

  Widget _buildPaymentSummary() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.getSurface(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Ringkasan Pembayaran',
              style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: AppTheme.textPrimary)),
          const SizedBox(height: 12),
          _SummaryRow(
              label: 'Layanan',
              value: _selectedService == 'turnitin'
                  ? 'Turnitin Check'
                  : 'Drillbot Check'),
          const SizedBox(height: 8),
          _SummaryRow(
              label: 'Jumlah File', value: '${_uploadedFiles.length} file'),
          const SizedBox(height: 8),
          _SummaryRow(label: 'Harga / File', value: 'Rp $_pricePerFile'),
          const Divider(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total',
                  style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      color: AppTheme.textPrimary)),
              Text('Rp ${_totalPrice.toStringAsFixed(0)}',
                  style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      color: AppTheme.primary)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    final canSubmit = _uploadedFiles.length >= _minFiles && !_isUploading;

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppTheme.surfaceMuted,
          disabledForegroundColor: AppTheme.textMuted,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: canSubmit ? 2 : 0,
        ),
        onPressed: canSubmit ? _showPaymentConfirmation : null,
        child: _isUploading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                    strokeWidth: 2.5, color: Colors.white),
              )
            : Text(
                'Lanjut ke Pembayaran - Rp ${_totalPrice.toStringAsFixed(0)}',
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
      ),
    );
  }

  void _showPaymentConfirmation() {
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
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const Text('Konfirmasi Order',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary)),
              const SizedBox(height: 16),

              // Mini Order Summary
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: AppTheme.primary.withValues(alpha: 0.15)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SummaryRow(
                        label: 'Layanan',
                        value: _selectedService == 'turnitin'
                            ? 'Turnitin Check'
                            : 'Drillbot Check'),
                    const SizedBox(height: 6),
                    _SummaryRow(
                        label: 'File',
                        value: '${_uploadedFiles.length} dokumen'),
                    const SizedBox(height: 6),
                    _SummaryRow(
                        label: 'Penulis',
                        value:
                            '${_firstNameController.text} ${_lastNameController.text}'),
                    const SizedBox(height: 6),
                    _SummaryRow(
                        label: 'WhatsApp', value: _whatsappController.text),
                    const Divider(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total Pembayaran',
                            style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
                                color: AppTheme.textPrimary)),
                        Text('Rp ${_totalPrice.toStringAsFixed(0)}',
                            style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                                color: AppTheme.primary)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Payment Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.qr_code_2_rounded, size: 20),
                  label: const Text('Bayar via QRIS',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    elevation: 3,
                  ),
                  onPressed: () {
                    Navigator.pop(ctx);
                    _submitOrder().then((_) {
                      if (_orderSuccess && mounted) {
                        _proceedToPayment();
                      }
                    });
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ============================================================
// SERVICE CARD
// ============================================================

class _ServiceCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _ServiceCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primary.withValues(alpha: 0.06)
              : AppTheme.getSurface(context),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: isSelected ? AppTheme.primary : AppTheme.borderLight,
              width: isSelected ? 2 : 1),
        ),
        child: Column(
          children: [
            Icon(icon,
                color: isSelected ? AppTheme.primary : AppTheme.textSecondary,
                size: 28),
            const SizedBox(height: 8),
            Text(title,
                style: TextStyle(
                    color: isSelected ? AppTheme.primary : AppTheme.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 13),
                textAlign: TextAlign.center),
            const SizedBox(height: 2),
            Text(subtitle,
                style: TextStyle(
                    color: AppTheme.getTextSecondary(context), fontSize: 10),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// EXCLUSION CHECKBOX
// ============================================================

class _ExclusionCheckbox extends StatelessWidget {
  final bool value;
  final String title;
  final String subtitle;
  final ValueChanged<bool?> onChanged;

  const _ExclusionCheckbox({
    required this.value,
    required this.title,
    required this.subtitle,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.getSurface(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Row(
        children: [
          Checkbox(
            value: value,
            activeColor: AppTheme.primary,
            onChanged: onChanged,
            visualDensity: VisualDensity.compact,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary)),
                Text(subtitle,
                    style: const TextStyle(
                        fontSize: 11, color: AppTheme.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// SUMMARY ROW
// ============================================================

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style:
                const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
        Text(value,
            style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w600)),
      ],
    );
  }
}
