import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../../../core/widgets/base_screen_layout.dart';
import '../../../core/widgets/curved_content_panel.dart';
import '../../../core/widgets/home_navigation_bar.dart';
import '../../../models/user_model.dart';
import '../../edit/presentation/pages/edit_principal.dart';

class ProfilePage extends StatelessWidget {
  final UserModel? user;

  const ProfilePage({super.key, this.user});

  static const _options = [
    _ProfileOptionData(icon: Icons.edit_outlined, label: 'Editar perfil'),
    _ProfileOptionData(icon: Icons.swap_horiz, label: 'Trocar de Perfil'),
    _ProfileOptionData(
      icon: Icons.add_box_outlined,
      label: 'Editar Cartões/Tabelas',
    ),
    _ProfileOptionData(icon: Icons.favorite_border, label: 'Editar Favoritos'),
    _ProfileOptionData(icon: Icons.settings_outlined, label: 'Configuração'),
    _ProfileOptionData(icon: Icons.logout, label: 'Sair', isDestructive: true),
  ];

  @override
  Widget build(BuildContext context) {
    return BaseScreenLayout(
      title: 'Perfil',
      body: CurvedContentPanel(
        maxContentWidth: 720,
        topOverlay: Container(
          width: 104,
          height: 104,
          padding: const EdgeInsets.all(2),
          decoration: const BoxDecoration(
            color: AppColors.contentBackground,
            shape: BoxShape.circle,
          ),
          child: ClipOval(
            child: ColoredBox(
              color: AppColors.categoryBlue,
              child: const Icon(
                Icons.person,
                color: Colors.white,
                size: 52,
                semanticLabel: 'Foto de perfil',
              ),
            ),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              user?.name ?? 'Usuário',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF24332E),
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            for (final option in _options) ...[
              Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  hoverColor: Colors.transparent,
                  onTap: () {
                    if (option.label == 'Editar Cartões/Tabelas') {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const Edit_principal(),
                        ),
                      );
                    } else if (option.isDestructive) {
                      Navigator.of(context)
                          .pushNamedAndRemoveUntil('/login', (route) => false);
                    }
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: AppColors.categoryBlue,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(
                            option.icon,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            option.label,
                            softWrap: true,
                            style: TextStyle(
                              color: option.isDestructive
                                  ? Colors.red.shade700
                                  : const Color(0xFF24332E),
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ],
        ),
      ),
      bottomNavigationBar: const HomeNavigationBar(),
    );
  }
}

class _ProfileOptionData {
  final IconData icon;
  final String label;
  final bool isDestructive;

  const _ProfileOptionData({
    required this.icon,
    required this.label,
    this.isDestructive = false,
  });
}
