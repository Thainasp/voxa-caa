import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:voxa/core/widgets/app_colors.dart';

import '../../../core/widgets/base_screen_layout.dart';
import '../../../core/widgets/curved_content_panel.dart';
import '../../../core/widgets/home_navigation_bar.dart';
import '../../../models/user_model.dart';
import '../../edit/presentation/pages/edit_principal.dart';
import '../../profile/presentation/settings.dart';
import 'edit_profile.dart';
import 'switch_profile.dart';

class ProfilePage extends StatefulWidget {
  final UserModel? user;

  const ProfilePage({super.key, this.user});

  @override
  State<ProfilePage> createState() => _ProfilePageState();

  static const _options = [
    _ProfileOptionData(icon: Icons.edit_outlined, label: 'Editar perfil'),
    _ProfileOptionData(icon: Icons.swap_horiz, label: 'Trocar de Perfil'),
    _ProfileOptionData(
      icon: Icons.add_box_outlined,
      label: 'Editar Cartões/Tabelas',
    ),
    _ProfileOptionData(icon: Icons.settings_outlined, label: 'Configuração'),
    _ProfileOptionData(icon: Icons.logout, label: 'Sair', isDestructive: true),
  ];
}

class _ProfilePageState extends State<ProfilePage> {
  UserModel? _user;

  @override
  void initState() {
    super.initState();
    _user = widget.user;
  }

  Future<void> _showLogoutDialog(BuildContext context) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) {
        return Dialog(
          backgroundColor: AppColors.contentBackground,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24.0),
          ),
          insetPadding: const EdgeInsets.symmetric(horizontal: 36.0),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 28.0,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Finalizar Sessão',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.titleColor,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Tem certeza que deseja sair?',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 17,
                    fontWeight: FontWeight.w400,
                    color: AppColors.titleColor,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton(
                    onPressed: () async {
                      Navigator.of(dialogContext).pop();
                      await Supabase.instance.client.auth.signOut();
                      if (context.mounted) {
                        Navigator.of(
                          context,
                        ).pushNamedAndRemoveUntil('/welcome', (route) => false);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.headerGreen,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    child: Text(
                      'Sim, sair',
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: AppColors.contentBackground,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Botão "Cancelar"
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(dialogContext).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.fieldFillColor,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    child: Text(
                      'Cancelar',
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: AppColors.titleColor,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _handleOptionTap(
    BuildContext context,
    _ProfileOptionData option,
  ) async {
    if (option.isDestructive) {
      _showLogoutDialog(context);
      return;
    }

    switch (option.label) {
      case 'Editar Cartões/Tabelas':
        Navigator.of(context)
            .push(MaterialPageRoute(builder: (_) => const Edit_principal()));
        break;
      case 'Editar perfil':
        final updatedUser = await Navigator.of(context).push<UserModel>(
          MaterialPageRoute(builder: (_) => EditProfileScreen(user: _user)),
        );
        if (updatedUser != null && mounted) {
          setState(() => _user = updatedUser);
        }
        break;
      case 'Trocar de Perfil':
        final selectedUser = await Navigator.of(context).push<UserModel>(
          MaterialPageRoute(builder: (_) => SwitchProfileScreen(user: _user)),
        );
        if (selectedUser != null && mounted) {
          setState(() => _user = selectedUser);
        }
        break;
      case 'Configuração':
        Navigator.of(context)
            .push(MaterialPageRoute(builder: (_) => const SettingsPage()));
        break;
      default:
        break;
    }
  }

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
          child: CircleAvatar(
            backgroundColor: AppColors.categoryBlue,
            child: _user?.avatarUrl == null
                ? const Icon(
                    Icons.person,
                    color: AppColors.contentBackground,
                    size: 52,
                    semanticLabel: 'Foto de perfil',
                  )
                : ClipOval(
                    child: Image.network(
                      _user!.avatarUrl!,
                      width: 104,
                      height: 104,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const Icon(
                        Icons.person,
                        color: AppColors.contentBackground,
                        size: 52,
                        semanticLabel: 'Foto de perfil',
                      ),
                    ),
                  ),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _user?.name ?? 'Usuário',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                color: AppColors.titleColor,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            for (final option in ProfilePage._options) ...[
              Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  hoverColor: Colors.transparent,
                  onTap: () => _handleOptionTap(context, option),
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
                            color: AppColors.contentBackground,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            option.label,
                            softWrap: true,
                            style: GoogleFonts.poppins(
                              color: option.isDestructive
                                  ? Colors.red.shade700
                                  : AppColors.titleColor,
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
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
