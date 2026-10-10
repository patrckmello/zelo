import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// API Zelo falsa em memória, com o mesmo formato JSON do backend FastAPI.
/// Permite exercitar o modo conectado do aplicativo sem rede.
class FakeZeloBackend {
  FakeZeloBackend({this.pointsConfigured = true});

  static const email = 'pessoa@example.com';
  static const password = 'senha-segura-123';

  bool pointsConfigured;

  String accountName = 'Pessoa de Teste';
  String accountEmail = email;
  String accountPassword = password;
  bool accountDeleted = false;

  /// Quando verdadeiro, o próximo uso do token de acesso devolve 401.
  bool expireAccessTokenOnce = false;
  bool failRefresh = false;

  /// Resposta da leitura da embalagem (`POST /v1/ocr/medication`).
  Map<String, dynamic> ocrResult = {
    'name_candidates': ['Dipirona Monoidratada', 'Dipirona'],
    'expiration_date': '2027-03-31',
    'expiration_text': 'VAL 03/2027',
    'expiration_has_day': false,
    'quantity': 20,
    'text': 'DIPIRONA MONOIDRATADA 500 mg 20 comprimidos VAL 03/2027',
  };

  /// Quantidade de fotos recebidas para leitura.
  var ocrUploads = 0;

  final requests = <http.Request>[];
  final medications = <Map<String, dynamic>>[];
  final disposals = <Map<String, dynamic>>[];
  final _validAccess = <String>{};
  final _validRefresh = <String>{};
  var _counter = 0;

  late final http.Client client = MockClient(_handle);

  Future<http.Response> _handle(http.Request request) async {
    requests.add(request);
    final path = request.url.path;
    final method = request.method;
    final multipart = (request.headers['content-type'] ?? '').startsWith(
      'multipart/form-data',
    );
    final body = multipart || request.body.isEmpty
        ? null
        : jsonDecode(request.body);

    if (path == '/v1/auth/login' && method == 'POST') {
      if (accountDeleted ||
          body['email'] != accountEmail ||
          body['password'] != accountPassword) {
        return _error(401, 'invalid_credentials', 'E-mail ou senha inválidos.');
      }
      return _json(200, _tokens());
    }
    if (path == '/v1/auth/register' && method == 'POST') {
      accountName = body['name'] as String;
      return _json(201, _tokens());
    }
    if (path == '/v1/auth/refresh' && method == 'POST') {
      final token = body['refresh_token'] as String;
      if (failRefresh || !_validRefresh.remove(token)) {
        return _error(401, 'invalid_refresh_token', 'Sessão expirada.');
      }
      return _json(200, _tokens());
    }
    if (path == '/v1/auth/logout' && method == 'POST') {
      _validRefresh.remove(body['refresh_token']);
      return http.Response('', 204);
    }
    if (path == '/v1/auth/password-reset/request') {
      return _json(202, {'message': 'ok'});
    }
    if (path == '/v1/auth/password-reset/confirm') {
      return body['token'] == 'codigo-valido-123'
          ? http.Response('', 204)
          : _error(400, 'invalid_reset_token', 'Código inválido ou expirado.');
    }

    final authorization = request.headers['Authorization'] ?? '';
    final token = authorization.replaceFirst('Bearer ', '');
    if (expireAccessTokenOnce && _validAccess.contains(token)) {
      expireAccessTokenOnce = false;
      _validAccess.remove(token);
    }
    if (!_validAccess.contains(token)) {
      return _error(401, 'not_authenticated', 'Sessão inválida.');
    }

    if (path == '/v1/ocr/medication' && method == 'POST') {
      final form = latin1.decode(request.bodyBytes);
      if (!multipart || !form.contains('name="image"')) {
        return _error(422, 'validation_error', 'Envie a foto da embalagem.');
      }
      ocrUploads++;
      return _json(200, ocrResult);
    }
    if (path.startsWith('/v1/account')) {
      return _account(path, method, body);
    }
    if (path == '/v1/medications' && method == 'GET') {
      final active =
          medications
              .where((item) => item['active'] == true)
              .map(_public)
              .toList()
            ..sort(
              (a, b) => (a['expiration_date'] as String).compareTo(
                b['expiration_date'] as String,
              ),
            );
      return _json(200, active);
    }
    if (path == '/v1/medications' && method == 'POST') {
      final item = {
        ...body as Map<String, dynamic>,
        'id': 'srv-${++_counter}',
        'active': true,
      };
      medications.add(item);
      return _json(201, _public(item));
    }
    if (path.startsWith('/v1/medications/')) {
      final id = path.split('/').last;
      final index = medications.indexWhere(
        (item) => item['id'] == id && item['active'] == true,
      );
      if (index == -1) {
        return _error(
          404,
          'medication_not_found',
          'Medicamento não encontrado.',
        );
      }
      if (method == 'DELETE') {
        medications.removeAt(index);
        return http.Response('', 204);
      }
      medications[index] = {
        ...medications[index],
        ...body as Map<String, dynamic>,
      };
      return _json(200, _public(medications[index]));
    }
    if (path == '/v1/disposals' && method == 'GET') {
      return _json(200, disposals);
    }
    if (path == '/v1/disposals' && method == 'POST') {
      final ids = (body['medication_ids'] as List).cast<String>();
      final items = <Map<String, dynamic>>[];
      for (final id in ids) {
        final medication = medications.firstWhere((item) => item['id'] == id);
        medication['active'] = false;
        items.add({
          'medication_name': medication['name'],
          'quantity': medication['quantity'],
          'expiration_date': medication['expiration_date'],
        });
      }
      final point = body['point'] as Map<String, dynamic>?;
      final record = {
        'id': 'descarte-${++_counter}',
        'disposed_on': body['disposed_on'],
        'point_external_id': point?['external_id'],
        'point_name': point?['name'],
        'point_address': point?['address'],
        'notes': body['notes'] ?? '',
        'items': items,
      };
      disposals.insert(0, record);
      return _json(201, record);
    }
    if (path == '/v1/collection-points/nearby') {
      if (!pointsConfigured) {
        return _error(
          503,
          'collection_points_not_configured',
          'A consulta de pontos ainda não foi configurada no servidor.',
        );
      }
      return _json(200, {
        'points': [
          {
            'id': 'logmed-001234',
            'name': 'Farmácia Exemplo - Centro',
            'address': 'Rua das Flores, 100',
            'city': 'São Paulo',
            'state': 'SP',
            'latitude': -23.5489,
            'longitude': -46.6388,
            'phone': '(11) 3333-4444',
            'residue_types': ['medicamento'],
            'distance_m': 412,
            'origin': 'logmed',
            'requires_confirmation': false,
          },
        ],
        'count': 1,
        'radius_m': int.parse(
          request.url.queryParameters['radius_m'] ?? '5000',
        ),
        'attribution': 'Dados: EcoMed — fontes CNES/DATASUS (Ministério da Saúde) e LogMed/Sindusfarma.',
        'cache': 'miss',
      });
    }
    return _error(404, 'not_found', 'Recurso não encontrado.');
  }

  http.Response _account(String path, String method, dynamic body) {
    bool passwordOk() => body['current_password'] == accountPassword;
    Map<String, dynamic> profile() => {
      'id': 'user-1',
      'name': accountName,
      'email': accountEmail,
      'created_at': '2026-10-02T12:00:00Z',
      'medications_count': medications
          .where((item) => item['active'] == true)
          .length,
      'disposals_count': disposals.length,
    };
    if (path == '/v1/account' && method == 'GET') {
      return _json(200, profile());
    }
    if (path == '/v1/account' && method == 'PATCH') {
      accountName = (body['name'] as String).trim();
      return _json(200, profile());
    }
    if (!passwordOk()) {
      return _error(401, 'invalid_password', 'Senha atual incorreta.');
    }
    if (path == '/v1/account/email') {
      accountEmail = body['new_email'] as String;
      return _json(200, profile());
    }
    if (path == '/v1/account/password') {
      accountPassword = body['new_password'] as String;
      _validRefresh.clear();
      return _json(200, _tokens(name: accountName));
    }
    if (path == '/v1/account/delete') {
      accountDeleted = true;
      _validAccess.clear();
      _validRefresh.clear();
      return http.Response('', 204);
    }
    return _error(404, 'not_found', 'Recurso não encontrado.');
  }

  Map<String, dynamic> _tokens({String? name}) {
    final access = 'access-${++_counter}';
    final refresh = 'refresh-${++_counter}';
    _validAccess.add(access);
    _validRefresh.add(refresh);
    return {
      'access_token': access,
      'refresh_token': refresh,
      'token_type': 'bearer',
      'expires_in': 900,
      'user': {
        'id': 'user-1',
        'name': name ?? accountName,
        'email': accountEmail,
      },
    };
  }

  static Map<String, dynamic> _public(Map<String, dynamic> item) => {
    'id': item['id'],
    'name': item['name'],
    'expiration_date': item['expiration_date'],
    'quantity': item['quantity'],
    'notes': item['notes'] ?? '',
  };

  static http.Response _json(int status, Object body) => http.Response(
    jsonEncode(body),
    status,
    headers: {'content-type': 'application/json; charset=utf-8'},
  );

  static http.Response _error(int status, String code, String message) =>
      _json(status, {
        'error': {'code': code, 'message': message},
      });
}
