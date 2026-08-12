// ============================================================
// CHAT PROVIDER — AI Chat State Management
// ============================================================

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../core/constants/api_constants.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';

class ChatMessage {
  final String role; // 'user' atau 'assistant'
  final String content;
  final DateTime timestamp;

  ChatMessage({
    required this.role,
    required this.content,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  bool get isUser => role == 'user';
}

class Conversation {
  final int id;
  final String title;
  final DateTime updatedAt;

  Conversation({required this.id, required this.title, required this.updatedAt});

  factory Conversation.fromJson(Map<String, dynamic> json) => Conversation(
    id: json['id'],
    title: json['title'] ?? 'Chat baru',
    updatedAt: DateTime.tryParse(json['updated_at'] ?? '') ?? DateTime.now(),
  );
}

class ChatProvider extends ChangeNotifier {
  List<ChatMessage> _messages = [];
  List<Conversation> _conversations = [];
  int? _currentConversationId;
  bool _isLoading = false;
  bool _isStreaming = false;
  String? _error;

  List<ChatMessage> get messages => _messages;
  List<Conversation> get conversations => _conversations;
  int? get currentConversationId => _currentConversationId;
  bool get isLoading => _isLoading;
  bool get isStreaming => _isStreaming;
  String? get error => _error;

  // ── Load Conversations ─────────────────────────────────────
  Future<void> loadConversations() async {
    try {
      final data = await ApiService.instance.get(ApiConstants.conversations);
      final list = data['data'] ?? data;
      _conversations = (list as List)
          .map((e) => Conversation.fromJson(e))
          .toList();
      notifyListeners();
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
    }
  }

  // ── Load Messages ─────────────────────────────────────────
  Future<void> loadMessages(int conversationId) async {
    _currentConversationId = conversationId;
    _isLoading = true;
    _messages = [];
    notifyListeners();

    try {
      final data = await ApiService.instance.get(
        '${ApiConstants.conversations}/$conversationId',
      );
      final msgs = data['messages'] ?? [];
      _messages = (msgs as List)
          .map((e) => ChatMessage(
                role: e['role'] ?? 'user',
                content: e['content'] ?? '',
                timestamp: DateTime.tryParse(e['created_at'] ?? ''),
              ))
          .toList();
    } on ApiException catch (e) {
      _error = e.message;
    }

    _isLoading = false;
    notifyListeners();
  }

  // ── Send Message ──────────────────────────────────────────
  Future<void> sendMessage(String message, {String? model}) async {
    if (message.trim().isEmpty) return;

    // Tambah pesan user ke list
    _messages.add(ChatMessage(role: 'user', content: message));
    _isStreaming = true;
    _error = null;
    notifyListeners();

    // Tambah placeholder untuk response AI
    final aiMsg = ChatMessage(role: 'assistant', content: '');
    _messages.add(aiMsg);

    try {
      final token = StorageService.getToken();
      final body = {
        'message': message,
        if (_currentConversationId != null)
          'conversation_id': _currentConversationId,
        if (model != null) 'model': model,
      };

      // Coba streaming dulu, kalau gagal pakai regular POST
      final response = await http.post(
        Uri.parse(ApiConstants.chat),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'text/event-stream',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final content = data['message'] ?? data['content'] ?? data['response'] ?? '';
        final convId = data['conversation_id'];

        // Update AI message
        final idx = _messages.lastIndexOf(aiMsg);
        if (idx != -1) {
          _messages[idx] = ChatMessage(role: 'assistant', content: content);
        }

        if (convId != null && _currentConversationId == null) {
          _currentConversationId = convId;
          await loadConversations(); // Refresh list
        }
      } else {
        _messages.removeLast();
        _error = 'Gagal mengirim pesan. Coba lagi.';
      }
    } catch (e) {
      _messages.removeLast();
      _error = 'Terjadi kesalahan: $e';
    }

    _isStreaming = false;
    notifyListeners();
  }

  // ── New Chat ───────────────────────────────────────────────
  void startNewChat() {
    _messages = [];
    _currentConversationId = null;
    _error = null;
    notifyListeners();
  }

  // ── Delete Conversation ───────────────────────────────────
  Future<void> deleteConversation(int id) async {
    try {
      await ApiService.instance.delete('${ApiConstants.conversations}/$id');
      _conversations.removeWhere((c) => c.id == id);
      if (_currentConversationId == id) startNewChat();
      notifyListeners();
    } catch (_) {}
  }
}
