import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:voxa/core/widgets/app_colors.dart';

import '../../../core/widgets/base_screen_layout.dart';
import '../../../core/widgets/curved_content_panel.dart';
import '../../../core/widgets/home_navigation_bar.dart';
import '../../../models/user_model.dart';
import 'add_dependent_profile.dart';

class SwitchProfileScreen extends StatefulWidget {
  final UserModel? user;

  const SwitchProfileScreen({super.key, this.user});

  @override
  State<SwitchProfileScreen> createState() => _SwitchProfileScreenState();
}

class _SwitchProfileScreenState extends State<SwitchProfileScreen> {
  late final List<UserModel> _profiles;

  @override
  void initState() {
    super.initState();
    _profiles = _loadProfiles();
  }

  @override
  Widget build(BuildContext context) {
    return BaseScreenLayout(
      title: 'Trocar De Perfil',
      body: CurvedContentPanel(
        scrollTop: 42,
        contentTopPadding: 28,
        child: Column(
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                final tileWidth = (constraints.maxWidth - 20) / 2;
                return Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 20,
                  runSpacing: 24,
                  children: _profiles
                      .map(
                        (profile) => SizedBox(
                          width: tileWidth,
                          child: _ProfileChoice(
                            user: profile,
                            onTap: () => Navigator.of(context).pop(profile),
                          ),
                        ),
                      )
                      .toList(),
                );
              },
            ),
            const SizedBox(height: 28),
            SizedBox.square(
              dimension: 64,
              child: IconButton.filled(
                onPressed: _addProfile,
                icon: const Icon(Icons.add, size: 34),
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.headerGreen,
                  foregroundColor: Colors.white,
                ),
                tooltip: 'Adicionar perfil',
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const HomeNavigationBar(),
    );
  }

  List<UserModel> _loadProfiles() {
    final authUser = Supabase.instance.client.auth.currentUser;
    final profiles = <UserModel>[];

    if (authUser != null) {
      final metadata = authUser.userMetadata ?? const <String, dynamic>{};
      profiles.add(
        UserModel(
          id: authUser.id,
          name:
              metadata['display_name'] as String? ??
              metadata['nome'] as String? ??
              authUser.email?.split('@').first ??
              'Usuário',
          email: authUser.email ?? '',
          phone: metadata['telefone'] as String?,
          avatarUrl: metadata['avatar_url'] as String?,
          isResponsavel: true,
        ),
      );

      final dependents = metadata['dependentes'];
      if (dependents is List) {
        profiles.addAll(
          dependents.whereType<Map>().map(
            (profile) => UserModel.fromMap(Map<String, dynamic>.from(profile)),
          ),
        );
      }
    }

    final currentProfile = widget.user;
    if (currentProfile != null) {
      final currentIndex = profiles.indexWhere(
        (profile) => profile.id == currentProfile.id,
      );
      if (currentIndex == -1) {
        profiles.insert(0, currentProfile);
      } else {
        profiles[currentIndex] = UserModel(
          id: currentProfile.id,
          name: currentProfile.name,
          email: currentProfile.email,
          phone: currentProfile.phone,
          birthDate: currentProfile.birthDate,
          isResponsavel: currentProfile.isResponsavel,
          avatarUrl:
              currentProfile.avatarUrl ?? profiles[currentIndex].avatarUrl,
          isDependent: currentProfile.isDependent,
        );
      }
    }
    return profiles;
  }

  Future<void> _addProfile() async {
    final profile = await Navigator.of(context).push<UserModel>(
      MaterialPageRoute(builder: (_) => const AddDependentProfileScreen()),
    );
    if (profile != null && mounted) {
      setState(() => _profiles.add(profile));
    }
  }
}

class _ProfileChoice extends StatelessWidget {
  final UserModel user;
  final VoidCallback onTap;

  const _ProfileChoice({required this.user, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Selecionar perfil ${user.name}',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: AppColors.categoryBlue,
                child: user.avatarUrl == null
                    ? const Icon(
                        Icons.person,
                        size: 34,
                        color: AppColors.contentBackground,
                      )
                    : ClipOval(
                        child: Image.network(
                          user.avatarUrl!,
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(
                                Icons.person,
                                size: 34,
                                color: AppColors.contentBackground,
                              ),
                        ),
                      ),
              ),
              const SizedBox(height: 8),
              Text(
                user.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  color: AppColors.titleColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
