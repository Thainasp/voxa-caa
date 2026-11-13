import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:voxa/core/widgets/custom_text_field.dart';
import 'package:voxa/features/auth/presentation/widgets/social_login_buttons.dart';
import 'package:voxa/models/user_model.dart';
import 'package:voxa/core/widgets/app_colors.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _loginFormKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _initializedArgs = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initializedArgs) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is UserModel) {
        _emailController.text = args.email;
      }
      _initializedArgs = true;
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _navigateToRegister() async {
    final result = await Navigator.pushNamed(context, '/register');

    if (result != null && result is UserModel) {
      setState(() {
        _emailController.text = result.email;
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Conta de ${result.name} cadastrada com sucesso!'),
          backgroundColor: AppColors.headerGreen,
        ),
      );
    }
  }

  Future<void> _handleLogin() async {
    if (!_loginFormKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // 1) Autenticação com Supabase Auth. Só aqui "e-mail ou senha inválidos"
      //    faz sentido como mensagem.
      final response = await Supabase.instance.client.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      final authUser = response.user;
      if (authUser == null) {
        throw const AuthException('Falha ao autenticar.');
      }

      // 2) Dados cadastrais. Se falhar, o login continua valendo (a pessoa já
      //    está autenticada) e usamos os dados do próprio Auth.
      final userProfile = await _loadUserProfile(authUser);

      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/home', arguments: userProfile);
    } on AuthException catch (e) {
      _showError(
        _isNetworkError(e)
            ? 'Sem conexão com o servidor. Verifique sua internet e tente novamente.'
            : _friendlyAuthMessage(e),
      );
    } catch (e) {
      _showError(
        _isNetworkError(e)
            ? 'Sem conexão com o servidor. Verifique sua internet e tente novamente.'
            : 'Não foi possível entrar agora. Tente novamente em instantes.',
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Monta o perfil do titular. Nunca lança: em caso de erro (rede, RLS,
  /// linha inexistente em `usuario`) devolve os dados do Auth.
  Future<UserModel> _loadUserProfile(User authUser) async {
    final meta = authUser.userMetadata;
    final metaAvatar = meta?['avatar_url'] as String?;

    final fallback = UserModel(
      id: authUser.id,
      name: (meta?['display_name'] ??
              meta?['nome'] ??
              authUser.email?.split('@').first ??
              'Usuário')
          .toString(),
      email: authUser.email ?? '',
      avatarUrl: metaAvatar,
      isResponsavel: true,
    );

    try {
      final userData = await Supabase.instance.client
          .from('usuario')
          .select()
          .eq('id', authUser.id)
          .maybeSingle();

      if (userData == null) return fallback;

      final fromDb = UserModel.fromMap({...userData});
      return fromDb.copyWith(
        name: fromDb.name.isEmpty ? fallback.name : fromDb.name,
        email: fromDb.email.isEmpty ? fallback.email : fromDb.email,
        // Prefere a foto salva na tabela; o metadata só entra como reserva.
        avatarUrl: fromDb.avatarUrl ?? metaAvatar,
        // Quem faz login com e-mail e senha é sempre o responsável.
        isResponsavel: true,
      );
    } catch (_) {
      return fallback;
    }
  }

  String _friendlyAuthMessage(AuthException e) {
    final msg = e.message.toLowerCase();

    if (msg.contains('invalid login credentials') ||
        msg.contains('invalid credentials')) {
      return 'E-mail ou senha inválidos.';
    }
    if (msg.contains('email not confirmed')) {
      return 'Confirme seu e-mail antes de entrar. Verifique sua caixa de entrada.';
    }
    if (e.statusCode == '429' ||
        msg.contains('too many requests') ||
        msg.contains('rate limit')) {
      return 'Muitas tentativas. Aguarde alguns instantes e tente novamente.';
    }
    if (msg.contains('banned')) {
      return 'Esta conta está bloqueada. Entre em contato com o suporte.';
    }
    return 'Não foi possível entrar: ${e.message}';
  }

  /// Identifica falhas de conexão (sem internet, DNS, timeout, bloqueio).
  bool _isNetworkError(Object error) {
    if (error is TimeoutException) return true;
    final text = '${error.runtimeType} $error'.toLowerCase();
    return text.contains('socketexception') ||
        text.contains('clientexception') ||
        text.contains('retryable') ||
        text.contains('failed host lookup') ||
        text.contains('failed to fetch') ||
        text.contains('network is unreachable') ||
        text.contains('connection refused') ||
        text.contains('connection closed') ||
        text.contains('timed out') ||
        text.contains('timeout');
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
    );
  }

  @override
  Widget build(BuildContext context) {
    final emailRegex = RegExp(r'^[\w.+\-]+@([\w\-]+\.)+[A-Za-z]{2,}$');

    return Scaffold(
      backgroundColor: AppColors.contentBackground,
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(color: AppColors.headerGreen),
              child: Text(
                'Menu do App',
                style: GoogleFonts.poppins(color: Colors.white, fontSize: 20),
              ),
            ),
            const ListTile(leading: Icon(Icons.home), title: Text('Início')),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: AppColors.headerGreen,
        child: const Icon(Icons.help_outline, color: Colors.white),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              color: AppColors.headerGreen,
              padding: const EdgeInsets.only(top: 50, bottom: 35),
              child: Center(
                child: Text(
                  'Bem Vindo',
                  style: GoogleFonts.poppins(
                    fontSize: 30,
                    fontWeight: FontWeight.w600,
                    color: AppColors.titleColor,
                  ),
                ),
              ),
            ),
            Container(
              width: double.infinity,
              transform: Matrix4.translationValues(0.0, -20.0, 0.0),
              decoration: const BoxDecoration(
                color: AppColors.contentBackground,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(35),
                  topRight: Radius.circular(35),
                ),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 30.0,
                vertical: 25.0,
              ),
              child: Form(
                key: _loginFormKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 10),
                    CustomTextField(
                      label: 'Email',
                      hintText: 'exemplo@exemplo.com',
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Por favor, insira o seu e-mail';
                        }
                        if (!emailRegex.hasMatch(value.trim())) {
                          return 'Formato de e-mail inválido';
                        }
                        return null;
                      },
                    ),
                    CustomTextField(
                      label: 'Senha',
                      hintText: '••••••••',
                      controller: _passwordController,
                      isPassword: true,
                      validator: (value) {
                        if (value == null || value.length < 6) {
                          return 'A senha deve conter no mínimo 6 dígitos';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 15),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _handleLogin,
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              'Login',
                              style: GoogleFonts.poppins(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: TextButton(
                        onPressed: () {
                          Navigator.pushNamed(context, '/forgot-password');
                        },
                        child: Text(
                          'Esqueceu a senha?',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 5),
                    ElevatedButton(
                      onPressed: _navigateToRegister,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.fieldFillColor,
                        foregroundColor: Colors.black87,
                        elevation: 0,
                      ),
                      child: Text(
                        'Cadastre-se',
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    const SizedBox(height: 25),
                    Center(
                      child: Text(
                        'ou faça login com',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w300,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SocialIconButton(icon: Icons.facebook, onTap: () {}),
                        const SizedBox(width: 15),
                        SocialIconButton(
                          icon: Icons.g_mobiledata_rounded,
                          onTap: () {},
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Não tem cadastro? ',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w300,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        GestureDetector(
                          onTap: _navigateToRegister,
                          child: Text(
                            'Cadastre-se',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w300,
                              color: Colors.blue,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
