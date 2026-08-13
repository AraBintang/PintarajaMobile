// ============================================================
// API SERVICE — PintarAja
// HTTP Client + Sanctum Token Authentication
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

  static final ApiService instance =
      ApiService._();

  // ==========================================================
  // AUTHENTICATED HEADERS
  // ==========================================================

  Map<String, String> get _headers {
    final token =
        StorageService.getToken();

    return {
      'Content-Type':
          'application/json',
      'Accept':
          'application/json',

      if (token != null &&
          token.isNotEmpty)
        'Authorization':
            'Bearer $token',
    };
  }

  // ==========================================================
  // PUBLIC HEADERS
  // ==========================================================

  Map<String, String>
      get _publicHeaders {
    return {
      'Content-Type':
          'application/json',
      'Accept':
          'application/json',
    };
  }

  // ==========================================================
  // GET
  // ==========================================================

  Future<dynamic> get(
    String url, {
    Map<String, String>? params,
  }) async {
    try {
      final uri =
          Uri.parse(url).replace(
        queryParameters:
            params,
      );

      final response =
          await http
              .get(
                uri,
                headers:
                    _headers,
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
        'Tidak ada koneksi internet. '
        'Cek WiFi atau data kamu.',
      );
    } on TimeoutException {
      throw const ApiException(
        'Request terlalu lama. '
        'Coba lagi.',
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
  }) async {
    try {
      final response =
          await http
              .post(
                Uri.parse(url),
                headers: useAuth
                    ? _headers
                    : _publicHeaders,
                body:
                    jsonEncode(body),
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
        'Request terlalu lama. '
        'Coba lagi.',
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
    Map<String, dynamic> body,
  ) async {
    try {
      final response =
          await http
              .put(
                Uri.parse(url),
                headers:
                    _headers,
                body:
                    jsonEncode(body),
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
    }
  }

  // ==========================================================
  // DELETE
  // ==========================================================

  Future<dynamic> delete(
    String url,
  ) async {
    try {
      final response =
          await http
              .delete(
                Uri.parse(url),
                headers:
                    _headers,
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
    }
  }

  // ==========================================================
  // POST MULTIPART
  // ==========================================================

  Future<dynamic> postMultipart(
    String url, {
    Map<String, String>? fields,
    Map<String, File>? files,
  }) async {
    try {
      final request =
          http.MultipartRequest(
        'POST',
        Uri.parse(url),
      );

      request.headers.addAll(
        _headers,
      );

      if (fields != null) {
        request.fields.addAll(
          fields,
        );
      }

      if (files != null) {
        for (final entry
            in files.entries) {
          request.files.add(
            await http
                .MultipartFile
                .fromPath(
              entry.key,
              entry.value.path,
            ),
          );
        }
      }

      final streamedResponse =
          await request
              .send()
              .timeout(
                const Duration(
                  seconds: 60,
                ),
              );

      final response =
          await http.Response
              .fromStream(
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
        'Upload terlalu lama. '
        'Coba lagi.',
      );
    }
  }

  // ==========================================================
  // RESPONSE HANDLER
  // ==========================================================

  dynamic _handleResponse(
    http.Response response,
  ) {
    final body =
        utf8.decode(
      response.bodyBytes,
    );

    dynamic data;

    try {
      data =
          jsonDecode(body);
    } catch (_) {
      data = body;
    }

    // ========================================================
    // SUCCESS
    // ========================================================

    if (response.statusCode >= 200 &&
        response.statusCode < 300) {
      return data;
    }

    // ========================================================
    // EXTRACT SERVER MESSAGE
    // ========================================================

    String message =
        _extractErrorMessage(
      data,
    );

    // ========================================================
    // 401
    // ========================================================

    if (response.statusCode ==
        401) {
      StorageService.clearAll();

      throw ApiException(
        message ==
                'Terjadi kesalahan.'
            ? 'Sesi habis. '
                'Silakan login kembali.'
            : message,
        statusCode:
            response.statusCode,
      );
    }

    // ========================================================
    // 403
    // ========================================================

    if (response.statusCode ==
        403) {
      throw ApiException(
        message ==
                'Terjadi kesalahan.'
            ? 'Akses ditolak.'
            : message,
        statusCode:
            response.statusCode,
      );
    }

    // ========================================================
    // 404
    // ========================================================

    if (response.statusCode ==
        404) {
      throw ApiException(
        message ==
                'Terjadi kesalahan.'
            ? 'Endpoint atau data '
                'tidak ditemukan.'
            : message,
        statusCode:
            response.statusCode,
      );
    }

    // ========================================================
    // 422 VALIDATION
    // ========================================================

    if (response.statusCode ==
        422) {
      throw ApiException(
        message,
        statusCode:
            response.statusCode,
      );
    }

    // ========================================================
    // 429
    // ========================================================

    if (response.statusCode ==
        429) {
      throw ApiException(
        message ==
                'Terjadi kesalahan.'
            ? 'Terlalu banyak permintaan. '
                'Coba lagi sebentar.'
            : message,
        statusCode:
            response.statusCode,
      );
    }

    // ========================================================
    // 500 / OTHER
    // ========================================================

    throw ApiException(
      message,
      statusCode:
          response.statusCode,
    );
  }

  // ==========================================================
  // EXTRACT MESSAGE
  // ==========================================================

  String _extractErrorMessage(
    dynamic data,
  ) {
    if (data is String &&
        data.trim().isNotEmpty) {
      return data.trim();
    }

    if (data is Map) {
      // Laravel biasanya:
      // { "message": "..." }

      final message =
          data['message'];

      if (message != null &&
          message
              .toString()
              .trim()
              .isNotEmpty) {
        return message
            .toString()
            .trim();
      }

      // Backend PintarAja login:
      // { "error": "..." }

      final error =
          data['error'];

      if (error != null &&
          error
              .toString()
              .trim()
              .isNotEmpty) {
        return error
            .toString()
            .trim();
      }

      // Laravel validation:
      // { "errors": {...} }

      final errors =
          data['errors'];

      if (errors is Map &&
          errors.isNotEmpty) {
        final firstValue =
            errors.values.first;

        if (firstValue is List &&
            firstValue.isNotEmpty) {
          return firstValue.first
              .toString();
        }

        return firstValue
            .toString();
      }
    }

    return 'Terjadi kesalahan.';
  }
}