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
            final hidden = !hasSession ||
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

  Future<void> _confirmAndSend(BuildContext context) async {
    final dialogContext = navigatorKey.currentContext;
    if (dialogContext == null) return;
    final emergency = context.read<EmergencyService>();
    final profile = context.read<ProfileProvider>().current;

    final confirmed = await showDialog<bool>(
      context: dialogContext,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        icon: const Icon(Icons.local_hospital, color: emergencyRed, size: 48),
        title: Text(
          'Pedir ajuda?',
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: AppColors.titleColor,
          ),
        ),
        content: Text(
          'Um SMS de alerta será enviado para o telefone do responsável.',
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(color: AppColors.titleColor),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancelar', style: GoogleFonts.poppins()),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: emergencyRed,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              'Enviar alerta',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await emergency.sendAlert(activeProfile: profile);
    final messengerContext = navigatorKey.currentContext;
    if (messengerContext == null || !messengerContext.mounted) return;
    final ok = emergency.state == EmergencyState.sentByServer ||
        emergency.state == EmergencyState.openedSmsApp;
    ScaffoldMessenger.maybeOf(messengerContext)?.showSnackBar(
      SnackBar(
        content: Text(emergency.lastMessage ?? ''),
        backgroundColor: ok ? AppColors.selectedCategoryGreen : emergencyRed,
      ),
    );
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
