import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:voxa/core/data/local/catalog_repository.dart';
import 'package:voxa/core/data/local/local_content_store.dart';
import 'package:voxa/core/data/remote/content_api.dart';
import 'package:voxa/core/services/app_services.dart';
import 'package:voxa/core/services/connectivity_service.dart';
import 'package:voxa/core/utils/uuid.dart';
import 'package:voxa/models/user_model.dart';

/// Conteúdo (pranchas e cartões) do perfil ativo.
///
/// Fluxo offline-first (Correções itens 2, 3 e 4):
/// 1. O catálogo ARASAAC vem do SQLite do aparelho (CatalogRepository).
/// 2. O conteúdo criado pelo usuário abre direto do SQLite; a nuvem é
///    consultada em segundo plano e, quando muda, a Home recarrega.
/// 3. Alterações com Wi-Fi vão direto ao Supabase (e são espelhadas no
///    SQLite). Sem Wi-Fi, ficam no SQLite e entram na fila de sincronização.
///
/// Toda chamada de rede passa pela [ContentApi] (camada de rede).
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
  static String? get activeProfileId => _activeProfileId;

  // ---------------------------------------------------------------------------
  // Dependências (substituíveis nos testes)
  // ---------------------------------------------------------------------------

  static SupabaseClient? _clientForTesting;
  static LocalContentStore? _testStore;
  static CatalogRepository? _testCatalog;

  /// Nos testes o controller usa este cliente, um SQLite em memória, considera
  /// que há Wi-Fi e não carrega o catálogo (a não ser que
  /// [catalogEnabledForTesting] seja true).
  static SupabaseClient? get clientForTesting => _clientForTesting;
  static set clientForTesting(SupabaseClient? client) {
    _clientForTesting = client;
    _testStore = null;
    _testCatalog = null;
    catalogEnabledForTesting = false;
  }

  static bool catalogEnabledForTesting = false;

  static bool get _testing => _clientForTesting != null;
  static SupabaseClient get _client =>
      _clientForTesting ?? Supabase.instance.client;
  static ContentApi get _api => _testing
      ? ContentApi(_clientForTesting!)
      : AppServices.instance.contentApi;
  static LocalContentStore get _store => _testing
      ? (_testStore ??= InMemoryContentStore())
      : AppServices.instance.store;
  static CatalogRepository? get _catalog {
    if (_testing) {
      return catalogEnabledForTesting
          ? (_testCatalog ??= CatalogRepository(_store))
          : null;
    }
    return AppServices.instance.catalog;
  }

  static int _idCounter = 0;
  static const _catalogBucket = ContentApi.catalogBucket;
  static const _imageTimeout = Duration(seconds: 4);

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

  static String _profileCacheKey(String authUserId, String slot) =>
      'voxa.profile.$authUserId.$slot';

  // ---------------------------------------------------------------------------
  // Perfil ativo
  // ---------------------------------------------------------------------------

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
    try {
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

      final profile = UserModel(
        id: resolvedRow['id'] as String,
        name: resolvedRow['nome'] as String? ?? fallbackName,
        email: email,
        avatarUrl: resolvedRow['avatar_url'] as String? ?? avatarUrl,
        isResponsavel: resolvedRow['is_responsavel'] as bool? ?? isAuthUserId,
      );
      await _cacheProfile(authUserId, profile);
      return profile;
    } catch (error) {
      if (!_isNetworkError(error)) rethrow;
      // Sem rede: usa o último perfil conhecido para o app abrir offline.
      if (!isAuthUserId) return requestedProfile!;
      final cached = await _cachedProfile(authUserId, 'master');
      if (cached != null) return cached;
      rethrow;
    }
  }

  static Future<void> _cacheProfile(String authUserId, UserModel profile) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = jsonEncode(profile.toMap());
      await prefs.setString(_profileCacheKey(authUserId, profile.id), json);
      if (profile.isResponsavel) {
        await prefs.setString(_profileCacheKey(authUserId, 'master'), json);
      }
    } catch (_) {}
  }

  static Future<UserModel?> _cachedProfile(String authUserId, String slot) async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_profileCacheKey(authUserId, slot));
    if (json == null) return null;
    return UserModel.fromMap(Map<String, dynamic>.from(jsonDecode(json) as Map));
  }

  // ---------------------------------------------------------------------------
  // Carregamento
  // ---------------------------------------------------------------------------

  static List<Map<String, dynamic>> _copyBoards() =>
      boards.map((board) => Map<String, dynamic>.from(board as Map)).toList();

  static Map<String, List> _copyCardsByBoard() => cardsByBoard.map(
    (key, cards) => MapEntry(
      key,
      cards.map((card) => Map<String, dynamic>.from(card as Map)).toList(),
    ),
  );

  /// Carrega o conteúdo do perfil.
  ///
  /// Com cache local: devolve na hora e atualiza pela nuvem em segundo plano.
  /// Sem cache (primeira vez neste aparelho): baixa da nuvem em qualquer rede,
  /// para o perfil não abrir vazio; depois disso só sincroniza no Wi-Fi.
  static Future<void> loadContentForProfile(String profileId) async {
    if (profileId.trim().isEmpty) {
      throw ArgumentError.value(profileId, 'profileId', 'Não pode ser vazio.');
    }
    if (!_testing && _client.auth.currentUser == null) {
      throw const AuthException(
        'Entre na sua conta para carregar suas tábuas e cartões.',
      );
    }

    boards = [];
    cardsByBoard = {};
    _activeProfileId = profileId;
    if (!_testing) AppServices.instance.sync.setActiveProfile(profileId);

    final catalog = await _buildCatalog();
    final local = _testing ? null : await _store.loadProfileContent(profileId);

    if (local != null) {
      await _apply(local.boards, local.cards, local.links, catalog);
      final sync = AppServices.instance.sync;
      if (sync.canSyncNow) unawaited(sync.sync());
      return;
    }

    try {
      await _downloadProfile(profileId, catalog);
    } catch (error) {
      // Sem rede e sem cache: mostra ao menos o catálogo ARASAAC.
      await _apply(const [], const [], const [], catalog);
      if (_isNetworkError(error)) {
        throw const SocketException(
          'Sem conexão: suas pranchas pessoais aparecem quando houver internet.',
        );
      }
      rethrow;
    }
  }

  /// Recarrega do SQLite (chamado quando a sincronização trouxe novidades).
  static Future<void> reloadFromLocal() async {
    final profileId = _activeProfileId;
    if (profileId == null) return;
    final local = await _store.loadProfileContent(profileId);
    if (local == null) return;
    await _apply(local.boards, local.cards, local.links, await _buildCatalog());
  }

  static Future<void> _downloadProfile(
    String profileId,
    ({List<Map<String, dynamic>> boards, Map<String, List> cardsByBoard})?
    catalog,
  ) async {
    final preferences = await SharedPreferences.getInstance();
    final legacyStorageKey = _legacyStorageKey(profileId);
    final legacyContent = preferences.getString(legacyStorageKey);

    var remote = await _api.fetchProfileContent(profileId);
    if (remote.boards.isEmpty && legacyContent != null) {
      await _api.migrateLegacyContent(
        profileId,
        _legacyContentPayload(legacyContent),
      );
      remote = await _api.fetchProfileContent(profileId);
    }
    await _store.replaceProfileContent(
      profileId,
      boards: remote.boards,
      cards: remote.cards,
      links: remote.links,
    );
    await _apply(remote.boards, remote.cards, remote.links, catalog);
    if (remote.boards.isNotEmpty && legacyContent != null) {
      await preferences.remove(legacyStorageKey);
    }
  }

  static Future<
    ({List<Map<String, dynamic>> boards, Map<String, List> cardsByBoard})?
  >
  _buildCatalog() async {
    final repository = _catalog;
    if (repository == null) return null;
    final data = await repository.load();
    return repository.build(
      catalog: data,
      publicImageUrl: _api.catalogImageUrl,
    );
  }

  static Future<void> _apply(
    List<Map<String, dynamic>> boardRows,
    List<Map<String, dynamic>> cardRows,
    List<Map<String, dynamic>> links,
    ({List<Map<String, dynamic>> boards, Map<String, List> cardsByBoard})?
    catalog,
  ) async {
    final userBoards = await Future.wait(boardRows.map(_mapBoardFromDatabase));
    final userCards = <String, List>{
      for (final board in userBoards) board['key'] as String: [],
    };
    final cardById = {for (final card in cardRows) card['id'] as String: card};
    final boardKeyById = {
      for (final board in userBoards) board['id']: board['key'],
    };
    final sortedLinks = [...links]
      ..sort(
        (a, b) => (a['ordem'] as int? ?? 0).compareTo(b['ordem'] as int? ?? 0),
      );
    for (final link in sortedLinks) {
      final card = cardById[link['cartao_id']];
      final boardKey = boardKeyById[link['prancha_id']];
      if (card == null || boardKey == null) continue;
      (userCards[boardKey] as List).add(
        await _mapCardFromDatabase(card, boardKey, link['ordem'] as int? ?? 0),
      );
    }

    final userKeys = userBoards.map((b) => b['key']).toSet();
    boards = [
      ...userBoards,
      ...?catalog?.boards.where((b) => !userKeys.contains(b['key'])),
    ];
    cardsByBoard = {
      ...?catalog?.cardsByBoard,
      ...userCards,
    };
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

  static Future<Map<String, dynamic>> _mapBoardFromDatabase(
    Map<String, dynamic> row,
  ) async {
    final storagePath = row['imagem_storage_path'] as String?;
    final isCatalogBoard = row['catalogo_arasaac'] as bool? ?? false;
    final localImage = row['_local_image_path'] as String?;
    return {
      'id': row['id'],
      'key': row['chave'],
      'label': row['nome'],
      'icon': isCatalogBoard
          ? Icons.category
          : _getIconData(row['icone'] as String?),
      'imagePath':
          localImage ??
          await _resolveImagePath(row['imagem_url'] as String?, storagePath),
      'imageStoragePath': storagePath,
      'audioPath': row['caminho_audio'],
      'order': row['ordem'] as int? ?? 0,
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
    final localImage = row['_local_image_path'] as String?;
    return {
      'id': row['id'],
      'boardKey': boardKey,
      'order': order,
      'label': row['texto'],
      'color': _hexToColor(row['cor_hex'] as String?),
      'icon': _getIconData(row['icone'] as String?),
      'imagePath': localImage != null
          ? localImage
          : storagePath != null && storagePath.isNotEmpty
          ? await _resolveImagePath(imagePath, storagePath)
          : arasaacId != null && imagePath == '$_catalogBucket/$arasaacId.png'
          ? _api.catalogImageUrl(arasaacId)
          : imagePath,
      'imageStoragePath': storagePath,
      'audioPath': row['caminho_audio'],
      'arasaacId': arasaacId,
    };
  }

  /// URL assinada das imagens privadas. Sem rede devolve null e o cartão
  /// mostra o ícone (a assinatura exige uma requisição ao Storage).
  static Future<String?> _resolveImagePath(
    String? imageUrl,
    String? storagePath,
  ) async {
    if (storagePath == null || storagePath.isEmpty) return imageUrl;
    if (!_testing &&
        AppServices.instance.sync.network == NetworkStatus.offline) {
      return null;
    }
    try {
      return await _api.signedImageUrl(storagePath).timeout(_imageTimeout);
    } catch (_) {
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // Decisão online/offline
  // ---------------------------------------------------------------------------

  /// true: grava direto no Supabase. false: grava no SQLite e enfileira.
  static Future<bool> _useRemote() async {
    if (_testing) return true;
    final sync = AppServices.instance.sync;
    if (!sync.canSyncNow) return false;
    if (sync.pending > 0) {
      // Envia antes o que estava na fila, para manter a ordem das alterações.
      await sync.sync();
      return sync.pending == 0 && sync.canSyncNow;
    }
    return true;
  }

  static Future<void> _enqueue(
    String tabela,
    String operacao,
    Map<String, dynamic> payload,
  ) async {
    await _store.enqueue(
      OutboxOperation(
        perfilId: _requireActiveProfile(),
        tabela: tabela,
        operacao: operacao,
        payload: payload,
      ),
    );
  }

  static Future<void> _afterOfflineChange() async {
    if (!_testing) await AppServices.instance.sync.onLocalChange();
  }

  static String _extensionFor(String contentType) => switch (contentType) {
    'image/png' => 'png',
    'image/webp' => 'webp',
    'image/gif' => 'gif',
    _ => 'jpg',
  };

  static void _validateImage(List<int> bytes, String contentType) {
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
  }

  /// Guarda a imagem escolhida offline até o próximo Wi-Fi.
  static Future<String> _saveImageLocally(List<int> bytes, String ext) async {
    final directory = await getApplicationDocumentsDirectory();
    final folder = Directory('${directory.path}/pending_images');
    await folder.create(recursive: true);
    final file = File('${folder.path}/${generateUuidV4()}.$ext');
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  }

  // ---------------------------------------------------------------------------
  // Pranchas
  // ---------------------------------------------------------------------------

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

    final existingBoard = isNew
        ? null
        : boards.cast<Map>().firstWhere(
            (item) => item['id'] == board['id'],
            orElse: () =>
                throw StateError('A tábua selecionada não existe mais.'),
          );
    final oldStoragePath = existingBoard?['imageStoragePath'] as String?;

    if (!await _useRemote()) {
      return _saveBoardOffline(
        board,
        profileId: profileId,
        boardKey: isNew ? boardKey : existingBoard!['key'] as String,
        label: label,
        isNew: isNew,
        existingBoard: existingBoard,
      );
    }

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

    try {
      final Map<String, dynamic> row;
      if (isNew) {
        row = await _api.insertBoard(data);
      } else {
        final id = board['id'];
        if (id == null) {
          throw ArgumentError('A tábua não tem um identificador.');
        }
        data.remove('perfil_id');
        data.remove('chave');
        row = await _api.updateBoard(id as String, profileId, data);
      }
      await _store.upsertBoard(row);

      final savedBoard = await _mapBoardFromDatabase(row);
      _putBoardInMemory(savedBoard);
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

  static Future<Map<String, dynamic>> _saveBoardOffline(
    Map<String, dynamic> board, {
    required String profileId,
    required String boardKey,
    required String label,
    required bool isNew,
    required Map? existingBoard,
  }) async {
    final id = isNew ? generateUuidV4() : board['id'] as String;
    String? storagePath = board['imageStoragePath'] as String?;
    String? localImagePath;
    final uploadBytes = board['_imageBytes'];
    final contentType = board['_imageContentType'] as String? ?? 'image/jpeg';
    if (uploadBytes is List<int>) {
      _validateImage(uploadBytes, contentType);
      final ext = _extensionFor(contentType);
      localImagePath = await _saveImageLocally(uploadBytes, ext);
      storagePath = '$profileId/${_newId()}.$ext';
    }
    final row = <String, dynamic>{
      'id': id,
      'perfil_id': profileId,
      'chave': boardKey,
      'nome': label,
      'icone': _getIconName(board['icon'] as IconData?),
      'imagem_url': storagePath == null ? board['imagePath'] as String? : null,
      'imagem_storage_path': storagePath,
      'caminho_audio': board['audioPath'],
      'ordem': existingBoard?['order'] as int? ?? editableBoards.length,
      'catalogo_arasaac': false,
    };
    await _store.upsertBoard({
      ...row,
      if (localImagePath != null) '_local_image_path': localImagePath,
    });
    await _enqueue('prancha', 'upsert', {
      ...row,
      if (localImagePath != null) '_local_image_path': localImagePath,
      if (localImagePath != null) '_image_content_type': contentType,
    });

    final savedBoard = await _mapBoardFromDatabase({
      ...row,
      if (localImagePath != null) '_local_image_path': localImagePath,
    });
    if (localImagePath == null && storagePath != null) {
      // Mantém a imagem que já aparecia (URL assinada anterior).
      savedBoard['imagePath'] = existingBoard?['imagePath'];
    }
    _putBoardInMemory(savedBoard);
    await _afterOfflineChange();
    return savedBoard;
  }

  static void _putBoardInMemory(Map<String, dynamic> savedBoard) {
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
  }

  static Future<void> deleteBoard(String key) async {
    final profileId = _requireActiveProfile();
    final board = boards.cast<Map>().firstWhere(
      (item) => item['key'] == key,
      orElse: () => throw StateError('A tábua selecionada não existe mais.'),
    );
    if (board['catalogoArasaac'] == true) {
      throw StateError('As pranchas do catálogo ARASAAC não podem ser excluídas.');
    }
    final boardId = board['id'] as String;
    final boardImagePath = board['imageStoragePath'] as String?;

    if (!await _useRemote()) {
      final cardIds = <String>{
        for (final card in cardsByBoard[key] ?? const []) card['id'] as String,
      };
      await _store.deleteBoard(boardId);
      await _enqueue('prancha', 'delete', {
        'id': boardId,
        'imagem_storage_path': boardImagePath,
      });
      boards = _copyBoards()..removeWhere((item) => item['id'] == boardId);
      cardsByBoard.remove(key);
      await _deleteOrphansOffline(cardIds);
      await _afterOfflineChange();
      return;
    }

    final cardIds = await _api.fetchLinkedCardIds(boardId);
    await _api.deleteLinksOfBoard(boardId);
    await _api.deleteBoard(boardId, profileId);
    await _store.deleteBoard(boardId);
    boards = _copyBoards()..removeWhere((item) => item['id'] == boardId);
    cardsByBoard.remove(key);
    await _deleteUnlinkedCards(cardIds, profileId);
    if (boardImagePath != null) await _removeStoredImage(boardImagePath);
  }

  // ---------------------------------------------------------------------------
  // Cartões
  // ---------------------------------------------------------------------------

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
    if (board['catalogoArasaac'] == true) {
      throw StateError('Escolha uma prancha criada por você para o cartão.');
    }
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
    final order =
        card['order'] as int? ?? (cardsByBoard[boardKey]?.length ?? 0);

    if (!await _useRemote()) {
      return _saveCardOffline(
        card,
        profileId: profileId,
        board: board,
        boardKey: boardKey,
        label: label,
        order: order,
        existing: existing,
      );
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
    String? insertedCardId;
    try {
      final Map<String, dynamic> row;
      if (isNew) {
        row = await _api.insertCard(data);
        insertedCardId = row['id'] as String;
        await _api.insertLink({
          'prancha_id': board['id'],
          'cartao_id': insertedCardId,
          'ordem': order,
        });
        await _store.upsertLink({
          'prancha_id': board['id'],
          'cartao_id': insertedCardId,
          'ordem': order,
        });
      } else {
        row = await _api.updateCard(card['id'] as String, profileId, data);
        final previousBoardKey = existing!['boardKey'] as String;
        if (previousBoardKey != boardKey) {
          if (!await _api.linkExists(board['id'] as String, card['id'] as String)) {
            await _api.insertLink({
              'prancha_id': board['id'],
              'cartao_id': card['id'],
              'ordem': order,
            });
          }
          final previousBoardId = _boardIdForKey(previousBoardKey);
          await _api.deleteLink(previousBoardId, card['id'] as String);
          await _store.deleteLink(previousBoardId, card['id'] as String);
        } else {
          await _api.updateLinkOrder(
            board['id'] as String,
            card['id'] as String,
            order,
          );
        }
        await _store.upsertLink({
          'prancha_id': board['id'],
          'cartao_id': card['id'],
          'ordem': order,
        });
      }
      await _store.upsertCard(row);

      final savedCard = await _mapCardFromDatabase(row, boardKey, order);
      _putCardInMemory(
        savedCard,
        boardKey: boardKey,
        order: order,
        previousBoardKey: isNew ? null : existing!['boardKey'] as String,
      );
      if (oldStoragePath != null &&
          oldStoragePath != storagePath &&
          oldStoragePath != uploadedStoragePath) {
        await _removeStoredImage(oldStoragePath);
      }
      return savedCard;
    } catch (_) {
      if (insertedCardId != null) {
        await _api.deleteCard(insertedCardId, profileId);
      }
      if (uploadedStoragePath != null) {
        await _removeStoredImage(uploadedStoragePath);
      }
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> _saveCardOffline(
    Map<String, dynamic> card, {
    required String profileId,
    required Map board,
    required String boardKey,
    required String label,
    required int order,
    required Map? existing,
  }) async {
    final isNew = existing == null;
    final id = isNew ? generateUuidV4() : card['id'] as String;
    String? storagePath = card['imageStoragePath'] as String?;
    String? localImagePath;
    final uploadBytes = card['_imageBytes'];
    final contentType = card['_imageContentType'] as String? ?? 'image/jpeg';
    if (uploadBytes is List<int>) {
      _validateImage(uploadBytes, contentType);
      final ext = _extensionFor(contentType);
      localImagePath = await _saveImageLocally(uploadBytes, ext);
      storagePath = '$profileId/${_newId()}.$ext';
    }
    final row = <String, dynamic>{
      'id': id,
      'perfil_id': profileId,
      'texto': label,
      'cor_hex': _colorToHex(card['color'] as Color? ?? Colors.teal),
      'icone': _getIconName(card['icon'] as IconData?),
      'caminho_imagem': storagePath == null ? card['imagePath'] as String? : null,
      'imagem_storage_path': storagePath,
      'caminho_audio': card['audioPath'],
      'arasaac_id': card['arasaacId'],
    };
    final link = {'prancha_id': board['id'], 'cartao_id': id, 'ordem': order};

    await _store.upsertCard({
      ...row,
      if (localImagePath != null) '_local_image_path': localImagePath,
    });
    await _enqueue('cartao', 'upsert', {
      ...row,
      if (localImagePath != null) '_local_image_path': localImagePath,
      if (localImagePath != null) '_image_content_type': contentType,
    });
    await _store.upsertLink(link);
    await _enqueue('prancha_cartao', 'upsert', link);

    final previousBoardKey = existing?['boardKey'] as String?;
    if (previousBoardKey != null && previousBoardKey != boardKey) {
      final previousBoardId = _boardIdForKey(previousBoardKey);
      await _store.deleteLink(previousBoardId, id);
      await _enqueue('prancha_cartao', 'delete', {
        'prancha_id': previousBoardId,
        'cartao_id': id,
      });
    }

    final savedCard = await _mapCardFromDatabase(
      {...row, if (localImagePath != null) '_local_image_path': localImagePath},
      boardKey,
      order,
    );
    if (localImagePath == null && storagePath != null) {
      savedCard['imagePath'] = existing?['imagePath'];
    }
    _putCardInMemory(
      savedCard,
      boardKey: boardKey,
      order: order,
      previousBoardKey: previousBoardKey,
    );
    await _afterOfflineChange();
    return savedCard;
  }

  /// Atualiza a lista em memória depois de salvar (o mesmo cartão pode estar
  /// em mais de uma prancha – relação N:N).
  static void _putCardInMemory(
    Map<String, dynamic> savedCard, {
    required String boardKey,
    required int order,
    required String? previousBoardKey,
  }) {
    final nextCards = _copyCardsByBoard();
    for (final entry in nextCards.entries) {
      final matchingCards = entry.value
          .where((item) => item['id'] == savedCard['id'])
          .toList();
      if (entry.key == boardKey) {
        final cardOrder = matchingCards.isEmpty
            ? order
            : matchingCards.first['order'] as int? ?? order;
        entry.value.removeWhere((item) => item['id'] == savedCard['id']);
        entry.value.add({...savedCard, 'boardKey': entry.key, 'order': cardOrder});
      } else if (previousBoardKey != null &&
          previousBoardKey != boardKey &&
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
    if (!boardCards.any((item) => item['id'] == savedCard['id'])) {
      boardCards.add({...savedCard, 'boardKey': boardKey, 'order': order});
    }
    boardCards.sort(
      (first, second) =>
          (first['order'] as int? ?? 0).compareTo(second['order'] as int? ?? 0),
    );
    cardsByBoard = nextCards;
  }

  static Future<void> deleteCard(Map<String, dynamic> card) async {
    final profileId = _requireActiveProfile();
    final id = card['id'];
    if (id == null) throw ArgumentError('O cartão não tem um identificador.');
    final boardKey = card['boardKey'] as String?;
    if (boardKey == null) {
      throw ArgumentError('O cartão não está associado a uma tábua.');
    }
    final boardId = _boardIdForKey(boardKey);
    final cardId = id as String;

    if (!await _useRemote()) {
      await _store.deleteLink(boardId, cardId);
      await _enqueue('prancha_cartao', 'delete', {
        'prancha_id': boardId,
        'cartao_id': cardId,
      });
      cardsByBoard[boardKey]?.removeWhere((item) => item['id'] == cardId);
      await _deleteOrphansOffline(<String>{cardId});
      await _afterOfflineChange();
      return;
    }

    await _api.deleteLink(boardId, cardId);
    await _store.deleteLink(boardId, cardId);
    cardsByBoard[boardKey]?.removeWhere((item) => item['id'] == cardId);
    await _deleteUnlinkedCards([cardId], profileId);
  }

  /// Offline: exclui os cartões que não estão em mais nenhuma prancha.
  static Future<void> _deleteOrphansOffline(Set<String> cardIds) async {
    for (final cardId in cardIds) {
      Map? stillUsed;
      for (final items in cardsByBoard.values) {
        for (final item in items) {
          if (item['id'] == cardId) stillUsed = item;
        }
      }
      if (stillUsed != null) continue;
      await _store.deleteCard(cardId);
      await _enqueue('cartao', 'delete', {'id': cardId});
    }
  }

  static Future<void> _deleteUnlinkedCards(
    List<String> cardIds,
    String profileId,
  ) async {
    if (cardIds.isEmpty) return;
    final stillUsedIds = await _api.fetchCardIdsStillLinked(cardIds);
    final orphanedIds = cardIds
        .where((cardId) => !stillUsedIds.contains(cardId))
        .toList();
    if (orphanedIds.isEmpty) return;

    final orphanedCards = await _api.fetchCardImagePaths(profileId, orphanedIds);
    await _api.deleteCards(orphanedIds, profileId);
    for (final cardId in orphanedIds) {
      await _store.deleteCard(cardId);
    }
    await _api.removeImages(
      orphanedCards
          .map((row) => row['imagem_storage_path'] as String?)
          .whereType<String>()
          .where((path) => path.isNotEmpty)
          .toList(),
    );
  }

  // ---------------------------------------------------------------------------
  // Utilitários
  // ---------------------------------------------------------------------------

  static String _requireActiveProfile() {
    final profileId = _activeProfileId;
    if (profileId == null) {
      throw StateError('Carregue um perfil antes de alterar o conteúdo.');
    }
    if (!_testing && _client.auth.currentUser == null) {
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
    _validateImage(bytes, contentType);
    final path = '$profileId/${_newId()}.${_extensionFor(contentType)}';
    await _api.uploadImage(path, bytes, contentType);
    return path;
  }

  static Future<void> _removeStoredImage(String path) =>
      _api.removeImages([path]);

  static bool _isNetworkError(Object error) {
    if (error is SocketException) return true;
    final text = '${error.runtimeType} $error'.toLowerCase();
    return text.contains('socketexception') ||
        text.contains('clientexception') ||
        text.contains('retryable') ||
        text.contains('failed host lookup') ||
        text.contains('timeoutexception') ||
        text.contains('connection refused') ||
        text.contains('network is unreachable');
  }

  /// Usado só pelos testes para inspecionar a fila offline.
  @visibleForTesting
  static LocalContentStore get storeForTesting => _store;
}
