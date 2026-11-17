import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

/// Resultado de [ContentApi.fetchProfileContent].
class ProfileContent {
  const ProfileContent({
    required this.boards,
    required this.cards,
    required this.links,
  });

  final List<Map<String, dynamic>> boards;
  final List<Map<String, dynamic>> cards;
  final List<Map<String, dynamic>> links;
}

/// Camada REMOTA de pranchas/cartões: fala DIRETO com o Supabase
/// (PostgREST + RLS + Storage). Não depende mais do Spring Boot rodando no
/// computador, então funciona no APK em qualquer rede.
///
/// O SQLite local e a fila de envio continuam sendo do [SyncService] /
/// LocalContentStore; esta classe só é chamada por eles (e pelo
/// HomeContentController quando está online).
///
/// Os parâmetros [baseUri], [httpClient] e [tokenProvider] existem apenas para
/// não quebrar quem ainda os passa (AppServices, testes). São ignorados: o
/// SupabaseClient já envia o JWT da sessão sozinho.
class ContentApi {
  ContentApi(
    this._client, {
    @Deprecated('Ignorado: o app fala direto com o Supabase.') Object? baseUri,
    @Deprecated('Ignorado: use o httpClient do SupabaseClient.')
    Object? httpClient,
    @Deprecated('Ignorado: o SupabaseClient usa o JWT da sessão.')
    Object? tokenProvider,
  });

  final SupabaseClient _client;

  static const imageBucket = 'content-images';
  static const catalogBucket = 'arasaac-catalog';
  static const signedUrlLifetimeSeconds = 3600;

  static const _pageSize = 1000;
  static const _chunkSize = 100;

  static const _boardCols = [
    'id',
    'perfil_id',
    'chave',
    'nome',
    'icone',
    'imagem_url',
    'imagem_storage_path',
    'caminho_audio',
    'ordem',
  ];

  static const _cardCols = [
    'id',
    'perfil_id',
    'texto',
    'caminho_imagem',
    'imagem_storage_path',
    'caminho_audio',
    'icone',
    'cor_hex',
    'arasaac_id',
    'is_favorito',
  ];

  // ---------------------------------------------------------------- helpers

  static Map<String, dynamic> _pick(
    Map<String, dynamic> row,
    List<String> cols,
  ) => {
    for (final c in cols)
      if (row.containsKey(c)) c: row[c],
  };

  /// Campos que podem ser alterados num UPDATE (id e perfil não mudam).
  static Map<String, dynamic> _patch(
    Map<String, dynamic> row,
    List<String> cols,
  ) => _pick(row, cols)
    ..remove('id')
    ..remove('perfil_id');

  static List<Map<String, dynamic>> _maps(dynamic value) => (value as List)
      .map((e) => Map<String, dynamic>.from(e as Map))
      .toList();

  static Map<String, dynamic> _board(Map<String, dynamic> r) => {
    ...r,
    'ordem': r['ordem'] ?? 0,
    'catalogo_arasaac': false,
  };

  static Map<String, dynamic> _card(Map<String, dynamic> r) => {
    ...r,
    'is_favorito': r['is_favorito'] ?? false,
    'frequencia_uso': r['frequencia_uso'] ?? 0,
  };

  static List<List<T>> _chunks<T>(List<T> list) => [
    for (var i = 0; i < list.length; i += _chunkSize)
      list.sublist(
        i,
        i + _chunkSize > list.length ? list.length : i + _chunkSize,
      ),
  ];

  /// O PostgREST devolve no máximo 1000 linhas por requisição.
  Future<List<Map<String, dynamic>>> _paged(
    PostgrestTransformBuilder<PostgrestList> Function() build,
  ) async {
    final out = <Map<String, dynamic>>[];
    for (var from = 0;; from += _pageSize) {
      final rows = _maps(await build().range(from, from + _pageSize - 1));
      out.addAll(rows);
      if (rows.length < _pageSize) return out;
    }
  }

  // ---------------------------------------------------------------- leitura

  Future<List<Map<String, dynamic>>> fetchUserBoards(String perfilId) async {
    final rows = await _paged(
      () => _client
          .from('prancha')
          .select()
          .eq('perfil_id', perfilId)
          .order('ordem')
          .order('id'),
    );
    return rows.where((r) => r['catalogo_arasaac'] != true).map(_board).toList();
  }

  Future<List<Map<String, dynamic>>> fetchAssociations(
    List<String> boardIds,
  ) async {
    final out = <Map<String, dynamic>>[];
    for (final ids in _chunks(boardIds)) {
      out.addAll(
        await _paged(
          () => _client
              .from('prancha_cartao')
              .select()
              .inFilter('prancha_id', ids)
              .order('prancha_id')
              .order('cartao_id'),
        ),
      );
    }
    return out
        .map((r) => {
              'prancha_id': r['prancha_id'],
              'cartao_id': r['cartao_id'],
              'ordem': r['ordem'] ?? 0,
            })
        .toList();
  }

  Future<List<Map<String, dynamic>>> fetchCards(
    String perfilId,
    List<String> cardIds,
  ) async {
    final out = <Map<String, dynamic>>[];
    for (final ids in _chunks(cardIds)) {
      out.addAll(
        await _paged(
          () => _client
              .from('cartao')
              .select()
              .eq('perfil_id', perfilId)
              .inFilter('id', ids)
              .order('id'),
        ),
      );
    }
    return out.map(_card).toList();
  }

  Future<ProfileContent> fetchProfileContent(String perfilId) async {
    final boards = await fetchUserBoards(perfilId);
    final links = await fetchAssociations(
      boards.map((b) => b['id'] as String).toList(),
    );
    final cardIds = links.map((l) => l['cartao_id'] as String).toSet().toList();
    final cards = await fetchCards(perfilId, cardIds);
    return ProfileContent(boards: boards, cards: cards, links: links);
  }

  Future<List<String>> fetchLinkedCardIds(String pranchaId) async {
    final rows = await _paged(
      () => _client
          .from('prancha_cartao')
          .select('cartao_id')
          .eq('prancha_id', pranchaId)
          .order('cartao_id'),
    );
    return rows.map((r) => r['cartao_id'] as String).toSet().toList();
  }

  Future<Set<String>> fetchCardIdsStillLinked(List<String> cardIds) async {
    final result = <String>{};
    for (final ids in _chunks(cardIds)) {
      final rows = await _paged(
        () => _client
            .from('prancha_cartao')
            .select('cartao_id')
            .inFilter('cartao_id', ids)
            .order('cartao_id')
            .order('prancha_id'),
      );
      result.addAll(rows.map((r) => r['cartao_id'] as String));
    }
    return result;
  }

  Future<bool> linkExists(String pranchaId, String cartaoId) async {
    final rows = await _client
        .from('prancha_cartao')
        .select('cartao_id')
        .eq('prancha_id', pranchaId)
        .eq('cartao_id', cartaoId)
        .limit(1);
    return (rows as List).isNotEmpty;
  }

  Future<List<Map<String, dynamic>>> fetchCardImagePaths(
    String perfilId,
    List<String> cardIds,
  ) async {
    final out = <Map<String, dynamic>>[];
    for (final ids in _chunks(cardIds)) {
      out.addAll(
        await _paged(
          () => _client
              .from('cartao')
              .select('id, imagem_storage_path')
              .eq('perfil_id', perfilId)
              .inFilter('id', ids)
              .order('id'),
        ),
      );
    }
    return out;
  }

  // ----------------------------------------------------------------- pranchas

  Future<Map<String, dynamic>> insertBoard(Map<String, dynamic> data) async =>
      _board(
        Map<String, dynamic>.from(
          await _client
              .from('prancha')
              .insert(_pick(data, _boardCols))
              .select()
              .single(),
        ),
      );

  Future<Map<String, dynamic>> updateBoard(
    String id,
    String perfilId,
    Map<String, dynamic> data,
  ) async => _board(
    Map<String, dynamic>.from(
      await _client
          .from('prancha')
          .update(_patch(data, _boardCols))
          .eq('id', id)
          .eq('perfil_id', perfilId)
          .select()
          .single(),
    ),
  );

  Future<void> deleteBoard(String id, String perfilId) async {
    await _client
        .from('prancha')
        .delete()
        .eq('id', id)
        .eq('perfil_id', perfilId);
  }

  Future<void> upsertBoard(Map<String, dynamic> row) async {
    await _client.from('prancha').upsert(_pick(row, _boardCols));
  }

  // ----------------------------------------------------------------- cartões

  Future<Map<String, dynamic>> insertCard(Map<String, dynamic> data) async =>
      _card(
        Map<String, dynamic>.from(
          await _client
              .from('cartao')
              .insert(_pick(data, _cardCols))
              .select()
              .single(),
        ),
      );

  Future<Map<String, dynamic>> updateCard(
    String id,
    String perfilId,
    Map<String, dynamic> data,
  ) async => _card(
    Map<String, dynamic>.from(
      await _client
          .from('cartao')
          .update(_patch(data, _cardCols))
          .eq('id', id)
          .eq('perfil_id', perfilId)
          .select()
          .single(),
    ),
  );

  Future<void> deleteCard(String id, String perfilId) async {
    await _client
        .from('cartao')
        .delete()
        .eq('id', id)
        .eq('perfil_id', perfilId);
  }

  Future<void> deleteCards(List<String> ids, String perfilId) async {
    for (final chunk in _chunks(ids)) {
      await _client
          .from('cartao')
          .delete()
          .eq('perfil_id', perfilId)
          .inFilter('id', chunk);
    }
  }

  Future<void> upsertCard(Map<String, dynamic> row) async {
    await _client.from('cartao').upsert(_pick(row, _cardCols));
  }

  // ------------------------------------------------------------------- links

  Future<void> insertLink(Map<String, dynamic> data) => upsertLink(data);

  Future<void> upsertLink(Map<String, dynamic> row) async {
    await _client.from('prancha_cartao').upsert({
      'prancha_id': row['prancha_id'],
      'cartao_id': row['cartao_id'],
      'ordem': row['ordem'] ?? 0,
    }, onConflict: 'prancha_id,cartao_id');
  }

  Future<void> updateLinkOrder(
    String pranchaId,
    String cartaoId,
    int ordem,
  ) async {
    await _client
        .from('prancha_cartao')
        .update({'ordem': ordem})
        .eq('prancha_id', pranchaId)
        .eq('cartao_id', cartaoId);
  }

  Future<void> deleteLink(String pranchaId, String cartaoId) async {
    await _client
        .from('prancha_cartao')
        .delete()
        .eq('prancha_id', pranchaId)
        .eq('cartao_id', cartaoId);
  }

  Future<void> deleteLinksOfBoard(String pranchaId) async {
    await _client.from('prancha_cartao').delete().eq('prancha_id', pranchaId);
  }

  Future<void> deleteLinksOfCard(String cartaoId) async {
    await _client.from('prancha_cartao').delete().eq('cartao_id', cartaoId);
  }

  /// Mantida no Supabase porque esta rotina é uma RPC já existente no banco.
  Future<void> migrateLegacyContent(
    String perfilId,
    Map<String, dynamic> data,
  ) async {
    await _client.rpc(
      'inicializar_conteudo_padrao',
      params: {'novo_perfil_id': perfilId, 'dados': data},
    );
  }

  // ----------------------------------------------------------------- storage

  Future<void> uploadImage(
    String path,
    List<int> bytes,
    String contentType,
  ) async {
    await _client.storage
        .from(imageBucket)
        .uploadBinary(
          path,
          Uint8List.fromList(bytes),
          fileOptions: FileOptions(contentType: contentType, upsert: false),
        );
  }

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

/// Mantida para compatibilidade com código que ainda captura esta exceção.
class ContentApiException implements Exception {
  const ContentApiException(this.statusCode, this.message);

  final int statusCode;
  final String message;

  @override
  String toString() => 'API Voxa ($statusCode): $message';
}
