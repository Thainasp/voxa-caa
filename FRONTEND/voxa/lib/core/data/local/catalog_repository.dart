import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:voxa/core/utils/fitzgerald.dart';

import 'local_content_store.dart';

/// Catálogo global ARASAAC (somente leitura).
///
/// Antes, cada perfil recebia no Supabase uma cópia de 13.767 cartões,
/// 610 pranchas e ~26,8 mil associações. Isso deixava a Home lenta (tudo era
/// baixado a cada abertura) e fazia a exclusão de dependente estourar o tempo
/// do banco (erro 57014). Agora o catálogo fica só no aparelho, em SQLite, e o
/// Supabase guarda apenas o que o usuário criou.
class CatalogRepository {
  CatalogRepository(this._store);

  static const assetPath = 'assets/arasaac/catalogo_inicial.json';
  static const principalKey = 'Principal';

  /// Prefixo dos ids de cartões do catálogo (não são UUIDs do Supabase).
  static const cardIdPrefix = 'arasaac:';

  final LocalContentStore _store;
  CatalogData? _cache;

  /// Ids com PNG embutido no app (funcionam offline). Os demais usam o bucket
  /// público "arasaac-catalog" do Supabase.
  Set<String>? _bundledIds;

  Future<CatalogData> load() async {
    if (_cache != null) return _cache!;
    final json = await rootBundle.loadString(assetPath);
    final decoded = jsonDecode(json) as Map<String, dynamic>;
    final assetVersion = decoded['version'] as String;

    var catalog = await _store.catalogVersion() == assetVersion
        ? await _store.loadCatalog()
        : null;
    if (catalog == null) {
      catalog = _parse(decoded);
      await _store.saveCatalog(catalog);
    }
    _bundledIds ??= await _loadBundledIds();
    return _cache = catalog;
  }

  CatalogData _parse(Map<String, dynamic> decoded) {
    final categories = (decoded['categories'] as List)
        .map((value) => Map<String, dynamic>.from(value as Map))
        .toList();
    final pictograms = <String, Map<String, dynamic>>{
      for (final value in decoded['pictograms'] as List)
        (value as Map)['id'].toString(): {
          'label': value['label'],
          'fitz': value['fitz'],
        },
    };
    return CatalogData(
      version: decoded['version'] as String,
      categories: categories
          .map(
            (c) => <String, dynamic>{
              'key': c['key'],
              'label': c['label'],
              'parentKey': c['parentKey'],
              'order': c['order'],
            },
          )
          .toList(),
      pictograms: pictograms,
      pictogramsByCategory: {
        for (final c in categories)
          c['key'] as String: (c['pictogramIds'] as List)
              .map((id) => id.toString())
              .toList(),
      },
      principalIds: (decoded['principalIds'] as List)
          .map((id) => id.toString())
          .toList(),
    );
  }

  Future<Set<String>> _loadBundledIds() async {
    try {
      final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
      return manifest
          .listAssets()
          .where((path) => path.startsWith('assets/arasaac/') && path.endsWith('.png'))
          .map((path) => path.split('/').last.replaceAll('.png', ''))
          .toSet();
    } catch (_) {
      return <String>{};
    }
  }

  /// Monta as pranchas e cartões do catálogo no mesmo formato usado pela Home.
  ///
  /// [publicImageUrl] devolve a URL pública de um PNG do bucket do catálogo.
  ({List<Map<String, dynamic>> boards, Map<String, List> cardsByBoard}) build({
    required CatalogData catalog,
    required String Function(String arasaacId) publicImageUrl,
  }) {
    final bundled = _bundledIds ?? const <String>{};
    Map<String, dynamic> card(String id, String boardKey, int order) {
      final data = catalog.pictograms[id] ?? const {'label': '?'};
      return {
        'id': '$cardIdPrefix$id',
        'boardKey': boardKey,
        'order': order,
        'label': data['label'],
        'color': Fitzgerald.colorFor(data['fitz'] as String?),
        'icon': Icons.image_outlined,
        'imagePath': bundled.contains(id)
            ? 'assets/arasaac/$id.png'
            : publicImageUrl(id),
        'imageStoragePath': null,
        'audioPath': null,
        'arasaacId': id,
        'fitz': data['fitz'],
        'catalogoArasaac': true,
      };
    }

    final boards = <Map<String, dynamic>>[
      {
        'id': '${cardIdPrefix}board:$principalKey',
        'key': principalKey,
        'label': 'Início',
        'icon': Icons.home,
        'imagePath': null,
        'imageStoragePath': null,
        'audioPath': null,
        'catalogoArasaac': true,
        'parentKey': null,
      },
      for (final category in catalog.categories)
        {
          'id': '${cardIdPrefix}board:${category['key']}',
          'key': category['key'],
          'label': category['label'],
          'icon': Icons.category,
          'imagePath': null,
          'imageStoragePath': null,
          'audioPath': null,
          'catalogoArasaac': true,
          'parentKey': category['parentKey'],
        },
    ];

    final cardsByBoard = <String, List>{
      principalKey: [
        for (var i = 0; i < catalog.principalIds.length; i++)
          card(catalog.principalIds[i], principalKey, i),
      ],
      for (final entry in catalog.pictogramsByCategory.entries)
        entry.key: [
          for (var i = 0; i < entry.value.length; i++)
            card(entry.value[i], entry.key, i),
        ],
    };
    return (boards: boards, cardsByBoard: cardsByBoard);
  }
}
