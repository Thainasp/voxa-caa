import 'package:flutter/material.dart';
import 'package:voxa/features/auth/presentation/widgets/custom_text_field.dart';
import 'package:voxa/features/auth/presentation/widgets/social_login_buttons.dart';
import 'package:voxa/models/user_model.dart';
import 'package:voxa/theme/app_colors.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _loginFormKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

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
        _passwordController.text = result.password;
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

  void _handleLogin() async {
    if (!_loginFormKey.currentState!.validate()) {
      return;
    }

    final user = UserRepository.findUser(
      _emailController.text,
      _passwordController.text,
    );

    if (user != null) {
      // Força a tela a rotacionar para o modo horizontal (Landscape)
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);

      if (!mounted) return;

      // Navega para a Home
      Navigator.pushReplacementNamed(context, '/home', arguments: user);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'E-mail ou senha inválidos, ou usuário não cadastrado.',
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');

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
            // Topo Verde (sem SafeArea recortando o topo/laterais para eliminar as linhas brancas)
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
                    color: Colors.black87,
                  ),
                ),
              ),
            ),

            // Card Principal Arredondado
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
                      onPressed: _handleLogin,
                      child: const Text('Login'),
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: TextButton(
                        onPressed: () {},
                        child: Text(
                          'Esqueceu a senha?',
                          style: GoogleFonts.leagueSpartan(
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
                      child: const Text('Cadastre - Se'),
                    ),
                    const SizedBox(height: 25),
                    Center(
                      child: Text(
                        'ou entre com',
                        style: GoogleFonts.leagueSpartan(
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
                          style: GoogleFonts.leagueSpartan(
                            fontSize: 13,
                            fontWeight: FontWeight.w300,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        GestureDetector(
                          onTap: _navigateToRegister,
                          child: Text(
                            'Cadastre - Se',
                            style: GoogleFonts.leagueSpartan(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.blue, // Mesma cor do "Acesse"
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
