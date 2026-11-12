import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:voxa/models/user_model.dart';

class HomeContentController {
  static List boards = [];
  static Map<String, List> cardsByBoard = {};
  static List<Map<String, dynamic>> get editableBoards => boards
      .whereType<Map>()
      .where((board) => board['catalogoArasaac'] != true)
      .map((board) => Map<String, dynamic>.from(board))
      .toList();
  static List<Map<String, dynamic>> get boardsWithUserCreatedFirst {
    final allBoards = boards
        .whereType<Map>()
        .map((board) => Map<String, dynamic>.from(board))
        .toList();
    return [
      ...allBoards.where((board) => board['catalogoArasaac'] != true),
      ...allBoards.where((board) => board['catalogoArasaac'] == true),
    ];
  }

  static String? _activeProfileId;
  static SupabaseClient? clientForTesting;
  static SupabaseClient get _client =>
      clientForTesting ?? Supabase.instance.client;
  static int _idCounter = 0;
  static const _imageBucket = 'content-images';
  static const _catalogBucket = 'arasaac-catalog';
  static const _signedUrlLifetimeSeconds = 3600;
  static const _catalogVersion = 'arasaac-2026-11-full-v2';

  static IconData _getIconData(String? iconName) {
    switch (iconName) {
      case 'home':
        return Icons.home;
      case 'restaurant':
        return Icons.restaurant;
      case 'restaurant_menu':
        return Icons.restaurant_menu;
      case 'directions_bus':
        return Icons.directions_bus;
      case 'help':
        return Icons.help;
      case 'local_drink':
        return Icons.local_drink;
      case 'apple':
        return Icons.apple;
      case 'woman':
        return Icons.woman;
      case 'man':
        return Icons.man;
      case 'school':
        return Icons.school;
      case 'medication':
        return Icons.medication;
      case 'bed':
        return Icons.bed;
      case 'wc':
        return Icons.wc;
      case 'pan_tool':
        return Icons.pan_tool;
      case 'emoji_emotions':
        return Icons.emoji_emotions;
      case 'sentiment_satisfied':
        return Icons.sentiment_satisfied;
      case 'sentiment_dissatisfied':
        return Icons.sentiment_dissatisfied;
      case 'battery_full':
        return Icons.battery_full;
      case 'healing':
        return Icons.healing;
      case 'mood_bad':
        return Icons.mood_bad;
      case 'sports_esports':
        return Icons.sports_esports;
      case 'menu_book':
        return Icons.menu_book;
      case 'brush':
        return Icons.brush;
      case 'music_note':
        return Icons.music_note;
      case 'tv':
        return Icons.tv;
      case 'person':
        return Icons.person;
      case 'medical_services':
        return Icons.medical_services;
      case 'groups':
        return Icons.groups;
      case 'place':
        return Icons.place;
      case 'volunteer_activism':
        return Icons.volunteer_activism;
      case 'check_circle':
        return Icons.check_circle;
      case 'cancel':
        return Icons.cancel;
      case 'add_circle':
        return Icons.add_circle;
      case 'remove_circle':
        return Icons.remove_circle;
      case 'hourglass_top':
        return Icons.hourglass_top;
      case 'warning':
        return Icons.warning;
      case 'category':
        return Icons.category;
      case 'phone_android':
        return Icons.phone_android;
      case 'toys':
        return Icons.toys;
      case 'sports_soccer':
        return Icons.sports_soccer;
      case 'checkroom':
        return Icons.checkroom;
      case 'headphones':
        return Icons.headphones;
      case 'rice_bowl':
        return Icons.rice_bowl;
      case 'soup_kitchen':
        return Icons.soup_kitchen;
      case 'dinner_dining':
        return Icons.dinner_dining;
      case 'local_bar':
        return Icons.local_bar;
      case 'dashboard_customize':
        return Icons.dashboard_customize;
      case 'park':
        return Icons.park;
      case 'local_hospital':
        return Icons.local_hospital;
      case 'store':
        return Icons.store;
      case 'folder':
        return Icons.folder;
      default:
        return Icons.image_outlined;
    }
  }

  static String _getIconName(IconData? icon) {
    const icons = <String, IconData>{
      'home': Icons.home,
      'restaurant': Icons.restaurant,
      'restaurant_menu': Icons.restaurant_menu,
      'directions_bus': Icons.directions_bus,
      'help': Icons.help,
      'local_drink': Icons.local_drink,
      'apple': Icons.apple,
      'woman': Icons.woman,
      'man': Icons.man,
      'school': Icons.school,
      'medication': Icons.medication,
      'bed': Icons.bed,
      'wc': Icons.wc,
      'pan_tool': Icons.pan_tool,
      'emoji_emotions': Icons.emoji_emotions,
      'sentiment_satisfied': Icons.sentiment_satisfied,
      'sentiment_dissatisfied': Icons.sentiment_dissatisfied,
      'battery_full': Icons.battery_full,
      'healing': Icons.healing,
      'mood_bad': Icons.mood_bad,
      'sports_esports': Icons.sports_esports,
      'menu_book': Icons.menu_book,
      'brush': Icons.brush,
      'music_note': Icons.music_note,
      'tv': Icons.tv,
      'person': Icons.person,
      'medical_services': Icons.medical_services,
      'groups': Icons.groups,
      'place': Icons.place,
      'volunteer_activism': Icons.volunteer_activism,
      'check_circle': Icons.check_circle,
      'cancel': Icons.cancel,
      'add_circle': Icons.add_circle,
      'remove_circle': Icons.remove_circle,
      'hourglass_top': Icons.hourglass_top,
      'warning': Icons.warning,
      'category': Icons.category,
      'phone_android': Icons.phone_android,
      'toys': Icons.toys,
      'sports_soccer': Icons.sports_soccer,
      'checkroom': Icons.checkroom,
      'headphones': Icons.headphones,
      'rice_bowl': Icons.rice_bowl,
      'soup_kitchen': Icons.soup_kitchen,
      'dinner_dining': Icons.dinner_dining,
      'local_bar': Icons.local_bar,
      'dashboard_customize': Icons.dashboard_customize,
      'park': Icons.park,
      'local_hospital': Icons.local_hospital,
      'store': Icons.store,
      'folder': Icons.folder,
      'image_outlined': Icons.image_outlined,
    };

    for (final entry in icons.entries) {
      if (entry.value.codePoint == icon?.codePoint) return entry.key;
    }
    return 'image_outlined';
  }

  static Color _hexToColor(String? hexString) {
    if (hexString == null || hexString.isEmpty) return Colors.teal;
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }

  static String _colorToHex(Color color) =>
      '#${color.toARGB32().toRadixString(16).padLeft(8, '0')}';

  static String _newId() =>
      '${DateTime.now().microsecondsSinceEpoch}-${_idCounter++}';

  static String _legacyStorageKey(String profileId) =>
      'voxa.content.$profileId';

  static Future<UserModel> resolveActiveProfile({
    required String authUserId,
    required String email,
    required UserModel? requestedProfile,
    required String fallbackName,
    String? avatarUrl,
  }) async {
    if (authUserId.trim().isEmpty) {
      throw ArgumentError.value(
        authUserId,
        'authUserId',
        'Não pode ser vazio.',
      );
    }

    final isAuthUserId =
        requestedProfile == null || requestedProfile.id == authUserId;
    final profileRow = isAuthUserId
        ? await _client
              .from('perfil')
              .select()
              .eq('usuario_id', authUserId)
              .eq('is_responsavel', true)
              .maybeSingle()
        : await _client
              .from('perfil')
              .select()
              .eq('id', requestedProfile.id)
              .eq('usuario_id', authUserId)
              .maybeSingle();

    if (profileRow == null && !isAuthUserId) {
      throw StateError(
        'O perfil selecionado não pertence à conta autenticada ou não existe.',
      );
    }

    final resolvedRow =
        profileRow ??
        await _client
            .from('perfil')
            .insert({
              'usuario_id': authUserId,
              'nome': fallbackName,
              'is_responsavel': true,
              ...?avatarUrl == null ? null : {'avatar_url': avatarUrl},
            })
            .select()
            .single();

    return UserModel(
      id: resolvedRow['id'] as String,
      name: resolvedRow['nome'] as String? ?? fallbackName,
      email: email,
      avatarUrl: resolvedRow['avatar_url'] as String? ?? avatarUrl,
      isResponsavel: resolvedRow['is_responsavel'] as bool? ?? isAuthUserId,
    );
  }

  static List<Map<String, dynamic>> _copyBoards() =>
      boards.map((board) => Map<String, dynamic>.from(board as Map)).toList();

  static Map<String, List> _copyCardsByBoard() => cardsByBoard.map(
    (key, cards) => MapEntry(
      key,
      cards.map((card) => Map<String, dynamic>.from(card as Map)).toList(),
    ),
  );

  static Future<void> loadContentForProfile(String profileId) async {
    if (profileId.trim().isEmpty) {
      throw ArgumentError.value(profileId, 'profileId', 'Não pode ser vazio.');
    }
    if (clientForTesting == null && _client.auth.currentUser == null) {
      throw const AuthException(
        'Entre na sua conta para carregar suas tábuas e cartões.',
      );
    }

    boards = [];
    cardsByBoard = {};
    _activeProfileId = profileId;
    final preferences = await SharedPreferences.getInstance();
    final legacyStorageKey = _legacyStorageKey(profileId);
    final legacyContent = preferences.getString(legacyStorageKey);
    var boardRows = await _client
        .from('prancha')
        .select()
        .eq('perfil_id', profileId)
        .order('ordem');
    if (boardRows.isEmpty && legacyContent != null) {
      await _client.rpc(
        'inicializar_conteudo_padrao',
        params: {
          'novo_perfil_id': profileId,
          'dados': _legacyContentPayload(legacyContent),
        },
      );
    }
    final catalogNeedsSync = await _client.rpc(
      'catalogo_arasaac_completo_necessita_sync',
      params: {'p_perfil_id': profileId, 'p_versao': _catalogVersion},
    ) as bool;
    if (catalogNeedsSync) {
      await _client.rpc(
        'sincronizar_catalogo_arasaac_completo',
        params: {
          'p_perfil_id': profileId,
          'p_versao': _catalogVersion,
          'p_dados': await _defaultContentPayload(),
        },
      );
    }
    boardRows = await _client
        .from('prancha')
        .select()
        .eq('perfil_id', profileId)
        .order('ordem');

    final loadedBoards = await Future.wait(
      boardRows.map(_mapBoardFromDatabase),
    );
    final boardIds = boardRows.map((board) => board['id'] as String).toList();
    final loadedCards = <String, List>{};
    for (final board in loadedBoards) {
      loadedCards[board['key'] as String] = [];
    }
    if (boardIds.isNotEmpty) {
      final associations = await _fetchAllAssociations(boardIds);
      final cardIds = associations
          .map((association) => association['cartao_id'] as String)
          .toSet()
          .toList();
      if (cardIds.isNotEmpty) {
        final cardRows = await _fetchAllCards(profileId, cardIds);
        final cardById = {
          for (final card in cardRows) card['id'] as String: card,
        };
        final boardKeyById = {
          for (final board in loadedBoards) board['id']: board['key'],
        };
        for (final association in associations) {
          final card = cardById[association['cartao_id']];
          final boardKey = boardKeyById[association['prancha_id']];
          if (card == null || boardKey == null) continue;
          (loadedCards[boardKey] as List).add(
            await _mapCardFromDatabase(
              card,
              boardKey,
              association['ordem'] as int? ?? 0,
            ),
          );
        }
      }
    }
    boards = loadedBoards;
    cardsByBoard = loadedCards;
    if (boardRows.isNotEmpty && legacyContent != null) {
      await preferences.remove(legacyStorageKey);
    }
  }

  static Future<List<Map<String, dynamic>>> _fetchAllAssociations(
    List<String> boardIds,
  ) async {
    const pageSize = 1000;
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
            .range(offset, offset + pageSize - 1);
        rows.addAll(List<Map<String, dynamic>>.from(page));
        if (page.length < pageSize) break;
        offset += pageSize;
      }
    }
    return rows;
  }

  static Future<List<Map<String, dynamic>>> _fetchAllCards(
    String profileId,
    List<String> cardIds,
  ) async {
    const pageSize = 1000;
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
            .eq('perfil_id', profileId)
            .inFilter('id', ids)
            .range(offset, offset + pageSize - 1);
        rows.addAll(List<Map<String, dynamic>>.from(page));
        if (page.length < pageSize) break;
        offset += pageSize;
      }
    }
    return rows;
  }

  static Map<String, dynamic> _legacyContentPayload(String content) {
    final decoded = jsonDecode(content);
    if (decoded is! Map<String, dynamic> ||
        decoded['boards'] is! List ||
        decoded['cardsByBoard'] is! Map<String, dynamic>) {
      throw const FormatException(
        'Os dados locais antigos de tábuas e cartões estão inválidos.',
      );
    }

    final cardsByKey = decoded['cardsByBoard'] as Map<String, dynamic>;
    return {
      'boards': (decoded['boards'] as List).asMap().entries.map((entry) {
        final board = Map<String, dynamic>.from(entry.value as Map);
        final key = board['key'] as String?;
        final cards = key == null ? null : cardsByKey[key];
        return {
          'key': key,
          'label': board['label'],
          'icon': board['icon'] ?? 'dashboard_customize',
          'imagePath': _safeLegacyImagePath(board['imagePath']),
          'audioPath': board['audioPath'],
          'order': entry.key,
          'cards': (cards is List ? cards : const <dynamic>[])
              .asMap()
              .entries
              .map((cardEntry) {
                final card = Map<String, dynamic>.from(cardEntry.value as Map);
                return {
                  'label': card['label'],
                  'color': card['color'] ?? '#ff00896b',
                  'icon': card['icon'] ?? 'image_outlined',
                  'imagePath': _safeLegacyImagePath(card['imagePath']),
                  'audioPath': card['audioPath'],
                  'arasaacId': card['arasaacId'],
                  'order': cardEntry.key,
                };
              })
              .toList(),
        };
      }).toList(),
    };
  }

  static String? _safeLegacyImagePath(dynamic value) {
    if (value is! String || value.isEmpty) return null;
    final uri = Uri.tryParse(value);
    if (uri != null &&
        uri.hasAuthority &&
        (uri.scheme == 'http' || uri.scheme == 'https')) {
      return value;
    }
    if (value.startsWith('assets/arasaac/') ||
        value.startsWith('assets/images/')) {
      return value;
    }
    return null;
  }

  static Future<Map<String, dynamic>> _defaultContentPayload() async {
    final catalogJson = await rootBundle.loadString(
      'assets/arasaac/catalogo_inicial.json',
    );
    final decoded = jsonDecode(catalogJson);
    if (decoded is! Map<String, dynamic> ||
        decoded['categories'] is! List ||
        decoded['pictograms'] is! List ||
        decoded['principalIds'] is! List ||
        decoded['categories'].length != 610 ||
        decoded['pictograms'].length != 13767) {
      throw const FormatException('O catálogo inicial ARASAAC está inválido.');
    }
    return {
      'categories': decoded['categories'],
      'pictograms': decoded['pictograms'],
      'principalIds': decoded['principalIds'],
    };
  }

  static Future<Map<String, dynamic>> _mapBoardFromDatabase(
    Map<String, dynamic> row,
  ) async {
    final storagePath = row['imagem_storage_path'] as String?;
    final isCatalogBoard = row['catalogo_arasaac'] as bool? ?? false;
    return {
      'id': row['id'],
      'key': row['chave'],
      'label': row['nome'],
      'icon': isCatalogBoard
          ? Icons.category
          : _getIconData(row['icone'] as String?),
      'imagePath': await _resolveImagePath(
        row['imagem_url'] as String?,
        storagePath,
      ),
      'imageStoragePath': storagePath,
      'audioPath': row['caminho_audio'],
      'catalogoArasaac': isCatalogBoard,
      'parentKey': row['catalogo_pai_chave'],
    };
  }

  static Future<Map<String, dynamic>> _mapCardFromDatabase(
    Map<String, dynamic> row,
    String boardKey,
    int order,
  ) async {
    final storagePath = row['imagem_storage_path'] as String?;
    final arasaacId = row['arasaac_id'] as String?;
    final imagePath = row['caminho_imagem'] as String?;
    return {
      'id': row['id'],
      'boardKey': boardKey,
      'order': order,
      'label': row['texto'],
      'color': _hexToColor(row['cor_hex'] as String?),
      'icon': _getIconData(row['icone'] as String?),
      'imagePath': storagePath != null && storagePath.isNotEmpty
          ? await _resolveImagePath(imagePath, storagePath)
          : arasaacId != null && imagePath == '$_catalogBucket/$arasaacId.png'
          ? _client.storage.from(_catalogBucket).getPublicUrl('$arasaacId.png')
          : imagePath,
      'imageStoragePath': storagePath,
      'audioPath': row['caminho_audio'],
      'arasaacId': arasaacId,
    };
  }

  static Future<String?> _resolveImagePath(
    String? imageUrl,
    String? storagePath,
  ) async {
    if (storagePath == null || storagePath.isEmpty) return imageUrl;
    return _client.storage
        .from(_imageBucket)
        .createSignedUrl(storagePath, _signedUrlLifetimeSeconds);
  }

  static Future<void> deleteBoard(String key) async {
    final profileId = _requireActiveProfile();
    final board = boards.cast<Map>().firstWhere(
      (item) => item['key'] == key,
      orElse: () => throw StateError('A tábua selecionada não existe mais.'),
    );
    final boardId = board['id'] as String;
    final associations = await _client
        .from('prancha_cartao')
        .select('cartao_id')
        .eq('prancha_id', boardId);
    final cardIds = associations
        .map((association) => association['cartao_id'] as String)
        .toSet()
        .toList();
    await _client.from('prancha_cartao').delete().eq('prancha_id', boardId);
    final boardImagePath = board['imageStoragePath'] as String?;
    await _client
        .from('prancha')
        .delete()
        .eq('id', boardId)
        .eq('perfil_id', profileId);
    boards = _copyBoards()..removeWhere((item) => item['id'] == boardId);
    cardsByBoard.remove(key);
    await _deleteUnlinkedCards(cardIds, profileId);
    if (boardImagePath != null) await _removeStoredImage(boardImagePath);
  }

  static Future<Map<String, dynamic>> saveCard(
    Map<String, dynamic> card,
    String boardKey, {
    required bool isNew,
  }) async {
    final profileId = _requireActiveProfile();
    final board = boards.cast<Map>().firstWhere(
      (item) => item['key'] == boardKey,
      orElse: () =>
          throw StateError('Selecione uma tábua válida para o cartão.'),
    );
    final label = (card['label'] as String? ?? '').trim();
    if (label.isEmpty) throw ArgumentError('O nome do cartão é obrigatório.');

    Map? existing;
    if (!isNew) {
      for (final items in cardsByBoard.values) {
        for (final item in items) {
          if (item['id'] == card['id']) {
            existing = item;
            break;
          }
        }
        if (existing != null) break;
      }
      if (existing == null) {
        throw StateError('O cartão selecionado não existe mais.');
      }
    }
    final oldStoragePath = existing?['imageStoragePath'] as String?;
    final uploadBytes = card['_imageBytes'];
    final String? uploadedStoragePath;
    if (uploadBytes is List<int>) {
      uploadedStoragePath = await _uploadContentImage(
        profileId,
        uploadBytes,
        card['_imageContentType'] as String? ?? 'image/jpeg',
      );
    } else {
      uploadedStoragePath = null;
    }

    final storagePath =
        uploadedStoragePath ?? card['imageStoragePath'] as String?;
    final imagePath = uploadedStoragePath == null
        ? card['imagePath'] as String?
        : await _resolveImagePath(null, uploadedStoragePath);
    final data = <String, dynamic>{
      'perfil_id': profileId,
      'texto': label,
      'cor_hex': _colorToHex(card['color'] as Color? ?? Colors.teal),
      'icone': _getIconName(card['icon'] as IconData?),
      'caminho_imagem': storagePath == null ? imagePath : null,
      'imagem_storage_path': storagePath,
      'caminho_audio': card['audioPath'],
      'arasaac_id': card['arasaacId'],
    };
    final order =
        card['order'] as int? ?? (cardsByBoard[boardKey]?.length ?? 0);
    String? insertedCardId;
    try {
      final Map<String, dynamic> row;
      if (isNew) {
        row = await _client.from('cartao').insert(data).select().single();
        insertedCardId = row['id'] as String;
        await _client.from('prancha_cartao').insert({
          'prancha_id': board['id'],
          'cartao_id': insertedCardId,
          'ordem': order,
        });
      } else {
        row = await _client
            .from('cartao')
            .update(data)
            .eq('id', card['id'])
            .eq('perfil_id', profileId)
            .select()
            .single();
        final previousBoardKey = existing!['boardKey'] as String;
        if (previousBoardKey != boardKey) {
          final targetAssociation = await _client
              .from('prancha_cartao')
              .select('cartao_id')
              .eq('prancha_id', board['id'])
              .eq('cartao_id', card['id'])
              .maybeSingle();
          if (targetAssociation == null) {
            await _client.from('prancha_cartao').insert({
              'prancha_id': board['id'],
              'cartao_id': card['id'],
              'ordem': order,
            });
          }
          await _client
              .from('prancha_cartao')
              .delete()
              .eq('prancha_id', _boardIdForKey(previousBoardKey))
              .eq('cartao_id', card['id']);
        } else {
          await _client
              .from('prancha_cartao')
              .update({'ordem': order})
              .eq('prancha_id', board['id'])
              .eq('cartao_id', card['id']);
        }
      }

      final savedCard = await _mapCardFromDatabase(row, boardKey, order);
      final nextCards = _copyCardsByBoard();
      final previousBoardKey = isNew ? null : existing!['boardKey'] as String;
      for (final entry in nextCards.entries) {
        final matchingCards = entry.value
            .where((item) => item['id'] == savedCard['id'])
            .toList();
        if (entry.key == boardKey) {
          final cardOrder = matchingCards.isEmpty
              ? order
              : matchingCards.first['order'] as int? ?? order;
          entry.value.removeWhere((item) => item['id'] == savedCard['id']);
          entry.value.add({
            ...savedCard,
            'boardKey': entry.key,
            'order': cardOrder,
          });
        } else if (previousBoardKey != boardKey &&
            entry.key == previousBoardKey) {
          entry.value.removeWhere((item) => item['id'] == savedCard['id']);
        } else if (matchingCards.isNotEmpty) {
          final cardOrder = matchingCards.first['order'] as int? ?? 0;
          entry.value
            ..removeWhere((item) => item['id'] == savedCard['id'])
            ..add({...savedCard, 'boardKey': entry.key, 'order': cardOrder});
        }
      }
      final boardCards = nextCards.putIfAbsent(boardKey, () => []);
      boardCards.sort(
        (first, second) => (first['order'] as int? ?? 0).compareTo(
          second['order'] as int? ?? 0,
        ),
      );
      cardsByBoard = nextCards;
      if (oldStoragePath != null &&
          oldStoragePath != storagePath &&
          oldStoragePath != uploadedStoragePath) {
        await _removeStoredImage(oldStoragePath);
      }
      return savedCard;
    } catch (_) {
      if (insertedCardId != null) {
        await _client
            .from('cartao')
            .delete()
            .eq('id', insertedCardId)
            .eq('perfil_id', profileId);
      }
      if (uploadedStoragePath != null) {
        await _removeStoredImage(uploadedStoragePath);
      }
      rethrow;
    }
  }

  static Future<void> deleteCard(Map<String, dynamic> card) async {
    final profileId = _requireActiveProfile();
    final id = card['id'];
    if (id == null) throw ArgumentError('O cartão não tem um identificador.');
    final boardKey = card['boardKey'] as String?;
    if (boardKey == null) {
      throw ArgumentError('O cartão não está associado a uma tábua.');
    }
    await _client
        .from('prancha_cartao')
        .delete()
        .eq('prancha_id', _boardIdForKey(boardKey))
        .eq('cartao_id', id);
    cardsByBoard[boardKey]?.removeWhere((item) => item['id'] == id);
    await _deleteUnlinkedCards([id as String], profileId);
  }

  static Future<void> _deleteUnlinkedCards(
    List<String> cardIds,
    String profileId,
  ) async {
    if (cardIds.isEmpty) return;
    final remainingAssociations = await _client
        .from('prancha_cartao')
        .select('cartao_id')
        .inFilter('cartao_id', cardIds);
    final stillUsedIds = remainingAssociations
        .map((association) => association['cartao_id'] as String)
        .toSet();
    final orphanedIds = cardIds
        .where((cardId) => !stillUsedIds.contains(cardId))
        .toList();
    if (orphanedIds.isEmpty) return;

    final orphanedCards = await _client
        .from('cartao')
        .select('id, imagem_storage_path')
        .eq('perfil_id', profileId)
        .inFilter('id', orphanedIds);
    await _client
        .from('cartao')
        .delete()
        .eq('perfil_id', profileId)
        .inFilter('id', orphanedIds);
    await _removeStoredImages(orphanedCards);
  }

  static String _requireActiveProfile() {
    final profileId = _activeProfileId;
    if (profileId == null) {
      throw StateError('Carregue um perfil antes de alterar o conteúdo.');
    }
    if (clientForTesting == null && _client.auth.currentUser == null) {
      throw const AuthException(
        'Entre na sua conta para alterar tábuas e cartões.',
      );
    }
    return profileId;
  }

  static String _boardIdForKey(String key) =>
      boards.cast<Map>().firstWhere(
            (item) => item['key'] == key,
            orElse: () =>
                throw StateError('A tábua do cartão não existe mais.'),
          )['id']
          as String;

  static Future<String> _uploadContentImage(
    String profileId,
    List<int> bytes,
    String contentType,
  ) async {
    if (!const {
      'image/jpeg',
      'image/png',
      'image/webp',
      'image/gif',
    }.contains(contentType)) {
      throw ArgumentError('Formato de imagem não suportado.');
    }
    if (bytes.isEmpty || bytes.length > 5 * 1024 * 1024) {
      throw ArgumentError('A imagem deve ter entre 1 byte e 5 MB.');
    }
    final extension = switch (contentType) {
      'image/png' => 'png',
      'image/webp' => 'webp',
      'image/gif' => 'gif',
      _ => 'jpg',
    };
    final path = '$profileId/${_newId()}.$extension';
    await _client.storage
        .from(_imageBucket)
        .uploadBinary(
          path,
          Uint8List.fromList(bytes),
          fileOptions: FileOptions(contentType: contentType, upsert: false),
        );
    return path;
  }

  static Future<void> _removeStoredImages(List<dynamic> rows) async {
    final paths = rows
        .map((row) => row['imagem_storage_path'] as String?)
        .whereType<String>()
        .where((path) => path.isNotEmpty)
        .toList();
    if (paths.isNotEmpty) {
      await _client.storage.from(_imageBucket).remove(paths);
    }
  }

  static Future<void> _removeStoredImage(String path) async {
    await _client.storage.from(_imageBucket).remove([path]);
  }

  static Future<Map<String, dynamic>> saveBoard(
    Map<String, dynamic> board, {
    required bool isNew,
  }) async {
    final profileId = _requireActiveProfile();
    var boardKey = (board['key'] as String? ?? '').trim();
    final label = (board['label'] as String? ?? '').trim();
    if (boardKey.isEmpty || label.isEmpty) {
      throw ArgumentError('Nome e chave da tábua são obrigatórios.');
    }

    if (isNew) {
      final baseKey = boardKey;
      var suffix = 2;
      while (boards.any((item) => item['key'] == boardKey)) {
        boardKey = '$baseKey-$suffix';
        suffix++;
      }
    }

    final oldStoragePath = isNew
        ? null
        : boards.cast<Map>().firstWhere(
                (item) => item['id'] == board['id'],
                orElse: () =>
                    throw StateError('A tábua selecionada não existe mais.'),
              )['imageStoragePath']
              as String?;
    final uploadBytes = board['_imageBytes'];
    final String? uploadedStoragePath;
    if (uploadBytes is List<int>) {
      uploadedStoragePath = await _uploadContentImage(
        profileId,
        uploadBytes,
        board['_imageContentType'] as String? ?? 'image/jpeg',
      );
    } else {
      uploadedStoragePath = null;
    }

    final storagePath =
        uploadedStoragePath ?? board['imageStoragePath'] as String?;
    final imagePath = uploadedStoragePath == null
        ? board['imagePath'] as String?
        : await _resolveImagePath(null, uploadedStoragePath);
    final data = {
      'perfil_id': profileId,
      'chave': boardKey,
      'nome': label,
      'icone': _getIconName(board['icon'] as IconData?),
      'imagem_url': storagePath == null ? imagePath : null,
      'imagem_storage_path': storagePath,
      'caminho_audio': board['audioPath'],
    };
    if (isNew) {
      data['chave'] = boardKey;
    }

    try {
      final Map<String, dynamic> row;
      if (isNew) {
        row = await _client.from('prancha').insert(data).select().single();
      } else {
        final id = board['id'];
        if (id == null) {
          throw ArgumentError('A tábua não tem um identificador.');
        }
        data.remove('perfil_id');
        data.remove('chave');
        row = await _client
            .from('prancha')
            .update(data)
            .eq('id', id)
            .eq('perfil_id', profileId)
            .select()
            .single();
      }

      final savedBoard = await _mapBoardFromDatabase(row);
      final nextBoards = _copyBoards();
      final index = nextBoards.indexWhere(
        (item) => item['id'] == savedBoard['id'],
      );
      if (index < 0) {
        nextBoards.add(savedBoard);
        cardsByBoard.putIfAbsent(savedBoard['key'] as String, () => []);
      } else {
        nextBoards[index] = savedBoard;
      }
      boards = nextBoards;
      if (oldStoragePath != null &&
          oldStoragePath != storagePath &&
          oldStoragePath != uploadedStoragePath) {
        await _removeStoredImage(oldStoragePath);
      }
      return savedBoard;
    } catch (_) {
      if (uploadedStoragePath != null) {
        await _removeStoredImage(uploadedStoragePath);
      }
      rethrow;
    }
  }
}
