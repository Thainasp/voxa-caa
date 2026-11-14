import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:voxa/core/data/remote/profile_api.dart';
import 'package:voxa/core/utils/uuid.dart';
import 'package:voxa/models/user_model.dart';

enum EmergencyState { idle, sending, sentByServer, openedSmsApp, failed }

class EmergencyService extends ChangeNotifier {
  EmergencyService({ProfileApi? profileApi}) : _profileApi = profileApi;

  ProfileApi? _profileApi;
  ProfileApi get _api => _profileApi ??= ProfileApi();

  static const _phoneCacheKey = 'voxa.emergency.phone';
  static const _customWsUrlKey = 'voxa.emergency.ws_url';
  static const _fallbackDemoPhone = '11999990000';

  EmergencyState _state = EmergencyState.idle;
  String? _lastMessage;

  String? _serverStatus;
  String? _maskedPhone;
  String? _alertaId;
  final List<String> _wsEvents = [];

  EmergencyState get state => _state;
  String? get lastMessage => _lastMessage;
  String? get serverStatus => _serverStatus;
  String? get maskedPhone => _maskedPhone;
  String? get alertaId => _alertaId;
  List<String> get wsEvents => List.unmodifiable(_wsEvents);
  bool get isSending => _state == EmergencyState.sending;

  void _set(EmergencyState state, [String? message]) {
    _state = state;
    _lastMessage = message;
    notifyListeners();
  }

  void _addWsEvent(
    String logEntry, {
    String? status,
    String? phone,
    String? id,
  }) {
    if (status != null) _serverStatus = status;
    if (phone != null && phone.isNotEmpty) _maskedPhone = phone;
    if (id != null && id.isNotEmpty) _alertaId = id;
    _wsEvents.add(logEntry);
    notifyListeners();
  }

  /// Permite configurar o IP do servidor direto no celular físico sem recompilar o APK.
  Future<void> setCustomWsUrl(String? url) async {
    final prefs = await SharedPreferences.getInstance();
    if (url == null || url.trim().isEmpty) {
      await prefs.remove(_customWsUrlKey);
    } else {
      await prefs.setString(_customWsUrlKey, _normalizeSockJsUrl(url.trim()));
    }
  }

  Future<String> getEffectiveWsUrl() async {
    final urls = await _candidateWsUrls();
    return urls.first;
  }

  String _normalizeSockJsUrl(String raw) {
    var url = raw.trim();
    if (url.startsWith('ws://')) url = 'http://${url.substring(5)}';
    if (url.startsWith('wss://')) url = 'https://${url.substring(6)}';
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      url = 'http://$url';
    }
    if (!url.endsWith('/ws')) {
      url = url.endsWith('/') ? '${url}ws' : '$url/ws';
    }
    return url;
  }

  /// Monta a lista de URLs para funcionar no Chrome Web, Emulador e APK Físico.
  Future<List<String>> _candidateWsUrls() async {
    final prefs = await SharedPreferences.getInstance();
    final customUrl = prefs.getString(_customWsUrlKey);
    final envUrl = dotenv.maybeGet('BACKEND_WS_URL')?.trim();

    final candidates = <String>[];

    if (customUrl != null && customUrl.isNotEmpty) {
      candidates.add(_normalizeSockJsUrl(customUrl));
    }

    if (kIsWeb) {
      // No Chrome (flutter run -d chrome), 10.0.2.2 não existe; usa localhost:8080
      if (envUrl != null && envUrl.isNotEmpty && !envUrl.contains('10.0.2.2')) {
        candidates.add(_normalizeSockJsUrl(envUrl));
      }
      candidates.add('http://localhost:8080/ws');
    } else {
      // No Android (APK físico ou Emulador)
      // 1. Tenta localhost primeiro se estiver no cabo USB (adb reverse tcp:8080 tcp:8080)
      candidates.add('http://localhost:8080/ws');
      // 2. Tenta a URL do .env (ex.: IP da rede Wi-Fi ou 10.0.2.2 do emulador)
      if (envUrl != null && envUrl.isNotEmpty) {
        candidates.add(_normalizeSockJsUrl(envUrl));
      }
    }

    return candidates.toSet().toList();
  }

  /// Guarda o telefone do responsável no aparelho para o plano B offline.
  Future<void> cachePhone(String usuarioId) async {
    try {
      final phone = await _api.fetchResponsiblePhone(usuarioId);
      if (phone == null || phone.isEmpty) return;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_phoneCacheKey, phone);
    } catch (_) {
      // Sem rede: mantém o último telefone salvo.
    }
  }

  Future<String> _resolvePhoneForFallback(User? authUser) async {
    final prefs = await SharedPreferences.getInstance();
    var cached = prefs.getString(_phoneCacheKey);
    if (cached != null && cached.isNotEmpty) return cached;

    if (authUser != null) {
      await cachePhone(authUser.id);
      cached = prefs.getString(_phoneCacheKey);
      if (cached != null && cached.isNotEmpty) return cached;

      final metaPhone =
          authUser.userMetadata?['telefone']?.toString() ??
          authUser.userMetadata?['phone']?.toString() ??
          authUser.phone;
      if (metaPhone != null && metaPhone.isNotEmpty) return metaPhone;
    }

    return _fallbackDemoPhone;
  }

  Future<void> sendAlert({required UserModel? activeProfile}) async {
    if (isSending) return;
    _wsEvents.clear();
    _serverStatus = 'CONECTANDO';
    _maskedPhone = null;
    _alertaId = null;
    _set(EmergencyState.sending, 'Conectando ao servidor WebSocket...');

    final authUser = Supabase.instance.client.auth.currentUser;
    final perfilNome = activeProfile?.name ?? 'Usuário do Voxa';
    final mensagem =
        'ALERTA VOXA: $perfilNome acionou o botão de emergência e precisa de ajuda.';

    final sentByServer =
        authUser != null &&
        activeProfile != null &&
        await _sendViaStompWithFallbackUrls(
          usuarioId: authUser.id,
          perfil: activeProfile,
          mensagem: mensagem,
        );

    if (sentByServer) {
      final destino = (_maskedPhone != null && _maskedPhone!.isNotEmpty)
          ? ' ($_maskedPhone)'
          : '';
      _set(
        EmergencyState.sentByServer,
        'Alerta concluído via WebSocket! Status: SMS_ENVIADO$destino.',
      );
      return;
    }

    // Plano B (Celular sem Wi-Fi / Servidor desligado): abre o app de SMS nativo
    final phone = await _resolvePhoneForFallback(authUser);

    if (kIsWeb) {
      _set(
        EmergencyState.failed,
        'Servidor WebSocket offline. No celular (APK), o Plano B abriria o SMS para $phone.',
      );
      return;
    }

    final uri = Uri.parse('sms:$phone?body=${Uri.encodeComponent(mensagem)}');
    try {
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      _set(
        opened ? EmergencyState.openedSmsApp : EmergencyState.failed,
        opened
            ? 'Modo Offline (Plano B): confirme o envio no app de SMS do aparelho.'
            : 'Não foi possível abrir o app de SMS. Ligue para o responsável.',
      );
    } catch (_) {
      _set(
        EmergencyState.failed,
        'Não foi possível abrir o app de SMS. Ligue para o responsável.',
      );
    }
  }

  Future<bool> _sendViaStompWithFallbackUrls({
    required String usuarioId,
    required UserModel perfil,
    required String mensagem,
  }) async {
    final urls = await _candidateWsUrls();
    for (final url in urls) {
      final ok = await _tryStompOnUrl(
        url: url,
        usuarioId: usuarioId,
        perfil: perfil,
        mensagem: mensagem,
      );
      if (ok) return true;
    }
    return false;
  }

  Future<bool> _tryStompOnUrl({
    required String url,
    required String usuarioId,
    required UserModel perfil,
    required String mensagem,
  }) async {
    final token = Supabase.instance.client.auth.currentSession?.accessToken;
    final clienteId = generateUuidV4();
    final result = Completer<bool>();
    StompClient? client;

    void finish(bool value) {
      if (!result.isCompleted) result.complete(value);
    }

    _addWsEvent('Tentando WebSocket em $url...', status: 'CONECTANDO');

    client = StompClient(
      config: StompConfig.sockJS(
        url: url,
        stompConnectHeaders: {
          if (token != null) 'Authorization': 'Bearer $token',
        },
        webSocketConnectHeaders: {
          if (token != null) 'Authorization': 'Bearer $token',
        },
        reconnectDelay: Duration.zero,
        connectionTimeout: const Duration(seconds: 3),
        onConnect: (frame) {
          _addWsEvent(
            'Conectado! Inscrito em /topic/alertas/${perfil.id}',
            status: 'CONECTADO',
          );

          client?.subscribe(
            destination: '/topic/alertas/${perfil.id}',
            callback: (event) {
              try {
                final data = jsonDecode(event.body ?? '{}') as Map;
                if (data['clienteId'] != null &&
                    data['clienteId'].toString() != clienteId) {
                  return;
                }
                final status = data['status']?.toString() ?? '';
                final telefoneMascarado = data['telefoneMascarado']?.toString();
                final alertaId = data['alertaId']?.toString();

                if (status == 'RECEBIDO') {
                  _addWsEvent(
                    'Recebido do tópico: status RECEBIDO',
                    status: 'RECEBIDO',
                    phone: telefoneMascarado,
                    id: alertaId,
                  );
                } else if (status == 'SMS_ENVIADO') {
                  _addWsEvent(
                    'Recebido do tópico: status SMS_ENVIADO (${telefoneMascarado ?? ""})',
                    status: 'SMS_ENVIADO',
                    phone: telefoneMascarado,
                    id: alertaId,
                  );
                  Future.delayed(
                    const Duration(milliseconds: 500),
                    () => finish(true),
                  );
                } else if (status == 'SMS_FALHOU') {
                  _addWsEvent(
                    'Recebido do tópico: status SMS_FALHOU',
                    status: 'SMS_FALHOU',
                    phone: telefoneMascarado,
                    id: alertaId,
                  );
                  finish(false);
                }
              } catch (_) {}
            },
          );

          client?.subscribe(
            destination: '/user/queue/erros',
            callback: (event) {
              try {
                final data = jsonDecode(event.body ?? '{}') as Map;
                final erroMsg =
                    data['erro']?.toString() ?? 'Erro retornado pelo servidor.';
                _lastMessage = erroMsg;
                _addWsEvent('Erro do servidor: $erroMsg', status: 'ERRO');
              } catch (_) {}
              finish(false);
            },
          );

          Future.delayed(const Duration(milliseconds: 150), () {
            if (result.isCompleted) return;
            _addWsEvent('Enviando SEND /app/alerta...');
            client?.send(
              destination: '/app/alerta',
              body: jsonEncode({
                'clienteId': clienteId,
                'usuarioId': usuarioId,
                'perfilId': perfil.id,
                'perfilNome': perfil.name,
                'mensagem': mensagem,
                'enviadoEm': DateTime.now().toUtc().toIso8601String(),
              }),
            );
          });
        },
        onWebSocketError: (_) => finish(false),
        onStompError: (_) => finish(false),
        onDisconnect: (_) => finish(false),
      ),
    );

    client.activate();
    final ok = await result.future.timeout(
      const Duration(seconds: 4),
      onTimeout: () => false,
    );
    client.deactivate();
    return ok;
  }

  void reset() {
    _wsEvents.clear();
    _serverStatus = null;
    _maskedPhone = null;
    _alertaId = null;
    _set(EmergencyState.idle);
  }
}
