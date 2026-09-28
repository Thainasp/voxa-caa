import 'package:flutter/material.dart';
import 'package:voxa/features/auth/presentation/login.dart';
import 'package:voxa/features/auth/presentation/register.dart';
import 'package:voxa/features/home/presentation/pages/home.dart'; // Ajuste o caminho se a sua home estiver em outro diretório
import 'package:voxa/theme/app_theme.dart';

void main() {
  runApp(const VoxaApp());
}

class VoxaApp extends StatelessWidget {
  const VoxaApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Voxa - CAA',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      // Inicia direto na tela de cadastro conforme solicitado
      initialRoute: '/register',
      routes: {
        '/register': (context) => const RegisterScreen(),
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const HomePage(),
      },
    );
  }
}