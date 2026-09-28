import 'package:flutter/material.dart';

import 'package:voxa/features/auth/presentation/login.dart';
import 'package:voxa/features/auth/presentation/register.dart';
import 'package:voxa/models/user_model.dart';
import 'package:voxa/theme/app_theme.dart';

import 'features/home/presentation/pages/home.dart';

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
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/home': (context) => HomePage(
          user: ModalRoute.of(context)?.settings.arguments as UserModel?,
        ),
      },
    );
  }
}
