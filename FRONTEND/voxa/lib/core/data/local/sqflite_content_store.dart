import 'dart:convert';

import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import 'local_content_store.dart';

/// Banco SQLite do aparelho (arquivo `voxa.db`).
///
/// - Catálogo global ARASAAC (610 categorias, 13.767 pictogramas): lido daqui
///   em vez de ser copiado para cada perfil no Supabase.
/// - Espelho do conteúdo do perfil (prancha, cartao, prancha_cartao): a Home
///   abre direto do aparelho, sem esperar a rede.
/// - Fila de sincronização (sync_outbox): alterações feitas sem Wi-Fi.
///
/// As linhas de prancha/cartão são guardadas em JSON (coluna `dados`) com as
/// mesmas colunas do Supabase, para que a mesma conversão sirva para dados
/// locais e remotos.
class SqfliteContentStore implements LocalContentStore {
  SqfliteContentStore._(this._db);

  static const _fileName = 'voxa.db';
  static const _schemaVersion = 1;

  final Database _db;

  static Future<SqfliteContentStore> open() async {
    final path = p.join(await getDatabasesPath(), _fileName);
    final db = await openDatabase(
      path,
      version: _schemaVersion,
      onCreate: (db, version) async {
        final batch = db.batch();
        batch.execute('''
          CREATE TABLE meta (chave TEXT PRIMARY KEY, valor TEXT)''');
        batch.execute('''
          CREATE TABLE catalog_categoria (
            chave TEXT PRIMARY KEY,
            nome TEXT NOT NULL,
            pai_chave TEXT,
            ordem INTEGER NOT NULL)''');
        batch.execute('''
          CREATE TABLE catalog_pictograma (
            id TEXT PRIMARY KEY,
            palavra TEXT NOT NULL,
            fitz TEXT)''');
        batch.execute('''
          CREATE TABLE catalog_categoria_pictograma (
            categoria_chave TEXT NOT NULL,
            pictograma_id TEXT NOT NULL,
            ordem INTEGER NOT NULL,
            PRIMARY KEY (categoria_chave, pictograma_id))''');
        batch.execute('''
          CREATE TABLE catalog_principal (
            pictograma_id TEXT PRIMARY KEY,
            ordem INTEGER NOT NULL)''');
        batch.execute('''
          CREATE TABLE prancha (
            id TEXT PRIMARY KEY,
            perfil_id TEXT NOT NULL,
            ordem INTEGER NOT NULL DEFAULT 0,
            dados TEXT NOT NULL)''');
        batch.execute('CREATE INDEX idx_prancha_perfil ON prancha (perfil_id)');
        batch.execute('''
          CREATE TABLE cartao (
            id TEXT PRIMARY KEY,
            perfil_id TEXT NOT NULL,
            dados TEXT NOT NULL)''');
        batch.execute('CREATE INDEX idx_cartao_perfil ON cartao (perfil_id)');
        batch.execute('''
          CREATE TABLE prancha_cartao (
            prancha_id TEXT NOT NULL,
            cartao_id TEXT NOT NULL,
            ordem INTEGER NOT NULL DEFAULT 0,
            PRIMARY KEY (prancha_id, cartao_id))''');
        batch.execute(
          'CREATE INDEX idx_prancha_cartao_cartao ON prancha_cartao (cartao_id)',
        );
        batch.execute('''
          CREATE TABLE perfil_sync (
            perfil_id TEXT PRIMARY KEY,
            ultimo_pull TEXT NOT NULL)''');
        batch.execute('''
          CREATE TABLE sync_outbox (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            perfil_id TEXT NOT NULL,
            tabela TEXT NOT NULL,
            operacao TEXT NOT NULL,
            payload TEXT NOT NULL,
            criado_em TEXT NOT NULL,
            tentativas INTEGER NOT NULL DEFAULT 0,
            ultimo_erro TEXT)''');
        await batch.commit(noResult: true);
      },
    );
    return SqfliteContentStore._(db);
  }

  // ---------------------------------------------------------------------------
  // Conteúdo do perfil
  // ---------------------------------------------------------------------------

  Map<String, dynamic> _decode(Object? json) =>
      Map<String, dynamic>.from(jsonDecode(json as String) as Map);

  @override
  Future<LocalProfileContent?> loadProfileContent(String perfilId) async {
    final sync = await _db.query(
      'perfil_sync',
      where: 'perfil_id = ?',
      whereArgs: [perfilId],
    );
    if (sync.isEmpty) return null;

    final boards = await _db.query(
      'prancha',
      where: 'perfil_id = ?',
      whereArgs: [perfilId],
      orderBy: 'ordem',
    );
    final cards = await _db.query(
      'cartao',
      where: 'perfil_id = ?',
      whereArgs: [perfilId],
    );
    final links = await _db.rawQuery(
      'SELECT pc.prancha_id, pc.cartao_id, pc.ordem '
      'FROM prancha_cartao pc JOIN prancha pr ON pr.id = pc.prancha_id '
      'WHERE pr.perfil_id = ? ORDER BY pc.prancha_id, pc.ordem',
      [perfilId],
    );

    return LocalProfileContent(
      boards: boards.map((row) => _decode(row['dados'])).toList(),
      cards: cards.map((row) => _decode(row['dados'])).toList(),
      links: links.map((row) => Map<String, dynamic>.from(row)).toList(),
      lastPull: DateTime.tryParse(sync.first['ultimo_pull'] as String),
    );
  }

  @override
  Future<void> replaceProfileContent(
    String perfilId, {
    required List<Map<String, dynamic>> boards,
    required List<Map<String, dynamic>> cards,
    required List<Map<String, dynamic>> links,
  }) async {
    await _db.transaction((txn) async {
      await _deleteProfile(txn, perfilId);
      final batch = txn.batch();
      for (final row in boards) {
        batch.insert('prancha', _boardRow(row));
      }
      for (final row in cards) {
        batch.insert('cartao', _cardRow(row));
      }
      for (final row in links) {
        batch.insert(
          'prancha_cartao',
          _linkRow(row),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      batch.insert('perfil_sync', {
        'perfil_id': perfilId,
        'ultimo_pull': DateTime.now().toIso8601String(),
      }, conflictAlgorithm: ConflictAlgorithm.replace);
      await batch.commit(noResult: true);
    });
  }

  Map<String, Object?> _boardRow(Map<String, dynamic> row) => {
    'id': row['id'],
    'perfil_id': row['perfil_id'],
    'ordem': row['ordem'] as int? ?? 0,
    'dados': jsonEncode(row),
  };

  Map<String, Object?> _cardRow(Map<String, dynamic> row) => {
    'id': row['id'],
    'perfil_id': row['perfil_id'],
    'dados': jsonEncode(row),
  };

  Map<String, Object?> _linkRow(Map<String, dynamic> row) => {
    'prancha_id': row['prancha_id'],
    'cartao_id': row['cartao_id'],
    'ordem': row['ordem'] as int? ?? 0,
  };

  @override
  Future<void> upsertBoard(Map<String, dynamic> row) async {
    await _db.insert(
      'prancha',
      _boardRow(row),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> deleteBoard(String id) async {
    await _db.transaction((txn) async {
      await txn.delete('prancha_cartao', where: 'prancha_id = ?', whereArgs: [id]);
      await txn.delete('prancha', where: 'id = ?', whereArgs: [id]);
    });
  }

  @override
  Future<void> upsertCard(Map<String, dynamic> row) async {
    await _db.insert(
      'cartao',
      _cardRow(row),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> deleteCard(String id) async {
    await _db.transaction((txn) async {
      await txn.delete('prancha_cartao', where: 'cartao_id = ?', whereArgs: [id]);
      await txn.delete('cartao', where: 'id = ?', whereArgs: [id]);
    });
  }

  @override
  Future<void> upsertLink(Map<String, dynamic> row) async {
    await _db.insert(
      'prancha_cartao',
      _linkRow(row),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> deleteLink(String pranchaId, String cartaoId) async {
    await _db.delete(
      'prancha_cartao',
      where: 'prancha_id = ? AND cartao_id = ?',
      whereArgs: [pranchaId, cartaoId],
    );
  }

  @override
  Future<void> deleteLinksOfBoard(String pranchaId) async {
    await _db.delete(
      'prancha_cartao',
      where: 'prancha_id = ?',
      whereArgs: [pranchaId],
    );
  }

  @override
  Future<void> deleteProfile(String perfilId) =>
      _db.transaction((txn) => _deleteProfile(txn, perfilId));

  Future<void> _deleteProfile(Transaction txn, String perfilId) async {
    await txn.rawDelete(
      'DELETE FROM prancha_cartao WHERE prancha_id IN '
      '(SELECT id FROM prancha WHERE perfil_id = ?)',
      [perfilId],
    );
    await txn.delete('prancha', where: 'perfil_id = ?', whereArgs: [perfilId]);
    await txn.delete('cartao', where: 'perfil_id = ?', whereArgs: [perfilId]);
    await txn.delete('perfil_sync', where: 'perfil_id = ?', whereArgs: [perfilId]);
  }

  // ---------------------------------------------------------------------------
  // Fila de sincronização
  // ---------------------------------------------------------------------------

  @override
  Future<void> enqueue(OutboxOperation operation) async {
    final row = operation.toRow()..remove('id');
    await _db.insert('sync_outbox', row);
  }

  @override
  Future<List<OutboxOperation>> pendingOperations() async {
    final rows = await _db.query('sync_outbox', orderBy: 'id');
    return rows.map(OutboxOperation.fromRow).toList();
  }

  @override
  Future<int> pendingCount() async {
    final result = await _db.rawQuery('SELECT COUNT(*) AS total FROM sync_outbox');
    return (result.first['total'] as int?) ?? 0;
  }

  @override
  Future<void> markDone(int id) async {
    await _db.delete('sync_outbox', where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<void> markFailed(int id, String error) async {
    await _db.rawUpdate(
      'UPDATE sync_outbox SET tentativas = tentativas + 1, ultimo_erro = ? '
      'WHERE id = ?',
      [error, id],
    );
  }

  // ---------------------------------------------------------------------------
  // Catálogo ARASAAC
  // ---------------------------------------------------------------------------

  @override
  Future<String?> catalogVersion() async {
    final rows = await _db.query(
      'meta',
      where: 'chave = ?',
      whereArgs: ['catalog_version'],
    );
    return rows.isEmpty ? null : rows.first['valor'] as String?;
  }

  @override
  Future<void> saveCatalog(CatalogData catalog) async {
    await _db.transaction((txn) async {
      await txn.delete('catalog_categoria_pictograma');
      await txn.delete('catalog_principal');
      await txn.delete('catalog_pictograma');
      await txn.delete('catalog_categoria');

      final batch = txn.batch();
      for (final category in catalog.categories) {
        batch.insert('catalog_categoria', {
          'chave': category['key'],
          'nome': category['label'],
          'pai_chave': category['parentKey'],
          'ordem': category['order'] as int? ?? 0,
        });
      }
      catalog.pictograms.forEach((id, data) {
        batch.insert('catalog_pictograma', {
          'id': id,
          'palavra': data['label'],
          'fitz': data['fitz'],
        });
      });
      catalog.pictogramsByCategory.forEach((categoryKey, ids) {
        for (var i = 0; i < ids.length; i++) {
          batch.insert(
            'catalog_categoria_pictograma',
            {'categoria_chave': categoryKey, 'pictograma_id': ids[i], 'ordem': i},
            conflictAlgorithm: ConflictAlgorithm.ignore,
          );
        }
      });
      for (var i = 0; i < catalog.principalIds.length; i++) {
        batch.insert(
          'catalog_principal',
          {'pictograma_id': catalog.principalIds[i], 'ordem': i},
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );
      }
      batch.insert('meta', {
        'chave': 'catalog_version',
        'valor': catalog.version,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
      await batch.commit(noResult: true);
    });
  }

  @override
  Future<CatalogData?> loadCatalog() async {
    final version = await catalogVersion();
    if (version == null) return null;

    final categories = await _db.query('catalog_categoria', orderBy: 'ordem');
    final pictograms = await _db.query('catalog_pictograma');
    final links = await _db.query(
      'catalog_categoria_pictograma',
      orderBy: 'categoria_chave, ordem',
    );
    final principal = await _db.query('catalog_principal', orderBy: 'ordem');

    final byCategory = <String, List<String>>{};
    for (final row in links) {
      byCategory
          .putIfAbsent(row['categoria_chave'] as String, () => [])
          .add(row['pictograma_id'] as String);
    }

    return CatalogData(
      version: version,
      categories: categories
          .map(
            (row) => <String, dynamic>{
              'key': row['chave'],
              'label': row['nome'],
              'parentKey': row['pai_chave'],
              'order': row['ordem'],
            },
          )
          .toList(),
      pictograms: {
        for (final row in pictograms)
          row['id'] as String: {'label': row['palavra'], 'fitz': row['fitz']},
      },
      pictogramsByCategory: byCategory,
      principalIds: principal.map((row) => row['pictograma_id'] as String).toList(),
    );
  }
}
