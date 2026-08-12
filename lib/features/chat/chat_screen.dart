// ============================================================
// CHAT SCREEN — AI Chat Interface Sesuai Mockup
// ============================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../data/providers/chat_provider.dart';

class ChatScreen extends StatefulWidget {
  final int? conversationId;
  const ChatScreen({super.key, this.conversationId});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _msgCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  String _selectedModel = 'GPT-4o';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final chat = context.read<ChatProvider>();
      if (widget.conversationId != null) {
        chat.loadMessages(widget.conversationId!);
      } else {
        chat.startNewChat();
      }
    });
  }

  @override
  void dispose() {
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final msg = _msgCtrl.text.trim();
    if (msg.isEmpty) return;
    _msgCtrl.clear();
    await context.read<ChatProvider>().sendMessage(msg, model: _selectedModel);
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      appBar: AppBar(
        backgroundColor: AppTheme.bgLight,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          children: [
            const Text(
              'AI Chat',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
            ),
            const SizedBox(height: 2),
            GestureDetector(
              onTap: _showModelSelector,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _selectedModel,
                    style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.keyboard_arrow_down_rounded, size: 12, color: AppTheme.textSecondary),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.history_rounded, size: 22),
            color: AppTheme.textPrimary,
            onPressed: () {},
            tooltip: 'Riwayat Chat',
          ),
        ],
      ),
      body: Column(
        children: [
          // Messages
          Expanded(
            child: Consumer<ChatProvider>(
              builder: (context, chat, _) {
                if (chat.isLoading) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppTheme.primary),
                  );
                }

                if (chat.messages.isEmpty) {
                  return _EmptyChat();
                }

                _scrollToBottom();
                  return ListView.builder(
                  controller: _scrollCtrl,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  itemCount: chat.messages.length,
                  itemBuilder: (_, i) => _MessageBubble(msg: chat.messages[i]),
                );
              },
            ),
          ),

          // Suggestion Pills
          Consumer<ChatProvider>(
            builder: (_, chat, __) {
              if (chat.messages.isEmpty || chat.isLoading) return const SizedBox.shrink();
              return Container(
                height: 38,
                margin: const EdgeInsets.only(bottom: 8),
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    _SuggestionChip('Contoh AI lainnya?'),
                    const SizedBox(width: 8),
                    _SuggestionChip('Bagaimana AI bekerja?'),
                    const SizedBox(width: 8),
                    _SuggestionChip('Manfaat AI'),
                  ],
                ),
              );
            },
          ),

          // Error message
          Consumer<ChatProvider>(
            builder: (_, chat, __) {
              if (chat.error == null) return const SizedBox.shrink();
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.error.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  chat.error!,
                  style: const TextStyle(color: AppTheme.error, fontSize: 13),
                ),
              );
            },
          ),

          // Input bar
          _InputBar(controller: _msgCtrl, onSend: _sendMessage),
        ],
      ),
    );
  }

  void _showModelSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.bgSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Container(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Pilih Model AI',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 16),
            _buildModelOption('GPT-4o', 'Model tercanggih untuk tugas kompleks'),
            _buildModelOption('GPT-3.5 Turbo', 'Model cepat dan hemat kuota'),
            _buildModelOption('Claude 3.5 Sonnet', 'Model terbaik untuk analisis mendalam'),
          ],
        ),
      ),
    );
  }

  Widget _buildModelOption(String name, String desc) {
    final isSelected = _selectedModel == name;
    return ListTile(
      onTap: () {
        setState(() => _selectedModel = name);
        Navigator.pop(context);
      },
      contentPadding: EdgeInsets.zero,
      title: Text(
        name,
        style: TextStyle(
          color: isSelected ? AppTheme.primary : Colors.white,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      subtitle: Text(desc, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
      trailing: isSelected ? const Icon(Icons.check_circle, color: AppTheme.primary) : null,
    );
  }
}

class _EmptyChat extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primary.withOpacity(0.3),
                  blurRadius: 20,
                ),
              ],
            ),
            child: const Icon(Icons.auto_awesome, color: Colors.white, size: 36),
          ),
          const SizedBox(height: 24),
          const Text(
            'Tanya Apa Saja ke PintarAja AI',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Masukkan pertanyaan atau topik esai kamu di bawah.',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _SuggestionChip extends StatelessWidget {
  final String label;
  const _SuggestionChip(this.label);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        context.read<ChatProvider>().sendMessage(label);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: AppTheme.bgSurface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.divider),
        ),
        child: Center(
          child: Text(
            label,
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
          ),
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final ChatMessage msg;
  const _MessageBubble({required this.msg});

  @override
  Widget build(BuildContext context) {
    final isUser = msg.isUser;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                gradient: AppTheme.primaryGradient,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.auto_awesome, color: Colors.white, size: 14),
            ),
            const SizedBox(width: 10),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: isUser ? AppTheme.primaryGradient : null,
                color: isUser ? null : AppTheme.bgSurface,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isUser ? 16 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 16),
                ),
                border: isUser ? null : Border.all(color: AppTheme.divider),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    msg.content,
                    style: TextStyle(
                      color: isUser ? Colors.white : AppTheme.textPrimary,
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '09:41',
                        style: TextStyle(
                          color: isUser ? Colors.white60 : AppTheme.textMuted,
                          fontSize: 9,
                        ),
                      ),
                      if (isUser) ...[
                        const SizedBox(width: 4),
                        const Icon(Icons.done_all_rounded, color: Colors.white60, size: 12),
                      ],
                    ],
                  ),
                  if (!isUser && msg.content.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    const Divider(color: AppTheme.divider),
                    const SizedBox(height: 4),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Icon(Icons.thumb_up_alt_outlined, size: 16, color: AppTheme.textMuted),
                        SizedBox(width: 16),
                        Icon(Icons.thumb_down_alt_outlined, size: 16, color: AppTheme.textMuted),
                        SizedBox(width: 16),
                        Icon(Icons.copy_rounded, size: 16, color: AppTheme.textMuted),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (isUser) const SizedBox(width: 10),
        ],
      ),
    );
  }
}

class _InputBar extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;

  const _InputBar({required this.controller, required this.onSend});

  @override
  Widget build(BuildContext context) {
    return Consumer<ChatProvider>(
      builder: (_, chat, __) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: const BoxDecoration(
            color: AppTheme.bgSurface,
            border: Border(top: BorderSide(color: AppTheme.divider)),
          ),
          child: Row(
            children: [
              // Attachment button
              IconButton(
                icon: const Icon(Icons.attach_file_rounded, color: AppTheme.textSecondary),
                onPressed: () {},
              ),
              const SizedBox(width: 4),
              // Main input
              Expanded(
                child: TextField(
                  controller: controller,
                  style: const TextStyle(color: AppTheme.textPrimary),
                  maxLines: 4,
                  minLines: 1,
                  decoration: const InputDecoration(
                    hintText: 'Ketik pesan...',
                    hintStyle: TextStyle(color: AppTheme.textMuted),
                    filled: false,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Mic / Voice icon
              IconButton(
                icon: const Icon(Icons.mic_none_rounded, color: AppTheme.textSecondary),
                onPressed: () {},
              ),
              const SizedBox(width: 4),
              // Send button
              GestureDetector(
                onTap: chat.isStreaming ? null : onSend,
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: chat.isStreaming ? null : AppTheme.primaryGradient,
                    color: chat.isStreaming ? AppTheme.bgInput : null,
                    shape: BoxShape.circle,
                  ),
                  child: chat.isStreaming
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: CircularProgressIndicator(
                            color: AppTheme.primary,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.arrow_upward_rounded, color: Colors.white, size: 20),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

