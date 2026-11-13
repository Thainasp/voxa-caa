import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'package:voxa/core/widgets/app_colors.dart';

/// Notificações nativas do app (Android/iOS) – BRADEMO CR3 / Correções item 4.
///
/// Mantém o padrão visual do Voxa dentro do que o sistema permite: logo do app
/// como ícone grande, ícone monocromático próprio na barra de status e a cor
/// azul dos ícones do app. O Android não permite trocar a fonte das
/// notificações; o texto usa a tipografia do sistema.
class NotificationService {
  NotificationService({FlutterLocalNotificationsPlugin? plugin})
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;
  bool _initialized = false;

  static const _syncNotificationId = 1001;
  static const _progressChannelId = 'voxa_sync_progress';
  static const _doneChannelId = 'voxa_sync_done';

  /// MSG01
  static const msgSyncTitle = 'Sincronização';
  static const msgSyncBody =
      'Vejo que se conectou ao Wi-Fi, aguarde enquanto fazemos a sincronização de dados.';

  /// MSG02
  static const msgDoneTitle = 'Sincronização concluída';
  static const msgDoneBody =
      'A sincronização dos seus dados foi concluída, você já pode usar offline novamente.';

  static const _largeIcon = DrawableResourceAndroidBitmap(
    'voxa_notification_logo',
  );

  Future<void> init() async {
    if (_initialized) return;
    const settings = InitializationSettings(
      android: AndroidInitializationSettings('ic_stat_voxa_sync'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
    );
    await _plugin.initialize(settings);
    _initialized = true;
  }

  /// Android 13+ exige pedir a permissão em tempo de execução.
  Future<void> requestPermission() async {
    await init();
    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
    await _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);
  }

  /// MSG01 com barra de progresso. Atualizações seguintes substituem a mesma
  /// notificação sem tocar som de novo (onlyAlertOnce).
  Future<void> showSyncProgress({required int done, required int total}) async {
    await init();
    final safeTotal = total <= 0 ? 1 : total;
    await _plugin.show(
      _syncNotificationId,
      msgSyncTitle,
      msgSyncBody,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _progressChannelId,
          'Sincronização em andamento',
          channelDescription:
              'Mostra o progresso do envio das alterações feitas offline.',
          importance: Importance.low,
          priority: Priority.low,
          icon: 'ic_stat_voxa_sync',
          largeIcon: _largeIcon,
          color: AppColors.categoryBlue,
          showProgress: true,
          maxProgress: safeTotal,
          progress: done.clamp(0, safeTotal),
          indeterminate: total <= 0,
          onlyAlertOnce: true,
          ongoing: true,
          autoCancel: false,
          subText: '$done de $total alterações',
          styleInformation: const BigTextStyleInformation(msgSyncBody),
        ),
        iOS: const DarwinNotificationDetails(presentSound: false),
      ),
    );
  }

  /// MSG02: substitui a notificação de progresso (mesmo id).
  Future<void> showSyncDone() async {
    await init();
    await _plugin.show(
      _syncNotificationId,
      msgDoneTitle,
      msgDoneBody,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _doneChannelId,
          'Sincronização concluída',
          channelDescription: 'Avisa quando os dados foram enviados à nuvem.',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          icon: 'ic_stat_voxa_done',
          largeIcon: _largeIcon,
          color: AppColors.headerGreen,
          autoCancel: true,
          styleInformation: const BigTextStyleInformation(msgDoneBody),
        ),
        iOS: const DarwinNotificationDetails(),
      ),
    );
  }

  Future<void> cancelSync() => _plugin.cancel(_syncNotificationId);
}

/// Usado nos testes e quando a plataforma não suporta notificações.
class SilentNotificationService extends NotificationService {
  SilentNotificationService() : super(plugin: null);

  @override
  Future<void> init() async {}
  @override
  Future<void> requestPermission() async {}
  @override
  Future<void> showSyncProgress({required int done, required int total}) async {}
  @override
  Future<void> showSyncDone() async {}
  @override
  Future<void> cancelSync() async {}
}

