// ============================================================
// APP SIDEBAR DRAWER
// Reusable Global Sidebar Drawer for Navigation & Workspace
// ============================================================

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/providers/chat_provider.dart';
import '../../../data/providers/language_provider.dart';

class AppSidebarDrawer extends StatelessWidget {
  final VoidCallback? onSearchTap;

  const AppSidebarDrawer({super.key, this.onSearchTap});

  @override
  Widget build(BuildContext context) {
    final chat = context.watch<ChatProvider>();
    final lang = context.watch<LanguageProvider>();
    final currentRoute = GoRouterState.of(context).matchedLocation;
    final isDark = AppTheme.isDarkMode(context);

    return Drawer(
      backgroundColor: AppTheme.getBg(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(right: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // ── Header ──────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.blueGrey.shade800 : Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Image.asset(
                      'assets/images/pintaraja.webp',
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const Icon(
                          Icons.auto_awesome_rounded,
                          color: AppTheme.primary,
                          size: 20),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'PintarAja',
                    style: TextStyle(
                      color: AppTheme.getTextColor(context),
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const Spacer(),
                  if (onSearchTap != null)
                    Material(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                      child: InkWell(
                        onTap: () {
                          Navigator.pop(context);
                          onSearchTap!();
                        },
                        borderRadius: BorderRadius.circular(10),
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Icon(
                            Icons.search_rounded,
                            color: AppTheme.getTextSecondary(context),
                            size: 21,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const Divider(height: 1),

            // ── Konten scrollable (aman saat keyboard terbuka) ───────
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── New Chat Button ────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.all(14),
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          chat.startNewChat();
                          if (currentRoute != '/chat') {
                            context.go('/chat');
                          }
                        },
                        icon: const Icon(Icons.add_comment_rounded, size: 18),
                        label: Text(lang.translate('new_chat')),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 44),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),

                    // ── Workspace Navigation ──────────────────────────
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 4),
                      child: Text(
                        lang.translate('workspace').toUpperCase(),
                        style: TextStyle(
                          color: AppTheme.getTextSecondary(context),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),

                    _buildWorkspaceItem(
                      context,
                      icon: Icons.chat_bubble_outline_rounded,
                      title: lang.translate('chat_ai'),
                      route: '/chat',
                      isActive: currentRoute == '/chat',
                    ),
                    _buildWorkspaceItem(
                      context,
                      icon: Icons.edit_outlined,
                      title: lang.translate('writer_ai'),
                      route: '/writer',
                      isActive: currentRoute == '/writer',
                    ),
                    _buildWorkspaceItem(
                      context,
                      icon: Icons.repeat_rounded,
                      title: 'Paraphrase',
                      route: '/paraphrase',
                      isActive: currentRoute == '/paraphrase',
                    ),
                    _buildWorkspaceItem(
                      context,
                      icon: Icons.person_outline_rounded,
                      title: 'Humanize',
                      route: '/tools',
                      isActive: currentRoute == '/tools',
                      comingSoon: true,
                    ),
                    _buildWorkspaceItem(
                      context,
                      icon: Icons.plagiarism_outlined,
                      title: 'Plagiatisme',
                      route: '/plagiarism',
                      isActive: currentRoute == '/plagiarism',
                    ),
                    _buildWorkspaceItem(
                      context,
                      icon: Icons.record_voice_over_rounded,
                      title: 'Transcribe AI',
                      route: '/transcribe',
                      isActive: currentRoute == '/transcribe',
                    ),

                    const SizedBox(height: 10),
                    const Divider(height: 1),

                    // ── Chat History ──────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 6),
                      child: Text(
                        'Riwayat Percakapan',
                        style: TextStyle(
                          color: AppTheme.getTextSecondary(context),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    if (chat.conversations.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(
                          'Belum ada obrolan.',
                          style: TextStyle(
                            color: AppTheme.getTextSecondary(context),
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      )
                    else
                      ...chat.conversations.map((convo) {
                        final isSelected =
                            chat.currentConversationId == convo.id &&
                                currentRoute == '/chat';
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: ListTile(
                            onTap: () {
                              Navigator.pop(context);
                              chat.selectConversation(convo.id);
                              if (currentRoute != '/chat') {
                                context.go('/chat');
                              }
                            },
                            dense: true,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                            selected: isSelected,
                            selectedTileColor:
                                AppTheme.primary.withValues(alpha: 0.08),
                            leading: Icon(
                              Icons.chat_bubble_outline_rounded,
                              size: 16,
                              color: isSelected
                                  ? AppTheme.primary
                                  : AppTheme.getTextSecondary(context),
                            ),
                            title: Text(
                              convo.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: isSelected
                                    ? AppTheme.primary
                                    : AppTheme.getTextColor(context),
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.w500,
                              ),
                            ),
                            trailing: isSelected
                                ? IconButton(
                                    icon: const Icon(
                                        Icons.delete_outline_rounded,
                                        size: 16,
                                        color: AppTheme.error),
                                    onPressed: () =>
                                        _confirmDelete(context, chat, convo.id),
                                  )
                                : null,
                          ),
                        );
                      }),
                  ],
                ),
              ),
            ),

            // ── Footer (Settings) ───────────────────────────────────
            const Divider(height: 1),
            Container(
              padding: const EdgeInsets.all(14),
              child: ListTile(
                onTap: () {
                  Navigator.pop(context);
                  context.push('/settings');
                },
                leading: const Icon(Icons.settings_outlined,
                    color: AppTheme.primary),
                title: Text(
                  'Pengaturan',
                  style: TextStyle(
                    color: AppTheme.getTextColor(context),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                trailing: const Icon(Icons.chevron_right_rounded),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkspaceItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String route,
    required bool isActive,
    bool comingSoon = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      child: ListTile(
        onTap: comingSoon
            ? () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('$title akan segera hadir!'),
                    behavior: SnackBarBehavior.floating,
                    duration: const Duration(seconds: 2),
                  ),
                );
              }
            : () {
                Navigator.pop(context);
                context.go(route);
              },
        dense: true,
        selected: isActive,
        selectedTileColor: AppTheme.primary.withValues(alpha: 0.12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        leading: Icon(
          icon,
          color: comingSoon
              ? AppTheme.getTextSecondary(context)
              : isActive
                  ? AppTheme.primary
                  : AppTheme.getTextSecondary(context),
          size: 20,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: comingSoon
                ? AppTheme.getTextSecondary(context)
                : isActive
                    ? AppTheme.primary
                    : AppTheme.getTextColor(context),
            fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
            fontSize: 13.5,
          ),
        ),
        trailing: comingSoon
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Soon',
                  style: TextStyle(
                    color: Colors.orange,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              )
            : null,
      ),
    );
  }

  void _confirmDelete(BuildContext context, ChatProvider chat, int convoId) {
    showDialog<void>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppTheme.getSurface(context),
        title: const Text('Hapus obrolan?'),
        content: const Text('Obrolan ini akan dihapus permanen.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            onPressed: () {
              chat.deleteConversation(convoId);
              Navigator.pop(dialogCtx);
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
