import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/constants/app_constants.dart';

class ApiService {
  ApiService({String? token}) : _token = token;

  String? _token;

  set token(String? value) => _token = value;

  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, String>? queryParameters,
  }) async {
    final uri = _buildUri(path, queryParameters);
    final response = await http
        .get(uri, headers: _headers())
        .timeout(const Duration(seconds: 20));

    return _parseResponse(response);
  }

  Future<Map<String, dynamic>> post(
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final uri = _buildUri(path);
    final response = await http
        .post(
          uri,
          headers: _headers(),
          body: jsonEncode(body ?? <String, dynamic>{}),
        )
        .timeout(const Duration(seconds: 20));

    return _parseResponse(response);
  }

  Uri _buildUri(String path, [Map<String, String>? queryParameters]) {
    final normalizedPath = path.startsWith('/') ? path.substring(1) : path;
    final base = '${AppConstants.apiBaseUrl}/$normalizedPath';
    return Uri.parse(base).replace(queryParameters: queryParameters);
  }

  Map<String, String> _headers() {
    final headers = <String, String>{
      'Content-Type' => 'application/json',
      'Accept' => 'application/json',
    };

    if (_token != null && _token!.isNotEmpty) {
      headers['Authorization'] = 'Bearer $_token';
    }

    return headers;
  }

  Map<String, dynamic> _parseResponse(http.Response response) {
    final body = response.body.isEmpty
        ? <String, dynamic>{}
        : jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode >= 400) {
      throw ApiException(
        message: (body['message'] ?? 'Request failed.') as String,
        statusCode: response.statusCode,
        errors: (body['errors'] as Map?)?.cast<String, dynamic>() ?? const {},
      );
    }

    return body;
  }
}

class ApiException implements Exception {
  const ApiException({
    required this.message,
    required this.statusCode,
    this.errors = const {},
  });

  final String message;
  final int statusCode;
  final Map<String, dynamic> errors;

  @override
  String toString() => message;
}
