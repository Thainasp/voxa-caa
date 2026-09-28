import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/base_screen_layout.dart';
import '../../../models/user_model.dart';

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
      appBar: AppBar(
        title: const Text('Perfil', style: TextStyle(color: Colors.black)),
        centerTitle: true,
        backgroundColor: AppColors.headerGreen,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final horizontalPadding = constraints.maxWidth < 480 ? 20.0 : 32.0;

          return Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                top: 42,
                child: Container(
                  decoration: const BoxDecoration(
                    color: AppColors.contentBackground,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(30),
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                top: 42,
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    96,
                    horizontalPadding,
                    20,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 720),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            user?.name ?? 'Usuário',
                            textAlign: TextAlign.center,
                            style: TextStyle(
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
                                  if (option.isDestructive) {
                                    Navigator.of(context)
                                        .pushNamedAndRemoveUntil(
                                          '/login',
                                          (route) => false,
                                        );
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
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
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
                  ),
                ),
              ),
              Positioned(
                top: 8,
                left: (constraints.maxWidth - 104) / 2,
                child: Container(
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
                      child: Icon(
                        Icons.person,
                        color: Colors.white,
                        size: 52,
                        semanticLabel: 'Foto de perfil genérica',
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: Builder(
        builder: (context) {
          final bottomInset = MediaQuery.paddingOf(context).bottom;

          return ColoredBox(
            color: AppColors.contentBackground,
            child: SizedBox(
              height: 64 + bottomInset,
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Material(
                  color: const Color(0xFFDFF7E2),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(32),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: SizedBox(
                    width: 64,
                    height: 64 + bottomInset,
                    child: Padding(
                      padding: EdgeInsets.only(bottom: bottomInset),
                      child: Center(
                        child: IconButton(
                          style: const ButtonStyle(
                            overlayColor: WidgetStatePropertyAll(
                              Colors.transparent,
                            ),
                            backgroundColor: WidgetStatePropertyAll(
                              Colors.transparent,
                            ),
                          ),
                          icon: const Icon(Icons.home, size: 26),
                          color: AppColors.selectedCategoryGreen,
                          tooltip: 'Início',
                          onPressed: () {
                            if (Navigator.of(context).canPop()) {
                              Navigator.of(context).pop();
                            }
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
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
