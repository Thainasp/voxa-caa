import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:voxa/core/data/local/catalog_repository.dart';
import 'package:voxa/core/data/local/local_content_store.dart';
import 'package:voxa/core/data/local/sqflite_content_store.dart';
import 'package:voxa/core/data/remote/content_api.dart';
import 'package:voxa/core/data/remote/profile_api.dart';
import 'package:voxa/core/data/sync/sync_service.dart';
import 'package:voxa/core/services/connectivity_service.dart';
import 'package:voxa/core/services/emergency_service.dart';
import 'package:voxa/core/services/notification_service.dart';
import 'package:voxa/core/services/tts_service.dart';
import 'package:voxa/core/state/profile_provider.dart';

/// Ponto único de criação dos serviços do app. Os ChangeNotifiers daqui são
/// registrados no MultiProvider do main.dart.
class AppServices {
  AppServices._({
    required this.store,
    required this.contentApi,
    required this.profileApi,
    required this.catalog,
    required this.connectivity,
    required this.notifications,
    required this.sync,
    required this.tts,
    required this.emergency,
    required this.profile,
  });

  static AppServices? _instance;

  static bool get isReady => _instance != null;

  static AppServices get instance =>
      _instance ??
      (throw StateError('Chame AppServices.init() no main() antes de usar.'));

  final LocalContentStore store;
  final ContentApi contentApi;
  final ProfileApi profileApi;
  final CatalogRepository catalog;
  final ConnectivityService connectivity;
  final NotificationService notifications;
  final SyncService sync;
  final TtsService tts;
  final EmergencyService emergency;
  final ProfileProvider profile;

  static Future<AppServices> init() async {
    if (_instance != null) return _instance!;
    final client = Supabase.instance.client;

    LocalContentStore store;
    try {
      store = kIsWeb ? InMemoryContentStore() : await SqfliteContentStore.open();
    } catch (error) {
      debugPrint('SQLite indisponível, usando memória: $error');
      store = InMemoryContentStore();
    }

    final contentApi = ContentApi(client);
    final connectivity = ConnectivityService();
    final notifications = kIsWeb
        ? SilentNotificationService()
        : NotificationService();
    try {
      await notifications.init();
    } catch (error) {
      debugPrint('Notificações indisponíveis: $error');
    }

    final sync = SyncService(
      store: store,
      api: contentApi,
      connectivity: connectivity,
      notifications: notifications,
    );
    await sync.start();

    return _instance = AppServices._(
      store: store,
      contentApi: contentApi,
      profileApi: ProfileApi(client),
      catalog: CatalogRepository(store),
      connectivity: connectivity,
      notifications: notifications,
      sync: sync,
      tts: TtsService(),
      emergency: EmergencyService(profileApi: ProfileApi(client)),
      profile: ProfileProvider(),
    );
  }
}
