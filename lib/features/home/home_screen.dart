// ============================================================
// HOME SCREEN — Beranda Mobile Mirip Website PintarAja
// ============================================================

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../data/providers/auth_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _openAccordionIndex = 0;

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;

    final servicesList = [
      {
        'title': 'AI Chat',
        'desc':
            'Diskusi interaktif dengan asisten AI tercanggih — didukung OpenAI, Gemini, Claude, DeepSeek & Qwen.',
        'badge': 'POPULER',
        'icon': Icons.chat_bubble_rounded,
        'color': const Color(0xFF2563EB),
        'route': '/chat',
      },
      {
        'title': 'AI Writer',
        'desc':
            'Tulis draf skripsi, esai, artikel ilmiah, dan dokumen akademik secara otomatis dengan template prompt.',
        'badge': null,
        'icon': Icons.edit_rounded,
        'color': const Color(0xFF7C3AED),
        'route': '/writer',
      },
      {
        'title': 'Paraphrase AI',
        'desc':
            'Parafrase dan tingkatkan kualitas tulisan Anda dengan struktur kalimat yang lebih baik dan profesional.',
        'badge': 'BARU',
        'icon': Icons.swap_horiz_rounded,
        'color': const Color(0xFF0EA5E9),
        'route': '/tools',
      },
      {
        'title': 'Check Plagiarism',
        'desc':
            'Deteksi plagiarisme dalam dokumen Anda dengan Turnitin & Drillbot AI Check.',
        'badge': 'BARU',
        'icon': Icons.verified_user_outlined,
        'color': const Color(0xFFF97316),
        'route': '/tools',
      },
      {
        'title': 'Transcribe AI',
        'desc':
            'Ubah rekaman wawancara, seminar, atau materi kuliah menjadi teks secara akurat.',
        'badge': 'BARU',
        'icon': Icons.mic_rounded,
        'color': const Color(0xFF10B981),
        'route': '/tools',
      },
      {
        'title': 'Humanizer AI',
        'desc':
            'Ubah teks hasil AI menjadi tulisan yang natural dan tidak terdeteksi sebagai mesin.',
        'badge': 'SOON',
        'icon': Icons.psychology_rounded,
        'color': const Color(0xFF6B7280),
        'route': '/tools',
      },
    ];

    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      appBar: AppBar(
        backgroundColor: AppTheme.bgLight,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            Image.asset('assets/images/pintaraja.webp',
                width: 28,
                height: 28,
                errorBuilder: (_, __, ___) =>
                    const Icon(Icons.auto_awesome, color: AppTheme.primary)),
            const SizedBox(width: 8),
            const Text(
              'PintarAja',
              style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w800,
                  fontSize: 18),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline_rounded,
                color: AppTheme.textPrimary),
            onPressed: () => context.push('/profile'),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hero Banner Sesuai Website PintarAja.com
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primary.withValues(alpha: 0.25),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        '✨ Solusi Mahasiswa, di Pintar Aja',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Halo, ${user?.name.split(' ').first ?? 'Mahasiswa'}!',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Sempurnakan riset, buat tugas, dan parafrase teks dengan asisten AI tercanggih.',
                      style: TextStyle(
                          color: Colors.white70, fontSize: 13, height: 1.4),
                    ),
                    const SizedBox(height: 16),
                    // Quick Token Info
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.diamond_rounded,
                              color: Color(0xFFFBBF24), size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Saldo Token: ${user?.quota ?? 0}',
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13),
                          ),
                          const Spacer(),
                          Text(
                            user?.plan ?? 'Free Plan',
                            style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                                fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Didukung AI Terpopuler
              const Text(
                'Didukung AI Terpopuler',
                style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildAiModelBadge('OpenAI GPT-4', const Color(0xFF10A37F)),
                    _buildAiModelBadge(
                        'Google Gemini', const Color(0xFF4285F4)),
                    _buildAiModelBadge('Claude 3.5', const Color(0xFFD97706)),
                    _buildAiModelBadge('DeepSeek R1', const Color(0xFF4F46E5)),
                    _buildAiModelBadge('Qwen AI', const Color(0xFF0284C7)),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // Pilihan Layanan Utama
              const Text(
                'Pilihan Layanan AI',
                style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              const Text(
                'Pilih tools akademik yang sesuai kebutuhan kamu',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
              ),
              const SizedBox(height: 16),

              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: servicesList.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.35,
                ),
                itemBuilder: (context, index) {
                  final s = servicesList[index];
                  return GestureDetector(
                    onTap: () => context.go(s['route'] as String),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppTheme.bgSurface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppTheme.divider),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: (s['color'] as Color)
                                      .withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(s['icon'] as IconData,
                                    color: s['color'] as Color, size: 20),
                              ),
                              const Spacer(),
                              if (s['badge'] != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 7, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: s['badge'] == 'SOON'
                                        ? Colors.grey.shade400
                                        : AppTheme.primary,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    s['badge'] as String,
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                            ],
                          ),
                          const Spacer(),
                          Text(
                            s['title'] as String,
                            style: const TextStyle(
                                color: AppTheme.textPrimary,
                                fontWeight: FontWeight.bold,
                                fontSize: 14),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            s['desc'] as String,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 10.5,
                                height: 1.3),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 30),

              // Detail Accordion Layanan PintarAja
              const Text(
                'Layanan Berkualitas dari PintarAja',
                style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              Column(
                children: List.generate(servicesList.length, (index) {
                  final s = servicesList[index];
                  final isOpen = _openAccordionIndex == index;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: AppTheme.bgSurface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.divider),
                    ),
                    child: Column(
                      children: [
                        ListTile(
                          onTap: () {
                            setState(() {
                              _openAccordionIndex = isOpen ? -1 : index;
                            });
                          },
                          leading: Icon(s['icon'] as IconData,
                              color: s['color'] as Color, size: 22),
                          title: Row(
                            children: [
                              Text(s['title'] as String,
                                  style: const TextStyle(
                                      color: AppTheme.textPrimary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14)),
                              if (s['badge'] != null) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: s['badge'] == 'SOON'
                                        ? Colors.grey.shade400
                                        : AppTheme.primary
                                            .withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    s['badge'] as String,
                                    style: TextStyle(
                                      color: s['badge'] == 'SOON'
                                          ? Colors.white
                                          : AppTheme.primary,
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          trailing: Icon(
                            isOpen
                                ? Icons.keyboard_arrow_up_rounded
                                : Icons.keyboard_arrow_down_rounded,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        if (isOpen)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  s['desc'] as String,
                                  style: const TextStyle(
                                      color: AppTheme.textSecondary,
                                      fontSize: 12.5,
                                      height: 1.5),
                                ),
                                const SizedBox(height: 12),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: s['color'] as Color,
                                    visualDensity: VisualDensity.compact,
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(10)),
                                  ),
                                  onPressed: () =>
                                      context.go(s['route'] as String),
                                  child: const Text('Coba Sekarang',
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  );
                }),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAiModelBadge(String name, Color accentColor) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: AppTheme.bgSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration:
                BoxDecoration(shape: BoxShape.circle, color: accentColor),
          ),
          const SizedBox(width: 6),
          Text(name,
              style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
