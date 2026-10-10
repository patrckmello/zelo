import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../storage/token_store.dart';

/// Falha da API com código estável e mensagem segura para exibição.
class ApiException implements Exception {
  const ApiException({
    required this.statusCode,
    required this.code,
    required this.message,
    this.retryAfter,
  });

  const ApiException.network()
    : statusCode = 0,
      code = 'network_error',
      message =
          'Sem conexão com o servidor do Zelo. Verifique a internet e tente '
          'novamente.',
      retryAfter = null;

  final int statusCode;
  final String code;
  final String message;
  final Duration? retryAfter;

  bool get isNetwork => statusCode == 0;

  @override
  String toString() => 'ApiException($statusCode, $code)';
}

/// Sessão autenticada devolvida pela API.
class ApiSession {
  const ApiSession({required this.accessToken, required this.user});

  final String accessToken;
  final Map<String, dynamic> user;
}

/// Cliente HTTP da API Zelo.
///
/// Mantém o token de acesso em memória, persiste somente o de renovação e,
/// diante de um 401, renova a sessão uma única vez antes de repetir a
/// chamada. Se a renovação falhar, a sessão local é descartada e
/// [sessionExpirations] é notificado.
class ZeloApiClient {
  ZeloApiClient({
    required this.baseUrl,
    required this._tokenStore,
    http.Client? httpClient,
    this.timeout = const Duration(seconds: 15),
  }) : _http = httpClient ?? http.Client();

  final Uri baseUrl;
  final Duration timeout;
  final TokenStore _tokenStore;
  final http.Client _http;
  final _expirations = StreamController<void>.broadcast();

  String? _accessToken;
  Future<ApiSession?>? _refreshInFlight;

  Stream<void> get sessionExpirations => _expirations.stream;

  bool get hasSession => _accessToken != null;

  /// Usa o token de renovação guardado para abrir uma sessão nova.
  Future<ApiSession?> restoreSession() async {
    final refreshToken = await _tokenStore.readRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) {
      return null;
    }
    return _refresh(refreshToken);
  }

  Future<ApiSession> openSession(String path, Map<String, dynamic> body) async {
    final json = await send('POST', path, body: body, authenticated: false);
    return _storeSession(json as Map<String, dynamic>);
  }

  /// Passa a usar os tokens devolvidos pela API (ex.: após trocar a senha).
  Future<ApiSession> adoptSession(Map<String, dynamic> json) =>
      _storeSession(json);

  /// Descarta a sessão só neste aparelho, sem chamar a API.
  Future<void> discardSession() async {
    _accessToken = null;
    await _tokenStore.clear();
  }

  Future<void> closeSession() async {
    final refreshToken = await _tokenStore.readRefreshToken();
    _accessToken = null;
    await _tokenStore.clear();
    if (refreshToken != null) {
      try {
        await send(
          'POST',
          '/v1/auth/logout',
          body: {'refresh_token': refreshToken},
          authenticated: false,
        );
      } on ApiException {
        // O token já foi descartado localmente; a revogação remota é melhor
        // esforço e expira sozinha no servidor.
      }
    }
  }

  Future<dynamic> send(
    String method,
    String path, {
    Map<String, String>? query,
    Object? body,
    bool authenticated = true,
  }) async {
    var response = await _perform(method, path, query, body, authenticated);
    if (response.statusCode == 401 && authenticated) {
      final renewed = await _renewAfterUnauthorized();
      if (renewed) {
        response = await _perform(method, path, query, body, authenticated);
      }
    }
    return _decode(response);
  }

  /// Envia um arquivo (multipart) autenticado, com a mesma renovação de
  /// sessão das demais chamadas.
  Future<dynamic> upload(
    String path, {
    required String field,
    required List<int> bytes,
    required String filename,
    required String contentType,
  }) async {
    Future<http.Response> perform() async {
      final request = http.MultipartRequest('POST', _uri(path, null))
        ..headers['Accept'] = 'application/json'
        ..files.add(
          http.MultipartFile.fromBytes(
            field,
            bytes,
            filename: filename,
            contentType: MediaType.parse(contentType),
          ),
        );
      final token = _accessToken;
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }
      return _execute(request, const Duration(seconds: 45));
    }

    var response = await perform();
    if (response.statusCode == 401 && await _renewAfterUnauthorized()) {
      response = await perform();
    }
    return _decode(response);
  }

  void dispose() {
    _expirations.close();
    _http.close();
  }

  Future<http.Response> _perform(
    String method,
    String path,
    Map<String, String>? query,
    Object? body,
    bool authenticated,
  ) async {
    final request = http.Request(method, _uri(path, query))
      ..headers['Accept'] = 'application/json';
    if (body != null) {
      request.headers['Content-Type'] = 'application/json';
      request.body = jsonEncode(body);
    }
    final token = _accessToken;
    if (authenticated && token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }
    return _execute(request, timeout);
  }

  Uri _uri(String path, Map<String, String>? query) => baseUrl.replace(
    path: '${baseUrl.path.replaceAll(RegExp(r'/$'), '')}$path',
    queryParameters: query,
  );

  Future<http.Response> _execute(
    http.BaseRequest request,
    Duration limit,
  ) async {
    try {
      final streamed = await _http.send(request).timeout(limit);
      return await http.Response.fromStream(streamed).timeout(limit);
    } on TimeoutException {
      throw const ApiException.network();
    } on http.ClientException {
      throw const ApiException.network();
    }
  }

  dynamic _decode(http.Response response) {
    final text = utf8.decode(response.bodyBytes);
    final json = text.isEmpty ? null : _tryJson(text);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return json;
    }
    final error = json is Map<String, dynamic> ? json['error'] : null;
    final retryAfter = int.tryParse(response.headers['retry-after'] ?? '');
    throw ApiException(
      statusCode: response.statusCode,
      code: error is Map<String, dynamic>
          ? (error['code'] as String? ?? 'http_error')
          : 'http_error',
      message: error is Map<String, dynamic> && error['message'] is String
          ? error['message'] as String
          : 'Não foi possível concluir a solicitação. Tente novamente.',
      retryAfter: retryAfter == null ? null : Duration(seconds: retryAfter),
    );
  }

  Object? _tryJson(String text) {
    try {
      return jsonDecode(text);
    } on FormatException {
      return null;
    }
  }

  Future<ApiSession> _storeSession(Map<String, dynamic> json) async {
    _accessToken = json['access_token'] as String;
    await _tokenStore.writeRefreshToken(json['refresh_token'] as String);
    return ApiSession(
      accessToken: _accessToken!,
      user: Map<String, dynamic>.from(json['user'] as Map),
    );
  }

  Future<ApiSession?> _refresh(String refreshToken) {
    // Chamadas simultâneas compartilham a mesma renovação.
    return _refreshInFlight ??= () async {
      try {
        final json = await send(
          'POST',
          '/v1/auth/refresh',
          body: {'refresh_token': refreshToken},
          authenticated: false,
        );
        return await _storeSession(json as Map<String, dynamic>);
      } on ApiException catch (error) {
        if (error.statusCode == 401) {
          _accessToken = null;
          await _tokenStore.clear();
          return null;
        }
        rethrow;
      } finally {
        _refreshInFlight = null;
      }
    }();
  }

  Future<bool> _renewAfterUnauthorized() async {
    final refreshToken = await _tokenStore.readRefreshToken();
    final session = refreshToken == null ? null : await _refresh(refreshToken);
    if (session == null) {
      _accessToken = null;
      if (!_expirations.isClosed) {
        _expirations.add(null);
      }
      return false;
    }
    return true;
  }
}
