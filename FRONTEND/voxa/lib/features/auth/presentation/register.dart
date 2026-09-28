import 'package:flutter/material.dart';
import 'package:voxa/features/auth/presentation/widgets/custom_text_field.dart';
import 'package:voxa/models/user_model.dart';
import 'package:voxa/core/theme/app_colors.dart';
import 'package:google_fonts/google_fonts.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _birthController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _termsAccepted = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _birthController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _handleRegister() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!_termsAccepted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Você deve aceitar os termos de uso para continuar.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final newUser = UserModel(
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      phone: _phoneController.text.trim(),
      birthDate: _birthController.text.trim(),
      password: _passwordController.text,
    );

    UserRepository.addUser(newUser);

    if (Navigator.canPop(context)) {
      Navigator.pop(context, newUser);
    } else {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  void _goToLogin() {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    } else {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');

    return Scaffold(
      // Fundo claro no Scaffold: elimina o retângulo verde que vazava na parte inferior
      backgroundColor: AppColors.contentBackground,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Topo Verde com Título
            Container(
              width: double.infinity,
              color: AppColors.headerGreen,
              padding: const EdgeInsets.only(top: 50, bottom: 35),
              child: Center(
                child: Text(
                  'Criar Conta',
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
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    CustomTextField(
                      label: 'Nome',
                      hintText: 'digite seu nome completo',
                      controller: _nameController,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Por favor, insira o seu nome';
                        }
                        return null;
                      },
                    ),
                    CustomTextField(
                      label: 'Email',
                      hintText: 'exemplo@exemplo.com',
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Insira um e-mail';
                        }
                        if (!emailRegex.hasMatch(value.trim())) {
                          return 'Formato de e-mail inválido';
                        }
                        return null;
                      },
                    ),
                    CustomTextField(
                      label: 'Telefone',
                      hintText: '+12 345678901',
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Por favor, insira o telefone';
                        }
                        final digitsOnly = value.replaceAll(RegExp(r'\D'), '');
                        if (digitsOnly.length < 10) {
                          return 'Insira um telefone válido (DDD + número)';
                        }
                        return null;
                      },
                    ),
                    CustomTextField(
                      label: 'Data De Nascimento',
                      hintText: 'DD / MM / YYYY',
                      controller: _birthController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [DateInputFormatter()],
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Informe a data de nascimento';
                        }
                        if (value.length < 10) {
                          return 'Formato incompleto (DD/MM/YYYY)';
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
                    CustomTextField(
                      label: 'Confirme A Senha',
                      hintText: '••••••••',
                      controller: _confirmPasswordController,
                      isPassword: true,
                      validator: (value) {
                        if (value != _passwordController.text) {
                          return 'As senhas não coincidem';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 8),

                    // Aceite dos Termos
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Checkbox(
                          value: _termsAccepted,
                          activeColor: AppColors.headerGreen,
                          onChanged: (bool? val) {
                            setState(() {
                              _termsAccepted = val ?? false;
                            });
                          },
                        ),
                        Expanded(
                          child: Text(
                            'Ao se cadastrar você aceita os termos de uso e privacidade.',
                            style: GoogleFonts.leagueSpartan(
                              fontSize: 13,
                              fontWeight: FontWeight.w400,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 15),
                    ElevatedButton(
                      onPressed: _handleRegister,
                      child: const Text('Cadastrar'),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Já tem conta? ',
                          style: GoogleFonts.leagueSpartan(
                            fontSize: 13,
                            fontWeight: FontWeight.w300,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        GestureDetector(
                          onTap: _goToLogin,
                          child: Text(
                            'Acesse',
                            style: GoogleFonts.leagueSpartan(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.blue,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 40),
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
