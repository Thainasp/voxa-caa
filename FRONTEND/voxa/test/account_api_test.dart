import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:voxa/core/data/remote/account_api.dart';

void main() {
  test('cria o registro público do usuário após autenticar', () async {
    final requests = <http.Request>[];
    final api = AccountApi(
      SupabaseClient(
        'https://test.supabase.co',
        'test-anon-key',
        accessToken: () async => 'user-session-token',
        httpClient: MockClient((request) async {
          requests.add(request);
          if (request.method == 'GET') {
            return http.Response(
              '[]',
              200,
              headers: {'content-type': 'application/json'},
              request: request,
            );
          }
          return http.Response(
            request.body,
            201,
            headers: {'content-type': 'application/json'},
            request: request,
          );
        }),
      ),
    );

    await api.ensureUserRecord(
      id: 'auth-user-id',
      name: 'Ana',
      email: 'ana@example.com',
      phone: '(11) 99999-9999',
      birthDate: '1990-01-01',
    );

    expect(requests, hasLength(2));
    expect(requests.first.method, 'GET');
    expect(requests.last.method, 'POST');
    expect(requests.last.headers['Authorization'], 'Bearer user-session-token');
    expect(jsonDecode(requests.last.body), {
      'id': 'auth-user-id',
      'nome': 'Ana',
      'email': 'ana@example.com',
      'telefone': '(11) 99999-9999',
      'data_nascimento': '1990-01-01',
      'avatar_url': null,
      'is_responsavel': true,
    });
  });

  test('não sobrescreve perfil público já existente', () async {
    final requests = <http.Request>[];
    final api = AccountApi(
      SupabaseClient(
        'https://test.supabase.co',
        'test-anon-key',
        accessToken: () async => 'user-session-token',
        httpClient: MockClient((request) async {
          requests.add(request);
          return http.Response(
            '[{"id":"auth-user-id"}]',
            200,
            headers: {'content-type': 'application/json'},
            request: request,
          );
        }),
      ),
    );

    await api.ensureUserRecord(
      id: 'auth-user-id',
      name: 'Ana',
      email: 'ana@example.com',
    );

    expect(requests, hasLength(1));
    expect(requests.single.method, 'GET');
  });
}
