import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:voxa/core/navigation/route_observer.dart';
import 'package:voxa/core/services/emergency_service.dart';
import 'package:voxa/core/state/profile_provider.dart';
import 'package:voxa/core/widgets/app_colors.dart';

/// Vermelho do botão de emergência (padrão enviado nas Correções, item 5).
const Color emergencyRed = Color(0xFFFF4B4B);

/// Botão de emergência presente em todas as telas após o login (RN-05).
///
/// Fica sobre o Navigator (MaterialApp.builder), então aparece em qualquer
/// tela sem precisar ser incluído uma a uma. Some nas telas anteriores ao
/// login e quando não há sessão.
class EmergencyButtonOverlay extends StatelessWidget {
  const EmergencyButtonOverlay({
    super.key,
    required this.child,
    required this.navigatorKey,
  });

  final Widget child;
  final GlobalKey<NavigatorState> navigatorKey;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        ValueListenableBuilder<String?>(
          valueListenable: topRouteTracker.topRouteName,
          builder: (context, routeName, _) {
            final hasSession =
                Supabase.instance.client.auth.currentSession != null;
            final hidden =
                !hasSession ||
                (routeName != null &&
                    routesWithoutEmergencyButton.contains(routeName));
            if (hidden) return const SizedBox.shrink();
            final padding = MediaQuery.paddingOf(context);
            return Positioned(
              right: 12 + padding.right,
              bottom: 76 + padding.bottom,
              child: _EmergencyButton(navigatorKey: navigatorKey),
            );
          },
        ),
      ],
    );
  }
}

class _EmergencyButton extends StatelessWidget {
  const _EmergencyButton({required this.navigatorKey});

  final GlobalKey<NavigatorState> navigatorKey;

  /// Estilo padronizado de botão primário do aplicativo (Poppins SemiBold + pílula 28px).
  ButtonStyle _primaryButtonStyle(Color backgroundColor) {
    return ElevatedButton.styleFrom(
      backgroundColor: backgroundColor,
      foregroundColor: Colors.white,
      elevation: 2,
      minimumSize: const Size(140, 46),
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      textStyle: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600),
    );
  }

  /// Estilo padronizado de botão secundário/texto do aplicativo.
  ButtonStyle _secondaryButtonStyle() {
    return TextButton.styleFrom(
      foregroundColor: AppColors.titleColor,
      minimumSize: const Size(110, 44),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      textStyle: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w500),
    );
  }

  Future<void> _configureServerUrl(
    BuildContext dialogContext,
    EmergencyService emergency,
  ) async {
    final currentUrl = await emergency.getEffectiveWsUrl();
    if (!dialogContext.mounted) return;
    final controller = TextEditingController(text: currentUrl);

    await showDialog<void>(
      context: dialogContext,
      builder: (ctx) {
        final isLandscape =
            MediaQuery.orientationOf(ctx) == Orientation.landscape;
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          insetPadding: EdgeInsets.symmetric(
            horizontal: isLandscape ? 40 : 24,
            vertical: isLandscape ? 12 : 24,
          ),
          title: Text(
            'Servidor WebSocket',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              fontSize: 18,
              color: AppColors.titleColor,
            ),
          ),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'No USB/Chrome use localhost:8080. No Wi-Fi use o IP do notebook (ex.: http://192.168.1.15:8080/ws):',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: AppColors.textColor,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: controller,
                    keyboardType: TextInputType.url,
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                      color: AppColors.textColor,
                    ),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: AppColors.fieldFillColor,
                      hintText: 'http://192.168.0.10:8080/ws',
                      hintStyle: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w400,
                        color: AppColors.textColor.withOpacity(0.5),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 14,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(28),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            TextButton(
              style: _secondaryButtonStyle(),
              onPressed: () async {
                await emergency.setCustomWsUrl(null);
                if (ctx.mounted) Navigator.of(ctx).pop();
              },
              child: const Text('Padrão'),
            ),
            ElevatedButton(
              style: _primaryButtonStyle(AppColors.selectedCategoryGreen),
              onPressed: () async {
                await emergency.setCustomWsUrl(controller.text);
                if (ctx.mounted) Navigator.of(ctx).pop();
              },
              child: const Text('Salvar'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _confirmAndSend(BuildContext context) async {
    final dialogContext = navigatorKey.currentContext;
    if (dialogContext == null) return;
    final emergency = context.read<EmergencyService>();
    final profile = context.read<ProfileProvider>().current;

    final confirmed = await showDialog<bool>(
      context: dialogContext,
      builder: (ctx) {
        final isLandscape =
            MediaQuery.orientationOf(ctx) == Orientation.landscape;
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          insetPadding: EdgeInsets.symmetric(
            horizontal: isLandscape ? 40 : 24,
            vertical: isLandscape ? 12 : 24,
          ),
          iconPadding: EdgeInsets.only(
            top: isLandscape ? 12 : 20,
            left: 24,
            right: 24,
          ),
          icon: Stack(
            alignment: Alignment.center,
            children: [
              Icon(
                Icons.local_hospital,
                color: emergencyRed,
                size: isLandscape ? 38 : 48,
              ),
              Positioned(
                right: 0,
                top: 0,
                child: IconButton(
                  tooltip: 'Configurar IP do servidor WebSocket',
                  icon: Icon(
                    Icons.settings_ethernet,
                    size: 20,
                    color: AppColors.textColor.withOpacity(0.6),
                  ),
                  onPressed: () => _configureServerUrl(ctx, emergency),
                ),
              ),
            ],
          ),
          title: Text(
            'Pedir ajuda?',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              fontSize: isLandscape ? 18 : 20,
              color: AppColors.titleColor,
            ),
          ),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: SingleChildScrollView(
              child: Text(
                'Um SMS de alerta será enviado para o telefone do responsável.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: AppColors.textColor,
                ),
              ),
            ),
          ),
          actionsAlignment: MainAxisAlignment.center,
          actionsPadding: EdgeInsets.only(
            left: 20,
            right: 20,
            bottom: isLandscape ? 12 : 20,
          ),
          actions: [
            TextButton(
              style: _secondaryButtonStyle(),
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              style: _primaryButtonStyle(emergencyRed),
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Enviar alerta'),
            ),
          ],
        );
      },
    );
    if (confirmed != true) return;

    final sendFuture = emergency.sendAlert(activeProfile: profile);

    final statusDialogContext = navigatorKey.currentContext;
    if (statusDialogContext != null && statusDialogContext.mounted) {
      await showDialog<void>(
        context: statusDialogContext,
        barrierDismissible: false,
        builder: (ctx) {
          final isLandscape =
              MediaQuery.orientationOf(ctx) == Orientation.landscape;
          final maxDialogHeight =
              MediaQuery.sizeOf(ctx).height * (isLandscape ? 0.48 : 0.60);

          return ChangeNotifierProvider<EmergencyService>.value(
            value: emergency,
            child: Consumer<EmergencyService>(
              builder: (context, service, _) {
                final isDone = !service.isSending;
                final isSuccess =
                    service.state == EmergencyState.sentByServer ||
                    service.state == EmergencyState.openedSmsApp;

                return AlertDialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                  insetPadding: EdgeInsets.symmetric(
                    horizontal: isLandscape ? 36 : 24,
                    vertical: isLandscape ? 10 : 24,
                  ),
                  iconPadding: EdgeInsets.only(
                    top: isLandscape ? 10 : 20,
                    bottom: 4,
                  ),
                  titlePadding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 4,
                  ),
                  contentPadding: EdgeInsets.fromLTRB(
                    24,
                    8,
                    24,
                    isLandscape ? 8 : 14,
                  ),
                  actionsPadding: EdgeInsets.only(
                    left: 24,
                    right: 24,
                    bottom: isLandscape ? 12 : 20,
                    top: 4,
                  ),
                  icon: Icon(
                    isDone
                        ? (isSuccess ? Icons.check_circle : Icons.error_outline)
                        : Icons.sync,
                    color: isDone
                        ? (isSuccess
                              ? AppColors.selectedCategoryGreen
                              : emergencyRed)
                        : emergencyRed,
                    size: isLandscape ? 34 : 44,
                  ),
                  title: Text(
                    isDone ? 'Status do Alerta' : 'Enviando Alerta (WebSocket)',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: isLandscape ? 16 : 18,
                      color: AppColors.titleColor,
                    ),
                  ),
                  content: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: 460,
                      maxHeight: maxDialogHeight,
                    ),
                    child: Scrollbar(
                      thumbVisibility: true,
                      radius: const Radius.circular(12),
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.only(right: 6),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (service.isSending) ...[
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: const LinearProgressIndicator(
                                  color: emergencyRed,
                                  minHeight: 5,
                                ),
                              ),
                              const SizedBox(height: 10),
                            ],
                            if (service.serverStatus != null)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.fieldFillColor,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Status STOMP: ${service.serverStatus}',
                                      style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                        color: AppColors.titleColor,
                                      ),
                                    ),
                                    if (service.maskedPhone != null)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 2),
                                        child: Text(
                                          'Telefone (LGPD): ${service.maskedPhone}',
                                          style: GoogleFonts.poppins(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w400,
                                            color: AppColors.textColor,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            if (service.wsEvents.isNotEmpty) ...[
                              const SizedBox(height: 10),
                              ...service.wsEvents.map(
                                (e) => Padding(
                                  padding: const EdgeInsets.only(bottom: 4),
                                  child: Text(
                                    '• $e',
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w400,
                                      color: AppColors.textColor,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                            if (isDone && service.lastMessage != null) ...[
                              const SizedBox(height: 10),
                              Text(
                                service.lastMessage!,
                                textAlign: TextAlign.center,
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                  color: AppColors.titleColor,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                  actionsAlignment: MainAxisAlignment.center,
                  actions: [
                    if (isDone)
                      ElevatedButton(
                        style: _primaryButtonStyle(
                          isSuccess
                              ? AppColors.selectedCategoryGreen
                              : emergencyRed,
                        ),
                        onPressed: () => Navigator.of(ctx).pop(),
                        child: const Text('Fechar'),
                      ),
                  ],
                );
              },
            ),
          );
        },
      );
    }

    await sendFuture;
    emergency.reset();
  }

  @override
  Widget build(BuildContext context) {
    final sending = context.watch<EmergencyService>().isSending;
    return Semantics(
      button: true,
      label: 'Botão de emergência. Envia um alerta ao responsável.',
      child: Material(
        color: emergencyRed,
        elevation: 6,
        shadowColor: Colors.black38,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: sending ? null : () => _confirmAndSend(context),
          child: SizedBox(
            width: 60,
            height: 60,
            child: Center(
              child: sending
                  ? const SizedBox(
                      width: 26,
                      height: 26,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.add, color: Colors.white, size: 44),
            ),
          ),
        ),
      ),
    );
  }
}
