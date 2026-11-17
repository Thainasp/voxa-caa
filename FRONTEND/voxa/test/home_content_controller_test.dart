import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:voxa/features/home/presentation/controllers/home_content_controller.dart';
import 'package:voxa/models/user_model.dart';

const _profileId = 'c6cf87a0-52db-42fd-aabc-c7e8cb987842';
const _ownerProfileId = '77777777-7777-4777-8777-777777777777';
const _boardId = '33333333-3333-4333-8333-333333333333';
const _cardId = '44444444-4444-4444-8444-444444444444';
const _newBoardId = '55555555-5555-4555-8555-555555555555';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockClient httpClient;
  late List<http.Request> requests;
  late List<Map<String, dynamic>> boards;
  late List<Map<String, dynamic>> cards;
  late List<Map<String, dynamic>> associations;
  late List<Map<String, dynamic>> profiles;
  late bool catalogNeedsSync;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    requests = [];
    boards = [
      {
        'id': _boardId,
        'perfil_id': _profileId,
        'chave': 'Principal',
        'nome': 'Início',
        'icone': 'home',
        'imagem_url': null,
        'imagem_storage_path': null,
        'caminho_audio': null,
        'ordem': 0,
      },
    ];
    cards = [];
    associations = [];
    profiles = [];
    catalogNeedsSync = false;
    httpClient = MockClient((request) async {
      requests.add(request);
      final path = request.url.path;

      if (path == '/api/v1/pranchas' && request.method == 'GET') {
        final profileId = request.url.queryParameters['perfilId'];
        return _jsonResponse(
          boards
              .where(
                (board) =>
                    board['perfil_id'] == profileId &&
                    board['catalogo_arasaac'] != true,
              )
              .map(_boardToApi)
              .toList(),
          request,
        );
      }
      if (path == '/api/v1/pranchas' && request.method == 'POST') {
        final row = _boardFromApi(
          jsonDecode(request.body) as Map<String, dynamic>,
        );
        row['id'] = _newBoardId;
        boards.add(row);
        return _jsonResponse(_boardToApi(row), request);
      }
      final boardLinks = RegExp(r'^/api/v1/pranchas/([^/]+)/cartoes$')
          .firstMatch(path);
      if (boardLinks != null && request.method == 'GET') {
        final boardId = boardLinks.group(1);
        return _jsonResponse(
          associations
              .where((item) => item['prancha_id'] == boardId)
              .map(
                (item) => {
                  'cartaoId': item['cartao_id'],
                  'ordem': item['ordem'],
                },
              )
              .toList(),
          request,
        );
      }
      final boardCardLink = RegExp(
        r'^/api/v1/pranchas/([^/]+)/cartoes/([^/]+)$',
      ).firstMatch(path);
      if (boardCardLink != null) {
        final boardId = boardCardLink.group(1);
        final cardId = boardCardLink.group(2);
        if (request.method == 'PUT') {
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          final association = associations.firstWhere(
            (item) =>
                item['prancha_id'] == boardId && item['cartao_id'] == cardId,
            orElse: () {
              final item = {
                'prancha_id': boardId,
                'cartao_id': cardId,
                'ordem': 0,
              };
              associations.add(item);
              return item;
            },
          );
          association['ordem'] = body['ordem'];
          return _jsonResponse({
            'cartaoId': cardId,
            'ordem': association['ordem'],
          }, request);
        }
        if (request.method == 'DELETE') {
          associations.removeWhere(
            (item) =>
                item['prancha_id'] == boardId && item['cartao_id'] == cardId,
          );
          return http.Response('', 204, request: request);
        }
      }
      final boardItem = RegExp(r'^/api/v1/pranchas/([^/]+)$').firstMatch(path);
      if (boardItem != null) {
        final id = boardItem.group(1);
        if (request.method == 'GET') {
          final row = boards.firstWhere((item) => item['id'] == id);
          return _jsonResponse(_boardToApi(row), request);
        }
        if (request.method == 'PUT') {
          final row = boards.firstWhere((item) => item['id'] == id);
          row.addAll(
            _boardFromApi(jsonDecode(request.body) as Map<String, dynamic>),
          );
          return _jsonResponse(_boardToApi(row), request);
        }
        if (request.method == 'DELETE') {
          boards.removeWhere((item) => item['id'] == id);
          associations.removeWhere((item) => item['prancha_id'] == id);
          return http.Response('', 204, request: request);
        }
      }
      if (path == '/api/v1/cartoes' && request.method == 'GET') {
        final profileId = request.url.queryParameters['perfilId'];
        return _jsonResponse(
          cards
              .where((card) => card['perfil_id'] == profileId)
              .map(_cardToApi)
              .toList(),
          request,
        );
      }
      if (path == '/api/v1/cartoes' && request.method == 'POST') {
        final row = _cardFromApi(
          jsonDecode(request.body) as Map<String, dynamic>,
        );
        row['id'] = _cardId;
        cards.add(row);
        return _jsonResponse(_cardToApi(row), request);
      }
      final cardBoards = RegExp(r'^/api/v1/cartoes/([^/]+)/pranchas$')
          .firstMatch(path);
      if (cardBoards != null && request.method == 'GET') {
        final cardId = cardBoards.group(1);
        return _jsonResponse(
          associations
              .where((item) => item['cartao_id'] == cardId)
              .map((item) => item['prancha_id'])
              .toList(),
          request,
        );
      }
      final cardItem = RegExp(r'^/api/v1/cartoes/([^/]+)$').firstMatch(path);
      if (cardItem != null) {
        final id = cardItem.group(1);
        if (request.method == 'GET') {
          final row = cards.firstWhere((item) => item['id'] == id);
          return _jsonResponse(_cardToApi(row), request);
        }
        if (request.method == 'PUT') {
          final row = cards.firstWhere((item) => item['id'] == id);
          row.addAll(
            _cardFromApi(jsonDecode(request.body) as Map<String, dynamic>),
          );
          return _jsonResponse(_cardToApi(row), request);
        }
        if (request.method == 'DELETE') {
          cards.removeWhere((item) => item['id'] == id);
          associations.removeWhere((item) => item['cartao_id'] == id);
          return http.Response('', 204, request: request);
        }
      }

      if (path.endsWith('/rest/v1/perfil')) {
        if (request.method == 'GET') {
          final userId = _queryValue(request, 'usuario_id');
          final profileId = _queryValue(request, 'id');
          final isResponsavel = _queryValue(request, 'is_responsavel');
          final result = profiles.where((profile) {
            return (userId == null || profile['usuario_id'] == userId) &&
                (profileId == null || profile['id'] == profileId) &&
                (isResponsavel == null ||
                    profile['is_responsavel'].toString() == isResponsavel);
          }).toList();
          return _jsonResponse(result, request);
        }
        if (request.method == 'POST') {
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          final profile = {'id': _ownerProfileId, ...body};
          profiles.add(profile);
          return _jsonResponse(profile, request);
        }
      }

      if (path.endsWith(
        '/rest/v1/rpc/catalogo_arasaac_completo_necessita_sync',
      )) {
        return _jsonResponse(catalogNeedsSync, request);
      }

      if (path.endsWith('/rest/v1/rpc/sincronizar_catalogo_arasaac_completo')) {
        final payload = jsonDecode(request.body) as Map<String, dynamic>;
        final data = payload['p_dados'] as Map<String, dynamic>;
        final categories = data['categories'] as List;
        final pictograms = data['pictograms'] as List;
        final principalIds = (data['principalIds'] as List)
            .map((id) => id.toString())
            .toList();
        final boardIdsByKey = <String, String>{};
        final cardIdsByArasaac = <String, String>{};
        boards = [
          {
            'id': _boardId,
            'perfil_id': _profileId,
            'chave': 'Principal',
            'nome': 'Início',
            'icone': 'home',
            'imagem_url': null,
            'imagem_storage_path': null,
            'caminho_audio': null,
            'ordem': 0,
            'catalogo_arasaac': true,
            'catalogo_pai_chave': null,
          },
        ];
        cards = [];
        associations = [];
        for (final (index, categoryValue) in categories.indexed) {
          final category = Map<String, dynamic>.from(categoryValue as Map);
          final id =
              '00000000-0000-4000-8000-${(index + 1).toString().padLeft(12, '0')}';
          boardIdsByKey[category['key'] as String] = id;
          boards.add({
            'id': id,
            'perfil_id': _profileId,
            'chave': category['key'],
            'nome': category['label'],
            'icone': 'folder',
            'imagem_url': null,
            'imagem_storage_path': null,
            'caminho_audio': null,
            'ordem': category['order'],
            'catalogo_arasaac': true,
            'catalogo_pai_chave': category['parentKey'],
          });
        }
        for (final (index, pictogramValue) in pictograms.indexed) {
          final pictogram = Map<String, dynamic>.from(pictogramValue as Map);
          final id = pictogram['id'].toString();
          final cardId =
              '00000000-0000-4000-8001-${(index + 1).toString().padLeft(12, '0')}';
          cardIdsByArasaac[id] = cardId;
          cards.add({
            'id': cardId,
            'perfil_id': _profileId,
            'texto': pictogram['label'],
            'cor_hex': '#ff00896b',
            'icone': 'image_outlined',
            'caminho_imagem': 'arasaac-catalog/$id.png',
            'imagem_storage_path': null,
            'caminho_audio': null,
            'arasaac_id': id,
          });
        }
        for (final categoryValue in categories) {
          final category = Map<String, dynamic>.from(categoryValue as Map);
          final boardId = boardIdsByKey[category['key']];
          final ids = category['pictogramIds'] as List;
          for (final (index, pictogramId) in ids.indexed) {
            associations.add({
              'prancha_id': boardId,
              'cartao_id': cardIdsByArasaac[pictogramId.toString()],
              'ordem': index,
            });
          }
        }
        for (final (index, pictogramId) in principalIds.indexed) {
          associations.add({
            'prancha_id': _boardId,
            'cartao_id': cardIdsByArasaac[pictogramId],
            'ordem': index,
          });
        }
        catalogNeedsSync = false;
        return http.Response('', 204, request: request);
      }

      if (path.endsWith('/rest/v1/rpc/inicializar_conteudo_padrao')) {
        final payload = jsonDecode(request.body) as Map<String, dynamic>;
        final seededBoards =
            (payload['dados'] as Map<String, dynamic>)['boards'] as List;
        boards = [];
        cards = [];
        associations = [];
        var nextCardIndex = 0;
        boards = seededBoards.indexed.map((entry) {
          final index = entry.$1;
          final item = Map<String, dynamic>.from(entry.$2 as Map);
          final boardId =
              '00000000-0000-4000-8000-${(index + 1).toString().padLeft(12, '0')}';
          final seededCards = item['cards'] as List;
          for (final cardValue in seededCards.indexed) {
            nextCardIndex++;
            final card = Map<String, dynamic>.from(cardValue.$2 as Map);
            final cardId =
                '00000000-0000-4000-8001-${nextCardIndex.toString().padLeft(12, '0')}';
            cards.add({
              'id': cardId,
              'perfil_id': _profileId,
              'texto': card['label'],
              'cor_hex': card['color'],
              'icone': card['icon'],
              'caminho_imagem': card['imagePath'],
              'imagem_storage_path': null,
              'caminho_audio': card['audioPath'],
              'arasaac_id': card['arasaacId'],
            });
            associations.add({
              'prancha_id': boardId,
              'cartao_id': cardId,
              'ordem': card['order'],
            });
          }
          return {
            'id': boardId,
            'perfil_id': _profileId,
            'chave': item['key'],
            'nome': item['label'],
            'icone': item['icon'],
            'imagem_url': item['imagePath'],
            'imagem_storage_path': null,
            'caminho_audio': item['audioPath'],
            'ordem': item['order'],
            'catalogo_arasaac': false,
            'catalogo_pai_chave': null,
          };
        }).toList();
        return http.Response('', 204, request: request);
      }

      if (path.endsWith('/rest/v1/prancha')) {
        if (request.method == 'GET') return _jsonResponse(boards, request);
        if (request.method == 'POST') {
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          final row = {'id': _newBoardId, ...body, 'ordem': 0};
          boards.add(row);
          return _jsonResponse(row, request);
        }
        if (request.method == 'PATCH') {
          final row = boards.firstWhere((item) => item['id'] == _newBoardId);
          row.addAll(jsonDecode(request.body) as Map<String, dynamic>);
          return _jsonResponse(row, request);
        }
        if (request.method == 'DELETE') {
          final boardId = _queryValue(request, 'id');
          boards.removeWhere((item) => item['id'] == boardId);
          associations.removeWhere((item) => item['prancha_id'] == boardId);
          return http.Response('', 204, request: request);
        }
      }

      if (path.endsWith('/rest/v1/prancha_cartao')) {
        if (request.method == 'GET') {
          final boardId = _queryValue(request, 'prancha_id');
          final boardIds = _queryValues(request, 'prancha_id');
          final cardId = _queryValue(request, 'cartao_id');
          final result = associations.where((association) {
            final matchesBoard = boardIds != null
                ? boardIds.contains(association['prancha_id'])
                : boardId == null || association['prancha_id'] == boardId;
            return matchesBoard &&
                (cardId == null || association['cartao_id'] == cardId);
          }).toList();
          return _jsonResponse(_pageRows(result, request), request);
        }
        if (request.method == 'POST') {
          final row = jsonDecode(request.body) as Map<String, dynamic>;
          associations.add(row);
          return _jsonResponse(row, request);
        }
        if (request.method == 'PATCH') {
          final boardId = _queryValue(request, 'prancha_id');
          final cardId = _queryValue(request, 'cartao_id');
          final row = associations.firstWhere(
            (item) =>
                item['prancha_id'] == boardId && item['cartao_id'] == cardId,
          );
          row.addAll(jsonDecode(request.body) as Map<String, dynamic>);
          return _jsonResponse(row, request);
        }
        if (request.method == 'DELETE') {
          final boardId = _queryValue(request, 'prancha_id');
          final cardId = _queryValue(request, 'cartao_id');
          associations.removeWhere(
            (item) =>
                (boardId == null || item['prancha_id'] == boardId) &&
                (cardId == null || item['cartao_id'] == cardId),
          );
          return http.Response('', 204, request: request);
        }
      }

      if (path.endsWith('/rest/v1/cartao')) {
        if (request.method == 'GET') {
          final cardIds = _queryValues(request, 'id');
          final profileId = _queryValue(request, 'perfil_id');
          final result = cards.where((card) {
            return (cardIds == null || cardIds.contains(card['id'])) &&
                (profileId == null || card['perfil_id'] == profileId);
          }).toList();
          return _jsonResponse(_pageRows(result, request), request);
        }
        if (request.method == 'POST') {
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          final row = {'id': _cardId, ...body};
          cards.add(row);
          return _jsonResponse(row, request);
        }
        if (request.method == 'PATCH') {
          final row = cards.firstWhere((item) => item['id'] == _cardId);
          row.addAll(jsonDecode(request.body) as Map<String, dynamic>);
          return _jsonResponse(row, request);
        }
        if (request.method == 'DELETE') {
          final cardId = _queryValue(request, 'id');
          final cardIds = _queryValues(request, 'id');
          cards.removeWhere(
            (item) =>
                (cardId != null && item['id'] == cardId) ||
                (cardIds != null && cardIds.contains(item['id'])),
          );
          return http.Response('', 204, request: request);
        }
      }

      return http.Response(
        jsonEncode({'message': 'Unexpected request: $request'}),
        500,
      );
    });

    HomeContentController.clientForTesting = SupabaseClient(
      'https://test.supabase.co',
      'test-anon-key',
      accessToken: () async => 'test-access-token',
      httpClient: httpClient,
    );
    HomeContentController.httpClientForTesting = httpClient;
  });

  tearDown(() {
    HomeContentController.clientForTesting = null;
    HomeContentController.httpClientForTesting = null;
    httpClient.close();
  });

  test('lista todas as tábuas com as criadas pelo usuário primeiro', () {
    final originalBoards = HomeContentController.boards;
    HomeContentController.boards = [
      {'key': 'Principal', 'catalogoArasaac': true},
      {'key': 'Minha tábua'},
      {'key': 'Comida', 'catalogoArasaac': true},
      {'key': 'Outra tábua', 'catalogoArasaac': false},
    ];

    expect(
      HomeContentController.boardsWithUserCreatedFirst.map(
        (board) => board['key'],
      ),
      ['Minha tábua', 'Outra tábua', 'Principal', 'Comida'],
    );
    HomeContentController.boards = originalBoards;
  });

  test(
    'resolve o perfil titular em vez de usar o ID de autenticação',
    () async {
      final profile = await HomeContentController.resolveActiveProfile(
        authUserId: _profileId,
        email: 'titular@example.com',
        requestedProfile: null,
        fallbackName: 'Titular',
      );

      expect(profile.id, _ownerProfileId);
      expect(profile.isResponsavel, isTrue);
      expect(profiles.single['usuario_id'], _profileId);
      expect(
        requests.any(
          (request) =>
              request.url.path.endsWith('/rest/v1/perfil') &&
              request.method == 'POST',
        ),
        isTrue,
      );
    },
  );

  test('valida o perfil selecionado dentro da conta autenticada', () async {
    profiles.add({
      'id': _profileId,
      'usuario_id': '88888888-8888-4888-8888-888888888888',
      'nome': 'Perfil dependente',
      'is_responsavel': false,
    });

    final profile = await HomeContentController.resolveActiveProfile(
      authUserId: '88888888-8888-4888-8888-888888888888',
      email: '',
      requestedProfile: const UserModel(
        id: _profileId,
        name: 'Perfil dependente',
      ),
      fallbackName: 'Titular',
    );

    expect(profile.id, _profileId);
    expect(profile.isResponsavel, isFalse);
    expect(
      requests.any(
        (request) =>
            request.url.path.endsWith('/rest/v1/perfil') &&
            request.method == 'POST',
      ),
      isFalse,
    );
  });

  test('carrega pranchas e cartões usando a tabela de associação', () async {
    const secondBoardId = '66666666-6666-4666-8666-666666666666';
    boards.add({
      'id': secondBoardId,
      'perfil_id': _profileId,
      'chave': 'Comida',
      'nome': 'Comida',
      'icone': 'restaurant_menu',
      'imagem_url': null,
      'imagem_storage_path': null,
      'caminho_audio': null,
      'ordem': 1,
    });
    cards = [
      {
        'id': _cardId,
        'perfil_id': _profileId,
        'texto': 'Quero',
        'cor_hex': '#ffffc107',
        'icone': 'pan_tool',
        'caminho_imagem': 'assets/arasaac/5441.png',
        'imagem_storage_path': null,
        'caminho_audio': null,
        'arasaac_id': '5441',
      },
    ];
    associations = [
      {'prancha_id': _boardId, 'cartao_id': _cardId, 'ordem': 0},
      {'prancha_id': secondBoardId, 'cartao_id': _cardId, 'ordem': 1},
    ];

    await HomeContentController.loadContentForProfile(_profileId);

    expect(
      requests.any(
        (request) =>
            request.url.path == '/rest/v1/prancha' && request.method == 'GET',
      ),
      isTrue,
    );
    expect(
      requests.any(
        (request) =>
            request.url.path == '/rest/v1/prancha_cartao' &&
            request.method == 'GET',
      ),
      isTrue,
    );
    expect(
      HomeContentController.boards.firstWhere(
        (board) => board['key'] == 'Principal',
      )['label'],
      'Início',
    );
    final loadedCard = HomeContentController.cardsByBoard['Principal']!.single;
    expect(loadedCard['label'], 'Quero');
    expect(loadedCard['imagePath'], 'assets/arasaac/5441.png');
    expect(loadedCard['arasaacId'], '5441');
    expect(HomeContentController.cardsByBoard['Comida']!.single['id'], _cardId);

    await HomeContentController.saveCard(
      {...loadedCard, 'label': 'Eu quero'},
      'Principal',
      isNew: false,
    );
    expect(
      HomeContentController.cardsByBoard['Comida']!.single['label'],
      'Eu quero',
    );
  });

  test(
    'monta o catálogo ARASAAC localmente, sem copiar para o Supabase',
    () async {
      boards = [];
      HomeContentController.catalogEnabledForTesting = true;
      await HomeContentController.loadContentForProfile(_profileId);

      // O catálogo não é mais sincronizado por perfil (causa do erro 57014).
      expect(
        requests.any(
          (request) => request.url.path.contains('/rpc/sincronizar_catalogo'),
        ),
        isFalse,
      );
      expect(cards, isEmpty);

      expect(HomeContentController.boards, hasLength(611));
      expect(
        HomeContentController.boards.every(
          (board) => board['catalogoArasaac'] == true,
        ),
        isTrue,
      );
      final principalCards = HomeContentController.cardsByBoard['Principal']!;
      expect(principalCards, hasLength(24));
      expect(
        HomeContentController.cardsByBoard.values.fold<int>(
          0,
          (count, boardCards) => count + boardCards.length,
        ),
        26852,
      );

      final catalog = jsonDecode(
        await rootBundle.loadString('assets/arasaac/catalogo_inicial.json'),
      ) as Map<String, dynamic>;
      expect(catalog['categories'], hasLength(610));
      expect(catalog['pictograms'], hasLength(13767));
      final firstPrincipalId = (catalog['principalIds'] as List).first
          .toString();
      final firstPrincipalCard = principalCards.first;
      expect(firstPrincipalCard['arasaacId'], firstPrincipalId);
      // "eu" é pronome pessoal: amarelo na chave Fitzgerald (RF03).
      expect(firstPrincipalCard['color'], isA<Color>());
      expect(
        firstPrincipalCard['imagePath'],
        anyOf(
          'assets/arasaac/$firstPrincipalId.png',
          endsWith('/arasaac-catalog/$firstPrincipalId.png'),
        ),
      );

      // Pranchas do catálogo não podem ser editadas nem excluídas.
      expect(HomeContentController.editableBoards, isEmpty);
      final catalogBoard = HomeContentController.boards.first;
      await expectLater(
        HomeContentController.saveBoard({
          ...catalogBoard,
          'label': 'Bebidas atualizada',
        }, isNew: false),
        throwsStateError,
      );
      expect(
        requests.any(
          (request) => request.url.path.contains('/arasaac:board:'),
        ),
        isFalse,
      );
      expect(
        () => HomeContentController.deleteBoard('Principal'),
        throwsStateError,
      );
    },
  );

  test('migra o conteúdo local legado para o Supabase', () async {
    SharedPreferences.setMockInitialValues({
      'voxa.content.$_profileId': jsonEncode({
        'boards': [
          {
            'key': 'legado',
            'label': 'Tábua legada',
            'imagePath': 'assets/arasaac/123.png',
          },
        ],
        'cardsByBoard': {
          'legado': [
            {'label': 'Cartão legado', 'imagePath': 'assets/arasaac/456.png'},
          ],
        },
      }),
    });
    boards = [];

    await HomeContentController.loadContentForProfile(_profileId);

    expect(HomeContentController.boards.single['label'], 'Tábua legada');
    expect(
      HomeContentController.boards.single['imagePath'],
      'assets/arasaac/123.png',
    );
    final card = HomeContentController.cardsByBoard['legado']!.single;
    expect(card['label'], 'Cartão legado');
    expect(card['imagePath'], 'assets/arasaac/456.png');
    expect(
      await SharedPreferences.getInstance().then(
        (preferences) => preferences.getString('voxa.content.$_profileId'),
      ),
      isNull,
    );
  });

  test(
    'faz CRUD de prancha e cartão com associação muitos-para-muitos',
    () async {
      await HomeContentController.loadContentForProfile(_profileId);

      final board = await HomeContentController.saveBoard({
        'key': 'teste',
        'label': 'Tábua de teste',
        'icon': Icons.dashboard_customize,
      }, isNew: true);
      final card = await HomeContentController.saveCard(
        {
          'label': 'Água',
          'color': Colors.blue,
          'icon': Icons.local_drink,
          'imagePath': 'https://example.com/agua.png',
        },
        board['key'] as String,
        isNew: true,
      );

      await HomeContentController.saveBoard({
        ...board,
        'label': 'Minha tábua',
      }, isNew: false);
      final updatedCard = await HomeContentController.saveCard(
        {...card, 'label': 'Quero água'},
        board['key'] as String,
        isNew: false,
      );

      expect(updatedCard['label'], 'Quero água');
      await HomeContentController.deleteCard(updatedCard);
      await HomeContentController.deleteBoard(board['key'] as String);

      bool called(String method, String table) => requests.any(
        (request) =>
            request.method == method &&
            request.url.path == '/rest/v1/$table',
      );

      // Criar prancha e cartão (INSERT) e o vínculo N:N (upsert = POST).
      expect(called('POST', 'prancha'), isTrue);
      expect(called('POST', 'cartao'), isTrue);
      expect(called('POST', 'prancha_cartao'), isTrue);
      // Editar prancha, cartão e a ordem do vínculo (UPDATE = PATCH).
      expect(called('PATCH', 'prancha'), isTrue);
      expect(called('PATCH', 'cartao'), isTrue);
      expect(called('PATCH', 'prancha_cartao'), isTrue);
      // Excluir vínculo, cartão órfão e prancha.
      expect(called('DELETE', 'prancha_cartao'), isTrue);
      expect(called('DELETE', 'cartao'), isTrue);
      expect(called('DELETE', 'prancha'), isTrue);
      // Nada deve ir para a API Spring.
      expect(
        requests.any((request) => request.url.path.contains('/api/v1/')),
        isFalse,
      );
    },
  );
}

Map<String, dynamic> _boardToApi(Map<String, dynamic> row) => {
  'id': row['id'],
  'perfilId': row['perfil_id'],
  'chave': row['chave'],
  'nome': row['nome'],
  'icone': row['icone'],
  'imagemUrl': row['imagem_url'],
  'imagemStoragePath': row['imagem_storage_path'],
  'caminhoAudio': row['caminho_audio'],
  'ordem': row['ordem'] ?? 0,
  'cartoes': null,
};

Map<String, dynamic> _boardFromApi(Map<String, dynamic> request) => {
  'id': request['id'],
  'perfil_id': request['perfilId'],
  'chave': request['chave'],
  'nome': request['nome'],
  'icone': request['icone'],
  'imagem_url': request['imagemUrl'],
  'imagem_storage_path': request['imagemStoragePath'],
  'caminho_audio': request['caminhoAudio'],
  'ordem': request['ordem'] ?? 0,
  'catalogo_arasaac': false,
};

Map<String, dynamic> _cardToApi(Map<String, dynamic> row) => {
  'id': row['id'],
  'perfilId': row['perfil_id'],
  'texto': row['texto'],
  'caminhoImagem': row['caminho_imagem'],
  'imagemStoragePath': row['imagem_storage_path'],
  'caminhoAudio': row['caminho_audio'],
  'icone': row['icone'],
  'corHex': row['cor_hex'],
  'arasaacId': row['arasaac_id'],
  'favorito': row['is_favorito'] ?? false,
  'frequenciaUso': row['frequencia_uso'] ?? 0,
};

Map<String, dynamic> _cardFromApi(Map<String, dynamic> request) => {
  'id': request['id'],
  'perfil_id': request['perfilId'],
  'texto': request['texto'],
  'caminho_imagem': request['caminhoImagem'],
  'imagem_storage_path': request['imagemStoragePath'],
  'caminho_audio': request['caminhoAudio'],
  'icone': request['icone'],
  'cor_hex': request['corHex'],
  'arasaac_id': request['arasaacId'],
  'is_favorito': request['favorito'] ?? false,
  'frequencia_uso': 0,
};

String? _queryValue(http.Request request, String key) {
  final value = request.url.queryParameters[key];
  if (value == null || !value.startsWith('eq.')) return null;
  return value.substring(3);
}

Set<String>? _queryValues(http.Request request, String key) {
  final value = request.url.queryParameters[key];
  if (value == null || !value.startsWith('in.(') || !value.endsWith(')')) {
    return null;
  }
  return value
      .substring(4, value.length - 1)
      .split(',')
      .map((item) => item.replaceAll('"', ''))
      .toSet();
}

List<Map<String, dynamic>> _pageRows(
  List<Map<String, dynamic>> rows,
  http.Request request,
) {
  final range = request.headers['range'] ?? request.headers['Range'];
  final match = range == null ? null : RegExp(r'(\d+)-(\d+)').firstMatch(range);
  final start = match == null
      ? int.tryParse(request.url.queryParameters['offset'] ?? '') ?? 0
      : int.parse(match.group(1)!);
  final limit = match == null
      ? int.tryParse(request.url.queryParameters['limit'] ?? '')
      : int.parse(match.group(2)!) - start + 1;
  if (limit == null) return rows;
  return rows.skip(start).take(limit).toList();
}

http.Response _jsonResponse(Object body, http.Request request) => http.Response(
  jsonEncode(body),
  200,
  headers: {'content-type': 'application/json'},
  request: request,
);
