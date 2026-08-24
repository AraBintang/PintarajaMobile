// ============================================================
// API SERVICE — PintarAja
// HTTP Client + Sanctum Authentication
// JSON + Multipart + Error Handling
// ============================================================

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'storage_service.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  const ApiException(
    this.message, {
    this.statusCode,
  });

  @override
  String toString() {
    if (statusCode != null) {
      return '$message (HTTP $statusCode)';
    }

    return message;
  }
}

class ApiService {
  ApiService._();

  static final ApiService instance = ApiService._();

  /// Called whenever an authenticated request receives HTTP 401.
  ///
  /// Wired in main.dart to [AuthProvider.handleUnauthorized] so the
  /// router's refreshListenable fires and the user is redirected to
  /// the login screen instead of staying stuck with a dead token.
  static void Function()? onUnauthorized;

  // ==========================================================
  // HEADERS
  // ==========================================================

  Map<String, String> _headers({
    bool authenticated = true,
  }) {
    final headers = <String, String>{
      'Accept': 'application/json',
    };

    if (authenticated) {
      final token = StorageService.getToken();

      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    return headers;
  }

  Map<String, String> _jsonHeaders({
    bool authenticated = true,
  }) {
    return {
      ..._headers(
        authenticated: authenticated,
      ),
      'Content-Type': 'application/json',
    };
  }

  // ==========================================================
  // GET
  // ==========================================================

  Future<dynamic> get(
    String url, {
    Map<String, String>? params,
    bool useAuth = true,
  }) async {
    try {
      Uri uri = Uri.parse(url);

      if (params != null && params.isNotEmpty) {
        uri = uri.replace(
          queryParameters: params,
        );
      }

      final response = await http
          .get(
            uri,
            headers: _headers(
              authenticated: useAuth,
            ),
          )
          .timeout(
            const Duration(
              seconds: 30,
            ),
          );

      return _handleResponse(
        response,
      );
    } on SocketException {
      throw const ApiException(
        'Tidak ada koneksi internet. Cek WiFi atau data kamu.',
      );
    } on TimeoutException {
      throw const ApiException(
        'Request terlalu lama. Coba lagi.',
      );
    } on HttpException {
      throw const ApiException(
        'Terjadi kesalahan jaringan.',
      );
    }
  }

  // ==========================================================
  // POST
  // ==========================================================

  Future<dynamic> post(
    String url,
    Map<String, dynamic> body, {
    bool useAuth = true,
    Duration timeout = const Duration(
      seconds: 60,
    ),
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse(url),
            headers: _jsonHeaders(
              authenticated: useAuth,
            ),
            body: jsonEncode(body),
          )
          .timeout(
            timeout,
          );

      return _handleResponse(
        response,
      );
    } on SocketException {
      throw const ApiException(
        'Tidak ada koneksi internet. Cek WiFi atau data kamu.',
      );
    } on TimeoutException {
      throw const ApiException(
        'Request terlalu lama. Coba lagi.',
      );
    } on HttpException {
      throw const ApiException(
        'Terjadi kesalahan jaringan.',
      );
    }
  }

  // ==========================================================
  // PUT
  // ==========================================================

  Future<dynamic> put(
    String url,
    Map<String, dynamic> body, {
    Duration timeout = const Duration(
      seconds: 60,
    ),
  }) async {
    try {
      final response = await http
          .put(
            Uri.parse(url),
            headers: _jsonHeaders(),
            body: jsonEncode(body),
          )
          .timeout(
            timeout,
          );

      return _handleResponse(
        response,
      );
    } on SocketException {
      throw const ApiException(
        'Tidak ada koneksi internet.',
      );
    } on TimeoutException {
      throw const ApiException(
        'Request terlalu lama. Coba lagi.',
      );
    } on HttpException {
      throw const ApiException(
        'Terjadi kesalahan jaringan.',
      );
    }
  }

  // ==========================================================
  // DELETE
  // ==========================================================

  Future<dynamic> delete(
    String url,
  ) async {
    try {
      final response = await http
          .delete(
            Uri.parse(url),
            headers: _headers(),
          )
          .timeout(
            const Duration(
              seconds: 30,
            ),
          );

      return _handleResponse(
        response,
      );
    } on SocketException {
      throw const ApiException(
        'Tidak ada koneksi internet.',
      );
    } on TimeoutException {
      throw const ApiException(
        'Request terlalu lama.',
      );
    } on HttpException {
      throw const ApiException(
        'Terjadi kesalahan jaringan.',
      );
    }
  }

  // ==========================================================
  // DELETE WITH BODY
  // ==========================================================

  Future<dynamic> deleteWithBody(
    String url,
    Map<String, dynamic> body,
  ) async {
    try {
      final request = http.Request(
        'DELETE',
        Uri.parse(url),
      );

      request.headers.addAll(
        _jsonHeaders(),
      );

      request.body = jsonEncode(body);

      final streamedResponse = await request.send().timeout(
            const Duration(
              seconds: 30,
            ),
          );

      final response = await http.Response.fromStream(
        streamedResponse,
      );

      return _handleResponse(
        response,
      );
    } on SocketException {
      throw const ApiException(
        'Tidak ada koneksi internet.',
      );
    } on TimeoutException {
      throw const ApiException(
        'Request terlalu lama.',
      );
    } on HttpException {
      throw const ApiException(
        'Terjadi kesalahan jaringan.',
      );
    }
  }

  // ==========================================================
  // MULTIPART UPLOAD
  // ==========================================================

  Future<dynamic> postMultipart(
    String url, {
    Map<String, String>? fields,
    Map<String, File>? files,
    Duration timeout = const Duration(
      seconds: 120,
    ),
  }) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse(url),
      );

      // Jangan memasukkan
      // Content-Type: application/json
      // di sini.
      //
      // MultipartRequest akan membuat
      // boundary multipart/form-data
      // sendiri.

      request.headers.addAll(
        _headers(),
      );

      if (fields != null && fields.isNotEmpty) {
        request.fields.addAll(
          fields,
        );
      }

      if (files != null && files.isNotEmpty) {
        for (final entry in files.entries) {
          final file = entry.value;

          if (!await file.exists()) {
            throw ApiException(
              'File tidak ditemukan: ${file.path}',
            );
          }

          request.files.add(
            await http.MultipartFile.fromPath(
              entry.key,
              file.path,
            ),
          );
        }
      }

      final streamedResponse = await request.send().timeout(
            timeout,
          );

      final response = await http.Response.fromStream(
        streamedResponse,
      );

      return _handleResponse(
        response,
      );
    } on SocketException {
      throw const ApiException(
        'Tidak ada koneksi internet.',
      );
    } on TimeoutException {
      throw const ApiException(
        'Upload terlalu lama. Coba lagi.',
      );
    } on HttpException {
      throw const ApiException(
        'Terjadi kesalahan jaringan.',
      );
    }
  }

  // ==========================================================
  // RESPONSE
  // ==========================================================

  dynamic _handleResponse(
    http.Response response,
  ) {
    final body = utf8.decode(
      response.bodyBytes,
    );

    dynamic data;

    if (body.trim().isEmpty) {
      data = null;
    } else {
      try {
        data = jsonDecode(body);
      } catch (_) {
        data = body;
      }
    }

    // ========================================================
    // SUCCESS
    // ========================================================

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return data;
    }

    // ========================================================
    // ERROR MESSAGE
    // ========================================================

    final message = _extractErrorMessage(
      data,
      response.statusCode,
    );

    // ========================================================
    // AUTH EXPIRED
    // ========================================================

    if (response.statusCode == 401) {
      // Hanya hapus data authentication.
      //
      // Jangan menggunakan clearAll()
      // karena SharedPreferences bisa
      // berisi setting aplikasi lain.

      unawaited(
        StorageService.clearAuth(),
      );

      onUnauthorized?.call();

      throw ApiException(
        message,
        statusCode: response.statusCode,
      );
    }

    // ========================================================
    // FORBIDDEN
    // ========================================================

    if (response.statusCode == 403) {
      throw ApiException(
        message,
        statusCode: response.statusCode,
      );
    }

    // ========================================================
    // NOT FOUND
    // ========================================================

    if (response.statusCode == 404) {
      throw ApiException(
        message,
        statusCode: response.statusCode,
      );
    }

    // ========================================================
    // VALIDATION
    // ========================================================

    if (response.statusCode == 422) {
      throw ApiException(
        message,
        statusCode: response.statusCode,
      );
    }

    // ========================================================
    // RATE LIMIT
    // ========================================================

    if (response.statusCode == 429) {
      throw ApiException(
        message,
        statusCode: response.statusCode,
      );
    }

    // ========================================================
    // OTHER
    // ========================================================

    throw ApiException(
      message,
      statusCode: response.statusCode,
    );
  }

  // ==========================================================
  // ERROR EXTRACTION
  // ==========================================================

  String _extractErrorMessage(
    dynamic data,
    int statusCode,
  ) {
    if (data is String && data.trim().isNotEmpty) {
      return data.trim();
    }

    if (data is Map) {
      // Laravel:
      // {"message":"..."}

      final message = data['message'];

      if (message != null && message.toString().trim().isNotEmpty) {
        return message.toString().trim();
      }

      // Custom:
      // {"error":"..."}

      final error = data['error'];

      if (error != null && error.toString().trim().isNotEmpty) {
        return error.toString().trim();
      }

      // Validation:
      // {"errors":{"email":["..."]}}

      final errors = data['errors'];

      if (errors is Map && errors.isNotEmpty) {
        final first = errors.values.first;

        if (first is List && first.isNotEmpty) {
          return first.first.toString();
        }

        return first.toString();
      }

      // Some endpoints may return:
      // {"detail":"..."}

      final detail = data['detail'];

      if (detail != null && detail.toString().trim().isNotEmpty) {
        return detail.toString().trim();
      }
    }

    switch (statusCode) {
      case 400:
        return 'Request tidak valid.';

      case 401:
        return 'Sesi login sudah berakhir. Silakan login kembali.';

      case 403:
        return 'Kamu tidak memiliki akses ke fitur ini.';

      case 404:
        return 'Data atau endpoint tidak ditemukan.';

      case 422:
        return 'Data yang dikirim tidak valid.';

      case 429:
        return 'Terlalu banyak permintaan. Coba lagi sebentar.';

      case 500:
        return 'Terjadi kesalahan pada server PintarAja.';

      case 502:
      case 503:
      case 504:
        return 'Server PintarAja sedang tidak tersedia.';

      default:
        return 'Terjadi kesalahan pada server.';
    }
  }
}
