import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:voxa/core/data/local/local_content_store.dart';
import 'package:voxa/core/data/remote/content_api.dart';
import 'package:voxa/core/data/sync/sync_service.dart';
import 'package:voxa/core/services/connectivity_service.dart';
import 'package:voxa/core/services/notification_service.dart';
import 'package:voxa/core/utils/uuid.dart';

const _profileId = 'c6cf87a0-52db-42fd-aabc-c7e8cb987842';

/// Rede controlada pelo teste.
class FakeConnectivity extends ConnectivityService {
  FakeConnectivity(this.status);
  NetworkStatus status;

  @override
  Future<NetworkStatus> current() async => status;

  @override
  Stream<NetworkStatus> get changes => const Stream.empty();
}

/// Registra as notificações em vez de exibi-las.
class RecordingNotifications extends SilentNotificationService {
  final List<String> events = [];

  @override
  Future<void> showSyncProgress({required int done, required int total}) async =>
      events.add('progresso $done/$total');

  @override
  Future<void> showSyncDone() async => events.add('concluída');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('gera UUID v4 válido', () {
    final pattern = RegExp(
      r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
    );
    final ids = List.generate(50, (_) => generateUuidV4());
    expect(ids.every(pattern.hasMatch), isTrue);
    expect(ids.toSet(), hasLength(50));
  });

  test('fila offline mantém a ordem e registra falhas', () async {
    final store = InMemoryContentStore();
    await store.enqueue(
      OutboxOperation(
        perfilId: _profileId,
        tabela: 'prancha',
        operacao: 'upsert',
        payload: {'id': 'b1'},
      ),
    );
    await store.enqueue(
      OutboxOperation(
        perfilId: _profileId,
        tabela: 'cartao',
        operacao: 'upsert',
        payload: {'id': 'c1'},
      ),
    );
    final pending = await store.pendingOperations();
    expect(pending.map((op) => op.tabela), ['prancha', 'cartao']);

    await store.markFailed(pending.first.id!, 'erro');
    expect((await store.pendingOperations()).first.tentativas, 1);

    await store.markDone(pending.first.id!);
    expect(await store.pendingCount(), 1);
  });

  group('SyncService', () {
    late List<http.Request> requests;
    late InMemoryContentStore store;
    late RecordingNotifications notifications;
    late FakeConnectivity connectivity;
    late SyncService sync;

    setUp(() async {
      requests = [];
      store = InMemoryContentStore();
      notifications = RecordingNotifications();
      connectivity = FakeConnectivity(NetworkStatus.mobile);
      final client = SupabaseClient(
        'https://test.supabase.co',
        'test-anon-key',
        accessToken: () async => 'test-access-token',
        httpClient: MockClient((request) async {
          requests.add(request);
          if (request.method == 'GET') {
            return http.Response(
              jsonEncode([]),
              200,
              headers: {'content-type': 'application/json'},
              request: request,
            );
          }
          return http.Response('', 201, request: request);
        }),
      );
      sync = SyncService(
        store: store,
        api: ContentApi(client),
        connectivity: connectivity,
        notifications: notifications,
        hasSession: () => true,
      );
      await sync.start();
      sync.setActiveProfile(_profileId);
      await store.enqueue(
        OutboxOperation(
          perfilId: _profileId,
          tabela: 'prancha',
          operacao: 'upsert',
          payload: {'id': 'b1', 'perfil_id': _profileId, 'chave': 'x'},
        ),
      );
      await store.enqueue(
        OutboxOperation(
          perfilId: _profileId,
          tabela: 'prancha_cartao',
          operacao: 'upsert',
          payload: {'prancha_id': 'b1', 'cartao_id': 'c1', 'ordem': 0},
        ),
      );
    });

    tearDown(() => sync.dispose());

    test('não envia nada em dados móveis', () async {
      await sync.onLocalChange();
      expect(sync.pending, 2);
      expect(requests.where((r) => r.method == 'POST'), isEmpty);
      expect(notifications.events, isEmpty);
    });

    test('no Wi-Fi envia a fila com progresso e mostra MSG02', () async {
      connectivity.status = NetworkStatus.wifi;
      await sync.start();
      await sync.sync(showNotifications: true);

      expect(sync.pending, 0);
      expect(
        requests.where((r) => r.method == 'POST').map((r) => r.url.path),
        ['/rest/v1/prancha', '/rest/v1/prancha_cartao'],
      );
      expect(notifications.events, [
        'progresso 0/2',
        'progresso 1/2',
        'progresso 2/2',
        'concluída',
      ]);
      expect(sync.contentVersion, 1);
    });
  });
}
