import 'dart:convert';
// ============================================================
// PINTARAJA â€” CHAT SCREEN
// Floating Sidebar + Blur + Token + AI Provider + Conversations
// Responsive untuk Android 720x1520
// ============================================================

import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../data/providers/auth_provider.dart';
import '../../data/providers/chat_provider.dart';
import '../shared/widgets/payment_sheet.dart';
import '../shared/widgets/app_sidebar_drawer.dart';

class ChatScreen extends StatefulWidget {
  final int? conversationId;

  const ChatScreen({
    super.key,
    this.conversationId,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();

  final ScrollController _scrollController = ScrollController();

  bool _shouldOpenDrawerAfterSearch = false;
  File? _pendingAttachedFile;
  String? _pendingAttachedFileName;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback(
      (_) async {
        final chat = context.read<ChatProvider>();

        await chat.initializeChat();

        if (!mounted) {
          return;
        }

        if (widget.conversationId != null) {
          await chat.loadMessages(
            widget.conversationId!,
          );
        }
      },
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // ==========================================================
  // DRAWER
  // ==========================================================

  // ==========================================================
  // NEW CHAT
  // ==========================================================

  Future<void> _startNewChat() async {
    FocusScope.of(context).unfocus();

    _messageController.clear();

    final chat = context.read<ChatProvider>();

    try {
      await chat.startNewChat();
    } catch (_) {
      // Gagal membuat conversation di server tidak boleh
      // membuat layar mati â€” user tetap bisa chat lokal.
    }

    if (!mounted) {
      return;
    }

    setState(() {});

    _scrollToBottom();
  }

  // ==========================================================
  // SEND MESSAGE
  // ==========================================================

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();

    if (message.isEmpty && _pendingAttachedFile == null) {
      return;
    }

    final chat = context.read<ChatProvider>();

    if (chat.isStreaming) {
      return;
    }

    final attachedFile = _pendingAttachedFile;
    final attachedFileName = _pendingAttachedFileName;

    _messageController.clear();
    _pendingAttachedFile = null;
    _pendingAttachedFileName = null;

    FocusScope.of(context).unfocus();

    try {
      await chat.sendMessage(
        message,
        attachedFile: attachedFile,
        attachedFileName: attachedFileName,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal mengirim pesan: $e'),
          backgroundColor: AppTheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (!mounted) {
      return;
    }

    _scrollToBottom();

    await context.read<AuthProvider>().refreshUser();

    if (!mounted) {
      return;
    }

    _scrollToBottom();
  }

  // ==========================================================
  // SCROLL
  // ==========================================================

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback(
      (_) {
        if (!_scrollController.hasClients) {
          return;
        }

        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(
            milliseconds: 280,
          ),
          curve: Curves.easeOut,
        );
      },
    );
  }

  // ==========================================================
  // SEARCH CONVERSATION
  // ==========================================================

  void _showConversationSearch() {
    final controller = TextEditingController();

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surfaceLight,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              16,
              8,
              16,
              20 +
                  MediaQuery.viewInsetsOf(
                    sheetContext,
                  ).bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Cari percakapan',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(
                  height: 12,
                ),
                TextField(
                  controller: controller,
                  autofocus: true,
                  textInputAction: TextInputAction.search,
                  onSubmitted: (
                    value,
                  ) {
                    _searchConversation(
                      value,
                      sheetContext,
                    );
                  },
                  decoration: InputDecoration(
                    hintText: 'Cari judul percakapan...',
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                    ),
                    suffixIcon: IconButton(
                      onPressed: () {
                        _searchConversation(
                          controller.text,
                          sheetContext,
                        );
                      },
                      icon: const Icon(
                        Icons.arrow_forward_rounded,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    ).whenComplete(
      controller.dispose,
    );
  }

  void _searchConversation(
    String value,
    BuildContext sheetContext,
  ) {
    final query = value.trim();

    if (query.isEmpty) {
      return;
    }

    Navigator.of(
      sheetContext,
    ).pop();

    context.read<ChatProvider>().loadConversations(
          search: query,
        );

    _shouldOpenDrawerAfterSearch = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _shouldOpenDrawerAfterSearch) {
        _shouldOpenDrawerAfterSearch = false;
        if (mounted) {
          Scaffold.of(context).openDrawer();
        }
      }
    });
  }

  // ==========================================================
  // MODEL SELECTOR
  // ==========================================================

  void _showModelSelector() {
    context.read<ChatProvider>().loadAiProviders();

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppTheme.surfaceLight,
      showDragHandle: true,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      builder: (context) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.78,
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
              child: Consumer<ChatProvider>(
                builder: (context, chat, _) {
                  if (chat.aiProviders.isEmpty) {
                    return const SizedBox(
                      height: 180,
                      child: Center(
                        child: Text(
                          'Tidak ada AI provider yang tersedia.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppTheme.textSecondary),
                        ),
                      ),
                    );
                  }

                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Pilih Model AI',
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 19,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Pilih AI Engine dari PintarAja (GPT, Gemini, Claude, DeepSeek, Llama, dll)',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 11.5,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Expanded(
                        child: SingleChildScrollView(
                          child: Column(
                            children: chat.aiProviders.map((provider) {
                              return _ProviderOption(
                                provider: provider,
                                selected:
                                    chat.selectedProviderId == provider.id,
                                onTap: () {
                                  if (provider.isLimited) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                            'Model ini telah mencapai limit harian. Silakan upgrade plan atau gunakan model lain.'),
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                    return;
                                  }
                                  chat.selectProvider(provider.id);
                                  Navigator.of(context).pop();
                                },
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  // ==========================================================
  // TOKEN
  // ==========================================================

  void _showTokenDialog() {
    final authProvider = context.read<AuthProvider>();
    final tokenBalance = authProvider.tokenBalance;
    final minCoins = authProvider.topupMinCoins;
    final pricePerCoin = 100.0;
    final priceLabel = pricePerCoin % 1 == 0
        ? pricePerCoin.toInt().toString()
        : pricePerCoin.toStringAsFixed(2);

    int selectedCoins = minCoins > 50 ? minCoins : 50;
    final TextEditingController coinsController =
        TextEditingController(text: '$selectedCoins');

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            final bottomPadding = MediaQuery.of(context).viewInsets.bottom;
            final totalPrice = selectedCoins * pricePerCoin;

            return Padding(
              padding: EdgeInsets.only(bottom: bottomPadding),
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                decoration: BoxDecoration(
                  color: AppTheme.getSurface(context),
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                              color: AppTheme.getBorder(context),
                              borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Token & Top Up',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: AppTheme.getTextColor(context))),
                          IconButton(
                              icon: const Icon(Icons.close_rounded),
                              onPressed: () => Navigator.pop(ctx)),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Sisa Token Card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppTheme.primary,
                              AppTheme.primary.withValues(alpha: 0.8)
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primary.withValues(alpha: 0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Sisa Token Anda',
                                style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.85),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600)),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.diamond_rounded,
                                    color: Color(0xFFFCD34D), size: 24),
                                const SizedBox(width: 8),
                                Text('$tokenBalance',
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 28,
                                        fontWeight: FontWeight.w800)),
                                const SizedBox(width: 4),
                                Text('token',
                                    style: TextStyle(
                                        color:
                                            Colors.white.withValues(alpha: 0.7),
                                        fontSize: 14)),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Top Up Section
                      Text('Top Up Token',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: AppTheme.getTextColor(context))),
                      const SizedBox(height: 4),
                      Text('Harga: Rp $priceLabel / token',
                          style: const TextStyle(
                              color: AppTheme.textSecondary, fontSize: 12)),
                      const SizedBox(height: 10),

                      // Preset Amount Buttons
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          ...[10, 50, 100, 500, 1000]
                              .where((amount) => amount >= minCoins)
                              .map((amount) {
                          final isSelected = selectedCoins == amount;
                          return GestureDetector(
                            onTap: () {
                              setModalState(() {
                                selectedCoins = amount;
                                coinsController.text = '$amount';
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppTheme.primary
                                    : AppTheme.surfaceMuted,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: isSelected
                                        ? AppTheme.primary
                                        : AppTheme.borderLight),
                              ),
                              child: Text('$amount',
                                  style: TextStyle(
                                      color: isSelected
                                          ? Colors.white
                                          : AppTheme.textPrimary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13)),
                            ),
                          );
                          }),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Custom Amount
                      TextField(
                        controller: coinsController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Jumlah Token (Min. $minCoins)',
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12)),
                          prefixIcon: const Icon(Icons.diamond_rounded),
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 12),
                        ),
                        onChanged: (val) {
                          final parsed = int.tryParse(val);
                          if (parsed != null) {
                            setModalState(() => selectedCoins = parsed);
                          }
                        },
                      ),
                      const SizedBox(height: 10),

                      // Total Price
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Total Harga:',
                                style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.textSecondary,
                                    fontSize: 13)),
                            Text('Rp ${totalPrice.toStringAsFixed(0)}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    color: AppTheme.primary,
                                    fontSize: 16)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Top Up Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            elevation: 2,
                          ),
                          onPressed: selectedCoins < minCoins
                              ? null
                              : () async {
                                  Navigator.pop(ctx);
                                  final auth = context.read<AuthProvider>();
                                  final phone =
                                      auth.user?.phone?.isNotEmpty == true
                                          ? auth.user!.phone!
                                          : '08123456789';

                                  await PaymentSelectionSheet.processDirectQris(
                                    this.context,
                                    amount: totalPrice.round(),
                                    coins: selectedCoins,
                                    phone: phone,
                                  );

                                  await auth.refreshUser();
                                },
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.qr_code_2_rounded, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                  'Bayar via QRIS - Rp ${totalPrice.toStringAsFixed(0)}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundApp,
      drawer: AppSidebarDrawer(onSearchTap: _showConversationSearch),
      body: _buildChatContent(),
    );
  }

  // ==========================================================
  // CHAT CONTENT
  // ==========================================================

  Widget _buildChatContent() {
    return SafeArea(
      child: Column(
        children: [
          _buildAppBar(),
          Expanded(
            child: Consumer<ChatProvider>(
              builder: (
                context,
                chat,
                _,
              ) {
                if (chat.isLoading && chat.messages.isEmpty) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: AppTheme.primary,
                    ),
                  );
                }

                if (chat.messages.isEmpty) {
                  return const _EmptyChat();
                }

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(
                    16,
                    14,
                    16,
                    20,
                  ),
                  itemCount: chat.messages.length,
                  itemBuilder: (
                    context,
                    index,
                  ) {
                    return _MessageBubble(
                      message: chat.messages[index],
                    );
                  },
                );
              },
            ),
          ),
          Consumer<ChatProvider>(
            builder: (
              context,
              chat,
              _,
            ) {
              final error = chat.error;

              if (error == null || error.trim().isEmpty) {
                return const SizedBox.shrink();
              }

              return _buildError(
                error,
              );
            },
          ),
          _ChatInput(
            controller: _messageController,
            onSend: _sendMessage,
            attachedFile: _pendingAttachedFile,
            attachedFileName: _pendingAttachedFileName,
            onFileChanged: (file) {
              setState(() {
                _pendingAttachedFile = file;
              });
            },
            onFileNameChanged: (name) {
              setState(() {
                _pendingAttachedFileName = name;
              });
            },
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // APP BAR
  // ==========================================================

  Widget _buildAppBar() {
    return Builder(builder: (context) {
      final tokenBalance = context.watch<AuthProvider>().tokenBalance;

      return Container(
        height: 62,
        padding: const EdgeInsets.only(
          left: 10,
          right: 10,
        ),
        decoration: const BoxDecoration(
          color: AppTheme.backgroundApp,
          border: Border(
            bottom: BorderSide(
              color: AppTheme.borderLight,
              width: 0.7,
            ),
          ),
        ),
        child: Row(
          children: [
            // MENU
            Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(
                12,
              ),
              child: InkWell(
                onTap: () {
                  FocusScope.of(context).unfocus();
                  Scaffold.of(context).openDrawer();
                },
                borderRadius: BorderRadius.circular(
                  12,
                ),
                child: const Padding(
                  padding: EdgeInsets.all(
                    10,
                  ),
                  child: Icon(
                    Icons.menu_rounded,
                    color: AppTheme.textPrimary,
                    size: 25,
                  ),
                ),
              ),
            ),

            // LOGO
            Image.asset(
              'assets/images/pintaraja.webp',
              width: 30,
              height: 30,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const Icon(
                Icons.auto_awesome_rounded,
                color: AppTheme.primary,
                size: 22,
              ),
            ),

            const SizedBox(
              width: 2,
            ),

            const Flexible(
              child: Text(
                'intaraja',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.6,
                ),
              ),
            ),

            const Spacer(),

            // TOKEN
            GestureDetector(
              onTap: _showTokenDialog,
              child: Container(
                constraints: const BoxConstraints(
                  maxWidth: 72,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceMuted,
                  borderRadius: BorderRadius.circular(
                    20,
                  ),
                  border: Border.all(
                    color: AppTheme.borderLight,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.diamond_rounded,
                      color: Color(
                        0xFFF59E0B,
                      ),
                      size: 15,
                    ),
                    const SizedBox(
                      width: 4,
                    ),
                    Flexible(
                      child: Text(
                        '$tokenBalance',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(
              width: 3,
            ),

            // NEW CHAT
            Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(
                12,
              ),
              child: InkWell(
                onTap: _startNewChat,
                borderRadius: BorderRadius.circular(
                  12,
                ),
                child: const Padding(
                  padding: EdgeInsets.all(
                    10,
                  ),
                  child: Icon(
                    Icons.add_comment_outlined,
                    color: AppTheme.textPrimary,
                    size: 22,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildError(
    String error,
  ) {
    return Container(
      margin: const EdgeInsets.fromLTRB(
        16,
        4,
        16,
        8,
      ),
      padding: const EdgeInsets.all(
        11,
      ),
      decoration: BoxDecoration(
        color: AppTheme.error.withValues(
          alpha: 0.10,
        ),
        borderRadius: BorderRadius.circular(
          12,
        ),
        border: Border.all(
          color: AppTheme.error.withValues(
            alpha: 0.25,
          ),
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
          const SizedBox(
            width: 8,
          ),
          Expanded(
            child: Text(
              error,
              maxLines: 4,
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
}

// ============================================================
// CONVERSATION ITEM
// ============================================================

// ============================================================
// EMPTY CHAT
// ============================================================

class _EmptyChat extends StatelessWidget {
  const _EmptyChat();

  @override
  Widget build(
    BuildContext context,
  ) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: 28,
          vertical: 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 78,
              height: 78,
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(
                  alpha: 0.10,
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.auto_awesome_rounded,
                color: AppTheme.primary,
                size: 36,
              ),
            ),
            const SizedBox(
              height: 20,
            ),
            const Text(
              'Tanya apa saja',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 21,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(
              height: 8,
            ),
            const Text(
              'Gunakan PintarAja untuk membantu tugas, riset, ide, dan berbagai kebutuhan akademikmu.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 13,
                height: 1.5,
              ),
            ),
            const SizedBox(
              height: 20,
            ),
            const Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                _SuggestionButton(
                  text: 'Bantu tugas kuliah',
                ),
                _SuggestionButton(
                  text: 'Buat ide skripsi',
                ),
                _SuggestionButton(
                  text: 'Ringkas teks',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// SUGGESTION BUTTON
// ============================================================

class _SuggestionButton extends StatelessWidget {
  final String text;

  const _SuggestionButton({
    required this.text,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return GestureDetector(
      onTap: () {
        final state = context.findAncestorStateOfType<_ChatScreenState>();

        if (state == null) {
          return;
        }

        state._messageController.text = text;

        state._sendMessage();
      },
      child: Container(
        constraints: const BoxConstraints(
          maxWidth: 170,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: 13,
          vertical: 9,
        ),
        decoration: BoxDecoration(
          color: AppTheme.surfaceLight,
          borderRadius: BorderRadius.circular(
            20,
          ),
          border: Border.all(
            color: AppTheme.borderLight,
          ),
        ),
        child: Text(
          text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 11.5,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

// ============================================================
// MESSAGE BUBBLE
// ============================================================

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;

  const _MessageBubble({
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    final maxWidth = MediaQuery.sizeOf(context).width * 0.82;

    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isUser)
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.auto_awesome_rounded,
                color: AppTheme.primary,
                size: 16,
              ),
            ),
          if (!isUser) const SizedBox(width: 9),
          Flexible(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isUser ? AppTheme.primary : AppTheme.surfaceLight,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(18),
                    topRight: const Radius.circular(18),
                    bottomLeft: Radius.circular(isUser ? 18 : 5),
                    bottomRight: Radius.circular(isUser ? 5 : 18),
                  ),
                  border:
                      isUser ? null : Border.all(color: AppTheme.borderLight),
                ),
                child: Builder(builder: (context) {
                  // Check if content is a JSON array
                  if (message.content.trim().startsWith('[') &&
                      message.content.trim().endsWith(']')) {
                    try {
                      final parsed = jsonDecode(message.content);
                      if (parsed is List) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: parsed.map<Widget>((part) {
                            if (part is Map) {
                              if (part['type'] == 'text') {
                                return Text(
                                  part['text'] ?? '',
                                  style: TextStyle(
                                      color: isUser
                                          ? Colors.white
                                          : AppTheme.textPrimary,
                                      fontSize: 14,
                                      height: 1.5),
                                );
                              } else if (part['type'] == 'image_url') {
                                final url = part['image_url']['url'];
                                if (url != null &&
                                    url.toString().startsWith('data:image')) {
                                  final base64Str =
                                      url.toString().split(',').last;
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 8.0),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: ConstrainedBox(
                                        constraints: const BoxConstraints(
                                          maxWidth: 240,
                                          maxHeight: 320,
                                        ),
                                        child: Image.memory(
                                            base64Decode(base64Str),
                                            fit: BoxFit.contain),
                                      ),
                                    ),
                                  );
                                }
                              } else if (part['type'] == 'file') {
                                return Container(
                                  margin: const EdgeInsets.only(top: 8),
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                      color: Colors.white24,
                                      borderRadius: BorderRadius.circular(8)),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.insert_drive_file,
                                          color: Colors.white, size: 16),
                                      const SizedBox(width: 4),
                                      Flexible(
                                        child: Text(part['name'] ?? 'File',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 12)),
                                      ),
                                    ],
                                  ),
                                );
                              }
                            }
                            return const SizedBox.shrink();
                          }).toList(),
                        );
                      }
                    } catch (e) {
                      // fallback
                    }
                  }

                  if (isUser) {
                    return Text(
                      message.content,
                      softWrap: true,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        height: 1.5,
                      ),
                    );
                  }

                  return MarkdownBody(
                    data: message.content,
                    styleSheet: MarkdownStyleSheet(
                      p: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 14,
                        height: 1.5,
                      ),
                      strong: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                      em: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 14,
                        fontStyle: FontStyle.italic,
                      ),
                      del: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 14,
                        decoration: TextDecoration.lineThrough,
                      ),
                      code: TextStyle(
                        color: AppTheme.primary,
                        fontSize: 13,
                        backgroundColor: AppTheme.surfaceMuted,
                      ),
                      codeblockDecoration: BoxDecoration(
                        color: AppTheme.surfaceMuted,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      codeblockPadding: const EdgeInsets.all(10),
                      h1: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      h2: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      h3: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                      listBullet: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 14,
                      ),
                      blockquote: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
          if (isUser) const SizedBox(width: 9),
          if (isUser)
            Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                color: AppTheme.surfaceMuted,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person_rounded,
                color: AppTheme.textSecondary,
                size: 17,
              ),
            ),
        ],
      ),
    );
  }
}

// ============================================================
// CHAT INPUT
// ============================================================

class _ChatInput extends StatefulWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final File? attachedFile;
  final String? attachedFileName;
  final ValueChanged<File?> onFileChanged;
  final ValueChanged<String?> onFileNameChanged;

  const _ChatInput({
    required this.controller,
    required this.onSend,
    this.attachedFile,
    this.attachedFileName,
    required this.onFileChanged,
    required this.onFileNameChanged,
  });

  @override
  State<_ChatInput> createState() => _ChatInputState();
}

class _ChatInputState extends State<_ChatInput> {
  void _pickAttachment() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppTheme.surfaceLight,
      showDragHandle: true,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library_rounded,
                    color: AppTheme.primary),
                title: const Text('Pilih Foto / Gambar'),
                onTap: () async {
                  Navigator.pop(ctx);
                  final picker = ImagePicker();
                  final picked =
                      await picker.pickImage(source: ImageSource.gallery);
                  if (picked != null) {
                    widget.onFileChanged(File(picked.path));
                    widget.onFileNameChanged(picked.name);
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt_rounded,
                    color: AppTheme.primary),
                title: const Text('Ambil Foto Kamera'),
                onTap: () async {
                  Navigator.pop(ctx);
                  final picker = ImagePicker();
                  final picked =
                      await picker.pickImage(source: ImageSource.camera);
                  if (picked != null) {
                    widget.onFileChanged(File(picked.path));
                    widget.onFileNameChanged(picked.name);
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.insert_drive_file_rounded,
                    color: AppTheme.primary),
                title: const Text('Pilih Dokumen File'),
                onTap: () async {
                  Navigator.pop(ctx);
                  final result = await FilePicker.platform.pickFiles();
                  if (result != null && result.files.single.path != null) {
                    widget.onFileChanged(File(result.files.single.path!));
                    widget.onFileNameChanged(result.files.single.name);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleSend() {
    widget.onSend();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ChatProvider>(
      builder: (context, chat, _) {
        return SafeArea(
          top: false,
          child: Container(
            padding: const EdgeInsets.fromLTRB(10, 7, 10, 9),
            decoration: const BoxDecoration(
              color: AppTheme.backgroundApp,
              border: Border(
                top: BorderSide(
                  color: AppTheme.borderLight,
                ),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.attachedFile != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceLight,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: AppTheme.primary.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        if (widget.attachedFileName != null &&
                            (widget.attachedFileName!
                                    .toLowerCase()
                                    .endsWith('.jpg') ||
                                widget.attachedFileName!
                                    .toLowerCase()
                                    .endsWith('.jpeg') ||
                                widget.attachedFileName!
                                    .toLowerCase()
                                    .endsWith('.png')))
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(widget.attachedFile!,
                                width: 40, height: 40, fit: BoxFit.cover),
                          )
                        else
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                                color: AppTheme.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8)),
                            child: const Icon(Icons.insert_drive_file_rounded,
                                color: AppTheme.primary, size: 24),
                          ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            widget.attachedFileName ?? 'Lampiran terpilih',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                color: AppTheme.textPrimary,
                                fontSize: 13,
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded,
                              size: 20, color: AppTheme.textMuted),
                          onPressed: () {
                            widget.onFileChanged(null);
                            widget.onFileNameChanged(null);
                          },
                        ),
                      ],
                    ),
                  ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceLight,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppTheme.borderLight),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      IconButton(
                        tooltip: 'Lampiran',
                        onPressed: _pickAttachment,
                        icon: const Icon(
                          Icons.attach_file_rounded,
                          color: AppTheme.textSecondary,
                          size: 20,
                        ),
                      ),
                      Expanded(
                        child: TextField(
                          controller: widget.controller,
                          minLines: 1,
                          maxLines: 5,
                          keyboardType: TextInputType.multiline,
                          textInputAction: TextInputAction.newline,
                          onSubmitted: (_) {
                            if (!chat.isStreaming) {
                              _handleSend();
                            }
                          },
                          decoration: const InputDecoration(
                            hintText: 'Tulis pesan...',
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            filled: false,
                            contentPadding: EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),

                      // MODEL SELECTOR BUTTON
                      GestureDetector(
                        onTap: () {
                          final chatScreenState = context
                              .findAncestorStateOfType<_ChatScreenState>();
                          chatScreenState?._showModelSelector();
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 4, right: 4),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceMuted,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppTheme.borderLight),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const Icon(Icons.auto_awesome_rounded,
                                  color: AppTheme.primary, size: 13),
                              const SizedBox(width: 3),
                              ConstrainedBox(
                                constraints: const BoxConstraints(maxWidth: 70),
                                child: Text(
                                  chat.selectedModelName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 1),
                              const Icon(Icons.keyboard_arrow_down_rounded,
                                  color: AppTheme.textSecondary, size: 13),
                            ],
                          ),
                        ),
                      ),

                      GestureDetector(
                        onTap: chat.isStreaming ? null : _handleSend,
                        child: Container(
                          width: 40,
                          height: 40,
                          margin: const EdgeInsets.only(bottom: 4),
                          decoration: BoxDecoration(
                            color: chat.isStreaming
                                ? AppTheme.surfaceMuted
                                : AppTheme.primary,
                            shape: BoxShape.circle,
                          ),
                          child: chat.isStreaming
                              ? const Padding(
                                  padding: EdgeInsets.all(10),
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppTheme.primary,
                                  ),
                                )
                              : const Icon(
                                  Icons.arrow_upward_rounded,
                                  color: Colors.white,
                                  size: 20,
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ============================================================
// PROVIDER OPTION
// ============================================================

class _ProviderOption extends StatelessWidget {
  final dynamic provider;
  final bool selected;
  final VoidCallback? onTap;

  const _ProviderOption({
    required this.provider,
    required this.selected,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final titleColor = selected ? AppTheme.primary : AppTheme.textPrimary;

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: selected
            ? AppTheme.primary.withValues(alpha: 0.06)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Icon(
                  Icons.auto_awesome_rounded,
                  color: AppTheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        provider.displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: titleColor,
                          fontSize: 13.5,
                          fontWeight:
                              selected ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                      if (provider.quota.limit > 0)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            'Sisa ${provider.quota.remaining} dari ${provider.quota.limit} limit harian',
                            style: TextStyle(
                              color: provider.quota.remaining <= 0
                                  ? AppTheme.error
                                  : AppTheme.textSecondary,
                              fontSize: 10,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                if (selected)
                  const Icon(Icons.check_circle_rounded,
                      color: AppTheme.primary, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

