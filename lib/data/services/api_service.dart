// ============================================================
// API SERVICE — HTTP Client dengan Sanctum Token Auth
// ============================================================

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../services/storage_service.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  ApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

class ApiService {
  ApiService._();
  static final ApiService instance = ApiService._();

  // ── Headers ───────────────────────────────────────────────
  Map<String, String> get _headers {
    final token = StorageService.getToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Map<String, String> get _publicHeaders => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  // ── GET ───────────────────────────────────────────────────
  Future<dynamic> get(String url, {Map<String, String>? params}) async {
    try {
      final uri = Uri.parse(url).replace(queryParameters: params);
      final response = await http
          .get(uri, headers: _headers)
          .timeout(const Duration(seconds: 30));
      return _handleResponse(response);
    } on SocketException {
      throw ApiException('Tidak ada koneksi internet. Cek WiFi atau data kamu.');
    } on HttpException {
      throw ApiException('Terjadi kesalahan jaringan.');
    }
  }

  // ── POST ──────────────────────────────────────────────────
  Future<dynamic> post(String url, Map<String, dynamic> body,
      {bool useAuth = true}) async {
    try {
      final response = await http
          .post(
            Uri.parse(url),
            headers: useAuth ? _headers : _publicHeaders,
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 30));
      return _handleResponse(response);
    } on SocketException {
      throw ApiException('Tidak ada koneksi internet. Cek WiFi atau data kamu.');
    }
  }

  // ── PUT ───────────────────────────────────────────────────
  Future<dynamic> put(String url, Map<String, dynamic> body) async {
    try {
      final response = await http
          .put(Uri.parse(url), headers: _headers, body: jsonEncode(body))
          .timeout(const Duration(seconds: 30));
      return _handleResponse(response);
    } on SocketException {
      throw ApiException('Tidak ada koneksi internet.');
    }
  }

  // ── DELETE ────────────────────────────────────────────────
  Future<dynamic> delete(String url) async {
    try {
      final response = await http
          .delete(Uri.parse(url), headers: _headers)
          .timeout(const Duration(seconds: 30));
      return _handleResponse(response);
    } on SocketException {
      throw ApiException('Tidak ada koneksi internet.');
    }
  }

  // ── POST Multipart (File Upload) ──────────────────────────
  Future<dynamic> postMultipart(
    String url, {
    Map<String, String>? fields,
    Map<String, File>? files,
  }) async {
    try {
      final request = http.MultipartRequest('POST', Uri.parse(url));
      request.headers.addAll(_headers);

      if (fields != null) request.fields.addAll(fields);
      if (files != null) {
        for (final entry in files.entries) {
          request.files.add(await http.MultipartFile.fromPath(
            entry.key,
            entry.value.path,
          ));
        }
      }

      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 60),
      );
      final response = await http.Response.fromStream(streamedResponse);
      return _handleResponse(response);
    } on SocketException {
      throw ApiException('Tidak ada koneksi internet.');
    }
  }

  // ── Handle Response ───────────────────────────────────────
  dynamic _handleResponse(http.Response response) {
    final body = utf8.decode(response.bodyBytes);

    dynamic data;
    try {
      data = jsonDecode(body);
    } catch (_) {
      data = body;
    }

    switch (response.statusCode) {
      case 200:
      case 201:
        return data;
      case 401:
        StorageService.clearAll();
        throw ApiException('Sesi habis. Silakan login kembali.', statusCode: 401);
      case 403:
        throw ApiException('Akses ditolak.', statusCode: 403);
      case 404:
        throw ApiException('Data tidak ditemukan.', statusCode: 404);
      case 422:
        final errors = data['errors'];
        if (errors is Map) {
          final firstError = errors.values.first;
          final msg = firstError is List ? firstError.first : firstError.toString();
          throw ApiException(msg, statusCode: 422);
        }
        throw ApiException(data['message'] ?? 'Validasi gagal.', statusCode: 422);
      case 429:
        throw ApiException('Terlalu banyak permintaan. Coba lagi sebentar.', statusCode: 429);
      case 500:
      default:
        throw ApiException(
          data is Map ? (data['message'] ?? 'Server error') : 'Terjadi kesalahan.',
          statusCode: response.statusCode,
        );
    }
  }
}
