import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:voxa/core/data/remote/content_api.dart';

void main() {
  test(
    'usa a API com bearer do Supabase e converte o conteúdo ao formato local',
    () async {
      final requests = <http.Request>[];
      final client = SupabaseClient(
        'https://test.supabase.co',
        'test-anon-key',
      );
      final api = ContentApi(
        client,
        baseUri: Uri.parse('https://api.voxa.test/api/v1'),
        tokenProvider: () => 'session-token',
        httpClient: MockClient((request) async {
          requests.add(request);
          final body = switch (request.url.path) {
            '/api/v1/pranchas' => [
              {
                'id': 'board-1',
                'perfilId': 'profile-1',
                'chave': 'rotina',
                'nome': 'Rotina',
                'ordem': 2,
              },
            ],
            '/api/v1/pranchas/board-1/cartoes' => [
              {'cartaoId': 'card-1', 'ordem': 1},
            ],
            '/api/v1/cartoes' => [
              {
                'id': 'card-1',
                'perfilId': 'profile-1',
                'texto': 'Comer',
                'corHex': '#ff00896b',
                'favorito': false,
                'frequenciaUso': 0,
              },
            ],
            _ => throw StateError('Endpoint inesperado: ${request.url}'),
          };
          return http.Response(
            jsonEncode(body),
            200,
            headers: {'content-type': 'application/json'},
            request: request,
          );
        }),
      );

      final content = await api.fetchProfileContent('profile-1');

      expect(content.boards.single['nome'], 'Rotina');
      expect(content.boards.single['perfil_id'], 'profile-1');
      expect(content.cards.single['texto'], 'Comer');
      expect(content.links.single, {
        'prancha_id': 'board-1',
        'cartao_id': 'card-1',
        'ordem': 1,
      });
      expect(requests, hasLength(3));
      expect(
        requests.every(
          (request) =>
              request.headers['Authorization'] == 'Bearer session-token',
        ),
        isTrue,
      );
      expect(requests.first.url.queryParameters['perfilId'], 'profile-1');
    },
  );

  test(
    'upsert envia os IDs locais e mantém Supabase como identidade remota',
    () async {
      final requests = <http.Request>[];
      final api = ContentApi(
        SupabaseClient('https://test.supabase.co', 'test-anon-key'),
        baseUri: Uri.parse('https://api.voxa.test/api/v1'),
        tokenProvider: () => 'session-token',
        httpClient: MockClient((request) async {
          requests.add(request);
          return http.Response('', 204, request: request);
        }),
      );

      await api.upsertBoard({
        'id': 'offline-board-id',
        'perfil_id': 'profile-1',
        'chave': 'rotina',
        'nome': 'Rotina',
        'ordem': 3,
        'imagem_storage_path': 'profile-1/board.png',
      });

      expect(requests.single.method, 'PUT');
      expect(requests.single.url.path, '/api/v1/pranchas/offline-board-id');
      expect(requests.single.headers['Authorization'], 'Bearer session-token');
      expect(jsonDecode(requests.single.body), {
        'id': 'offline-board-id',
        'perfilId': 'profile-1',
        'chave': 'rotina',
        'nome': 'Rotina',
        'icone': null,
        'imagemUrl': null,
        'imagemStoragePath': 'profile-1/board.png',
        'caminhoAudio': null,
        'ordem': 3,
      });
    },
  );
}
