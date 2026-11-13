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

/// Botão de emergência (Correções item 5 / RF09 / RF10 / BRADWBK CR8).
///
/// Contrato STOMP com o back-end Spring Boot (documentado no Voxa.doc):
/// - Conexão:  BACKEND_WS_URL (ex.: http://10.0.2.2:8080/ws, SockJS)
/// - Envio:    SEND      /app/alerta
/// - Escuta:   SUBSCRIBE /topic/alertas/{perfilId}
///
/// O servidor grava o alerta, envia o SMS ao telefone cadastrado do
/// responsável e publica no tópico o resultado (status SMS_ENVIADO ou
/// SMS_FALHOU), que também aparece em tempo real no cliente web do cuidador.
///
/// Plano B: se o servidor não responder (sem internet, servidor fora do ar ou
/// falha no SMS), o app abre o aplicativo de SMS do aparelho com a mensagem
/// pronta para o telefone cadastrado. O SMS usa a rede celular, então funciona
/// mesmo sem internet.
class EmergencyService extends ChangeNotifier {
  EmergencyService({ProfileApi? profileApi}) : _profileApi = profileApi;

  ProfileApi? _profileApi;
  ProfileApi get _api => _profileApi ??= ProfileApi();

  static const _phoneCacheKey = 'voxa.emergency.phone';
  static const _serverTimeout = Duration(seconds: 10);

  EmergencyState _state = EmergencyState.idle;
  String? _lastMessage;

  EmergencyState get state => _state;
  String? get lastMessage => _lastMessage;
  bool get isSending => _state == EmergencyState.sending;

  void _set(EmergencyState state, [String? message]) {
    _state = state;
    _lastMessage = message;
    notifyListeners();
  }

  /// Guarda o telefone do responsável no aparelho para o plano B offline.
  Future<void> cachePhone(String usuarioId) async {
    try {
      final phone = await _api.fetchResponsiblePhone(usuarioId);
      if (phone == null) return;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_phoneCacheKey, phone);
    } catch (_) {
      // Sem rede: mantém o último telefone salvo.
    }
  }

  Future<String?> _cachedPhone() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_phoneCacheKey);
  }

  Future<void> sendAlert({required UserModel? activeProfile}) async {
    if (isSending) return;
    _set(EmergencyState.sending, 'Enviando alerta...');

    final authUser = Supabase.instance.client.auth.currentUser;
    final perfilNome = activeProfile?.name ?? 'Usuário do Voxa';
    final mensagem =
        'ALERTA VOXA: $perfilNome acionou o botão de emergência e precisa de ajuda.';

    final sentByServer = authUser != null &&
        activeProfile != null &&
        await _sendViaStomp(
          usuarioId: authUser.id,
          perfil: activeProfile,
          mensagem: mensagem,
        );

    if (sentByServer) {
      _set(
        EmergencyState.sentByServer,
        'Alerta enviado. O responsável vai receber um SMS.',
      );
      return;
    }

    final phone = await _cachedPhone();
    if (phone == null) {
      _set(
        EmergencyState.failed,
        'Não foi possível enviar o alerta e não há telefone cadastrado.',
      );
      return;
    }
    final uri = Uri.parse('sms:$phone?body=${Uri.encodeComponent(mensagem)}');
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    _set(
      opened ? EmergencyState.openedSmsApp : EmergencyState.failed,
      opened
          ? 'Sem conexão com o servidor: confirme o envio no app de SMS.'
          : 'Não foi possível abrir o SMS. Ligue para o responsável.',
    );
  }

  Future<bool> _sendViaStomp({
    required String usuarioId,
    required UserModel perfil,
    required String mensagem,
  }) async {
    final url = dotenv.maybeGet('BACKEND_WS_URL');
    if (url == null || url.isEmpty) return false;

    final token = Supabase.instance.client.auth.currentSession?.accessToken;
    final clienteId = generateUuidV4();
    final result = Completer<bool>();
    StompClient? client;

    void finish(bool value) {
      if (!result.isCompleted) result.complete(value);
    }

    client = StompClient(
      config: StompConfig.sockJS(
        url: url,
        stompConnectHeaders: {
          if (token != null) 'Authorization': 'Bearer $token',
        },
        webSocketConnectHeaders: {
          if (token != null) 'Authorization': 'Bearer $token',
        },
        reconnectDelay: Duration.zero, // uma tentativa; o plano B cuida do resto
        connectionTimeout: const Duration(seconds: 5),
        onConnect: (frame) {
          client?.subscribe(
            destination: '/topic/alertas/${perfil.id}',
            callback: (event) {
              try {
                final data = jsonDecode(event.body ?? '{}') as Map;
                if (data['clienteId'] != clienteId) return;
                final status = data['status']?.toString();
                if (status == 'SMS_ENVIADO') finish(true);
                if (status == 'SMS_FALHOU') finish(false);
              } catch (_) {}
            },
          );
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
        },
        onWebSocketError: (_) => finish(false),
        onStompError: (_) => finish(false),
        onDisconnect: (_) => finish(false),
      ),
    );

    client.activate();
    final ok = await result.future.timeout(
      _serverTimeout,
      onTimeout: () => false,
    );
    client.deactivate();
    return ok;
  }

  void reset() => _set(EmergencyState.idle);
}
