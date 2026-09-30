import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/api_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../data/providers/auth_provider.dart';
import '../../data/services/storage_service.dart';
import '../shared/widgets/app_sidebar_drawer.dart';

class ImageGeneratorScreen extends StatefulWidget {
  const ImageGeneratorScreen({super.key});

  @override
  State<ImageGeneratorScreen> createState() => _ImageGeneratorScreenState();
}

class _ImageGeneratorScreenState extends State<ImageGeneratorScreen> {
  final TextEditingController _promptController = TextEditingController();
  final List<File> _referenceImages = [];

  bool _isLoading = false;
  String? _statusMessage;
  String? _imageUrl;
  String? _error;

  String _aspectRatio = '9:16';
  String _qualityMode = 'Kualitas';
  String _selectedModel = 'grok-imagine';

  final List<Map<String, String>> _aspectRatios = [
    {'id': '9:16', 'label': '9:16 (Vertikal)'},
    {'id': '16:9', 'label': '16:9 (Horizontal)'},
    {'id': '1:1', 'label': '1:1 (Persegi)'},
  ];

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }

  Future<void> _pickReferenceImages() async {
    if (_referenceImages.length >= 5) {
      _showSnackBar('Maksimal 5 gambar referensi.');
      return;
    }

    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: true,
    );

    if (result != null && result.files.isNotEmpty) {
      setState(() {
        for (final file in result.files) {
          if (file.path != null && _referenceImages.length < 5) {
            _referenceImages.add(File(file.path!));
          }
        }
      });
    }
  }

  void _removeReferenceImage(int index) {
    setState(() {
      _referenceImages.removeAt(index);
    });
  }

  Future<void> _generateImage() async {
    final promptText = _promptController.text.trim();
    if (promptText.isEmpty) {
      setState(() {
        _error = 'Deskripsi gambar (prompt) tidak boleh kosong.';
      });
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true;
      _error = null;
      _imageUrl = null;
      _statusMessage = 'Sedang mengirim permintaan ke server AI...';
    });

    try {
      final token = StorageService.getToken();

      String finalPrompt = promptText;
      if (_aspectRatio == '9:16') {
        finalPrompt += ' (rasio vertikal 9:16)';
      } else if (_aspectRatio == '16:9') {
        finalPrompt += ' (rasio horizontal 16:9)';
      }
      if (_qualityMode.isNotEmpty) {
        finalPrompt += ' (mode ${_qualityMode.toLowerCase()})';
      }

      final uri = Uri.parse(ApiConstants.imageGenerator);
      final request = http.MultipartRequest('POST', uri);
      request.headers['Authorization'] = 'Bearer $token';
      request.headers['Accept'] = 'application/json';

      request.fields['prompt'] = finalPrompt;
      request.fields['model'] = _selectedModel;

      for (int i = 0; i < _referenceImages.length; i++) {
        final file = _referenceImages[i];
        request.files.add(
          await http.MultipartFile.fromPath('images[$i]', file.path),
        );
      }

      final streamedResponse = await request.send().timeout(
            const Duration(seconds: 120),
          );
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body);

        if (data['status'] == 'processing' && data['job_id'] != null) {
          final String jobId = data['job_id'].toString();
          final String enhancedPrompt =
              data['enhanced_prompt']?.toString() ?? finalPrompt;

          await _pollJobStatus(jobId, enhancedPrompt);
        } else if (data['url'] != null) {
          setState(() {
            _imageUrl = data['url'].toString();
            _isLoading = false;
          });
          if (mounted) {
            await context.read<AuthProvider>().refreshUser();
          }
        } else {
          throw Exception('Format respon tidak sesuai.');
        }
      } else {
        final errJson = jsonDecode(response.body);
        final msg = errJson['message'] ?? 'Gagal membuat gambar.';
        throw Exception(msg);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceAll('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _pollJobStatus(String jobId, String prompt) async {
    const maxPolls = 60; // 10 menit
    int pollCount = 0;
    final token = StorageService.getToken();

    while (pollCount < maxPolls && _isLoading) {
      pollCount++;
      setState(() {
        _statusMessage =
            'Sedang melukis gambar imajinasi Anda... ($pollCount/60)';
      });

      await Future.delayed(const Duration(seconds: 10));
      if (!mounted || !_isLoading) return;

      try {
        final statusUri = Uri.parse(
          '${ApiConstants.checkImageStatus}?job_id=$jobId&prompt=${Uri.encodeComponent(prompt)}',
        );

        final response = await http.get(
          statusUri,
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
        );

        if (response.statusCode >= 200 && response.statusCode < 300) {
          final data = jsonDecode(response.body);
          final status = data['status'];

          if (status == 'completed') {
            final url = data['url']?.toString();
            if (url != null && url.isNotEmpty) {
              setState(() {
                _imageUrl = url;
                _isLoading = false;
                _promptController.clear();
                _referenceImages.clear();
              });
              if (mounted) {
                await context.read<AuthProvider>().refreshUser();
              }
              return;
            }
          } else if (status == 'failed') {
            throw Exception(data['message'] ?? 'Gagal memproses gambar.');
          }
        }
      } catch (e) {
        if (pollCount >= maxPolls) {
          rethrow;
        }
      }
    }

    if (_isLoading) {
      throw Exception('Proses memakan waktu terlalu lama. Coba lagi nanti.');
    }
  }

  void _showSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isDark = AppTheme.isDarkMode(context);

    return Scaffold(
      drawer: const AppSidebarDrawer(),
      backgroundColor: AppTheme.getBg(context),
      appBar: AppBar(
        backgroundColor: AppTheme.getBg(context),
        elevation: 0,
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: Icon(Icons.menu_rounded,
                color: AppTheme.getTextColor(context)),
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
        title: Text(
          'AI Image Generator',
          style: TextStyle(
            color: AppTheme.getTextColor(context),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Icon(Icons.diamond_rounded,
                    color: Color(0xFFFCD34D), size: 16),
                const SizedBox(width: 4),
                Text(
                  '${auth.tokenBalance}',
                  style: const TextStyle(
                    color: AppTheme.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Mode Switcher (Gambar vs Video)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.grey.shade900
                      : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(4),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: AppTheme.primary,
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.image_rounded,
                                color: Colors.white, size: 18),
                            SizedBox(width: 6),
                            Text(
                              'Gambar AI',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => context.go('/video-generator'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(9),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.videocam_outlined,
                                  color: AppTheme.getTextSecondary(context),
                                  size: 18),
                              const SizedBox(width: 6),
                              Text(
                                'Video AI',
                                style: TextStyle(
                                  color: AppTheme.getTextSecondary(context),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    if (_imageUrl == null && !_isLoading) ...[
                      const SizedBox(height: 30),
                      Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.palette_outlined,
                          size: 36,
                          color: AppTheme.primary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'AI Image Generator',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.getTextColor(context),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Text(
                          'Ketikkan deskripsi imajinasi Anda di bawah dan biarkan AI melukisnya menjadi gambar berkualitas tinggi.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            color: AppTheme.getTextSecondary(context),
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),
                    ],

                    // Loading State
                    if (_isLoading) ...[
                      const SizedBox(height: 40),
                      const CircularProgressIndicator(),
                      const SizedBox(height: 16),
                      Text(
                        _statusMessage ?? 'Sedang memproses...',
                        style: TextStyle(
                          color: AppTheme.getTextColor(context),
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Proses pembuatan gambar memerlukan waktu ~1-3 menit.',
                        style: TextStyle(
                          color: AppTheme.getTextSecondary(context),
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 40),
                    ],

                    // Error Box
                    if (_error != null) ...[
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.error.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppTheme.error.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline_rounded,
                                color: AppTheme.error, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _error!,
                                style: const TextStyle(
                                  color: AppTheme.error,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // Image Result
                    if (_imageUrl != null && !_isLoading) ...[
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: AppTheme.getSurface(context),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppTheme.getBorder(context)),
                        ),
                        child: Column(
                          children: [
                            ClipRRect(
                              borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(16)),
                              child: CachedNetworkImage(
                                imageUrl: _imageUrl!,
                                placeholder: (ctx, _) => Container(
                                  height: 300,
                                  color: Colors.grey.shade300,
                                  child: const Center(
                                      child: CircularProgressIndicator()),
                                ),
                                errorWidget: (ctx, _, __) => Container(
                                  height: 200,
                                  color: Colors.grey.shade200,
                                  child: const Icon(Icons.broken_image_rounded,
                                      size: 40),
                                ),
                                fit: BoxFit.contain,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  ElevatedButton.icon(
                                    onPressed: () async {
                                      final uri = Uri.parse(_imageUrl!);
                                      if (await canLaunchUrl(uri)) {
                                        await launchUrl(uri,
                                            mode: LaunchMode.externalApplication);
                                      }
                                    },
                                    icon: const Icon(Icons.download_rounded,
                                        size: 18),
                                    label: const Text('Buka / Download'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppTheme.primary,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Bottom Input Form
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.getSurface(context),
                border: Border(top: BorderSide(color: AppTheme.getBorder(context))),
              ),
              child: Column(
                children: [
                  // Reference Images List
                  if (_referenceImages.isNotEmpty) ...[
                    SizedBox(
                      height: 60,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _referenceImages.length,
                        itemBuilder: (ctx, i) {
                          return Stack(
                            children: [
                              Container(
                                margin: const EdgeInsets.only(right: 8),
                                width: 55,
                                height: 55,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  image: DecorationImage(
                                    image: FileImage(_referenceImages[i]),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 2,
                                right: 10,
                                child: GestureDetector(
                                  onTap: () => _removeReferenceImage(i),
                                  child: Container(
                                    padding: const EdgeInsets.all(2),
                                    decoration: const BoxDecoration(
                                      color: Colors.black54,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.close_rounded,
                                        size: 12, color: Colors.white),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],

                  // Config Chips Row
                  Row(
                    children: [
                      IconButton(
                        onPressed: _isLoading ? null : _pickReferenceImages,
                        icon: const Icon(Icons.add_photo_alternate_outlined),
                        color: AppTheme.primary,
                        tooltip: 'Upload Gambar Referensi',
                      ),
                      const SizedBox(width: 4),

                      // Aspect Ratio Menu
                      PopupMenuButton<String>(
                        initialValue: _aspectRatio,
                        onSelected: (val) {
                          setState(() => _aspectRatio = val);
                        },
                        itemBuilder: (ctx) => _aspectRatios
                            .map((item) => PopupMenuItem(
                                  value: item['id'],
                                  child: Text(item['label']!),
                                ))
                            .toList(),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            border: Border.all(
                                color: AppTheme.getBorder(context)),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.aspect_ratio_rounded,
                                  size: 14),
                              const SizedBox(width: 4),
                              Text(_aspectRatio,
                                  style: const TextStyle(fontSize: 12)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),

                      // Quality Mode Chip
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _qualityMode = _qualityMode == 'Kualitas'
                                ? 'Kecepatan'
                                : 'Kualitas';
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            border: Border.all(
                                color: AppTheme.getBorder(context)),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _qualityMode == 'Kualitas'
                                    ? Icons.star_rounded
                                    : Icons.bolt_rounded,
                                size: 14,
                                color: AppTheme.primary,
                              ),
                              const SizedBox(width: 4),
                              Text(_qualityMode,
                                  style: const TextStyle(fontSize: 12)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Prompt Text Input + Submit Button
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _promptController,
                          enabled: !_isLoading,
                          maxLines: 4,
                          minLines: 1,
                          style: TextStyle(
                            color: AppTheme.getTextColor(context),
                            fontSize: 14,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Deskripsikan gambar yang diinginkan...',
                            hintStyle: TextStyle(
                              color: AppTheme.getTextSecondary(context),
                              fontSize: 13,
                            ),
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: AppTheme.getBorder(context),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filled(
                        onPressed: _isLoading ? null : _generateImage,
                        icon: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2),
                              )
                            : const Icon(Icons.arrow_upward_rounded),
                        style: IconButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.all(12),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
