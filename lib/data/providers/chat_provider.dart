import 'dart:io';
// ============================================================
// PINTARAJA — CHAT PROVIDER
// AI Provider + Daily Quota + Token-aware Chat
// Conversation + Messages
// ============================================================

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../core/constants/api_constants.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';

// ============================================================
// CHAT MESSAGE
// ============================================================

class ChatMessage {
  final int? id;
  final int? conversationId;
  final String role;
  final String content;
  final DateTime timestamp;
  final String? time;
  final List<dynamic> annotations;

  const ChatMessage({
    this.id,
    this.conversationId,
    required this.role,
    required this.content,
    required this.timestamp,
    this.time,
    this.annotations = const [],
  });

  bool get isUser => role.toLowerCase() == 'user';

  bool get isAssistant => role.toLowerCase() == 'assistant';

  factory ChatMessage.fromJson(
    Map<String, dynamic> json,
  ) {
    final rawTime = json['time'] ?? json['created_at'] ?? json['createdAt'];

    DateTime parsedTimestamp = DateTime.now();

    if (rawTime != null) {
      final parsed = DateTime.tryParse(
        rawTime.toString(),
      );

      if (parsed != null) {
        parsedTimestamp = parsed;
      }
    }

    final rawAnnotations = json['annotations'];

    return ChatMessage(
      id: _toInt(json['id']),
      conversationId: _toInt(
        json['conversationId'] ?? json['conversation_id'],
      ),
      role: json['role']?.toString() ?? 'user',
      content: json['content']?.toString() ?? '',
      timestamp: parsedTimestamp,
      time: rawTime?.toString(),
      annotations: rawAnnotations is List
          ? List<dynamic>.from(
              rawAnnotations,
            )
          : const [],
    );
  }

  static int? _toInt(
    dynamic value,
  ) {
    if (value == null) {
      return null;
    }

    if (value is int) {
      return value;
    }

    return int.tryParse(
      value.toString(),
    );
  }
}

// ============================================================
// CONVERSATION
// ============================================================

class Conversation {
  final int id;
  final String title;
  final String lastUpdated;
  final int? nextCursor;
  final bool hasMoreChats;

  const Conversation({
    required this.id,
    required this.title,
    required this.lastUpdated,
    this.nextCursor,
    this.hasMoreChats = false,
  });

  factory Conversation.fromJson(
    Map<String, dynamic> json,
  ) {
    return Conversation(
      id: int.tryParse(
            json['id']?.toString() ?? '',
          ) ??
          0,
      title: json['title']?.toString() ?? 'Obrolan Baru',
      lastUpdated: json['lastUpdated']?.toString() ??
          json['updated_at']?.toString() ??
          'baru saja',
      nextCursor: int.tryParse(
        json['nextCursor']?.toString() ?? '',
      ),
      hasMoreChats: json['hasMoreChats'] == true,
    );
  }
}

// ============================================================
// AI QUOTA
// ============================================================

class AiQuota {
  final int used;
  final int limit;
  final int remaining;

  const AiQuota({
    required this.used,
    required this.limit,
    required this.remaining,
  });

  factory AiQuota.fromJson(
    dynamic json,
  ) {
    if (json is! Map) {
      return const AiQuota(
        used: 0,
        limit: 0,
        remaining: 0,
      );
    }

    return AiQuota(
      used: _toInt(
        json['used'],
      ),
      limit: _toInt(
        json['limit'],
      ),
      remaining: _toInt(
        json['remaining'],
      ),
    );
  }

  bool get hasLimit => limit > 0;

  bool get isUnlimited => limit <= 0;

  bool get isExhausted => hasLimit && remaining <= 0;

  double get progress {
    if (!hasLimit || limit <= 0) {
      return 0;
    }

    return (used / limit).clamp(
      0.0,
      1.0,
    );
  }

  static int _toInt(
    dynamic value,
  ) {
    if (value == null) {
      return 0;
    }

    if (value is int) {
      return value;
    }

    if (value is double) {
      return value.toInt();
    }

    return int.tryParse(
          value.toString(),
        ) ??
        0;
  }
}

// ============================================================
// AI PROVIDER
// ============================================================

class AiProvider {
  final int id;
  final String code;
  final String model;
  final bool isLimited;
  final AiQuota quota;

  const AiProvider({
    required this.id,
    required this.code,
    required this.model,
    required this.isLimited,
    required this.quota,
  });

  factory AiProvider.fromJson(
    Map<String, dynamic> json, {
    AiQuota? quota,
  }) {
    final providerQuota = quota ??
        const AiQuota(
          used: 0,
          limit: 0,
          remaining: 0,
        );

    final code = json['code']?.toString() ?? '';

    final model = json['model']?.toString() ?? '';

    return AiProvider(
      id: int.tryParse(
            json['id']?.toString() ?? '',
          ) ??
          0,
      code: code,
      model: model,
      isLimited: json['isLimited'] == true || providerQuota.isExhausted,
      quota: providerQuota,
    );
  }

  String get displayName {
    final value = model.toLowerCase();

    if (value.contains('gpt')) {
      return model.isNotEmpty ? model : 'GPT';
    }

    if (value.contains('gemini')) {
      return model.isNotEmpty ? model : 'Gemini';
    }

    if (value.contains('claude')) {
      return model.isNotEmpty ? model : 'Claude';
    }

    if (value.contains('grok')) {
      return model.isNotEmpty ? model : 'Grok';
    }

    if (value.contains('deepseek')) {
      return model.isNotEmpty ? model : 'DeepSeek';
    }

    if (value.contains('qwen')) {
      return model.isNotEmpty ? model : 'Qwen';
    }

    if (value.contains('dreamina')) {
      return model.isNotEmpty ? model : 'Dreamina';
    }

    return model.isNotEmpty ? model : code;
  }
}

// ============================================================
// CHAT PROVIDER
// ============================================================

class ChatProvider extends ChangeNotifier {
  // ==========================================================
  // STATE
  // ==========================================================

  List<ChatMessage> _messages = [];

  List<Conversation> _conversations = [];

  List<AiProvider> _aiProviders = [];

  Map<String, AiQuota> _quotas = {};

  int? _currentConversationId;

  int? _selectedProviderId;

  bool _isLoading = false;

  bool _isStreaming = false;

  bool _isCreatingConversation = false;

  String? _error;

  String? _systemPrompt;

  String? get systemPrompt => _systemPrompt;

  void setSystemPrompt(String? prompt) {
    _systemPrompt = prompt?.trim().isEmpty == true ? null : prompt?.trim();
    notifyListeners();
  }

  // ==========================================================
  // GETTERS
  // ==========================================================

  List<ChatMessage> get messages => List.unmodifiable(
        _messages,
      );

  List<Conversation> get conversations => List.unmodifiable(
        _conversations,
      );

  List<AiProvider> get aiProviders => List.unmodifiable(
        _aiProviders,
      );

  Map<String, AiQuota> get quotas => Map.unmodifiable(
        _quotas,
      );

  int? get currentConversationId => _currentConversationId;

  int? get selectedProviderId => _selectedProviderId;

  bool get isLoading => _isLoading;

  bool get isStreaming => _isStreaming;

  bool get isCreatingConversation => _isCreatingConversation;

  String? get error => _error;

  AiProvider? get selectedProvider {
    final selectedId = _selectedProviderId;

    if (selectedId == null) {
      return null;
    }

    for (final provider in _aiProviders) {
      if (provider.id == selectedId) {
        return provider;
      }
    }

    return null;
  }

  String get selectedModelName {
    final provider = selectedProvider;

    if (provider == null) {
      return 'Pilih AI';
    }

    return provider.displayName;
  }

  // ==========================================================
  // INITIALIZE
  // ==========================================================

  Future<void> initializeChat() async {
    _error = null;

    await Future.wait([
      loadAiProviders(),
      loadConversations(),
    ]);

    notifyListeners();
  }

  // ==========================================================
  // LOAD PROVIDERS + QUOTA
  // GET /api/chats
  // ==========================================================

  Future<void> loadAiProviders() async {
    try {
      final data = await ApiService.instance.get(
        ApiConstants.chats,
      );

      if (data is! Map) {
        throw const ApiException(
          'Response AI provider tidak valid.',
        );
      }

      _parseQuotas(
        data['quota'],
      );

      final rawProviders = data['ai'];

      if (rawProviders is! List) {
        _aiProviders = [];

        notifyListeners();

        return;
      }

      final providers = <AiProvider>[];

      for (final raw in rawProviders) {
        if (raw is! Map) {
          continue;
        }

        final providerMap = Map<String, dynamic>.from(
          raw,
        );

        final code = providerMap['code']?.toString() ?? '';

        final quota = _quotas[code] ??
            const AiQuota(
              used: 0,
              limit: 0,
              remaining: 0,
            );

        providers.add(
          AiProvider.fromJson(
            providerMap,
            quota: quota,
          ),
        );
      }

      _aiProviders = providers
          .where(
            (provider) => provider.id > 0,
          )
          .toList();

      // ======================================================
      // SELECT DEFAULT
      // ======================================================

      if (_selectedProviderId == null) {
        _selectedProviderId = _findPreferredProvider();
      } else {
        final exists = _aiProviders.any(
          (provider) => provider.id == _selectedProviderId,
        );

        if (!exists) {
          _selectedProviderId = _findPreferredProvider();
        }
      }

      notifyListeners();
    } on ApiException catch (e) {
      _error = e.message;

      notifyListeners();
    } catch (e) {
      _error = 'Gagal memuat AI provider.';

      notifyListeners();
    }
  }

  // ==========================================================
  // PARSE QUOTA
  // ==========================================================

  void _parseQuotas(
    dynamic rawQuota,
  ) {
    _quotas = {};

    if (rawQuota is! Map) {
      return;
    }

    rawQuota.forEach(
      (
        key,
        value,
      ) {
        _quotas[key.toString()] = AiQuota.fromJson(
          value,
        );
      },
    );
  }

  // ==========================================================
  // PREFERRED PROVIDER
  // GPT FIRST
  // ==========================================================

  int? _findPreferredProvider() {
    if (_aiProviders.isEmpty) {
      return null;
    }

    // GPT lebih diprioritaskan, namun backend bisa
    // mengembalikan value dengan casing berbeda atau label lain.
    for (final provider in _aiProviders) {
      final code = provider.code.toLowerCase();
      final model = provider.model.toLowerCase();

      if ((!provider.isLimited) &&
          (code == 'setting-gpt' ||
              code.contains('gpt') ||
              model.contains('gpt'))) {
        return provider.id;
      }
    }

    // Kalau GPT habis,
    // cari provider aktif berikutnya.
    for (final provider in _aiProviders) {
      if (!provider.isLimited) {
        return provider.id;
      }
    }

    // Semua limit habis.
    return _aiProviders.first.id;
  }

  // ==========================================================
  // SELECT PROVIDER
  // ==========================================================

  void selectProvider(
    int providerId,
  ) {
    final provider = _findProvider(
      providerId,
    );

    if (provider == null) {
      return;
    }

    _selectedProviderId = provider.id;

    notifyListeners();
  }

  // ==========================================================
  // SELECT BY MODEL
  // ==========================================================

  void selectProviderByModel(
    String model,
  ) {
    final query = model.trim().toLowerCase();

    if (query.isEmpty) {
      return;
    }

    AiProvider? exact;

    for (final provider in _aiProviders) {
      final providerModel = provider.model.toLowerCase();

      final providerName = provider.displayName.toLowerCase();

      final providerCode = provider.code.toLowerCase();

      if (providerModel == query ||
          providerName == query ||
          providerCode == query) {
        exact = provider;
        break;
      }
    }

    exact ??= _aiProviders.cast<AiProvider?>().firstWhere(
      (provider) {
        if (provider == null) {
          return false;
        }

        final name = provider.displayName.toLowerCase();

        final modelName = provider.model.toLowerCase();

        final code = provider.code.toLowerCase();

        return name.contains(
              query,
            ) ||
            modelName.contains(
              query,
            ) ||
            code.contains(
              query,
            );
      },
      orElse: () => null,
    );

    if (exact != null) {
      _selectedProviderId = exact.id;

      notifyListeners();
    }
  }

  // ==========================================================
  // FIND PROVIDER
  // ==========================================================

  AiProvider? _findProvider(
    int providerId,
  ) {
    for (final provider in _aiProviders) {
      if (provider.id == providerId) {
        return provider;
      }
    }

    return null;
  }

  // ==========================================================
  // REFRESH QUOTA
  // ==========================================================

  Future<void> refreshProviders() async {
    await loadAiProviders();
  }

  // ==========================================================
  // LOAD CONVERSATIONS
  // GET /api/convers
  // ==========================================================

  Future<void> loadConversations({
    String? search,
    int page = 1,
    int perPage = 15,
  }) async {
    try {
      final params = <String, String>{
        'page': page.toString(),
        'per_page': perPage.toString(),
      };

      if (search != null && search.trim().isNotEmpty) {
        params['search'] = search.trim();
      }

      final data = await ApiService.instance.get(
        ApiConstants.conversations,
        params: params,
      );

      if (data is! Map) {
        throw const ApiException(
          'Response conversation tidak valid.',
        );
      }

      final rawList = data['data'];

      if (rawList is! List) {
        _conversations = [];

        notifyListeners();

        return;
      }

      _conversations = rawList
          .whereType<Map>()
          .map(
            (
              item,
            ) =>
                Conversation.fromJson(
              Map<String, dynamic>.from(
                item,
              ),
            ),
          )
          .where(
            (conversation) => conversation.id > 0,
          )
          .toList();

      notifyListeners();
    } on ApiException catch (e) {
      _error = e.message;

      notifyListeners();
    } catch (e) {
      _error = 'Gagal memuat percakapan.';

      notifyListeners();
    }
  }

  // ==========================================================
  // CREATE CONVERSATION
  // POST /api/convers
  // ==========================================================

  Future<int?> createConversation({
    String? title,
  }) async {
    _isCreatingConversation = true;

    _error = null;

    notifyListeners();

    try {
      final body = <String, dynamic>{};

      if (title != null && title.trim().isNotEmpty) {
        body['title'] = title.trim();
      }

      final data = await ApiService.instance.post(
        ApiConstants.conversations,
        body,
      );

      if (data is! Map) {
        throw const ApiException(
          'Response conversation tidak valid.',
        );
      }

      final rawConversation = data['conversation'];

      if (rawConversation is! Map) {
        throw const ApiException(
          'Conversation tidak ditemukan.',
        );
      }

      final conversation = Conversation.fromJson(
        Map<String, dynamic>.from(
          rawConversation,
        ),
      );

      if (conversation.id <= 0) {
        throw const ApiException(
          'ID conversation tidak valid.',
        );
      }

      _currentConversationId = conversation.id;

      _messages = [];

      await loadConversations();

      return conversation.id;
    } on ApiException catch (e) {
      _error = e.message;

      notifyListeners();

      return null;
    } catch (_) {
      _error = 'Gagal membuat obrolan baru.';

      notifyListeners();

      return null;
    } finally {
      _isCreatingConversation = false;

      notifyListeners();
    }
  }

  // ==========================================================
  // LOAD MESSAGE
  // GET /api/chats/{id}
  // ==========================================================

  Future<void> loadMessages(
    int conversationId,
  ) async {
    _currentConversationId = conversationId;

    _isLoading = true;

    _error = null;

    _messages = [];

    notifyListeners();

    try {
      final data = await ApiService.instance.get(
        ApiConstants.conversationChats(
          conversationId,
        ),
      );

      if (data is! Map) {
        throw const ApiException(
          'Response chat tidak valid.',
        );
      }

      final rawMessages = data['chats'];

      if (rawMessages is! List) {
        _messages = [];

        _isLoading = false;

        notifyListeners();

        return;
      }

      _messages = rawMessages
          .whereType<Map>()
          .map(
            (
              item,
            ) =>
                ChatMessage.fromJson(
              Map<String, dynamic>.from(
                item,
              ),
            ),
          )
          .toList();
    } on ApiException catch (e) {
      _error = e.message;
    } catch (_) {
      _error = 'Gagal memuat pesan.';
    } finally {
      _isLoading = false;

      notifyListeners();
    }
  }

  // ==========================================================
  // START NEW CHAT
  // ==========================================================

  Future<int?> startNewChat({
    bool createOnServer = true,
  }) async {
    _messages = [];

    _currentConversationId = null;

    _error = null;

    notifyListeners();

    if (!createOnServer) {
      return null;
    }

    return createConversation();
  }

  // ==========================================================
  // SEND MESSAGE
  // POST /api/chats
  // ==========================================================

  Future<void> sendMessage(
    String message, {
    String? model,
    File? attachedFile,
    String? attachedFileName,
  }) async {
    final cleanMessage = message.trim();

    if (cleanMessage.isEmpty && attachedFile == null) {
      return;
    }

    _error = null;

    // ========================================================
    // PROVIDER
    // ========================================================

    if (_aiProviders.isEmpty) {
      await loadAiProviders();
    }

    if (model != null && model.trim().isNotEmpty) {
      selectProviderByModel(
        model,
      );
    }

    if (_selectedProviderId == null) {
      _error = 'AI provider belum tersedia.';

      notifyListeners();

      return;
    }

    final provider = selectedProvider;

    if (provider == null) {
      _error = 'AI provider tidak ditemukan.';

      notifyListeners();

      return;
    }

    if (provider.isLimited) {
      _error = 'Kuota ${provider.displayName} untuk hari ini sudah habis.';

      notifyListeners();

      return;
    }

    // ========================================================
    // CONVERSATION
    // ========================================================

    if (_currentConversationId == null) {
      final id = await createConversation();

      if (id == null) {
        return;
      }
    }

    final conversationId = _currentConversationId!;

    // ========================================================
    // LOCAL USER MESSAGE
    // ========================================================
    String finalContent = cleanMessage;
    String? base64Str;
    if (attachedFile != null) {
      try {
        final bytes = await attachedFile.readAsBytes();
        base64Str = base64Encode(bytes);
        final name = attachedFileName ?? 'file';
        final isImage = name.toLowerCase().endsWith('.jpg') ||
            name.toLowerCase().endsWith('.jpeg') ||
            name.toLowerCase().endsWith('.png');

        final arr = [];
        if (cleanMessage.isNotEmpty) {
          arr.add({"type": "text", "text": cleanMessage});
        }
        if (isImage) {
          arr.add({
            "type": "image_url",
            "image_url": {"url": "data:image/jpeg;base64,$base64Str"},
            "name": name
          });
        } else {
          arr.add({"type": "file", "name": name});
        }
        finalContent = jsonEncode(arr);
      } catch (e) {
        // Fallback
        finalContent = cleanMessage;
      }
    }

    _messages.add(
      ChatMessage(
        role: 'user',
        content: finalContent,
        timestamp: DateTime.now(),
        conversationId: conversationId,
      ),
    );

    // Temporary assistant bubble.
    final placeholderIndex = _messages.length;

    _messages.add(
      ChatMessage(
        role: 'assistant',
        content: '',
        timestamp: DateTime.now(),
        conversationId: conversationId,
      ),
    );

    _isStreaming = true;

    notifyListeners();

    try {
      // ======================================================
      // HISTORY
      // ======================================================

      final messageToAi = _buildMessageHistory();

      // ======================================================
      // TOKEN
      // ======================================================

      final token = StorageService.getToken();

      if (token == null || token.isEmpty) {
        throw const ApiException(
          'Sesi login tidak ditemukan.',
        );
      }

      // ======================================================
      // REQUEST BODY
      // ======================================================

      String responseString = '';
      int statusCode = 200;

      if (attachedFile != null) {
        final request = http.MultipartRequest(
            'POST', Uri.parse(ApiConstants.chatGenerateFromFile));
        final token = StorageService.getToken() ?? '';
        request.headers['Authorization'] = 'Bearer $token';
        request.fields['providerId'] = provider.id.toString();
        request.fields['conversationId'] = conversationId.toString();
        if (cleanMessage.isNotEmpty) {
          request.fields['message'] = cleanMessage;
        }
        request.files.add(
            await http.MultipartFile.fromPath('files[]', attachedFile.path));

        final streamedResponse = await request.send();
        statusCode = streamedResponse.statusCode;
        responseString = await streamedResponse.stream.bytesToString();
      } else {
        final body = {
          'providerId': provider.id,
          'conversationId': conversationId,
          'message': finalContent,
          'messageToAi': messageToAi,
        };

        final response = await http
            .post(
              Uri.parse(ApiConstants.chats),
              headers: {
                'Content-Type': 'application/json',
                'Accept': 'application/json, text/event-stream',
                'Authorization': 'Bearer $token',
              },
              body: jsonEncode(body),
            )
            .timeout(const Duration(seconds: 120));

        statusCode = response.statusCode;
        responseString = utf8.decode(response.bodyBytes);
      }

      if (statusCode < 200 || statusCode >= 300) {
        _removeAssistantPlaceholder(placeholderIndex);
        try {
          final json = jsonDecode(responseString);
          _error = json['message'] ?? 'Gagal memproses pesan.';
        } catch (_) {
          _error = 'Error ';
        }
        notifyListeners();
        return;
      }

      final content = _parseAiResponse(responseString);

      final aiResponse = content.trim().isEmpty
          ? 'AI tidak memberikan respons.'
          : content.trim();

      if (placeholderIndex < _messages.length) {
        _messages[placeholderIndex] = ChatMessage(
          role: 'assistant',
          content: aiResponse,
          timestamp: DateTime.now(),
          conversationId: conversationId,
        );
      }

      // Backend melakukan deduction
      // sendiri. Kita hanya refresh state.
      await Future.wait([
        loadAiProviders(),
        loadConversations(),
      ]);

      notifyListeners();
    } on ApiException catch (e) {
      _removeAssistantPlaceholder(
        placeholderIndex,
      );

      _error = e.message;

      notifyListeners();
    } catch (e) {
      _removeAssistantPlaceholder(
        placeholderIndex,
      );

      _error = 'Gagal mengirim pesan. Coba lagi.';

      if (kDebugMode) {
        debugPrint(
          'Chat send error: $e',
        );
      }

      notifyListeners();
    } finally {
      _isStreaming = false;

      notifyListeners();
    }
  }

  // ==========================================================
  // MESSAGE HISTORY
  // ==========================================================

  List<Map<String, dynamic>> _buildMessageHistory() {
    final result = <Map<String, dynamic>>[];

    if (_systemPrompt != null && _systemPrompt!.isNotEmpty) {
      result.add({
        'role': 'system',
        'content': _systemPrompt!,
      });
    }

    final recent = _messages
        .where(
          (
            message,
          ) =>
              message.content.trim().isNotEmpty,
        )
        .toList();

    final start = recent.length > 10 ? recent.length - 10 : 0;

    for (int i = start; i < recent.length; i++) {
      final message = recent[i];

      result.add({
        'role': message.isUser ? 'user' : 'assistant',
        'content': message.content,
      });
    }

    return result;
  }

  // ==========================================================
  // REMOVE PLACEHOLDER
  // ==========================================================

  void _removeAssistantPlaceholder(
    int index,
  ) {
    if (index >= 0 && index < _messages.length && !_messages[index].isUser) {
      _messages.removeAt(
        index,
      );
    }
  }

  // ==========================================================
  // RESPONSE ERROR
  // ==========================================================

  String _extractResponseError(
    http.Response response,
  ) {
    final text = utf8.decode(
      response.bodyBytes,
    );

    try {
      final decoded = jsonDecode(text);

      if (decoded is Map) {
        final message = decoded['message'] ?? decoded['error'];

        if (message != null) {
          return message.toString();
        }

        final quotaRemaining = decoded['quota_remaining'];

        if (quotaRemaining != null) {
          return 'Kuota harian tersisa: $quotaRemaining.';
        }

        final errors = decoded['errors'];

        if (errors is Map && errors.isNotEmpty) {
          final first = errors.values.first;

          if (first is List && first.isNotEmpty) {
            return first.first.toString();
          }

          return first.toString();
        }
      }
    } catch (_) {
      // Not JSON.
    }

    if (response.statusCode == 402) {
      return 'Token kamu tidak cukup untuk menggunakan layanan ini.';
    }

    if (response.statusCode == 403) {
      return 'AI provider ini tidak tersedia untuk paket akun kamu.';
    }

    if (response.statusCode == 429) {
      return 'Batas penggunaan AI hari ini sudah tercapai.';
    }

    if (text.trim().isNotEmpty) {
      return text.trim();
    }

    return 'Gagal mengirim pesan.';
  }

  // ==========================================================
  // PARSE AI RESPONSE
  // Support normal JSON + SSE
  // ==========================================================

  String _parseAiResponse(
    String rawResponse,
  ) {
    final response = rawResponse.trim();

    if (response.isEmpty) {
      return '';
    }

    // ========================================================
    // NORMAL JSON
    // ========================================================

    try {
      final data = jsonDecode(response);

      final parsed = _extractTextFromJson(
        data,
      );

      if (parsed.isNotEmpty) {
        return parsed;
      }
    } catch (_) {}

    // ========================================================
    // SSE
    // ========================================================

    final buffer = StringBuffer();

    final lines = response.split(
      RegExp(
        r'\r?\n',
      ),
    );

    for (final rawLine in lines) {
      final line = rawLine.trim();

      if (!line.startsWith(
        'data:',
      )) {
        continue;
      }

      final payload = line.substring(5).trim();

      if (payload.isEmpty || payload == '[DONE]') {
        continue;
      }

      try {
        final data = jsonDecode(payload);

        final text = _extractTextFromJson(
          data,
        );

        if (text.isNotEmpty) {
          buffer.write(text);
        }
      } catch (_) {
        buffer.write(
          payload,
        );
      }
    }

    final parsedSse = buffer.toString();

    if (parsedSse.trim().isNotEmpty) {
      return parsedSse;
    }

    // ========================================================
    // RAW FALLBACK
    // ========================================================

    return response;
  }

  // ==========================================================
  // EXTRACT TEXT
  // ==========================================================

  String _extractTextFromJson(
    dynamic data,
  ) {
    if (data is String) {
      return data;
    }

    if (data is! Map) {
      return '';
    }

    final directKeys = [
      'message',
      'content',
      'response',
      'text',
      'answer',
      'output',
      'delta',
    ];

    for (final key in directKeys) {
      final value = data[key];

      if (value is String && value.trim().isNotEmpty) {
        return value;
      }
    }

    // OpenAI-like structure.
    final choices = data['choices'];

    if (choices is List && choices.isNotEmpty) {
      final first = choices.first;

      if (first is Map) {
        final message = first['message'];

        if (message is Map) {
          final content = message['content'];

          if (content is String) {
            return content;
          }
        }

        final delta = first['delta'];

        if (delta is Map) {
          final content = delta['content'];

          if (content is String) {
            return content;
          }
        }

        final text = first['text'];

        if (text is String) {
          return text;
        }
      }
    }

    return '';
  }

  // ==========================================================
  // DELETE CONVERSATION
  // DELETE /api/convers/{id}
  // ==========================================================

  Future<bool> deleteConversation(
    int id,
  ) async {
    try {
      await ApiService.instance.delete(
        '${ApiConstants.conversations}/$id',
      );

      _conversations.removeWhere(
        (
          conversation,
        ) =>
            conversation.id == id,
      );

      if (_currentConversationId == id) {
        _messages = [];

        _currentConversationId = null;
      }

      notifyListeners();

      return true;
    } on ApiException catch (e) {
      _error = e.message;

      notifyListeners();

      return false;
    } catch (_) {
      _error = 'Gagal menghapus percakapan.';

      notifyListeners();

      return false;
    }
  }

  // ==========================================================
  // RENAME CONVERSATION
  // PUT /api/convers/{id}
  // ==========================================================

  Future<bool> renameConversation(
    int id,
    String title,
  ) async {
    final cleanTitle = title.trim();

    if (cleanTitle.isEmpty) {
      return false;
    }

    try {
      await ApiService.instance.put(
        '${ApiConstants.conversations}/$id',
        {
          'title': cleanTitle.length > 50
              ? cleanTitle.substring(
                  0,
                  50,
                )
              : cleanTitle,
        },
      );

      await loadConversations();

      return true;
    } on ApiException catch (e) {
      _error = e.message;

      notifyListeners();

      return false;
    } catch (_) {
      _error = 'Gagal mengubah nama percakapan.';

      notifyListeners();

      return false;
    }
  }

  // ==========================================================
  // SELECT CONVERSATION
  // ==========================================================

  Future<void> selectConversation(
    int id,
  ) async {
    await loadMessages(
      id,
    );
  }

  // ==========================================================
  // CLEAR ERROR
  // ==========================================================

  void clearError() {
    _error = null;

    notifyListeners();
  }
}
