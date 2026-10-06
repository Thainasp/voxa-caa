import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:voxa/features/splash/presentation/splash_screen.dart';
import 'package:voxa/features/auth/presentation/welcome_screen.dart';
import 'package:voxa/features/auth/presentation/login.dart';
import 'package:voxa/features/auth/presentation/register.dart';
import 'package:voxa/features/auth/presentation/forgot_password.dart';
import 'package:voxa/features/auth/presentation/new_password.dart';

import 'package:voxa/core/presentation/terms_and_conditions.dart';
import 'package:voxa/models/user_model.dart';
import 'package:voxa/theme/app_theme.dart';
import 'features/home/presentation/pages/home.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env");

  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    publishableKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  Supabase.instance.client.auth.onAuthStateChange.listen((data) {
    if (data.event == AuthChangeEvent.passwordRecovery) {
      navigatorKey.currentState?.pushNamed('/new-password');
    }
  });

  runApp(const VoxaApp());
}

final supabase = Supabase.instance.client;

class VoxaApp extends StatelessWidget {
  const VoxaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Voxa - CAA',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/welcome': (context) => const WelcomeScreen(),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/terms': (context) => const TermsAndConditionsScreen(),
        '/forgot-password': (context) => const ForgotPasswordScreen(),
        '/new-password': (context) => const NewPasswordScreen(),
        '/home': (context) => HomePage(
          user: ModalRoute.of(context)?.settings.arguments as UserModel?,
        ),
      },
    );
  }
}