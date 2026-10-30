import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:voxa/core/widgets/app_colors.dart';
import 'package:voxa/core/widgets/custom_text_field.dart';
import 'package:voxa/core/widgets/home_navigation_bar.dart';
import 'package:voxa/models/user_model.dart';
import 'package:voxa/features/profile/presentation/profile.dart';

class ProfileAccessScreen extends StatefulWidget {
  final UserModel? currentUser;

  const ProfileAccessScreen({super.key, this.currentUser});

  @override
  State<ProfileAccessScreen> createState() => _ProfileAccessScreenState();
}

class _ProfileAccessScreenState extends State<ProfileAccessScreen> {
  final TextEditingController _passwordController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  final SupabaseClient _supabase = Supabase.instance.client;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  void _navigateToHome() {
    Navigator.of(context).pop(widget.currentUser);
  }

  Future<void> _handleAccessProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final user = _supabase.auth.currentUser;
    if (user == null || user.email == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sessão expirada. Faça login novamente.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await _supabase.auth.signInWithPassword(
        email: user.email!,
        password: _passwordController.text.trim(),
      );

      final authUser = response.user;
      if (authUser != null && mounted) {
        UserModel profileToOpen;

        if (widget.currentUser != null) {
          profileToOpen = widget.currentUser!;
        } else {
          String profileId = authUser.id;
          String profileName =
              (authUser.userMetadata?['display_name'] ??
                      authUser.userMetadata?['nome'] ??
                      authUser.userMetadata?['name'] ??
                      'Titular')
                  .toString();
          String? avatarUrl = authUser.userMetadata?['avatar_url'] as String?;
          String? phone = authUser.userMetadata?['telefone'] as String?;

          try {
            final perfilData = await _supabase
                .from('perfil')
                .select()
                .eq('usuario_id', authUser.id)
                .eq('is_responsavel', true)
                .maybeSingle();

            if (perfilData != null) {
              profileId = perfilData['id'] as String;
              if (perfilData['nome'] != null) profileName = perfilData['nome'];
              if (perfilData['avatar_url'] != null)
                avatarUrl = perfilData['avatar_url'];
            }
          } catch (_) {}

          profileToOpen = UserModel(
            id: profileId,
            email: authUser.email!,
            name: profileName,
            phone: phone,
            avatarUrl: avatarUrl,
            isResponsavel: true,
          );
        }

        // Abre a tela de perfil e devolve o perfil resultante para a Home
        final result = await Navigator.of(context).push<UserModel>(
          MaterialPageRoute(
            builder: (context) => ProfilePage(user: profileToOpen),
          ),
        );

        if (mounted) {
          Navigator.of(context).pop(result ?? profileToOpen);
        }
      }
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.message == 'Invalid login credentials'
                  ? 'Senha incorreta. Tente novamente.'
                  : 'Erro na autenticação: ${e.message}',
            ),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ocorreu um erro inesperado. Tente novamente.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.contentBackground,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Container(
              color: AppColors.headerGreen,
              padding: const EdgeInsets.only(left: 12.0, top: 4.0, bottom: 4.0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.arrow_back,
                      color: AppColors.titleColor,
                      size: 28,
                    ),
                    onPressed: _navigateToHome,
                  ),
                ],
              ),
            ),
            Expanded(
              child: Stack(
                children: [
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    height: 40,
                    child: Container(color: AppColors.headerGreen),
                  ),
                  Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: AppColors.contentBackground,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(36),
                        topRight: Radius.circular(36),
                      ),
                    ),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 32.0),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const SizedBox(height: 72),
                            Text(
                              'Por favor, entre com a sua senha para\ncontinuar',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.poppins(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                color: AppColors.titleColor,
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 36),
                            CustomTextField(
                              controller: _passwordController,
                              hintText: '••••••••',
                              isPassword: true,
                              keyboardType: TextInputType.visiblePassword,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Por favor, digite sua senha';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 36),
                            SizedBox(
                              width: double.infinity,
                              height: 48,
                              child: ElevatedButton(
                                onPressed: _isLoading
                                    ? null
                                    : _handleAccessProfile,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.headerGreen,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(24),
                                  ),
                                ),
                                child: _isLoading
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                Colors.white,
                                              ),
                                        ),
                                      )
                                    : Text(
                                        'Acessar Perfil',
                                        style: GoogleFonts.poppins(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.white,
                                        ),
                                      ),
                              ),
                            ),
                            const SizedBox(height: 14),
                            SizedBox(
                              width: double.infinity,
                              height: 48,
                              child: ElevatedButton(
                                onPressed: _navigateToHome,
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
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: HomeNavigationBar(onHomePressed: _navigateToHome),
    );
  }
}
