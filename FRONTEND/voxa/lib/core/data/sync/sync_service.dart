import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:voxa/core/data/local/local_content_store.dart';
import 'package:voxa/core/data/remote/content_api.dart';
import 'package:voxa/core/services/connectivity_service.dart';
import 'package:voxa/core/services/notification_service.dart';

enum SyncStatus { idle, syncing, error }

/// Sincronização offline-first (Correções itens 3 e 4 / RF08).
///
/// - Toda alteração feita sem Wi-Fi entra na fila `sync_outbox` do SQLite.
/// - Ao conectar no Wi-Fi, a fila é enviada ao Supabase na ordem em que as
///   alterações aconteceram. Enquanto isso aparece a notificação MSG01 com
///   barra de progresso; ao terminar ela é substituída pela MSG02.
/// - Em dados móveis nada é enviado (requisito do item 3).
/// - Depois de enviar, baixa o conteúdo do perfil ativo e atualiza o SQLite.
///
/// É um ChangeNotifier compartilhado pelo Provider: a Home mostra quantas
/// alterações estão pendentes e recarrega quando o conteúdo muda.
class SyncService extends ChangeNotifier {
  SyncService({
    required LocalContentStore store,
    required ContentApi api,
    required ConnectivityService connectivity,
    required NotificationService notifications,
    bool Function()? hasSession,
  }) : _store = store,
       _api = api,
       _connectivity = connectivity,
       _notifications = notifications,
       _hasSession =
           hasSession ??
           (() => Supabase.instance.client.auth.currentSession != null);

  final LocalContentStore _store;
  final ContentApi _api;
  final ConnectivityService _connectivity;
  final NotificationService _notifications;
  final bool Function() _hasSession;

  /// Depois de tantas falhas a operação deixa de bloquear a fila.
  static const maxAttempts = 5;

  StreamSubscription<NetworkStatus>? _subscription;
  NetworkStatus _network = NetworkStatus.offline;
  SyncStatus _status = SyncStatus.idle;
  int _pending = 0;
  int _progressDone = 0;
  int _progressTotal = 0;
  int _contentVersion = 0;
  String? _lastError;
  String? _activeProfileId;
  DateTime? _lastSyncAt;
  Future<void>? _running;

  NetworkStatus get network => _network;
  SyncStatus get status => _status;
  int get pending => _pending;
  int get progressDone => _progressDone;
  int get progressTotal => _progressTotal;
  String? get lastError => _lastError;
  DateTime? get lastSyncAt => _lastSyncAt;
  bool get isOnWifi => _network == NetworkStatus.wifi;
  bool get isOffline => _network == NetworkStatus.offline;

  /// Muda sempre que o conteúdo local do perfil ativo foi atualizado pela
  /// nuvem; a Home observa este valor para recarregar.
  int get contentVersion => _contentVersion;

  bool get canSyncNow => isOnWifi && _hasSession();

  Future<void> start() async {
    _network = await _connectivity.current();
    _pending = await _store.pendingCount();
    notifyListeners();
    _subscription ??= _connectivity.changes.listen(_onNetworkChanged);
  }

  void setActiveProfile(String? perfilId) => _activeProfileId = perfilId;

  Future<void> _onNetworkChanged(NetworkStatus status) async {
    final becameWifi = status == NetworkStatus.wifi && !isOnWifi;
    _network = status;
    notifyListeners();
    if (becameWifi) await sync(showNotifications: true);
  }

  /// Chamado pelo controller depois de gravar uma alteração na fila.
  Future<void> onLocalChange() async {
    _pending = await _store.pendingCount();
    notifyListeners();
    if (canSyncNow) await sync(showNotifications: false);
  }

  /// Envia a fila e baixa o conteúdo do perfil ativo. Chamadas simultâneas
  /// reaproveitam a execução em andamento.
  Future<void> sync({bool showNotifications = true}) =>
      _running ??= _sync(showNotifications).whenComplete(() => _running = null);

  Future<void> _sync(bool showNotifications) async {
    if (!canSyncNow) return;
    final operations = (await _store.pendingOperations())
        .where((op) => op.tentativas < maxAttempts)
        .toList();

    _status = SyncStatus.syncing;
    _lastError = null;
    _progressDone = 0;
    _progressTotal = operations.length;
    notifyListeners();

    final notify = showNotifications && operations.isNotEmpty;
    try {
      if (notify) {
        await _notifications.showSyncProgress(done: 0, total: operations.length);
      }

      for (final operation in operations) {
        if (!canSyncNow) {
          throw const SocketException('Wi-Fi desconectado durante o envio.');
        }
        try {
          await _push(operation);
          await _store.markDone(operation.id!);
        } on SocketException {
          rethrow;
        } on TimeoutException {
          rethrow;
        } catch (error) {
          if (_isNetworkError(error)) rethrow;
          // Erro de dados (ex.: RLS): registra e segue com o resto da fila.
          await _store.markFailed(operation.id!, error.toString());
        }
        _progressDone++;
        notifyListeners();
        if (notify) {
          await _notifications.showSyncProgress(
            done: _progressDone,
            total: _progressTotal,
          );
        }
      }

      await _pullActiveProfile();
      _status = SyncStatus.idle;
      _lastSyncAt = DateTime.now();
      if (notify) await _notifications.showSyncDone();
    } catch (error) {
      _status = SyncStatus.error;
      _lastError = _isNetworkError(error)
          ? 'Conexão perdida. As alterações continuam salvas no aparelho.'
          : 'Falha ao sincronizar: $error';
      if (notify) await _notifications.cancelSync();
    } finally {
      _pending = await _store.pendingCount();
      notifyListeners();
    }
  }

  Future<void> _pullActiveProfile() async {
    final perfilId = _activeProfileId;
    if (perfilId == null) return;
    final remote = await _api.fetchProfileContent(perfilId);
    await _store.replaceProfileContent(
      perfilId,
      boards: remote.boards,
      cards: remote.cards,
      links: remote.links,
    );
    _contentVersion++;
  }

  Future<void> _push(OutboxOperation op) async {
    final payload = Map<String, dynamic>.from(op.payload);
    switch ((op.tabela, op.operacao)) {
      case ('prancha', 'upsert'):
        await _uploadPendingImage(payload);
        await _api.upsertBoard(payload);
      case ('prancha', 'delete'):
        await _api.deleteLinksOfBoard(payload['id'] as String);
        await _api.deleteBoard(payload['id'] as String, op.perfilId);
        await _removeImage(payload['imagem_storage_path'] as String?);
      case ('cartao', 'upsert'):
        await _uploadPendingImage(payload);
        await _api.upsertCard(payload);
      case ('cartao', 'delete'):
        await _api.deleteLinksOfCard(payload['id'] as String);
        await _api.deleteCard(payload['id'] as String, op.perfilId);
        await _removeImage(payload['imagem_storage_path'] as String?);
      case ('prancha_cartao', 'upsert'):
        await _api.upsertLink(payload);
      case ('prancha_cartao', 'delete'):
        await _api.deleteLink(
          payload['prancha_id'] as String,
          payload['cartao_id'] as String,
        );
      default:
        throw StateError('Operação desconhecida: ${op.tabela}/${op.operacao}');
    }
  }

  /// Imagem escolhida offline: o arquivo ficou no aparelho e o caminho do
  /// Storage já foi reservado. Envia antes de gravar a linha.
  Future<void> _uploadPendingImage(Map<String, dynamic> payload) async {
    final localPath = payload.remove('_local_image_path') as String?;
    final contentType =
        payload.remove('_image_content_type') as String? ?? 'image/jpeg';
    final storagePath = payload['imagem_storage_path'] as String?;
    if (localPath == null || storagePath == null) return;
    final file = File(localPath);
    if (!await file.exists()) return;
    try {
      await _api.uploadImage(storagePath, await file.readAsBytes(), contentType);
    } on StorageException catch (error) {
      // Já enviado numa tentativa anterior.
      if (error.statusCode != '409' && error.statusCode != '400') rethrow;
    }
    await file.delete();
  }

  Future<void> _removeImage(String? storagePath) async {
    if (storagePath == null || storagePath.isEmpty) return;
    try {
      await _api.removeImages([storagePath]);
    } catch (_) {
      // A linha já foi excluída; uma imagem órfã não deve travar a fila.
    }
  }

  static bool _isNetworkError(Object error) {
    if (error is SocketException || error is TimeoutException) return true;
    final text = '${error.runtimeType} $error'.toLowerCase();
    return text.contains('socketexception') ||
        text.contains('clientexception') ||
        text.contains('failed host lookup') ||
        text.contains('connection refused') ||
        text.contains('connection closed') ||
        text.contains('network is unreachable');
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
