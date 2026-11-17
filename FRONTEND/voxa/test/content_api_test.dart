import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:voxa/core/data/remote/content_api.dart';

SupabaseClient _client(MockClient httpClient) => SupabaseClient(
  'https://test.supabase.co',
  'test-anon-key',
  accessToken: () async => 'session-token',
  httpClient: httpClient,
);

http.Response _json(Object body, http.Request request) => http.Response(
  jsonEncode(body),
  200,
  headers: {'content-type': 'application/json'},
  request: request,
);

void main() {
  test('lê direto do Supabase e devolve o conteúdo no formato local', () async {
    final requests = <http.Request>[];
    final api = ContentApi(
      _client(
        MockClient((request) async {
          requests.add(request);
          final body = switch (request.url.path) {
            '/rest/v1/prancha' => [
              {
                'id': 'board-1',
                'perfil_id': 'profile-1',
                'chave': 'rotina',
                'nome': 'Rotina',
                'ordem': 2,
              },
            ],
            '/rest/v1/prancha_cartao' => [
              {'prancha_id': 'board-1', 'cartao_id': 'card-1', 'ordem': 1},
            ],
            '/rest/v1/cartao' => [
              {
                'id': 'card-1',
                'perfil_id': 'profile-1',
                'texto': 'Comer',
                'cor_hex': '#ff00896b',
              },
            ],
            _ => throw StateError('Endpoint inesperado: ${request.url}'),
          };
          return _json(body, request);
        }),
      ),
    );

    final content = await api.fetchProfileContent('profile-1');

    expect(content.boards.single['nome'], 'Rotina');
    expect(content.boards.single['perfil_id'], 'profile-1');
    expect(content.cards.single['texto'], 'Comer');
    expect(content.cards.single['is_favorito'], false);
    expect(content.links.single, {
      'prancha_id': 'board-1',
      'cartao_id': 'card-1',
      'ordem': 1,
    });
    expect(requests, hasLength(3));
    expect(
      requests.every(
        (r) => r.headers['Authorization'] == 'Bearer session-token',
      ),
      isTrue,
    );
    expect(requests.first.url.queryParameters['perfil_id'], 'eq.profile-1');
  });

  test('upsert envia os IDs locais para o Supabase', () async {
    final requests = <http.Request>[];
    final api = ContentApi(
      _client(
        MockClient((request) async {
          requests.add(request);
          return http.Response('', 204, request: request);
        }),
      ),
    );

    await api.upsertBoard({
      'id': 'offline-board-id',
      'perfil_id': 'profile-1',
      'chave': 'rotina',
      'nome': 'Rotina',
      'ordem': 3,
      'imagem_storage_path': 'profile-1/board.png',
      'campo_inexistente': 'deve ser ignorado',
    });

    final request = requests.single;
    expect(request.method, 'POST');
    expect(request.url.path, '/rest/v1/prancha');
    expect(request.headers['Prefer'], contains('resolution=merge-duplicates'));
    final decoded = jsonDecode(request.body);
    final body = decoded is List ? decoded.single : decoded;
    expect(body, {
      'id': 'offline-board-id',
      'perfil_id': 'profile-1',
      'chave': 'rotina',
      'nome': 'Rotina',
      'ordem': 3,
      'imagem_storage_path': 'profile-1/board.png',
    });
  });
}
