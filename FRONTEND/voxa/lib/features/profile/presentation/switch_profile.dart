import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:voxa/core/widgets/app_colors.dart';
import 'package:voxa/core/widgets/crown_icon.dart';

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
  List<UserModel> _profiles = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchProfiles();
  }

  Future<void> _fetchProfiles() async {
    final client = Supabase.instance.client;
    final authUser = client.auth.currentUser;
    if (authUser == null) return;

    try {
      final data = await client
          .from('perfil')
          .select()
          .eq('usuario_id', authUser.id)
          .order('is_responsavel', ascending: false);

      final list = (data as List).map<UserModel>((item) {
        final isResp = item['is_responsavel'] == true;
        return UserModel(
          id: item['id'],
          name: item['nome'],
          email: isResp ? (authUser.email ?? '') : '',
          avatarUrl: item['avatar_url'],
          isResponsavel: isResp,
        );
      }).toList();

      if (mounted) {
        setState(() {
          _profiles = list;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _addProfile() async {
    final profile = await Navigator.of(context).push<UserModel>(
      MaterialPageRoute(builder: (_) => const AddDependentProfileScreen()),
    );
    if (profile != null && mounted) {
      setState(() => _profiles.add(profile));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BaseScreenLayout(
      title: 'Trocar De Perfil',
      body: CurvedContentPanel(
        scrollTop: 42,
        contentTopPadding: 28,
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.headerGreen),
              )
            : Column(
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
                                  onTap: () =>
                                      Navigator.of(context).pop(profile),
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
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.person,
                            size: 34,
                            color: AppColors.contentBackground,
                          ),
                        ),
                      ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
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
                  ),
                  if (user.isResponsavel) ...[
                    const SizedBox(width: 4),
                    const CrownIcon(size: 16),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
