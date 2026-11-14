import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

/// API REST de pranchas/cartões no Spring; Supabase continua responsável por
/// Auth, Storage e pela migração legada de conteúdo.
class ContentApi {
  ContentApi(
    this._client, {
    Uri? baseUri,
    http.Client? httpClient,
    String? Function()? tokenProvider,
  }) : _baseUri = baseUri ?? _defaultBaseUri(),
       _httpClient = httpClient ?? http.Client(),
       _tokenProvider =
           tokenProvider ?? (() => _client.auth.currentSession?.accessToken);

  final SupabaseClient _client;
  final Uri _baseUri;
  final http.Client _httpClient;
  final String? Function() _tokenProvider;

  static const imageBucket = 'content-images';
  static const catalogBucket = 'arasaac-catalog';
  static const signedUrlLifetimeSeconds = 3600;

  static Uri _defaultBaseUri() {
    final configured = dotenv.isInitialized
        ? dotenv.maybeGet('BACKEND_API_URL')?.trim()
        : null;
    if (configured != null && configured.isNotEmpty) {
      return Uri.parse(configured);
    }
    return Uri(
      scheme: 'http',
      host: kIsWeb || defaultTargetPlatform != TargetPlatform.android
          ? 'localhost'
          : '10.0.2.2',
      port: 8080,
      path: '/api/v1',
    );
  }

  Uri _uri(String path, [Map<String, String?> query = const {}]) {
    final basePath = _baseUri.path.replaceFirst(RegExp(r'/+$'), '');
    final suffix = path.replaceFirst(RegExp(r'^/+'), '');
    return _baseUri.replace(
      path: '$basePath/$suffix',
      queryParameters: {
        ..._baseUri.queryParameters,
        for (final entry in query.entries)
          if (entry.value != null) entry.key: entry.value!,
      },
    );
  }

  Future<dynamic> _request(
    String method,
    String path, {
    Map<String, String?> query = const {},
    Map<String, dynamic>? body,
  }) async {
    final token = _tokenProvider();
    if (token == null || token.isEmpty) {
      throw const AuthException('Entre na sua conta para acessar o conteúdo.');
    }

    final request = http.Request(method, _uri(path, query));
    request.headers.addAll({
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
      if (body != null) 'Content-Type': 'application/json',
    });
    if (body != null) request.body = jsonEncode(body);

    final streamed = await _httpClient.send(request);
    final response = await http.Response.fromStream(streamed);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ContentApiException(
        response.statusCode,
        response.body.isEmpty
            ? response.reasonPhrase ?? 'Erro na API'
            : response.body,
      );
    }
    if (response.statusCode == 204 || response.body.isEmpty) return null;
    return jsonDecode(response.body);
  }

  static Map<String, dynamic> _map(dynamic value) =>
      Map<String, dynamic>.from(value as Map);

  static List<Map<String, dynamic>> _maps(dynamic value) =>
      (value as List).map(_map).toList();

  static Map<String, dynamic> _boardFromApi(Map<String, dynamic> row) => {
    'id': row['id'],
    'perfil_id': row['perfilId'],
    'chave': row['chave'],
    'nome': row['nome'],
    'icone': row['icone'],
    'imagem_url': row['imagemUrl'],
    'imagem_storage_path': row['imagemStoragePath'],
    'caminho_audio': row['caminhoAudio'],
    'ordem': row['ordem'] ?? 0,
    'catalogo_arasaac': false,
  };

  static Map<String, dynamic> _cardFromApi(Map<String, dynamic> row) => {
    'id': row['id'],
    'perfil_id': row['perfilId'],
    'texto': row['texto'],
    'caminho_imagem': row['caminhoImagem'],
    'imagem_storage_path': row['imagemStoragePath'],
    'caminho_audio': row['caminhoAudio'],
    'icone': row['icone'],
    'cor_hex': row['corHex'],
    'arasaac_id': row['arasaacId'],
    'is_favorito': row['favorito'] ?? false,
    'frequencia_uso': row['frequenciaUso'] ?? 0,
  };

  Map<String, dynamic> _boardRequest(Map<String, dynamic> row) => {
    if (row['id'] != null) 'id': row['id'],
    'perfilId': row['perfil_id'],
    'chave': row['chave'],
    'nome': row['nome'],
    'icone': row['icone'],
    'imagemUrl': row['imagem_url'],
    'imagemStoragePath': row['imagem_storage_path'],
    'caminhoAudio': row['caminho_audio'],
    'ordem': row['ordem'] ?? 0,
  };

  Map<String, dynamic> _cardRequest(Map<String, dynamic> row) => {
    if (row['id'] != null) 'id': row['id'],
    'perfilId': row['perfil_id'],
    'texto': row['texto'],
    'caminhoImagem': row['caminho_imagem'],
    'imagemStoragePath': row['imagem_storage_path'],
    'caminhoAudio': row['caminho_audio'],
    'icone': row['icone'],
    'corHex': row['cor_hex'],
    'arasaacId': row['arasaac_id'],
    'favorito': row['is_favorito'] ?? false,
  };

  Future<List<Map<String, dynamic>>> fetchUserBoards(String perfilId) async =>
      _maps(await _request('GET', 'pranchas', query: {'perfilId': perfilId}))
          .map(_boardFromApi)
          .toList();

  Future<List<Map<String, dynamic>>> fetchAssociations(
    List<String> boardIds,
  ) async {
    final rows = <Map<String, dynamic>>[];
    for (final boardId in boardIds) {
      final items = _maps(await _request('GET', 'pranchas/$boardId/cartoes'));
      rows.addAll(
        items.map(
          (item) => {
            'prancha_id': boardId,
            'cartao_id': item['cartaoId'],
            'ordem': item['ordem'] ?? 0,
          },
        ),
      );
    }
    return rows;
  }

  Future<List<Map<String, dynamic>>> fetchCards(
    String perfilId,
    List<String> cardIds,
  ) async {
    if (cardIds.isEmpty) return [];
    final rows = _maps(
      await _request('GET', 'cartoes', query: {'perfilId': perfilId}),
    ).map(_cardFromApi).toList();
    final ids = cardIds.toSet();
    return rows.where((row) => ids.contains(row['id'])).toList();
  }

  Future<
    ({
      List<Map<String, dynamic>> boards,
      List<Map<String, dynamic>> cards,
      List<Map<String, dynamic>> links,
    })
  >
  fetchProfileContent(String perfilId) async {
    final boards = await fetchUserBoards(perfilId);
    final links = await fetchAssociations(
      boards.map((board) => board['id'] as String).toList(),
    );
    final cardIds = links
        .map((link) => link['cartao_id'] as String)
        .toSet()
        .toList();
    final cards = await fetchCards(perfilId, cardIds);
    return (boards: boards, cards: cards, links: links);
  }

  Future<List<String>> fetchLinkedCardIds(String pranchaId) async {
    final rows = _maps(await _request('GET', 'pranchas/$pranchaId/cartoes'));
    return rows.map((row) => row['cartaoId'] as String).toSet().toList();
  }

  Future<Set<String>> fetchCardIdsStillLinked(List<String> cardIds) async {
    final result = <String>{};
    for (final cardId in cardIds) {
      final boardIds =
          await _request('GET', 'cartoes/$cardId/pranchas') as List;
      if (boardIds.isNotEmpty) result.add(cardId);
    }
    return result;
  }

  Future<bool> linkExists(String pranchaId, String cartaoId) async =>
      (await fetchLinkedCardIds(pranchaId)).contains(cartaoId);

  Future<List<Map<String, dynamic>>> fetchCardImagePaths(
    String perfilId,
    List<String> cardIds,
  ) async {
    final results = <Map<String, dynamic>>[];
    for (final id in cardIds) {
      final row = _cardFromApi(_map(await _request('GET', 'cartoes/$id')));
      if (row['perfil_id'] == perfilId) {
        results.add({
          'id': row['id'],
          'imagem_storage_path': row['imagem_storage_path'],
        });
      }
    }
    return results;
  }

  Future<Map<String, dynamic>> insertBoard(Map<String, dynamic> data) async =>
      _boardFromApi(
        _map(await _request('POST', 'pranchas', body: _boardRequest(data))),
      );

  Future<Map<String, dynamic>> updateBoard(
    String id,
    String perfilId,
    Map<String, dynamic> data,
  ) async {
    final current = _boardFromApi(_map(await _request('GET', 'pranchas/$id')));
    final updated = {...current, ...data, 'id': id, 'perfil_id': perfilId};
    return _boardFromApi(
      _map(await _request('PUT', 'pranchas/$id', body: _boardRequest(updated))),
    );
  }

  Future<void> deleteBoard(String id, String perfilId) async {
    await _request('DELETE', 'pranchas/$id');
  }

  Future<Map<String, dynamic>> insertCard(Map<String, dynamic> data) async =>
      _cardFromApi(
        _map(await _request('POST', 'cartoes', body: _cardRequest(data))),
      );

  Future<Map<String, dynamic>> updateCard(
    String id,
    String perfilId,
    Map<String, dynamic> data,
  ) async {
    final current = _cardFromApi(_map(await _request('GET', 'cartoes/$id')));
    final request = {...current, ...data, 'id': id, 'perfil_id': perfilId};
    return _cardFromApi(
      _map(await _request('PUT', 'cartoes/$id', body: _cardRequest(request))),
    );
  }

  Future<void> deleteCard(String id, String perfilId) async {
    await _request('DELETE', 'cartoes/$id');
  }

  Future<void> deleteCards(List<String> ids, String perfilId) async {
    for (final id in ids) {
      await deleteCard(id, perfilId);
    }
  }

  Future<void> insertLink(Map<String, dynamic> data) => _link(
    data['prancha_id'] as String,
    data['cartao_id'] as String,
    data['ordem'] as int,
  );

  Future<void> updateLinkOrder(String pranchaId, String cartaoId, int ordem) =>
      _link(pranchaId, cartaoId, ordem);

  Future<void> _link(String pranchaId, String cartaoId, int ordem) async {
    await _request(
      'PUT',
      'pranchas/$pranchaId/cartoes/$cartaoId',
      body: {'ordem': ordem},
    );
  }

  Future<void> deleteLink(String pranchaId, String cartaoId) async {
    await _request('DELETE', 'pranchas/$pranchaId/cartoes/$cartaoId');
  }

  Future<void> deleteLinksOfBoard(String pranchaId) async {
    final cardIds = await fetchLinkedCardIds(pranchaId);
    for (final cardId in cardIds) {
      await deleteLink(pranchaId, cardId);
    }
  }

  Future<void> deleteLinksOfCard(String cartaoId) async {
    final boardIds =
        await _request('GET', 'cartoes/$cartaoId/pranchas') as List;
    for (final boardId in boardIds.cast<String>()) {
      await deleteLink(boardId, cartaoId);
    }
  }

  Future<void> upsertBoard(Map<String, dynamic> row) async {
    final id = row['id'] as String;
    await _request('PUT', 'pranchas/$id', body: _boardRequest(row));
  }

  Future<void> upsertCard(Map<String, dynamic> row) async {
    final id = row['id'] as String;
    await _request('PUT', 'cartoes/$id', body: _cardRequest(row));
  }

  Future<void> upsertLink(Map<String, dynamic> row) => _link(
    row['prancha_id'] as String,
    row['cartao_id'] as String,
    row['ordem'] as int? ?? 0,
  );

  /// Mantida no Supabase porque esta rotina é uma RPC já existente no banco.
  Future<void> migrateLegacyContent(
    String perfilId,
    Map<String, dynamic> data,
  ) => _client.rpc(
    'inicializar_conteudo_padrao',
    params: {'novo_perfil_id': perfilId, 'dados': data},
  );

  Future<void> uploadImage(String path, List<int> bytes, String contentType) =>
      _client.storage
          .from(imageBucket)
          .uploadBinary(
            path,
            Uint8List.fromList(bytes),
            fileOptions: FileOptions(contentType: contentType, upsert: false),
          );

  Future<String> signedImageUrl(String storagePath) => _client.storage
      .from(imageBucket)
      .createSignedUrl(storagePath, signedUrlLifetimeSeconds);

  Future<void> removeImages(List<String> paths) async {
    if (paths.isEmpty) return;
    await _client.storage.from(imageBucket).remove(paths);
  }

  String catalogImageUrl(String arasaacId) =>
      _client.storage.from(catalogBucket).getPublicUrl('$arasaacId.png');
}

class ContentApiException implements Exception {
  const ContentApiException(this.statusCode, this.message);

  final int statusCode;
  final String message;

  @override
  String toString() => 'API Voxa ($statusCode): $message';
}
