import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:voxa/core/widgets/app_colors.dart';

class HomeNavigationBar extends StatelessWidget {
  final VoidCallback? onHomePressed;

  const HomeNavigationBar({super.key, this.onHomePressed});

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.contentBackground,
        border: Border.fromBorderSide(BorderSide.none),
      ),
      height: 64 + bottomInset,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Material(
          color: const Color(0xFFDFF7E2),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          clipBehavior: Clip.antiAlias,
          child: SizedBox(
            width: 64,
            height: 64 + bottomInset,
            child: Padding(
              padding: EdgeInsets.only(bottom: bottomInset),
              child: Center(
                child: IconButton(
                  style: const ButtonStyle(
                    overlayColor: WidgetStatePropertyAll(Colors.transparent),
                    backgroundColor: WidgetStatePropertyAll(Colors.transparent),
                    elevation: WidgetStatePropertyAll(0),
                  ),
                  icon: const Icon(Icons.home, size: 26),
                  color: AppColors.selectedCategoryGreen,
                  tooltip: 'Início',
                  onPressed: () {
                    if (onHomePressed != null) {
                      onHomePressed!();
                    } else {
                      _navigateToHome(context);
                    }
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Volta para a Home removendo todas as telas que estão acima dela.
  ///
  /// - Sem sessão ativa não existe Home para onde voltar (ex.: telas abertas
  ///   antes do login), então não faz nada.
  /// - Se a Home não estiver na pilha (ex.: recarregar a página no web), ela é
  ///   recriada limpando a pilha.
  ///
  /// Importante: o `popUntil` descarta as telas intermediárias sem resultado.
  /// Quem estiver aguardando o retorno de um `push` (ex.: ProfileAccess)
  /// precisa checar se ainda está ativo antes de fazer outro `pop`.
  void _navigateToHome(BuildContext context) {
    if (Supabase.instance.client.auth.currentSession == null) return;

    final navigator = Navigator.of(context);

    var foundHome = false;
    navigator.popUntil((route) {
      if (route.settings.name == '/home') {
        foundHome = true;
        return true;
      }
      return route.isFirst;
    });

    if (foundHome) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (navigator.mounted) {
        navigator.pushNamedAndRemoveUntil('/home', (route) => false);
      }
    });
  }
}
