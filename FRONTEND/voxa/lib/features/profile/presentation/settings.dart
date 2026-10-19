import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:voxa/core/widgets/app_colors.dart';

import '../../../core/widgets/base_screen_layout.dart';
import '../../../core/widgets/curved_content_panel.dart';
import '../../../core/widgets/home_navigation_bar.dart';
import '../../profile/presentation/change_password.dart';
import '../../profile/presentation/delete_account.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final options = [
      _SettingsOptionData(
        icon: Icons.notifications_none,
        title: 'Termos E Condições',
        onTap: () {
          Navigator.of(context).pushNamed('/terms');
        },
      ),
      _SettingsOptionData(
        icon: Icons.vpn_key_outlined,
        title: 'Mudança De Senha',
        onTap: () {
          Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const ChangePasswordPage()));
        },
      ),
      _SettingsOptionData(
        icon: Icons.person_outline,
        title: 'Apagar Conta',
        onTap: () {
          Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const DeleteAccountPage()));
        },
      ),
    ];

    return BaseScreenLayout(
      title: 'Configurações',
      body: CurvedContentPanel(
        maxContentWidth: 720,
        child: Column(
          children: [
            const SizedBox(height: 12),
            for (final item in options) ...[
              Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  hoverColor: Colors.transparent,
                  onTap: item.onTap,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8.0,
                      vertical: 14.0,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 46,
                          height: 46,
                          decoration: const BoxDecoration(
                            color: AppColors.headerGreen,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            item.icon,
                            color: const Color(0xFF24332E),
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            item.title,
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF24332E),
                            ),
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right,
                          color: Color(0xFF24332E),
                          size: 26,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ],
        ),
      ),
      bottomNavigationBar: const HomeNavigationBar(),
    );
  }
}

class _SettingsOptionData {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _SettingsOptionData({
    required this.icon,
    required this.title,
    required this.onTap,
  });
}
