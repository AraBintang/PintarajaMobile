// ============================================================
// PINTARAJA — CHAT SCREEN
// Floating Sidebar + Blur + Token + AI Provider + Conversations
// Responsive untuk Android 720x1520
// ============================================================

import 'dart:io';
import 'dart:ui';

import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../data/providers/auth_provider.dart';
import '../../data/providers/chat_provider.dart';

class ChatScreen extends StatefulWidget {
  final int? conversationId;

  const ChatScreen({
    super.key,
    this.conversationId,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _messageController =
      TextEditingController();

  final ScrollController _scrollController =
      ScrollController();

  late final AnimationController _drawerController;

  bool get _isDrawerVisible =>
      _drawerController.value > 0;

  @override
  void initState() {
    super.initState();

    _drawerController = AnimationController(
      vsync: this,
      duration: const Duration(
        milliseconds: 280,
      ),
      reverseDuration: const Duration(
        milliseconds: 220,
      ),
    );

    WidgetsBinding.instance.addPostFrameCallback(
      (_) async {
        final chat =
            context.read<ChatProvider>();

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
    _drawerController.dispose();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // ==========================================================
  // DRAWER
  // ==========================================================

  void _openDrawer() {
    FocusScope.of(context).unfocus();
    _drawerController.forward();
  }

  void _closeDrawer() {
    _drawerController.reverse();
  }

  void _toggleDrawer() {
    if (_drawerController.value > 0) {
      _closeDrawer();
    } else {
      _openDrawer();
    }
  }

  // ==========================================================
  // NEW CHAT
  // ==========================================================

  Future<void> _startNewChat() async {
    FocusScope.of(context).unfocus();

    _messageController.clear();

    final chat =
        context.read<ChatProvider>();

    await chat.startNewChat();

    if (!mounted) {
      return;
    }

    _closeDrawer();
    _scrollToBottom();
  }

  // ==========================================================
  // OPEN CONVERSATION
  // ==========================================================

  Future<void> _openConversation(
    Conversation conversation,
  ) async {
    FocusScope.of(context).unfocus();

    _closeDrawer();

    final chat =
        context.read<ChatProvider>();

    await chat.selectConversation(
      conversation.id,
    );

    if (!mounted) {
      return;
    }

    _scrollToBottom();
  }

  // ==========================================================
  // SEND MESSAGE
  // ==========================================================

  Future<void> _sendMessage() async {
    final message =
        _messageController.text.trim();

    if (message.isEmpty) {
      return;
    }

    final chat =
        context.read<ChatProvider>();

    if (chat.isStreaming) {
      return;
    }

    _messageController.clear();

    FocusScope.of(context).unfocus();

    await chat.sendMessage(
      message,
    );

    if (!mounted) {
      return;
    }

    _scrollToBottom();

    await context
        .read<AuthProvider>()
        .refreshUser();

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
          _scrollController
              .position
              .maxScrollExtent,
          duration:
              const Duration(
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
    final controller =
        TextEditingController();

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor:
          AppTheme.surfaceLight,
      showDragHandle: true,
      shape:
          const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding:
                EdgeInsets.fromLTRB(
              16,
              8,
              16,
              20 +
                  MediaQuery.viewInsetsOf(
                    sheetContext,
                  ).bottom,
            ),
            child: Column(
              mainAxisSize:
                  MainAxisSize.min,
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                const Text(
                  'Cari percakapan',
                  style:
                      TextStyle(
                    color:
                        AppTheme
                            .textPrimary,
                    fontSize:
                        18,
                    fontWeight:
                        FontWeight.w700,
                  ),
                ),

                const SizedBox(
                  height: 12,
                ),

                TextField(
                  controller:
                      controller,
                  autofocus: true,
                  textInputAction:
                      TextInputAction.search,
                  onSubmitted: (
                    value,
                  ) {
                    _searchConversation(
                      value,
                      sheetContext,
                    );
                  },
                  decoration:
                      InputDecoration(
                    hintText:
                        'Cari judul percakapan...',
                    prefixIcon:
                        const Icon(
                      Icons
                          .search_rounded,
                    ),
                    suffixIcon:
                        IconButton(
                      onPressed:
                          () {
                        _searchConversation(
                          controller
                              .text,
                          sheetContext,
                        );
                      },
                      icon:
                          const Icon(
                        Icons
                            .arrow_forward_rounded,
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

    context
        .read<ChatProvider>()
        .loadConversations(
          search: query,
        );

    _openDrawer();
  }

  // ==========================================================
  // MODEL SELECTOR
  // ==========================================================

  void _showModelSelector() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor:
          AppTheme.surfaceLight,
      showDragHandle: true,
      isScrollControlled: true,
      shape:
          const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding:
                const EdgeInsets.fromLTRB(
              16,
              8,
              16,
              20,
            ),
            child:
                Consumer<ChatProvider>(
              builder: (
                context,
                chat,
                _,
              ) {
                if (chat.aiProviders.isEmpty) {
                  return const SizedBox(
                    height: 180,
                    child: Center(
                      child: Text(
                        'Tidak ada AI provider yang tersedia.',
                        textAlign:
                            TextAlign.center,
                        style: TextStyle(
                          color:
                              AppTheme
                                  .textSecondary,
                        ),
                      ),
                    ),
                  );
                }

                return Column(
                  mainAxisSize:
                      MainAxisSize.min,
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Pilih Model AI',
                      style: TextStyle(
                        color:
                            AppTheme
                                .textPrimary,
                        fontSize: 19,
                        fontWeight:
                            FontWeight.w700,
                      ),
                    ),

                    const SizedBox(
                      height: 5,
                    ),

                    const Text(
                      'Model dan kuota mengikuti akun PintarAja kamu.',
                      style: TextStyle(
                        color:
                            AppTheme
                                .textSecondary,
                        fontSize: 11.5,
                      ),
                    ),

                    const SizedBox(
                      height: 16,
                    ),

                    ...chat.aiProviders
                        .map(
                      (provider) {
                        return _ProviderOption(
                          provider:
                              provider,
                          selected:
                              chat.selectedProviderId ==
                                  provider.id,
                          onTap:
                              provider
                                      .isLimited
                                  ? null
                                  : () {
                                      chat.selectProvider(
                                        provider.id,
                                      );

                                      Navigator.of(
                                        context,
                                      ).pop();
                                    },
                        );
                      },
                    ),
                  ],
                );
              },
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
    final token =
        context
            .read<AuthProvider>()
            .tokenBalance;

    showDialog<void>(
      context: context,
      builder: (context) {
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
            'Saldo token kamu: $token',
            style: const TextStyle(
              color:
                  AppTheme.textSecondary,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(
                  context,
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
    return AnimatedBuilder(
      animation:
          _drawerController,
      builder: (
        context,
        _,
      ) {
        return Scaffold(
          backgroundColor:
              AppTheme.backgroundApp,
          body: Stack(
            children: [
              _buildChatContent(),

              if (_isDrawerVisible)
                _buildFloatingDrawer(),
            ],
          ),
        );
      },
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
            child:
                Consumer<ChatProvider>(
              builder: (
                context,
                chat,
                _,
              ) {
                if (chat.isLoading &&
                    chat.messages.isEmpty) {
                  return const Center(
                    child:
                        CircularProgressIndicator(
                      color:
                          AppTheme.primary,
                    ),
                  );
                }

                if (chat.messages.isEmpty) {
                  return const _EmptyChat();
                }

                return ListView.builder(
                  controller:
                      _scrollController,
                  padding:
                      const EdgeInsets
                          .fromLTRB(
                    16,
                    14,
                    16,
                    20,
                  ),
                  itemCount:
                      chat.messages.length,
                  itemBuilder: (
                    context,
                    index,
                  ) {
                    return _MessageBubble(
                      message:
                          chat.messages[index],
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
              final error =
                  chat.error;

              if (error == null ||
                  error.trim().isEmpty) {
                return const SizedBox
                    .shrink();
              }

              return _buildError(
                error,
              );
            },
          ),

          _ChatInput(
            controller:
                _messageController,
            onSend:
                _sendMessage,
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // APP BAR
  // ==========================================================

  Widget _buildAppBar() {
    final tokenBalance =
        context
            .watch<AuthProvider>()
            .tokenBalance;

    return Container(
      height: 62,
      padding:
          const EdgeInsets.symmetric(
        horizontal: 8,
      ),
      decoration:
          const BoxDecoration(
        color:
            AppTheme.backgroundApp,
        border:
            Border(
          bottom:
              BorderSide(
            color:
                AppTheme.borderLight,
            width:
                0.7,
          ),
        ),
      ),
      child: Row(
        children: [
          // MENU
          Material(
            color:
                Colors.transparent,
            borderRadius:
                BorderRadius.circular(
              12,
            ),
            child:
                InkWell(
              onTap:
                  _toggleDrawer,
              borderRadius:
                  BorderRadius.circular(
                12,
              ),
              child:
                  const Padding(
                padding:
                    EdgeInsets.all(
                  10,
                ),
                child:
                    Icon(
                  Icons.menu_rounded,
                  color:
                      AppTheme
                          .textPrimary,
                  size:
                      25,
                ),
              ),
            ),
          ),

          // LOGO
          Image.asset(
            'assets/images/pintaraja.webp',
            width: 30,
            height: 30,
            fit:
                BoxFit.contain,
          ),

          const SizedBox(
            width: 2,
          ),

          const Flexible(
            child:
                Text(
              'intaraja',
              maxLines: 1,
              overflow:
                  TextOverflow.ellipsis,
              style:
                  TextStyle(
                color:
                    AppTheme
                        .textPrimary,
                fontSize:
                    18,
                fontWeight:
                    FontWeight.w700,
                letterSpacing:
                    -0.6,
              ),
            ),
          ),

          // SEARCH
          Material(
            color:
                Colors.transparent,
            borderRadius:
                BorderRadius.circular(
              10,
            ),
            child:
                InkWell(
              onTap:
                  _showConversationSearch,
              borderRadius:
                  BorderRadius.circular(
                10,
              ),
              child:
                  const Padding(
                padding:
                    EdgeInsets.all(
                  8,
                ),
                child:
                    Icon(
                  Icons.search_rounded,
                  color:
                      AppTheme
                          .textSecondary,
                  size:
                      21,
                ),
              ),
            ),
          ),

          const SizedBox(
            width: 2,
          ),

          // MODEL
          Flexible(
            child:
                GestureDetector(
              onTap:
                  _showModelSelector,
              child:
                  Consumer<
                      ChatProvider>(
                builder: (
                  context,
                  chat,
                  _,
                ) {
                  return Container(
                    constraints:
                        const BoxConstraints(
                      maxWidth:
                          110,
                    ),
                    padding:
                        const EdgeInsets
                            .symmetric(
                      horizontal:
                          8,
                      vertical:
                          5,
                    ),
                    decoration:
                        BoxDecoration(
                      color:
                          AppTheme
                              .surfaceMuted,
                      borderRadius:
                          BorderRadius
                              .circular(
                        20,
                      ),
                    ),
                    child:
                        Row(
                      mainAxisSize:
                          MainAxisSize.min,
                      children: [
                        Flexible(
                          child:
                              Text(
                            chat.selectedModelName,
                            maxLines:
                                1,
                            overflow:
                                TextOverflow
                                    .ellipsis,
                            style:
                                const TextStyle(
                              color:
                                  AppTheme
                                      .textSecondary,
                              fontSize:
                                  10,
                              fontWeight:
                                  FontWeight
                                      .w600,
                            ),
                          ),
                        ),
                        const SizedBox(
                          width: 2,
                        ),
                        const Icon(
                          Icons
                              .keyboard_arrow_down_rounded,
                          color:
                              AppTheme
                                  .textSecondary,
                          size:
                              14,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),

          const Spacer(),

          // TOKEN
          GestureDetector(
            onTap:
                _showTokenDialog,
            child:
                Container(
              constraints:
                  const BoxConstraints(
                maxWidth:
                    72,
              ),
              padding:
                  const EdgeInsets
                      .symmetric(
                horizontal:
                    8,
                vertical:
                    6,
              ),
              decoration:
                  BoxDecoration(
                color:
                    AppTheme
                        .surfaceMuted,
                borderRadius:
                    BorderRadius
                        .circular(
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
                    width: 4,
                  ),
                  Flexible(
                    child:
                        Text(
                      '$tokenBalance',
                      maxLines:
                          1,
                      overflow:
                          TextOverflow
                              .ellipsis,
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
            color:
                Colors.transparent,
            borderRadius:
                BorderRadius.circular(
              12,
            ),
            child:
                InkWell(
              onTap:
                  _startNewChat,
              borderRadius:
                  BorderRadius.circular(
                12,
              ),
              child:
                  const Padding(
                padding:
                    EdgeInsets.all(
                  10,
                ),
                child:
                    Icon(
                  Icons
                      .add_comment_outlined,
                  color:
                      AppTheme
                          .textPrimary,
                  size:
                      22,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // ERROR
  // ==========================================================

  Widget _buildError(
    String error,
  ) {
    return Container(
      margin:
          const EdgeInsets.fromLTRB(
        16,
        4,
        16,
        8,
      ),
      padding:
          const EdgeInsets.all(
        11,
      ),
      decoration:
          BoxDecoration(
        color:
            AppTheme.error.withValues(
          alpha: 0.10,
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
            alpha: 0.25,
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
            width: 8,
          ),
          Expanded(
            child:
                Text(
              error,
              maxLines:
                  4,
              overflow:
                  TextOverflow
                      .ellipsis,
              style:
                  const TextStyle(
                color:
                    AppTheme.error,
                fontSize:
                    12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // FLOATING DRAWER
  // ==========================================================

  Widget _buildFloatingDrawer() {
    final size =
        MediaQuery.sizeOf(
      context,
    );

    final drawerWidth =
        (size.width * 0.78).clamp(
      280.0,
      360.0,
    );

    final progress =
        Curves.easeOutCubic.transform(
      _drawerController.value,
    );

    final leftPosition =
        -drawerWidth +
            (drawerWidth * progress);

    return Positioned.fill(
      child:
          Stack(
        children: [
          // BLUR OVERLAY
          Positioned.fill(
            child:
                GestureDetector(
              behavior:
                  HitTestBehavior.opaque,
              onTap:
                  _closeDrawer,
              child:
                  BackdropFilter(
                filter:
                    ImageFilter.blur(
                  sigmaX:
                      5 *
                          _drawerController
                              .value,
                  sigmaY:
                      5 *
                          _drawerController
                              .value,
                ),
                child:
                    Container(
                  color:
                      Colors.black
                          .withValues(
                    alpha:
                        0.24 *
                            _drawerController
                                .value,
                  ),
                ),
              ),
            ),
          ),

          // FLOATING PANEL
          Positioned(
            left:
                leftPosition,
            top:
                8,
            bottom:
                8,
            width:
                drawerWidth,
            child:
                Material(
              color:
                  Colors.transparent,
              elevation:
                  18,
              shadowColor:
                  Colors.black
                      .withValues(
                alpha:
                    0.18,
              ),
              borderRadius:
                  const BorderRadius.only(
                topRight:
                    Radius.circular(
                  24,
                ),
                bottomRight:
                    Radius.circular(
                  24,
                ),
              ),
              child:
                  Container(
                decoration:
                    BoxDecoration(
                  color:
                      AppTheme
                          .backgroundApp,
                  borderRadius:
                      const BorderRadius
                          .only(
                    topRight:
                        Radius.circular(
                      24,
                    ),
                    bottomRight:
                        Radius.circular(
                      24,
                    ),
                  ),
                  border:
                      Border.all(
                    color:
                        Colors.white
                            .withValues(
                      alpha:
                          0.75,
                    ),
                  ),
                ),
                child:
                    _SidebarSurface(
                  onClose:
                      _closeDrawer,
                  onNewChat:
                      _startNewChat,
                  onConversationTap:
                      _openConversation,
                  onSettings: () {
                      _closeDrawer();
                      context.push('/settings');
                     },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// SIDEBAR
// ============================================================

class _SidebarSurface
    extends StatelessWidget {
  final VoidCallback onClose;
  final VoidCallback onNewChat;
  final ValueChanged<Conversation>
      onConversationTap;
  final VoidCallback onSettings;

  const _SidebarSurface({
    required this.onClose,
    required this.onNewChat,
    required this.onConversationTap,
    required this.onSettings,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return SafeArea(
      child:
          Column(
        children: [
          // HEADER
          _SidebarHeader(
            onClose:
                onClose,
          ),

          const Divider(
            height: 1,
            color:
                AppTheme
                    .borderLight,
          ),

          const SizedBox(
            height: 12,
          ),

          // NEW CHAT
          Padding(
            padding:
                const EdgeInsets
                    .symmetric(
              horizontal: 14,
            ),
            child:
                _SidebarNewChatButton(
              onTap:
                  onNewChat,
            ),
          ),

          const SizedBox(
            height: 14,
          ),

          // WORKSPACE
          Padding(
            padding:
                const EdgeInsets
                    .fromLTRB(
              20,
              0,
              20,
              6,
            ),
            child:
                const Align(
              alignment:
                  Alignment.centerLeft,
              child:
                  Text(
                'Workspace',
                style:
                    TextStyle(
                  color:
                      AppTheme
                          .textMuted,
                  fontSize:
                      11,
                  fontWeight:
                      FontWeight.w600,
                ),
              ),
            ),
          ),

          _SidebarItem(
            icon:
                Icons.home_outlined,
            title:
                'Beranda',
            onTap:
                () {
              onClose();
              context.go(
                '/home',
              );
            },
          ),

          _SidebarItem(
            icon:
                Icons.edit_outlined,
            title:
                'Writer',
            onTap:
                () {
              onClose();
              context.go(
                '/writer',
              );
            },
          ),

          _SidebarItem(
            icon:
                Icons.grid_view_rounded,
            title:
                'AI Tools',
            onTap:
                () {
              onClose();
              context.go(
                '/tools',
              );
            },
          ),

          const SizedBox(
            height: 10,
          ),

          const Divider(
            height: 1,
            color:
                AppTheme
                    .borderLight,
          ),

          const SizedBox(
            height: 6,
          ),

          // CONVERSATIONS
          Expanded(
            child:
                Consumer<ChatProvider>(
              builder: (
                context,
                chat,
                _,
              ) {
                return ListView(
                  physics:
                      const ClampingScrollPhysics(),
                  padding:
                      const EdgeInsets
                          .fromLTRB(
                    14,
                    2,
                    14,
                    10,
                  ),
                  children: [
                    const Padding(
                      padding:
                          EdgeInsets
                              .fromLTRB(
                        6,
                        6,
                        6,
                        5,
                      ),
                      child:
                          Text(
                        'Percakapan',
                        style:
                            TextStyle(
                          color:
                              AppTheme
                                  .textMuted,
                          fontSize:
                              11,
                          fontWeight:
                              FontWeight.w600,
                        ),
                      ),
                    ),

                    if (chat
                        .conversations
                        .isEmpty)
                      const Padding(
                        padding:
                            EdgeInsets
                                .fromLTRB(
                          8,
                          12,
                          8,
                          16,
                        ),
                        child:
                            Text(
                          'Belum ada percakapan.',
                          style:
                              TextStyle(
                            color:
                                AppTheme
                                    .textMuted,
                            fontSize:
                                11,
                          ),
                        ),
                      )
                    else
                      ...chat
                          .conversations
                          .map(
                        (
                          conversation,
                        ) {
                          return _ConversationItem(
                            conversation:
                                conversation,
                            selected:
                                chat.currentConversationId ==
                                    conversation
                                        .id,
                            onTap:
                                () {
                              onConversationTap(
                                conversation,
                              );
                            },
                            onDelete:
                                () {
                              context
                                  .read<
                                      ChatProvider>()
                                  .deleteConversation(
                                    conversation
                                        .id,
                                  );
                            },
                            onRename:
                                (
                              title,
                            ) {
                              context
                                  .read<
                                      ChatProvider>()
                                  .renameConversation(
                                    conversation
                                        .id,
                                    title,
                                  );
                            },
                          );
                        },
                      ),
                  ],
                );
              },
            ),
          ),

          // SETTINGS
          Container(
            width:
                double.infinity,
            padding:
                const EdgeInsets
                    .fromLTRB(
              14,
              8,
              14,
              8,
            ),
            decoration:
                const BoxDecoration(
              border:
                  Border(
                top:
                    BorderSide(
                  color:
                      AppTheme
                          .borderLight,
                ),
              ),
            ),
            child:
                _SidebarItem(
              icon:
                  Icons.settings_outlined,
              title:
                  'Pengaturan',
              onTap:
                  onSettings,
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

class _ConversationItem
    extends StatelessWidget {
  final Conversation conversation;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final ValueChanged<String> onRename;

  const _ConversationItem({
    required this.conversation,
    required this.selected,
    required this.onTap,
    required this.onDelete,
    required this.onRename,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Padding(
      padding:
          const EdgeInsets.only(
        bottom: 3,
      ),
      child:
          Material(
        color:
            selected
                ? AppTheme
                    .primary
                    .withValues(
                  alpha:
                      0.08,
                )
                : Colors.transparent,
        borderRadius:
            BorderRadius.circular(
          13,
        ),
        child:
            InkWell(
          onTap:
              onTap,
          borderRadius:
              BorderRadius.circular(
            13,
          ),
          child:
              Padding(
            padding:
                const EdgeInsets
                    .fromLTRB(
              10,
              10,
              4,
              10,
            ),
            child:
                Row(
              children: [
                Icon(
                  Icons
                      .chat_bubble_outline_rounded,
                  color:
                      selected
                          ? AppTheme
                              .primary
                          : AppTheme
                              .textSecondary,
                  size:
                      18,
                ),

                const SizedBox(
                  width: 10,
                ),

                Expanded(
                  child:
                      Column(
                    crossAxisAlignment:
                        CrossAxisAlignment
                            .start,
                    children: [
                      Text(
                        conversation
                            .title,
                        maxLines:
                            1,
                        overflow:
                            TextOverflow
                                .ellipsis,
                        style:
                            TextStyle(
                          color:
                              selected
                                  ? AppTheme
                                      .primary
                                  : AppTheme
                                      .textPrimary,
                          fontSize:
                              12.5,
                          fontWeight:
                              selected
                                  ? FontWeight
                                      .w700
                                  : FontWeight
                                      .w500,
                        ),
                      ),

                      const SizedBox(
                        height: 3,
                      ),

                      Text(
                        conversation
                            .lastUpdated,
                        maxLines:
                            1,
                        overflow:
                            TextOverflow
                                .ellipsis,
                        style:
                            const TextStyle(
                          color:
                              AppTheme
                                  .textMuted,
                          fontSize:
                              9.5,
                        ),
                      ),
                    ],
                  ),
                ),

                PopupMenuButton<String>(
                  padding:
                      EdgeInsets.zero,
                  icon:
                      const Icon(
                    Icons
                        .more_vert_rounded,
                    color:
                        AppTheme
                            .textMuted,
                    size:
                        18,
                  ),
                  onSelected:
                      (value) async {
                    if (value ==
                        'rename') {
                      await _renameConversation(
                        context,
                      );
                    }

                    if (value ==
                        'delete') {
                      await _confirmDelete(
                        context,
                      );
                    }
                  },
                  itemBuilder:
                      (context) {
                    return const [
                      PopupMenuItem<String>(
                        value:
                            'rename',
                        child:
                            Text(
                          'Ubah nama',
                        ),
                      ),
                      PopupMenuItem<String>(
                        value:
                            'delete',
                        child:
                            Text(
                          'Hapus',
                        ),
                      ),
                    ];
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _renameConversation(
    BuildContext context,
  ) async {
    final controller =
        TextEditingController(
      text:
          conversation.title,
    );

    final result =
        await showDialog<String>(
      context:
          context,
      builder:
          (dialogContext) {
        return AlertDialog(
          backgroundColor:
              AppTheme
                  .surfaceLight,
          title:
              const Text(
            'Ubah nama percakapan',
            style:
                TextStyle(
              color:
                  AppTheme
                      .textPrimary,
            ),
          ),
          content:
              TextField(
            controller:
                controller,
            autofocus:
                true,
            maxLength:
                50,
            decoration:
                const InputDecoration(
              hintText:
                  'Nama percakapan',
            ),
          ),
          actions: [
            TextButton(
              onPressed:
                  () {
                Navigator.of(
                  dialogContext,
                ).pop();
              },
              child:
                  const Text(
                'Batal',
              ),
            ),
            ElevatedButton(
              onPressed:
                  () {
                final title =
                    controller
                        .text
                        .trim();

                if (title.isEmpty) {
                  return;
                }

                Navigator.of(
                  dialogContext,
                ).pop(
                  title,
                );
              },
              child:
                  const Text(
                'Simpan',
              ),
            ),
          ],
        );
      },
    );

    controller.dispose();

    if (result == null ||
        result.trim().isEmpty) {
      return;
    }

    onRename(
      result.trim(),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
  ) async {
    final confirmed =
        await showDialog<bool>(
      context:
          context,
      builder:
          (dialogContext) {
        return AlertDialog(
          backgroundColor:
              AppTheme
                  .surfaceLight,
          title:
              const Text(
            'Hapus percakapan?',
            style:
                TextStyle(
              color:
                  AppTheme
                      .textPrimary,
            ),
          ),
          content:
              const Text(
            'Percakapan ini akan dihapus dari akun kamu.',
            style:
                TextStyle(
              color:
                  AppTheme
                      .textSecondary,
            ),
          ),
          actions: [
            TextButton(
              onPressed:
                  () {
                Navigator.of(
                  dialogContext,
                ).pop(
                  false,
                );
              },
              child:
                  const Text(
                'Batal',
              ),
            ),
            TextButton(
              onPressed:
                  () {
                Navigator.of(
                  dialogContext,
                ).pop(
                  true,
                );
              },
              child:
                  const Text(
                'Hapus',
                style:
                    TextStyle(
                  color:
                      AppTheme
                          .error,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed ==
        true) {
      onDelete();
    }
  }
}

// ============================================================
// SIDEBAR HEADER
// ============================================================

class _SidebarHeader
    extends StatelessWidget {
  final VoidCallback onClose;

  const _SidebarHeader({
    required this.onClose,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Padding(
      padding:
          const EdgeInsets
              .fromLTRB(
        16,
        14,
        10,
        14,
      ),
      child:
          Row(
        children: [
          Container(
            width:
                42,
            height:
                42,
            padding:
                const EdgeInsets.all(
              6,
            ),
            decoration:
                BoxDecoration(
              color:
                  Colors.white,
              borderRadius:
                  BorderRadius.circular(
                13,
              ),
              boxShadow: [
                BoxShadow(
                  color:
                      Colors.black
                          .withValues(
                    alpha:
                        0.05,
                  ),
                  blurRadius:
                      12,
                  offset:
                      const Offset(
                    0,
                    5,
                  ),
                ),
              ],
            ),
            child:
                Image.asset(
              'assets/images/pintaraja.webp',
              fit:
                  BoxFit.contain,
            ),
          ),

          const SizedBox(
            width: 7,
          ),

          const Expanded(
            child:
                Text(
              'intaraja',
              style:
                  TextStyle(
                color:
                    AppTheme
                        .textPrimary,
                fontSize:
                    21,
                fontWeight:
                    FontWeight.w700,
                letterSpacing:
                    -0.7,
              ),
            ),
          ),

          Material(
            color:
                Colors.transparent,
            borderRadius:
                BorderRadius.circular(
              12,
            ),
            child:
                InkWell(
              onTap:
                  onClose,
              borderRadius:
                  BorderRadius.circular(
                12,
              ),
              child:
                  const Padding(
                padding:
                    EdgeInsets.all(
                  9,
                ),
                child:
                    Icon(
                  Icons
                      .close_rounded,
                  color:
                      AppTheme
                          .textSecondary,
                  size:
                      21,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// NEW CHAT BUTTON
// ============================================================

class _SidebarNewChatButton
    extends StatelessWidget {
  final VoidCallback onTap;

  const _SidebarNewChatButton({
    required this.onTap,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Material(
      color:
          AppTheme.primary,
      borderRadius:
          BorderRadius.circular(
        16,
      ),
      child:
          InkWell(
        onTap:
            onTap,
        borderRadius:
            BorderRadius.circular(
          16,
        ),
        child:
            const Padding(
          padding:
              EdgeInsets.all(
            13,
          ),
          child:
              Row(
            children: [
              SizedBox(
                width:
                    38,
                height:
                    38,
                child:
                    DecoratedBox(
                  decoration:
                      BoxDecoration(
                    color:
                        Color.fromRGBO(
                      255,
                      255,
                      255,
                      0.14,
                    ),
                    borderRadius:
                        BorderRadius.all(
                      Radius.circular(
                        11,
                      ),
                    ),
                  ),
                  child:
                      Icon(
                    Icons
                        .add_comment_outlined,
                    color:
                        Colors.white,
                    size:
                        20,
                  ),
                ),
              ),

              SizedBox(
                width:
                    11,
              ),

              Expanded(
                child:
                    Column(
                  crossAxisAlignment:
                      CrossAxisAlignment
                          .start,
                  children: [
                    Text(
                      'Obrolan baru',
                      style:
                          TextStyle(
                        color:
                            Colors.white,
                        fontSize:
                            13,
                        fontWeight:
                            FontWeight.w600,
                      ),
                    ),
                    SizedBox(
                      height:
                          2,
                    ),
                    Text(
                      'Mulai percakapan baru',
                      style:
                          TextStyle(
                        color:
                            Color.fromRGBO(
                          255,
                          255,
                          255,
                          0.72,
                        ),
                        fontSize:
                            10.5,
                      ),
                    ),
                  ],
                ),
              ),

              Icon(
                Icons
                    .arrow_forward_ios_rounded,
                color:
                    Colors.white70,
                size:
                    13,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// SIDEBAR ITEM
// ============================================================

class _SidebarItem
    extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _SidebarItem({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Padding(
      padding:
          const EdgeInsets
              .symmetric(
        horizontal: 10,
        vertical: 1,
      ),
      child:
          Material(
        color:
            Colors.transparent,
        borderRadius:
            BorderRadius.circular(
          13,
        ),
        child:
            InkWell(
          onTap:
              onTap,
          borderRadius:
              BorderRadius.circular(
            13,
          ),
          child:
              Padding(
            padding:
                const EdgeInsets
                    .symmetric(
              horizontal: 10,
              vertical: 10,
            ),
            child:
                Row(
              children: [
                Icon(
                  icon,
                  color:
                      AppTheme
                          .textSecondary,
                  size:
                      20,
                ),

                const SizedBox(
                  width: 13,
                ),

                Expanded(
                  child:
                      Text(
                    title,
                    maxLines:
                        1,
                    overflow:
                        TextOverflow
                            .ellipsis,
                    style:
                        const TextStyle(
                      color:
                          AppTheme
                              .textPrimary,
                      fontSize:
                          13,
                      fontWeight:
                          FontWeight.w500,
                    ),
                  ),
                ),

                const Icon(
                  Icons
                      .chevron_right_rounded,
                  color:
                      AppTheme.textMuted,
                  size:
                      18,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// SETTINGS SHEET
// ============================================================

// ============================================================
// SETTINGS ACCOUNT CARD
// ============================================================

class _SettingsAccountCard
    extends StatelessWidget {
  final String name;
  final String email;
  final String plan;

  const _SettingsAccountCard({
    required this.name,
    required this.email,
    required this.plan,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    final initial =
        name.trim().isEmpty
            ? '?'
            : name
                .trim()
                .substring(
                  0,
                  1,
                )
                .toUpperCase();

    return Container(
      width:
          double.infinity,
      padding:
          const EdgeInsets.all(
        16,
      ),
      decoration:
          BoxDecoration(
        color:
            AppTheme
                .surfaceMuted,
        borderRadius:
            BorderRadius.circular(
          18,
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
        children: [
          Container(
            width:
                52,
            height:
                52,
            decoration:
                BoxDecoration(
              color:
                  AppTheme
                      .primary
                      .withValues(
                alpha:
                    0.10,
              ),
              shape:
                  BoxShape.circle,
            ),
            child:
                Center(
              child:
                  Text(
                initial,
                style:
                    const TextStyle(
                  color:
                      AppTheme
                          .primary,
                  fontSize:
                      21,
                  fontWeight:
                      FontWeight
                          .w700,
                ),
              ),
            ),
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
                Text(
                  name,
                  maxLines:
                      1,
                  overflow:
                      TextOverflow
                          .ellipsis,
                  style:
                      const TextStyle(
                    color:
                        AppTheme
                            .textPrimary,
                    fontSize:
                        15,
                    fontWeight:
                        FontWeight
                            .w700,
                  ),
                ),

                const SizedBox(
                  height: 3,
                ),

                Text(
                  email,
                  maxLines:
                      1,
                  overflow:
                      TextOverflow
                          .ellipsis,
                  style:
                      const TextStyle(
                    color:
                        AppTheme
                            .textSecondary,
                    fontSize:
                        11,
                  ),
                ),

                const SizedBox(
                  height: 5,
                ),

                Text(
                  plan,
                  style:
                      const TextStyle(
                    color:
                        AppTheme
                            .primary,
                    fontSize:
                        10.5,
                    fontWeight:
                        FontWeight
                            .w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// SETTINGS SECTION
// ============================================================

class _SettingsSection
    extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SettingsSection({
    required this.title,
    required this.children,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Padding(
          padding:
              const EdgeInsets
                  .fromLTRB(
            6,
            0,
            6,
            6,
          ),
          child:
              Text(
            title,
            style:
                const TextStyle(
              color:
                  AppTheme
                      .textMuted,
              fontSize:
                  11,
              fontWeight:
                  FontWeight
                      .w600,
            ),
          ),
        ),
        Container(
          decoration:
              BoxDecoration(
            color:
                AppTheme
                    .surfaceLight,
            borderRadius:
                BorderRadius.circular(
              16,
            ),
            border:
                Border.all(
              color:
                  AppTheme
                      .borderLight,
            ),
          ),
          child:
              Column(
            children: children,
          ),
        ),
      ],
    );
  }
}

// ============================================================
// SETTINGS TILE
// ============================================================

class _SettingsTile
    extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Material(
      color:
          Colors.transparent,
      child:
          InkWell(
        onTap:
            onTap,
        child:
            Padding(
          padding:
              const EdgeInsets
                  .symmetric(
            horizontal:
                14,
            vertical:
                12,
          ),
          child:
              Row(
            children: [
              Container(
                width:
                    38,
                height:
                    38,
                decoration:
                    BoxDecoration(
                  color:
                      AppTheme
                          .surfaceMuted,
                  borderRadius:
                      BorderRadius
                          .circular(
                    11,
                  ),
                ),
                child:
                    Icon(
                  icon,
                  color:
                      AppTheme
                          .textSecondary,
                  size:
                      20,
                ),
              ),

              const SizedBox(
                width: 11,
              ),

              Expanded(
                child:
                    Column(
                  crossAxisAlignment:
                      CrossAxisAlignment
                          .start,
                  children: [
                    Text(
                      title,
                      maxLines:
                          1,
                      overflow:
                          TextOverflow
                              .ellipsis,
                      style:
                          const TextStyle(
                        color:
                            AppTheme
                                .textPrimary,
                        fontSize:
                            13,
                        fontWeight:
                            FontWeight
                                .w600,
                      ),
                    ),

                    const SizedBox(
                      height: 2,
                    ),

                    Text(
                      subtitle,
                      maxLines:
                          2,
                      overflow:
                          TextOverflow
                              .ellipsis,
                      style:
                          const TextStyle(
                        color:
                            AppTheme
                                .textSecondary,
                        fontSize:
                            10.5,
                      ),
                    ),
                  ],
                ),
              ),

              const Icon(
                Icons
                    .chevron_right_rounded,
                color:
                    AppTheme.textMuted,
                size:
                    19,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// EMPTY CHAT
// ============================================================

class _EmptyChat
    extends StatelessWidget {
  const _EmptyChat();

  @override
  Widget build(
    BuildContext context,
  ) {
    return Center(
      child:
          SingleChildScrollView(
        padding:
            const EdgeInsets
                .symmetric(
          horizontal:
              28,
          vertical:
              24,
        ),
        child:
            Column(
          mainAxisSize:
              MainAxisSize.min,
          children: [
            Container(
              width:
                  78,
              height:
                  78,
              decoration:
                  BoxDecoration(
                color:
                    AppTheme
                        .primary
                        .withValues(
                  alpha:
                      0.10,
                ),
                shape:
                    BoxShape.circle,
              ),
              child:
                  const Icon(
                Icons
                    .auto_awesome_rounded,
                color:
                    AppTheme.primary,
                size:
                    36,
              ),
            ),

            const SizedBox(
              height: 20,
            ),

            const Text(
              'Tanya apa saja',
              textAlign:
                  TextAlign.center,
              style:
                  TextStyle(
                color:
                    AppTheme
                        .textPrimary,
                fontSize:
                    21,
                fontWeight:
                    FontWeight.w700,
              ),
            ),

            const SizedBox(
              height: 8,
            ),

            const Text(
              'Gunakan PintarAja untuk membantu tugas, riset, ide, dan berbagai kebutuhan akademikmu.',
              textAlign:
                  TextAlign.center,
              style:
                  TextStyle(
                color:
                    AppTheme
                        .textSecondary,
                fontSize:
                    13,
                height:
                    1.5,
              ),
            ),

            const SizedBox(
              height: 20,
            ),

            Wrap(
              alignment:
                  WrapAlignment
                      .center,
              spacing:
                  8,
              runSpacing:
                  8,
              children: const [
                _SuggestionButton(
                  text:
                      'Bantu tugas kuliah',
                ),
                _SuggestionButton(
                  text:
                      'Buat ide skripsi',
                ),
                _SuggestionButton(
                  text:
                      'Ringkas teks',
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

class _SuggestionButton
    extends StatelessWidget {
  final String text;

  const _SuggestionButton({
    required this.text,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return GestureDetector(
      onTap:
          () {
        final state =
            context
                .findAncestorStateOfType<
                    _ChatScreenState>();

        if (state == null) {
          return;
        }

        state
            ._messageController
            .text = text;

        state._sendMessage();
      },
      child:
          Container(
        constraints:
            const BoxConstraints(
          maxWidth:
              170,
        ),
        padding:
            const EdgeInsets
                .symmetric(
          horizontal:
              13,
          vertical:
              9,
        ),
        decoration:
            BoxDecoration(
          color:
              AppTheme
                  .surfaceLight,
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
            Text(
          text,
          maxLines:
              1,
          overflow:
              TextOverflow.ellipsis,
          style:
              const TextStyle(
            color:
                AppTheme
                    .textSecondary,
            fontSize:
                11.5,
            fontWeight:
                FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

// ============================================================
// MESSAGE BUBBLE
// ============================================================

class _MessageBubble
    extends StatelessWidget {
  final ChatMessage message;

  const _MessageBubble({
    required this.message,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    final isUser =
        message.isUser;

    final maxWidth =
        MediaQuery.sizeOf(
              context,
            ).width *
            0.82;

    return Padding(
      padding:
          const EdgeInsets.only(
        bottom: 18,
      ),
      child:
          Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        mainAxisAlignment:
            isUser
                ? MainAxisAlignment.end
                : MainAxisAlignment.start,
        children: [
          if (!isUser)
            Container(
              width:
                  32,
              height:
                  32,
              decoration:
                  BoxDecoration(
                color:
                    AppTheme
                        .primary
                        .withValues(
                  alpha:
                      0.10,
                ),
                shape:
                    BoxShape.circle,
              ),
              child:
                  const Icon(
                Icons
                    .auto_awesome_rounded,
                color:
                    AppTheme.primary,
                size:
                    16,
              ),
            ),

          if (!isUser)
            const SizedBox(
              width: 9,
            ),

          Flexible(
            child:
                ConstrainedBox(
              constraints:
                  BoxConstraints(
                maxWidth:
                    maxWidth,
              ),
              child:
                  Container(
                padding:
                    const EdgeInsets.all(
                  14,
                ),
                decoration:
                    BoxDecoration(
                  color:
                      isUser
                          ? AppTheme
                              .primary
                          : AppTheme
                              .surfaceLight,
                  borderRadius:
                      BorderRadius.only(
                    topLeft:
                        const Radius
                            .circular(
                      18,
                    ),
                    topRight:
                        const Radius
                            .circular(
                      18,
                    ),
                    bottomLeft:
                        Radius.circular(
                      isUser
                          ? 18
                          : 5,
                    ),
                    bottomRight:
                        Radius.circular(
                      isUser
                          ? 5
                          : 18,
                    ),
                  ),
                  border:
                      isUser
                          ? null
                          : Border.all(
                              color:
                                  AppTheme
                                      .borderLight,
                            ),
                ),
                child:
                    Text(
                  message.content,
                  softWrap:
                      true,
                  style:
                      TextStyle(
                    color:
                        isUser
                            ? Colors.white
                            : AppTheme
                                .textPrimary,
                    fontSize:
                        14,
                    height:
                        1.5,
                  ),
                ),
              ),
            ),
          ),

          if (isUser)
            const SizedBox(
              width: 9,
            ),

          if (isUser)
            Container(
              width:
                  32,
              height:
                  32,
              decoration:
                  const BoxDecoration(
                color:
                    AppTheme
                        .surfaceMuted,
                shape:
                    BoxShape.circle,
              ),
              child:
                  const Icon(
                Icons.person_rounded,
                color:
                    AppTheme
                        .textSecondary,
                size:
                    17,
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

class _ChatInput
    extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;

  const _ChatInput({
    required this.controller,
    required this.onSend,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Consumer<ChatProvider>(
      builder: (
        context,
        chat,
        _,
      ) {
        return SafeArea(
          top:
              false,
          child:
              Container(
            padding:
                const EdgeInsets
                    .fromLTRB(
              10,
              7,
              10,
              9,
            ),
            decoration:
                const BoxDecoration(
              color:
                  AppTheme
                      .backgroundApp,
              border:
                  Border(
                top:
                    BorderSide(
                  color:
                      AppTheme
                          .borderLight,
                ),
              ),
            ),
            child:
                Container(
              padding:
                  const EdgeInsets
                      .symmetric(
                horizontal:
                    4,
              ),
              decoration:
                  BoxDecoration(
                color:
                    AppTheme
                        .surfaceLight,
                borderRadius:
                    BorderRadius.circular(
                  18,
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
                crossAxisAlignment:
                    CrossAxisAlignment.end,
                children: [
                  IconButton(
                    tooltip:
                        'Lampiran',
                    onPressed:
                        () {
                      _showInfoSnackBar(
                        context,
                        'Lampiran akan kita sambungkan berikutnya.',
                      );
                    },
                    icon:
                        const Icon(
                      Icons
                          .attach_file_rounded,
                      color:
                          AppTheme
                              .textSecondary,
                      size:
                          20,
                    ),
                  ),

                  Expanded(
                    child:
                        TextField(
                      controller:
                          controller,
                      minLines:
                          1,
                      maxLines:
                          5,
                      keyboardType:
                          TextInputType.multiline,
                      textInputAction:
                          TextInputAction.newline,
                      onSubmitted:
                          (_) {
                        if (!chat
                            .isStreaming) {
                          onSend();
                        }
                      },
                      decoration:
                          const InputDecoration(
                        hintText:
                            'Tulis pesan...',
                        border:
                            InputBorder.none,
                        enabledBorder:
                            InputBorder.none,
                        focusedBorder:
                            InputBorder.none,
                        filled:
                            false,
                        contentPadding:
                            EdgeInsets
                                .symmetric(
                          vertical:
                              12,
                        ),
                      ),
                    ),
                  ),

                  IconButton(
                    tooltip:
                        'Voice',
                    onPressed:
                        () {
                      _showInfoSnackBar(
                        context,
                        'Voice chat akan kita sambungkan berikutnya.',
                      );
                    },
                    icon:
                        const Icon(
                      Icons
                          .mic_none_rounded,
                      color:
                          AppTheme
                              .textSecondary,
                      size:
                          20,
                    ),
                  ),

                  GestureDetector(
                    onTap:
                        chat.isStreaming
                            ? null
                            : onSend,
                    child:
                        Container(
                      width:
                          40,
                      height:
                          40,
                      margin:
                          const EdgeInsets
                              .only(
                        bottom:
                            4,
                      ),
                      decoration:
                          BoxDecoration(
                        color:
                            chat.isStreaming
                                ? AppTheme
                                    .surfaceMuted
                                : AppTheme
                                    .primary,
                        shape:
                            BoxShape.circle,
                      ),
                      child:
                          chat.isStreaming
                              ? const Padding(
                                  padding:
                                      EdgeInsets.all(
                                    10,
                                  ),
                                  child:
                                      CircularProgressIndicator(
                                    strokeWidth:
                                        2,
                                    color:
                                        AppTheme
                                            .primary,
                                  ),
                                )
                              : const Icon(
                                  Icons
                                      .arrow_upward_rounded,
                                  color:
                                      Colors.white,
                                  size:
                                      20,
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
  }

  static void _showInfoSnackBar(
    BuildContext context,
    String message,
  ) {
    ScaffoldMessenger.of(
      context,
    )
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content:
              Text(message),
          behavior:
              SnackBarBehavior
                  .floating,
        ),
      );
  }
}

// ============================================================
// AI PROVIDER OPTION
// ============================================================

class _ProviderOption
    extends StatelessWidget {
  final AiProvider provider;
  final bool selected;
  final VoidCallback? onTap;

  const _ProviderOption({
    required this.provider,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    final quota =
        provider.quota;

    String quotaText;

    if (!quota.hasLimit) {
      quotaText =
          'Tanpa batas harian';
    } else if (provider.isLimited) {
      quotaText =
          'Kuota hari ini habis';
    } else {
      quotaText =
          'Sisa ${quota.remaining} / ${quota.limit} hari ini';
    }

    Color titleColor;

    if (provider.isLimited) {
      titleColor =
          AppTheme.textMuted;
    } else if (selected) {
      titleColor =
          AppTheme.primary;
    } else {
      titleColor =
          AppTheme.textPrimary;
    }

    return Padding(
      padding:
          const EdgeInsets.only(
        bottom:
            4,
      ),
      child:
          Material(
        color:
            Colors.transparent,
        borderRadius:
            BorderRadius.circular(
          14,
        ),
        child:
            InkWell(
          onTap:
              onTap,
          borderRadius:
              BorderRadius.circular(
            14,
          ),
          child:
              Padding(
            padding:
                const EdgeInsets
                    .symmetric(
              horizontal:
                  10,
              vertical:
                  10,
            ),
            child:
                Row(
              children: [
                Container(
                  width:
                      40,
                  height:
                      40,
                  decoration:
                      BoxDecoration(
                    color:
                        provider
                                .isLimited
                            ? AppTheme
                                .surfaceMuted
                            : AppTheme
                                .primary
                                .withValues(
                                alpha:
                                    0.10,
                              ),
                    borderRadius:
                        BorderRadius
                            .circular(
                      11,
                    ),
                  ),
                  child:
                      Icon(
                    Icons
                        .auto_awesome_rounded,
                    color:
                        provider
                                .isLimited
                            ? AppTheme
                                .textMuted
                            : AppTheme
                                .primary,
                    size:
                        20,
                  ),
                ),

                const SizedBox(
                  width: 11,
                ),

                Expanded(
                  child:
                      Column(
                    crossAxisAlignment:
                        CrossAxisAlignment
                            .start,
                    children: [
                      Text(
                        provider
                            .displayName,
                        maxLines:
                            1,
                        overflow:
                            TextOverflow
                                .ellipsis,
                        style:
                            TextStyle(
                          color:
                              titleColor,
                          fontSize:
                              13.5,
                          fontWeight:
                              selected
                                  ? FontWeight
                                      .w700
                                  : FontWeight
                                      .w500,
                        ),
                      ),

                      const SizedBox(
                        height: 3,
                      ),

                      Text(
                        quotaText,
                        maxLines:
                            1,
                        overflow:
                            TextOverflow
                                .ellipsis,
                        style:
                            const TextStyle(
                          color:
                              AppTheme
                                  .textMuted,
                          fontSize:
                              10,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(
                  width: 8,
                ),

                if (provider.isLimited)
                  const Icon(
                    Icons
                        .lock_outline_rounded,
                    color:
                        AppTheme
                            .textMuted,
                    size:
                        18,
                  )
                else if (selected)
                  const Icon(
                    Icons
                        .check_circle_rounded,
                    color:
                        AppTheme.primary,
                    size:
                        20,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}