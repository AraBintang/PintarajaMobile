// ============================================================
// PINTARAJA — TRANSCRIBE SCREEN
// Konversi audio & video menjadi teks
// Upload, YouTube link, atau rekam langsung
// ============================================================

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import '../../core/constants/api_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../data/services/api_service.dart';
import '../../data/services/storage_service.dart';
import '../shared/widgets/app_sidebar_drawer.dart';

class TranscribeScreen extends StatefulWidget {
  const TranscribeScreen({super.key});

  @override
  State<TranscribeScreen> createState() => _TranscribeScreenState();
}

class _TranscribeScreenState extends State<TranscribeScreen>
    with SingleTickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _youtubeController = TextEditingController();
  final AudioRecorder _audioRecorder = AudioRecorder();

  // Input method: "upload", "youtube", "record"
  String _selectedMethod = 'upload';

  // Upload state
  File? _selectedFile;

  // YouTube state
  String? _youtubeError;

  // Recording state
  bool _isRecording = false;
  bool _hasRecording = false;
  File? _recordedFile;

  // Transcription state
  bool _isSubmitting = false;
  bool _isProcessing = false;
  String? _transcriptionStatus;
  String? _transcriptionResult;
  String? _error;

  // History
  List<Map<String, dynamic>> _history = [];
  bool _isLoadingHistory = false;

  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _loadHistory();
    _checkActiveTranscription();
  }

  @override
  void dispose() {
    _youtubeController.dispose();
    _pollTimer?.cancel();
    _stopRecording();
    _audioRecorder.dispose();
    super.dispose();
  }

  // ==========================================================
  // FILE PICKING
  // ==========================================================

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['mp3', 'wav', 'mp4', 'm4a', 'ogg', 'webm'],
    );

    if (result == null || result.files.isEmpty) return;

    final file = result.files.first;
    final sizeMB = file.size / (1024 * 1024);

    if (sizeMB > 25) {
      setState(() {
        _error = 'File terlalu besar (${sizeMB.toStringAsFixed(1)}MB). Maksimum 25MB.';
      });
      return;
    }

    if (file.path != null) {
      final f = File(file.path!);
      if (await f.exists()) {
        setState(() {
          _error = null;
          _selectedFile = f;
        });
      }
    }
  }

  // ==========================================================
  // RECORDING
  // ==========================================================

  Future<void> _toggleRecording() async {
    if (_isRecording) {
      await _stopRecording();
    } else {
      await _startRecording();
    }
  }

  Future<void> _startRecording() async {
    try {
      if (!await _audioRecorder.hasPermission()) {
        setState(() {
          _error = 'Izin microphone belum diberikan.';
        });
        return;
      }

      final dir = await getTemporaryDirectory();
      final filePath =
          '${dir.path}/recording_${DateTime.now().millisecondsSinceEpoch}.m4a';

      await _audioRecorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          sampleRate: 44100,
        ),
        path: filePath,
      );

      setState(() {
        _isRecording = true;
        _error = null;
      });
    } catch (e) {
      setState(() {
        _error = 'Gagal memulai rekaman. Pastikan izin microphone diberikan.';
      });
    }
  }

  Future<void> _stopRecording() async {
    try {
      final path = await _audioRecorder.stop();

      if (path != null && path.isNotEmpty) {
        final f = File(path);
        if (await f.exists()) {
          setState(() {
            _isRecording = false;
            _hasRecording = true;
            _recordedFile = f;
          });
          return;
        }
      }

      setState(() {
        _isRecording = false;
      });
    } catch (_) {
      setState(() {
        _isRecording = false;
      });
    }
  }

  void _clearRecording() {
    setState(() {
      _hasRecording = false;
      _recordedFile = null;
    });
  }

  // ==========================================================
  // TRANSCRIPTION API
  // ==========================================================

  bool get _canSubmit {
    if (_isSubmitting || _isProcessing) return false;

    switch (_selectedMethod) {
      case 'upload':
        return _selectedFile != null;
      case 'youtube':
        return _youtubeController.text.trim().isNotEmpty;
      case 'record':
        return _hasRecording && _recordedFile != null;
      default:
        return false;
    }
  }

  Future<void> _startTranscription() async {
    if (!_canSubmit) return;

    FocusScope.of(context).unfocus();
    setState(() {
      _isSubmitting = true;
      _error = null;
      _transcriptionResult = null;
    });

    try {
      final token = StorageService.getToken();
      if (token == null || token.isEmpty) {
        throw ApiException('Sesi login sudah berakhir.');
      }

      final request = http.MultipartRequest(
        'POST',
        Uri.parse(ApiConstants.transcribes),
      );

      request.headers['Authorization'] = 'Bearer $token';
      request.headers['Accept'] = 'application/json';

      switch (_selectedMethod) {
        case 'upload':
          request.fields['source'] = 'upload';
          request.files.add(
            await http.MultipartFile.fromPath('file', _selectedFile!.path),
          );
          break;

        case 'youtube':
          request.fields['source'] = 'youtube';
          request.fields['video_url'] = _youtubeController.text.trim();
          break;

        case 'record':
          request.fields['source'] = 'upload';
          request.files.add(
            await http.MultipartFile.fromPath('file', _recordedFile!.path),
          );
          break;
      }

      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = _parseResponse(response.body);

        if (data != null && data['id'] != null) {
          final id = data['id'] is int
              ? data['id'] as int
              : int.tryParse(data['id'].toString());

          if (id != null) {
            setState(() {
              _isSubmitting = false;
              _isProcessing = true;
              _transcriptionStatus = data['status']?.toString() ?? 'pending';
            });
            _startPolling(id);
            return;
          }
        }

        setState(() {
          _isSubmitting = false;
          _error = 'Gagal memulai transkripsi. Response tidak valid.';
        });
      } else {
        final data = _parseResponse(response.body);
        final message = _extractError(data, response.statusCode);

        if (!mounted) return;
        setState(() {
          _isSubmitting = false;
          _error = message;
        });
      }
    } on SocketException {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _error = 'Tidak ada koneksi internet.';
      });
    } on TimeoutException {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _error = 'Request terlalu lama. Coba lagi.';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _error = 'Gagal memulai transkripsi.';
      });
    }
  }

  void _startPolling(int id) {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _checkTranscriptionStatus(id);
    });
  }

  Future<void> _checkTranscriptionStatus(int id) async {
    try {
      final result = await ApiService.instance.get(
        ApiConstants.transcribeStatus(id),
      );

      if (!mounted) return;

      final status = result['status']?.toString() ?? '';
      final data = result['data']?.toString();

      if (status == 'completed' || status == 'failed') {
        _pollTimer?.cancel();

        setState(() {
          _isProcessing = false;
          _transcriptionStatus = status;
          _transcriptionResult = status == 'completed' ? data : null;
          _error = status == 'failed' ? 'Transkripsi gagal. Coba lagi.' : null;
        });

        _loadHistory();
      } else {
        setState(() {
          _transcriptionStatus = status;
        });
      }
    } catch (_) {
      // Polling errors are silent
    }
  }

  Future<void> _checkActiveTranscription() async {
    try {
      final result = await ApiService.instance.get(
        ApiConstants.transcribeActive,
      );

      if (!mounted) return;

      if (result is Map && result['active'] == true) {
        final data = result['data'];
        if (data is Map && data['id'] != null) {
          final id = data['id'] is int
              ? data['id'] as int
              : int.tryParse(data['id'].toString());

          if (id != null) {
            final status = data['status']?.toString() ?? 'processing';

            if (status != 'completed' && status != 'failed') {
            setState(() {
              _isProcessing = true;
              _transcriptionStatus = status;
            });
              _startPolling(id);
            }
          }
        }
      }
    } catch (_) {
      // Silent check
    }
  }

  // ==========================================================
  // HISTORY
  // ==========================================================

  Future<void> _loadHistory() async {
    setState(() => _isLoadingHistory = true);

    try {
      final result = await ApiService.instance.get(
        ApiConstants.transcribes,
      );

      if (!mounted) return;

      if (result is Map && result['data'] is List) {
        setState(() {
          _history = List<Map<String, dynamic>>.from(result['data']);
          _isLoadingHistory = false;
        });
      } else if (result is List) {
        setState(() {
          _history = List<Map<String, dynamic>>.from(result);
          _isLoadingHistory = false;
        });
      } else {
        setState(() {
          _history = [];
          _isLoadingHistory = false;
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoadingHistory = false;
      });
    }
  }

  Future<void> _deleteTranscription(int id) async {
    try {
      await ApiService.instance.delete('${ApiConstants.transcribes}/$id');
      _loadHistory();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal menghapus transkripsi.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _viewResult(Map<String, dynamic> item) {
    final data = item['data']?.toString();
    final status = item['status']?.toString() ?? '';
    final name = item['name']?.toString() ?? 'Transkripsi';

    if (status == 'completed' && data != null && data.isNotEmpty) {
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) {
          return DraggableScrollableSheet(
            initialChildSize: 0.7,
            minChildSize: 0.4,
            maxChildSize: 0.95,
            builder: (ctx, scrollController) {
              return Container(
                decoration: BoxDecoration(
                  color: AppTheme.getSurface(context),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                ),
                child: Column(
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 12),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppTheme.getBorder(context),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 14,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              name,
                              style: TextStyle(
                                color: AppTheme.getTextColor(context),
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.copy_rounded, size: 20),
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: data));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Teks disalin ke clipboard.'),
                                  behavior: SnackBarBehavior.floating,
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: SingleChildScrollView(
                        controller: scrollController,
                        padding: const EdgeInsets.all(20),
                        child: SelectableText(
                          data,
                          style: TextStyle(
                            color: AppTheme.getTextColor(context),
                            fontSize: 14,
                            height: 1.7,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      );
    } else if (status != 'completed') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Transkripsi masih dalam status "$status".'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tidak ada data transkripsi.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // ==========================================================
  // HELPERS
  // ==========================================================

  Map<String, dynamic>? _parseResponse(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  String _extractError(dynamic data, int statusCode) {
    if (data is Map) {
      final message = data['message'];
      if (message != null && message.toString().trim().isNotEmpty) {
        return message.toString().trim();
      }
      final errors = data['errors'];
      if (errors is Map && errors.isNotEmpty) {
        final first = errors.values.first;
        if (first is List && first.isNotEmpty) {
          return first.first.toString();
        }
      }
    }

    switch (statusCode) {
      case 401:
        return 'Sesi login sudah berakhir.';
      case 403:
        return 'Kamu tidak memiliki akses.';
      case 422:
        return 'Data tidak valid. Cek input kamu.';
      case 429:
        return 'Terlalu banyak permintaan. Coba lagi.';
      default:
        return 'Terjadi kesalahan. Coba lagi.';
    }
  }

  String _sourceIcon(String source) {
    switch (source) {
      case 'upload':
        return '📁';
      case 'youtube':
        return '🎬';
      case 'record':
        return '🎙️';
      default:
        return '📄';
    }
  }

  String _statusText(String? status) {
    switch (status) {
      case 'pending':
        return 'Menunggu...';
      case 'processing':
        return 'Memproses...';
      case 'completed':
        return 'Selesai';
      case 'failed':
        return 'Gagal';
      default:
        return status ?? '-';
    }
  }

  Color _statusColor(String? status) {
    switch (status) {
      case 'completed':
        return AppTheme.success;
      case 'failed':
        return AppTheme.error;
      case 'processing':
        return AppTheme.warning;
      default:
        return AppTheme.textMuted;
    }
  }

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDarkMode(context);

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppTheme.getBg(context),
      drawer: const AppSidebarDrawer(),
      appBar: AppBar(
        backgroundColor: AppTheme.getBg(context),
        elevation: 0,
        leading: Builder(
          builder: (drawerContext) => IconButton(
            icon: Icon(
              Icons.menu_rounded,
              color: AppTheme.getTextColor(context),
            ),
            onPressed: () => Scaffold.of(drawerContext).openDrawer(),
          ),
        ),
        title: Text(
          'Transcribe AI',
          style: TextStyle(
            color: AppTheme.getTextColor(context),
            fontWeight: FontWeight.w700,
            fontSize: 17,
          ),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(isDark),
              const SizedBox(height: 20),
              _buildInputMethodCards(isDark),
              const SizedBox(height: 16),
              _buildActiveInputSection(isDark),
              if (_error != null) ...[
                const SizedBox(height: 12),
                _buildErrorBox(),
              ],
              const SizedBox(height: 20),
              _buildTranscribeButton(isDark),
              if (_isProcessing || _transcriptionResult != null) ...[
                const SizedBox(height: 20),
                _buildStatusSection(isDark),
              ],
              const SizedBox(height: 24),
              _buildHistorySection(isDark),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // HEADER
  // ==========================================================

  Widget _buildHeader(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.accentPurple.withValues(alpha: 0.08),
            AppTheme.primary.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.accentPurple.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.accentPurple.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.record_voice_over_rounded,
              color: AppTheme.accentPurple,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Transcribe AI',
                  style: TextStyle(
                    color: AppTheme.getTextColor(context),
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Konversi audio & video menjadi teks',
                  style: TextStyle(
                    color: AppTheme.getTextSecondary(context),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // INPUT METHOD CARDS
  // ==========================================================

  Widget _buildInputMethodCards(bool isDark) {
    return Row(
      children: [
        Expanded(
          child: _MethodCard(
            icon: Icons.upload_file_rounded,
            title: 'Upload File',
            isSelected: _selectedMethod == 'upload',
            onTap: () => setState(() => _selectedMethod = 'upload'),
            isDark: isDark,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _MethodCard(
            icon: Icons.link_rounded,
            title: 'YouTube',
            isSelected: _selectedMethod == 'youtube',
            onTap: () => setState(() => _selectedMethod = 'youtube'),
            isDark: isDark,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _MethodCard(
            icon: Icons.mic_rounded,
            title: 'Rekam',
            isSelected: _selectedMethod == 'record',
            onTap: () => setState(() => _selectedMethod = 'record'),
            isDark: isDark,
          ),
        ),
      ],
    );
  }

  // ==========================================================
  // ACTIVE INPUT SECTION
  // ==========================================================

  Widget _buildActiveInputSection(bool isDark) {
    switch (_selectedMethod) {
      case 'upload':
        return _buildUploadSection(isDark);
      case 'youtube':
        return _buildYouTubeSection(isDark);
      case 'record':
        return _buildRecordSection(isDark);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildUploadSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Upload File',
          style: TextStyle(
            color: AppTheme.getTextColor(context),
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'MP3, WAV, MP4, M4A, OGG, WebM \u2022 Max 25MB',
          style: TextStyle(
            color: AppTheme.getTextSecondary(context),
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 10),

        if (_selectedFile != null) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppTheme.getSurface(context),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.borderLight),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppTheme.accentPurple.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.audio_file_rounded,
                    color: AppTheme.accentPurple,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _selectedFile!.path.split(Platform.pathSeparator).last,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _formatFileSize(_selectedFile!),
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.close_rounded,
                    size: 18,
                    color: AppTheme.textMuted,
                  ),
                  onPressed: () => setState(() => _selectedFile = null),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],

        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _isSubmitting ? null : _pickFile,
            icon: const Icon(
              Icons.cloud_upload_rounded,
              size: 18,
              color: AppTheme.accentPurple,
            ),
            label: Text(
              _selectedFile == null ? 'Pilih File' : 'Ganti File',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: AppTheme.accentPurple,
              ),
            ),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppTheme.accentPurple),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildYouTubeSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'YouTube Link',
          style: TextStyle(
            color: AppTheme.getTextColor(context),
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Paste link YouTube untuk transkripsi',
          style: TextStyle(
            color: AppTheme.getTextSecondary(context),
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _youtubeController,
          keyboardType: TextInputType.url,
          enabled: !_isSubmitting,
          decoration: InputDecoration(
            hintText: 'https://youtube.com/watch?v=...',
            prefixIcon: const Icon(
              Icons.play_circle_outline_rounded,
              size: 20,
            ),
            errorText: _youtubeError,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
          ),
          onChanged: (v) {
            if (_youtubeError != null) {
              setState(() => _youtubeError = null);
            }
          },
        ),
      ],
    );
  }

  Widget _buildRecordSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Rekam Audio',
          style: TextStyle(
            color: AppTheme.getTextColor(context),
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Rekam langsung dari mikrofon',
          style: TextStyle(
            color: AppTheme.getTextSecondary(context),
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 14),
        Center(
          child: Column(
            children: [
              // Recording button
              GestureDetector(
                onTap: _isSubmitting ? null : _toggleRecording,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: _isRecording
                        ? AppTheme.error
                        : AppTheme.error.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                    boxShadow: _isRecording
                        ? [
                            BoxShadow(
                              color: AppTheme.error.withValues(alpha: 0.4),
                              blurRadius: 20,
                              spreadRadius: 5,
                            ),
                          ]
                        : [],
                  ),
                  child: _isRecording
                      ? _buildPulsingRecordIcon()
                      : const Icon(
                          Icons.mic_rounded,
                          color: AppTheme.error,
                          size: 36,
                        ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                _isRecording ? 'Menekan untuk berhenti...' : 'Tekan untuk mulai rekam',
                style: TextStyle(
                  color: AppTheme.getTextSecondary(context),
                  fontSize: 12,
                ),
              ),

              // Recorded file indicator
              if (_hasRecording && _recordedFile != null) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.success.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.success.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.check_circle_rounded,
                        color: AppTheme.success,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Rekaman siap',
                          style: const TextStyle(
                            color: AppTheme.success,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: _isSubmitting ? null : _clearRecording,
                        icon: const Icon(Icons.refresh_rounded, size: 14),
                        label: const Text(
                          'Ulangi',
                          style: TextStyle(fontSize: 11),
                        ),
                        style: TextButton.styleFrom(
                          foregroundColor: AppTheme.textSecondary,
                          padding: EdgeInsets.zero,
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPulsingRecordIcon() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.8, end: 1.2),
      duration: const Duration(milliseconds: 600),
      builder: (context, scale, child) {
        return Transform.scale(
          scale: scale,
          child: child,
        );
      },
      onEnd: () {
        // Continuously rebuild by calling setState
        if (_isRecording && mounted) {
          setState(() {});
        }
      },
      child: const Icon(
        Icons.stop_rounded,
        color: Colors.white,
        size: 40,
      ),
    );
  }

  // ==========================================================
  // ERROR BOX
  // ==========================================================

  Widget _buildErrorBox() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.error.withValues(alpha: 0.25),
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
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _error!,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppTheme.error,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // TRANSCRIBE BUTTON
  // ==========================================================

  Widget _buildTranscribeButton(bool isDark) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: _canSubmit ? AppTheme.accentPurple : AppTheme.surfaceMuted,
          foregroundColor: _canSubmit ? Colors.white : AppTheme.textMuted,
          disabledBackgroundColor: AppTheme.surfaceMuted,
          disabledForegroundColor: AppTheme.textMuted,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: _canSubmit ? 2 : 0,
        ),
        onPressed: _canSubmit ? _startTranscription : null,
        child: _isSubmitting
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
            : const Text(
                'Mulai Transcribe',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
      ),
    );
  }

  // ==========================================================
  // STATUS SECTION
  // ==========================================================

  Widget _buildStatusSection(bool isDark) {
    if (_isProcessing) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.warning.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppTheme.warning.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          children: [
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: AppTheme.warning,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Sedang memproses...',
                    style: TextStyle(
                      color: AppTheme.warning,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Status: ${_statusText(_transcriptionStatus)}',
                    style: TextStyle(
                      color: AppTheme.getTextSecondary(context),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    if (_transcriptionResult != null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.success.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppTheme.success.withValues(alpha: 0.2),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.check_circle_rounded,
                  color: AppTheme.success,
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Transkripsi Selesai!',
                    style: TextStyle(
                      color: AppTheme.success,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.copy_rounded,
                    size: 18,
                    color: AppTheme.success,
                  ),
                  onPressed: () {
                    Clipboard.setData(
                      ClipboardData(text: _transcriptionResult!),
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Teks disalin ke clipboard.'),
                        behavior: SnackBarBehavior.floating,
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.getSurface(context),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.borderLight),
              ),
              child: SelectableText(
                _transcriptionResult!,
                style: TextStyle(
                  color: AppTheme.getTextColor(context),
                  fontSize: 13,
                  height: 1.6,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }

  // ==========================================================
  // HISTORY SECTION
  // ==========================================================

  Widget _buildHistorySection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Riwayat Transkripsi',
              style: TextStyle(
                color: AppTheme.getTextColor(context),
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
            if (!_isLoadingHistory)
              Text(
                '${_history.length} item',
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),

        if (_isLoadingHistory)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          )
        else if (_history.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.getSurface(context),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.borderLight),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.record_voice_over_outlined,
                  size: 40,
                  color: AppTheme.getTextSecondary(context),
                ),
                const SizedBox(height: 10),
                Text(
                  'Belum ada transkripsi',
                  style: TextStyle(
                    color: AppTheme.getTextSecondary(context),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Mulai transkripsi pertama kamu!',
                  style: TextStyle(
                    color: AppTheme.getTextSecondary(context),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          )
        else
          ..._history.map((item) => _buildHistoryItem(item, isDark)),
      ],
    );
  }

  Widget _buildHistoryItem(Map<String, dynamic> item, bool isDark) {
    final name = item['name']?.toString() ?? 'Transkripsi';
    final source = item['source']?.toString() ?? 'upload';
    final status = item['status']?.toString() ?? '';
    final createdAt = item['created_at']?.toString();
    final id = item['id'];

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _viewResult(item),
          onLongPress: id != null
              ? () => _showDeleteDialog(id, name)
              : null,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
            decoration: BoxDecoration(
              color: AppTheme.getSurface(context),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.borderLight),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppTheme.accentPurple.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _sourceIcon(source),
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AppTheme.getTextColor(context),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (createdAt != null)
                        Text(
                          _formatDate(createdAt),
                          style: TextStyle(
                            color: AppTheme.getTextSecondary(context),
                            fontSize: 10,
                          ),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: _statusColor(status).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _statusText(status),
                    style: TextStyle(
                      color: _statusColor(status),
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: AppTheme.getTextSecondary(context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // DIALOGS
  // ==========================================================

  void _showDeleteDialog(dynamic id, String name) {
    showDialog<void>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppTheme.getSurface(context),
        title: const Text('Hapus transkripsi?'),
        content: Text(
          'Transkripsi "$name" akan dihapus permanen.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.error,
            ),
            onPressed: () {
              Navigator.pop(dialogCtx);
              _deleteTranscription(id);
            },
            child: const Text(
              'Hapus',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // FORMATTERS
  // ==========================================================

  String _formatFileSize(File file) {
    try {
      final bytes = file.lengthSync();
      if (bytes < 1024) return '$bytes B';
      if (bytes < 1024 * 1024) {
        return '${(bytes / 1024).toStringAsFixed(1)} KB';
      }
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } catch (_) {
      return '';
    }
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final diff = now.difference(date);

      if (diff.inMinutes < 1) return 'Baru saja';
      if (diff.inHours < 1) return '${diff.inMinutes} menit lalu';
      if (diff.inDays < 1) return '${diff.inHours} jam lalu';
      if (diff.inDays < 7) return '${diff.inDays} hari lalu';

      return '${date.day}/${date.month}/${date.year}';
    } catch (_) {
      return dateStr;
    }
  }
}

// ============================================================
// METHOD CARD
// ============================================================

class _MethodCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isDark;

  const _MethodCard({
    required this.icon,
    required this.title,
    required this.isSelected,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.accentPurple.withValues(alpha: 0.06)
              : AppTheme.getSurface(context),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? AppTheme.accentPurple
                : AppTheme.borderLight,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected
                  ? AppTheme.accentPurple
                  : AppTheme.getTextSecondary(context),
              size: 26,
            ),
            const SizedBox(height: 6),
            Text(
              title,
              style: TextStyle(
                color: isSelected
                    ? AppTheme.accentPurple
                    : AppTheme.getTextColor(context),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                fontSize: 11,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
