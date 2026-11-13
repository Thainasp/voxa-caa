import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

/// Camada de rede do conteúdo (pranchas, cartões e a ponte N:N).
///
/// É o único ponto do app que conversa com as tabelas `prancha`, `cartao` e
/// `prancha_cartao` e com o Storage. As telas e o controller da Home não
/// chamam o Supabase diretamente (BRADEMO, recursos nativos – CR1).
///
/// Mapeamento para os verbos HTTP (PostgREST do Supabase):
/// - select  -> GET
/// - insert  -> POST
/// - upsert  -> POST com "Prefer: resolution=merge-duplicates"
/// - update  -> PATCH (equivalente ao PUT parcial)
/// - delete  -> DELETE
class ContentApi {
  ContentApi(this._client);

  final SupabaseClient _client;

  static const imageBucket = 'content-images';
  static const catalogBucket = 'arasaac-catalog';
  static const signedUrlLifetimeSeconds = 3600;
  static const _pageSize = 1000;

  // ---------------------------------------------------------------------------
  // Leitura (GET)
  // ---------------------------------------------------------------------------

  /// Somente pranchas criadas pelo usuário. As cópias antigas do catálogo
  /// (catalogo_arasaac = true) são ignoradas: o catálogo agora é local.
  Future<List<Map<String, dynamic>>> fetchUserBoards(String perfilId) async {
    final rows = await _client
        .from('prancha')
        .select()
        .eq('perfil_id', perfilId)
        .eq('catalogo_arasaac', false)
        .order('ordem');
    return List<Map<String, dynamic>>.from(
      rows,
    ).where((row) => row['catalogo_arasaac'] != true).toList();
  }

  Future<List<Map<String, dynamic>>> fetchAssociations(
    List<String> boardIds,
  ) async {
    const boardIdBatchSize = 100;
    final rows = <Map<String, dynamic>>[];
    for (var start = 0; start < boardIds.length; start += boardIdBatchSize) {
      final end = (start + boardIdBatchSize).clamp(0, boardIds.length);
      final ids = boardIds.sublist(start, end);
      var offset = 0;
      while (true) {
        final page = await _client
            .from('prancha_cartao')
            .select('prancha_id, cartao_id, ordem')
            .inFilter('prancha_id', ids)
            .order('prancha_id')
            .order('ordem')
            .range(offset, offset + _pageSize - 1);
        rows.addAll(List<Map<String, dynamic>>.from(page));
        if (page.length < _pageSize) break;
        offset += _pageSize;
      }
    }
    return rows;
  }

  Future<List<Map<String, dynamic>>> fetchCards(
    String perfilId,
    List<String> cardIds,
  ) async {
    const idBatchSize = 500;
    final rows = <Map<String, dynamic>>[];
    for (var start = 0; start < cardIds.length; start += idBatchSize) {
      final end = (start + idBatchSize).clamp(0, cardIds.length);
      final ids = cardIds.sublist(start, end);
      var offset = 0;
      while (true) {
        final page = await _client
            .from('cartao')
            .select()
            .eq('perfil_id', perfilId)
            .inFilter('id', ids)
            .range(offset, offset + _pageSize - 1);
        rows.addAll(List<Map<String, dynamic>>.from(page));
        if (page.length < _pageSize) break;
        offset += _pageSize;
      }
    }
    return rows;
  }

  /// Baixa todo o conteúdo do usuário de um perfil (usado no "pull").
  Future<
    ({
      List<Map<String, dynamic>> boards,
      List<Map<String, dynamic>> cards,
      List<Map<String, dynamic>> links,
    })
  >
  fetchProfileContent(String perfilId) async {
    final boards = await fetchUserBoards(perfilId);
    final boardIds = boards.map((b) => b['id'] as String).toList();
    final links = boardIds.isEmpty
        ? <Map<String, dynamic>>[]
        : await fetchAssociations(boardIds);
    final cardIds = links.map((l) => l['cartao_id'] as String).toSet().toList();
    final cards = cardIds.isEmpty
        ? <Map<String, dynamic>>[]
        : await fetchCards(perfilId, cardIds);
    return (boards: boards, cards: cards, links: links);
  }

  Future<List<String>> fetchLinkedCardIds(String pranchaId) async {
    final rows = await _client
        .from('prancha_cartao')
        .select('cartao_id')
        .eq('prancha_id', pranchaId);
    return rows.map((row) => row['cartao_id'] as String).toSet().toList();
  }

  Future<Set<String>> fetchCardIdsStillLinked(List<String> cardIds) async {
    final rows = await _client
        .from('prancha_cartao')
        .select('cartao_id')
        .inFilter('cartao_id', cardIds);
    return rows.map((row) => row['cartao_id'] as String).toSet();
  }

  Future<bool> linkExists(String pranchaId, String cartaoId) async {
    final row = await _client
        .from('prancha_cartao')
        .select('cartao_id')
        .eq('prancha_id', pranchaId)
        .eq('cartao_id', cartaoId)
        .maybeSingle();
    return row != null;
  }

  Future<List<Map<String, dynamic>>> fetchCardImagePaths(
    String perfilId,
    List<String> cardIds,
  ) async {
    final rows = await _client
        .from('cartao')
        .select('id, imagem_storage_path')
        .eq('perfil_id', perfilId)
        .inFilter('id', cardIds);
    return List<Map<String, dynamic>>.from(rows);
  }

  // ---------------------------------------------------------------------------
  // Escrita (POST / PATCH / DELETE)
  // ---------------------------------------------------------------------------

  Future<Map<String, dynamic>> insertBoard(Map<String, dynamic> data) =>
      _client.from('prancha').insert(data).select().single();

  Future<Map<String, dynamic>> updateBoard(
    String id,
    String perfilId,
    Map<String, dynamic> data,
  ) => _client
      .from('prancha')
      .update(data)
      .eq('id', id)
      .eq('perfil_id', perfilId)
      .select()
      .single();

  Future<void> deleteBoard(String id, String perfilId) =>
      _client.from('prancha').delete().eq('id', id).eq('perfil_id', perfilId);

  Future<Map<String, dynamic>> insertCard(Map<String, dynamic> data) =>
      _client.from('cartao').insert(data).select().single();

  Future<Map<String, dynamic>> updateCard(
    String id,
    String perfilId,
    Map<String, dynamic> data,
  ) => _client
      .from('cartao')
      .update(data)
      .eq('id', id)
      .eq('perfil_id', perfilId)
      .select()
      .single();

  Future<void> deleteCard(String id, String perfilId) =>
      _client.from('cartao').delete().eq('id', id).eq('perfil_id', perfilId);

  Future<void> deleteCards(List<String> ids, String perfilId) => _client
      .from('cartao')
      .delete()
      .eq('perfil_id', perfilId)
      .inFilter('id', ids);

  Future<void> insertLink(Map<String, dynamic> data) =>
      _client.from('prancha_cartao').insert(data);

  Future<void> updateLinkOrder(String pranchaId, String cartaoId, int ordem) =>
      _client
          .from('prancha_cartao')
          .update({'ordem': ordem})
          .eq('prancha_id', pranchaId)
          .eq('cartao_id', cartaoId);

  Future<void> deleteLink(String pranchaId, String cartaoId) => _client
      .from('prancha_cartao')
      .delete()
      .eq('prancha_id', pranchaId)
      .eq('cartao_id', cartaoId);

  Future<void> deleteLinksOfBoard(String pranchaId) =>
      _client.from('prancha_cartao').delete().eq('prancha_id', pranchaId);

  Future<void> deleteLinksOfCard(String cartaoId) =>
      _client.from('prancha_cartao').delete().eq('cartao_id', cartaoId);

  // ---- usados pela sincronização (idempotentes) ----------------------------

  Future<void> upsertBoard(Map<String, dynamic> row) =>
      _client.from('prancha').upsert(row);

  Future<void> upsertCard(Map<String, dynamic> row) =>
      _client.from('cartao').upsert(row);

  Future<void> upsertLink(Map<String, dynamic> row) => _client
      .from('prancha_cartao')
      .upsert(row, onConflict: 'prancha_id,cartao_id');

  /// Conteúdo antigo salvo no aparelho antes do Supabase (SharedPreferences).
  Future<void> migrateLegacyContent(String perfilId, Map<String, dynamic> data) =>
      _client.rpc(
        'inicializar_conteudo_padrao',
        params: {'novo_perfil_id': perfilId, 'dados': data},
      );

  // ---------------------------------------------------------------------------
  // Storage (imagens)
  // ---------------------------------------------------------------------------

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

  /// URL pública de um pictograma do catálogo (não faz requisição).
  String catalogImageUrl(String arasaacId) =>
      _client.storage.from(catalogBucket).getPublicUrl('$arasaacId.png');
}
