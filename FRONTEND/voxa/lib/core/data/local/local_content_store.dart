import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Operação pendente de envio à API (fila "outbox").
///
/// Cada alteração feita sem Wi-Fi vira uma linha nesta fila, na ordem em que
/// aconteceu. Ao conectar no Wi-Fi o SyncService envia uma a uma.
class OutboxOperation {
  final int? id;
  final String perfilId;

  /// 'prancha' | 'cartao' | 'prancha_cartao'
  final String tabela;

  /// 'upsert' | 'delete'
  final String operacao;

  /// upsert: linha completa (colunas do Supabase).
  /// delete: chave(s) da linha (ex.: {'id': ...} ou {'prancha_id', 'cartao_id'}).
  final Map<String, dynamic> payload;
  final DateTime criadoEm;
  final int tentativas;
  final String? ultimoErro;

  OutboxOperation({
    this.id,
    required this.perfilId,
    required this.tabela,
    required this.operacao,
    required this.payload,
    DateTime? criadoEm,
    this.tentativas = 0,
    this.ultimoErro,
  }) : criadoEm = criadoEm ?? DateTime.now();

  Map<String, Object?> toRow() => {
    if (id != null) 'id': id,
    'perfil_id': perfilId,
    'tabela': tabela,
    'operacao': operacao,
    'payload': jsonEncode(payload),
    'criado_em': criadoEm.toIso8601String(),
    'tentativas': tentativas,
    'ultimo_erro': ultimoErro,
  };

  factory OutboxOperation.fromRow(Map<String, Object?> row) => OutboxOperation(
    id: row['id'] as int?,
    perfilId: row['perfil_id'] as String,
    tabela: row['tabela'] as String,
    operacao: row['operacao'] as String,
    payload: Map<String, dynamic>.from(
      jsonDecode(row['payload'] as String) as Map,
    ),
    criadoEm: DateTime.tryParse(row['criado_em'] as String? ?? ''),
    tentativas: row['tentativas'] as int? ?? 0,
    ultimoErro: row['ultimo_erro'] as String?,
  );
}

/// Conteúdo do perfil guardado no aparelho, com as colunas do Supabase.
class LocalProfileContent {
  final List<Map<String, dynamic>> boards;
  final List<Map<String, dynamic>> cards;
  final List<Map<String, dynamic>> links;
  final DateTime? lastPull;

  const LocalProfileContent({
    required this.boards,
    required this.cards,
    required this.links,
    this.lastPull,
  });
}

/// Catálogo global ARASAAC guardado no aparelho (não é por perfil).
class CatalogData {
  final String version;

  /// {key, label, parentKey, order}
  final List<Map<String, dynamic>> categories;

  /// id -> {label, fitz}
  final Map<String, Map<String, dynamic>> pictograms;

  /// categoryKey -> ids na ordem
  final Map<String, List<String>> pictogramsByCategory;
  final List<String> principalIds;

  const CatalogData({
    required this.version,
    required this.categories,
    required this.pictograms,
    required this.pictogramsByCategory,
    required this.principalIds,
  });
}

abstract class LocalContentStore {
  // ---- conteúdo do perfil -------------------------------------------------
  Future<LocalProfileContent?> loadProfileContent(String perfilId);
  Future<void> replaceProfileContent(
    String perfilId, {
    required List<Map<String, dynamic>> boards,
    required List<Map<String, dynamic>> cards,
    required List<Map<String, dynamic>> links,
  });
  Future<void> upsertBoard(Map<String, dynamic> row);
  Future<void> deleteBoard(String id);
  Future<void> upsertCard(Map<String, dynamic> row);
  Future<void> deleteCard(String id);
  Future<void> upsertLink(Map<String, dynamic> row);
  Future<void> deleteLink(String pranchaId, String cartaoId);
  Future<void> deleteLinksOfBoard(String pranchaId);
  Future<void> deleteProfile(String perfilId);

  // ---- fila de sincronização ---------------------------------------------
  Future<void> enqueue(OutboxOperation operation);
  Future<List<OutboxOperation>> pendingOperations();
  Future<int> pendingCount();
  Future<void> markDone(int id);
  Future<void> markFailed(int id, String error);

  // ---- catálogo ARASAAC ---------------------------------------------------
  Future<String?> catalogVersion();
  Future<void> saveCatalog(CatalogData catalog);
  Future<CatalogData?> loadCatalog();
}

/// Implementação em memória, usada nos testes e como reserva se o SQLite não
/// puder ser aberto no mobile.
class InMemoryContentStore implements LocalContentStore {
  final Map<String, Map<String, dynamic>> _boards = {};
  final Map<String, Map<String, dynamic>> _cards = {};
  final Map<String, Map<String, dynamic>> _links = {};
  final Map<String, DateTime> _lastPull = {};
  final List<OutboxOperation> _outbox = [];
  int _nextOutboxId = 1;
  CatalogData? _catalog;

  String _linkKey(String pranchaId, String cartaoId) => '$pranchaId|$cartaoId';

  @override
  Future<LocalProfileContent?> loadProfileContent(String perfilId) async {
    if (!_lastPull.containsKey(perfilId)) return null;
    final boards =
        _boards.values
            .where((b) => b['perfil_id'] == perfilId)
            .map((b) => Map<String, dynamic>.from(b))
            .toList()
          ..sort(
            (a, b) =>
                (a['ordem'] as int? ?? 0).compareTo(b['ordem'] as int? ?? 0),
          );
    final boardIds = boards.map((b) => b['id']).toSet();
    return LocalProfileContent(
      boards: boards,
      cards: _cards.values
          .where((c) => c['perfil_id'] == perfilId)
          .map((c) => Map<String, dynamic>.from(c))
          .toList(),
      links: _links.values
          .where((l) => boardIds.contains(l['prancha_id']))
          .map((l) => Map<String, dynamic>.from(l))
          .toList(),
      lastPull: _lastPull[perfilId],
    );
  }

  @override
  Future<void> replaceProfileContent(
    String perfilId, {
    required List<Map<String, dynamic>> boards,
    required List<Map<String, dynamic>> cards,
    required List<Map<String, dynamic>> links,
  }) async {
    await deleteProfile(perfilId);
    for (final b in boards) {
      _boards[b['id'] as String] = Map<String, dynamic>.from(b);
    }
    for (final c in cards) {
      _cards[c['id'] as String] = Map<String, dynamic>.from(c);
    }
    for (final l in links) {
      _links[_linkKey(l['prancha_id'] as String, l['cartao_id'] as String)] =
          Map<String, dynamic>.from(l);
    }
    _lastPull[perfilId] = DateTime.now();
  }

  @override
  Future<void> upsertBoard(Map<String, dynamic> row) async =>
      _boards[row['id'] as String] = Map<String, dynamic>.from(row);

  @override
  Future<void> deleteBoard(String id) async {
    _boards.remove(id);
    await deleteLinksOfBoard(id);
  }

  @override
  Future<void> upsertCard(Map<String, dynamic> row) async =>
      _cards[row['id'] as String] = Map<String, dynamic>.from(row);

  @override
  Future<void> deleteCard(String id) async {
    _cards.remove(id);
    _links.removeWhere((_, l) => l['cartao_id'] == id);
  }

  @override
  Future<void> upsertLink(Map<String, dynamic> row) async =>
      _links[_linkKey(
        row['prancha_id'] as String,
        row['cartao_id'] as String,
      )] = Map<String, dynamic>.from(
        row,
      );

  @override
  Future<void> deleteLink(String pranchaId, String cartaoId) async =>
      _links.remove(_linkKey(pranchaId, cartaoId));

  @override
  Future<void> deleteLinksOfBoard(String pranchaId) async =>
      _links.removeWhere((_, l) => l['prancha_id'] == pranchaId);

  @override
  Future<void> deleteProfile(String perfilId) async {
    final boardIds = _boards.values
        .where((b) => b['perfil_id'] == perfilId)
        .map((b) => b['id'])
        .toSet();
    _boards.removeWhere((_, b) => b['perfil_id'] == perfilId);
    _cards.removeWhere((_, c) => c['perfil_id'] == perfilId);
    _links.removeWhere((_, l) => boardIds.contains(l['prancha_id']));
    _lastPull.remove(perfilId);
  }

  @override
  Future<void> enqueue(OutboxOperation operation) async {
    _outbox.add(
      OutboxOperation(
        id: _nextOutboxId++,
        perfilId: operation.perfilId,
        tabela: operation.tabela,
        operacao: operation.operacao,
        payload: operation.payload,
        criadoEm: operation.criadoEm,
      ),
    );
  }

  @override
  Future<List<OutboxOperation>> pendingOperations() async => List.of(_outbox);

  @override
  Future<int> pendingCount() async => _outbox.length;

  @override
  Future<void> markDone(int id) async =>
      _outbox.removeWhere((op) => op.id == id);

  @override
  Future<void> markFailed(int id, String error) async {
    final index = _outbox.indexWhere((op) => op.id == id);
    if (index < 0) return;
    final op = _outbox[index];
    _outbox[index] = OutboxOperation(
      id: op.id,
      perfilId: op.perfilId,
      tabela: op.tabela,
      operacao: op.operacao,
      payload: op.payload,
      criadoEm: op.criadoEm,
      tentativas: op.tentativas + 1,
      ultimoErro: error,
    );
  }

  @override
  Future<String?> catalogVersion() async => _catalog?.version;

  @override
  Future<void> saveCatalog(CatalogData catalog) async => _catalog = catalog;

  @override
  Future<CatalogData?> loadCatalog() async => _catalog;

  Map<String, dynamic> _persistentState() => {
    'boards': _boards.values.toList(),
    'cards': _cards.values.toList(),
    'links': _links.values.toList(),
    'lastPull': {
      for (final entry in _lastPull.entries)
        entry.key: entry.value.toIso8601String(),
    },
    'outbox': _outbox.map((operation) => operation.toRow()).toList(),
    'nextOutboxId': _nextOutboxId,
  };

  void _restorePersistentState(Map<String, dynamic> state) {
    for (final value in state['boards'] as List? ?? const []) {
      final row = Map<String, dynamic>.from(value as Map);
      _boards[row['id'] as String] = row;
    }
    for (final value in state['cards'] as List? ?? const []) {
      final row = Map<String, dynamic>.from(value as Map);
      _cards[row['id'] as String] = row;
    }
    for (final value in state['links'] as List? ?? const []) {
      final row = Map<String, dynamic>.from(value as Map);
      _links[_linkKey(
            row['prancha_id'] as String,
            row['cartao_id'] as String,
          )] =
          row;
    }
    final lastPull = state['lastPull'] as Map? ?? const {};
    for (final entry in lastPull.entries) {
      final date = DateTime.tryParse(entry.value as String);
      if (date != null) _lastPull[entry.key as String] = date;
    }
    for (final value in state['outbox'] as List? ?? const []) {
      _outbox.add(
        OutboxOperation.fromRow(Map<String, Object?>.from(value as Map)),
      );
    }
    _nextOutboxId =
        state['nextOutboxId'] as int? ??
        (_outbox.fold<int>(
              0,
              (max, operation) =>
                  (operation.id ?? 0) > max ? operation.id ?? 0 : max,
            ) +
            1);
  }
}

/// Persistência offline do Flutter Web usando o armazenamento do navegador.
class SharedPreferencesContentStore extends InMemoryContentStore {
  SharedPreferencesContentStore._(this._preferences);

  static const _stateKey = 'voxa.web.content.v1';
  final SharedPreferences _preferences;

  static Future<SharedPreferencesContentStore> open() async {
    final preferences = await SharedPreferences.getInstance();
    final store = SharedPreferencesContentStore._(preferences);
    final encoded = preferences.getString(_stateKey);
    if (encoded != null) {
      store._restorePersistentState(
        Map<String, dynamic>.from(jsonDecode(encoded) as Map),
      );
    }
    return store;
  }

  Future<void> _persist() async {
    await _preferences.setString(_stateKey, jsonEncode(_persistentState()));
  }

  @override
  Future<void> replaceProfileContent(
    String perfilId, {
    required List<Map<String, dynamic>> boards,
    required List<Map<String, dynamic>> cards,
    required List<Map<String, dynamic>> links,
  }) async {
    await super.replaceProfileContent(
      perfilId,
      boards: boards,
      cards: cards,
      links: links,
    );
    await _persist();
  }

  @override
  Future<void> upsertBoard(Map<String, dynamic> row) async {
    await super.upsertBoard(row);
    await _persist();
  }

  @override
  Future<void> deleteBoard(String id) async {
    await super.deleteBoard(id);
    await _persist();
  }

  @override
  Future<void> upsertCard(Map<String, dynamic> row) async {
    await super.upsertCard(row);
    await _persist();
  }

  @override
  Future<void> deleteCard(String id) async {
    await super.deleteCard(id);
    await _persist();
  }

  @override
  Future<void> upsertLink(Map<String, dynamic> row) async {
    await super.upsertLink(row);
    await _persist();
  }

  @override
  Future<void> deleteLink(String pranchaId, String cartaoId) async {
    await super.deleteLink(pranchaId, cartaoId);
    await _persist();
  }

  @override
  Future<void> deleteLinksOfBoard(String pranchaId) async {
    await super.deleteLinksOfBoard(pranchaId);
    await _persist();
  }

  @override
  Future<void> deleteProfile(String perfilId) async {
    await super.deleteProfile(perfilId);
    await _persist();
  }

  @override
  Future<void> enqueue(OutboxOperation operation) async {
    await super.enqueue(operation);
    await _persist();
  }

  @override
  Future<void> markDone(int id) async {
    await super.markDone(id);
    await _persist();
  }

  @override
  Future<void> markFailed(int id, String error) async {
    await super.markFailed(id, error);
    await _persist();
  }
}
