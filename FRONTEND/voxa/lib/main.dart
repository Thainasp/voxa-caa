import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:voxa/core/data/sync/sync_service.dart';
import 'package:voxa/core/services/app_services.dart';
import 'package:voxa/core/services/emergency_service.dart';
import 'package:voxa/core/state/profile_provider.dart';
import 'package:voxa/core/widgets/emergency_button.dart';

import 'package:voxa/core/navigation/route_observer.dart';
import 'package:voxa/core/presentation/terms_and_conditions.dart';
import 'package:voxa/core/state/active_profile.dart';
import 'package:voxa/core/widgets/app_theme.dart';
import 'package:voxa/features/auth/presentation/forgot_password.dart';
import 'package:voxa/features/auth/presentation/login.dart';
import 'package:voxa/features/auth/presentation/new_password.dart';
import 'package:voxa/features/auth/presentation/register.dart';
import 'package:voxa/features/auth/presentation/welcome_screen.dart';
import 'package:voxa/features/profile/presentation/profile.dart';
import 'package:voxa/features/profile/presentation/profile_access.dart';
import 'package:voxa/features/profile/presentation/settings.dart';
import 'package:voxa/features/splash/presentation/splash_screen.dart';
import 'package:voxa/models/user_model.dart';

import 'features/home/presentation/pages/home.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Fontes: usa somente os arquivos locais da pasta /google_fonts (declarada
  // no pubspec.yaml). Assim o app funciona 100% offline.
  GoogleFonts.config.allowRuntimeFetching = false;

  // Todas as telas ficam na vertical. Somente a Home trava a horizontal
  // enquanto estiver visível (ver home.dart).
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  await dotenv.load(fileName: ".env");

  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    publishableKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  // SQLite, catálogo, sincronização, notificações, voz e emergência.
  final services = await AppServices.init();

  Supabase.instance.client.auth.onAuthStateChange.listen((data) {
    switch (data.event) {
      case AuthChangeEvent.signedIn:
      case AuthChangeEvent.initialSession:
        final user = data.session?.user;
        if (user != null) {
          // Permissão de notificação (Android 13+) e telefone do responsável
          // guardado para o plano B offline do botão de emergência.
          services.notifications.requestPermission();
          services.emergency.cachePhone(user.id);
          services.sync.sync(showNotifications: true);
        }
        break;
      case AuthChangeEvent.passwordRecovery:
        // Chegou pelo link do e-mail (deep link no Android / URL no web).
        // Limpa a pilha para não empilhar a tela duas vezes.
        navigatorKey.currentState?.pushNamedAndRemoveUntil(
          '/new-password',
          (route) => false,
        );
        break;
      case AuthChangeEvent.signedOut:
        ActiveProfile.clear();
        services.sync.setActiveProfile(null);
        break;
      default:
        break;
    }
  });

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<SyncService>.value(value: services.sync),
        ChangeNotifierProvider<ProfileProvider>.value(value: services.profile),
        ChangeNotifierProvider<EmergencyService>.value(
          value: services.emergency,
        ),
      ],
      child: const VoxaApp(),
    ),
  );
}

final supabase = Supabase.instance.client;

class VoxaApp extends StatelessWidget {
  const VoxaApp({super.key});

  UserModel? _resolveUser(BuildContext context) {
    final routeUser = ModalRoute.of(context)?.settings.arguments as UserModel?;
    if (routeUser != null) return routeUser;

    // Perfil que já estava em uso (ex.: dependente) tem prioridade sobre o
    // titular ao recriar a Home.
    final activeUser = ActiveProfile.current;
    if (activeUser != null) return activeUser;

    final authUser = supabase.auth.currentUser;
    if (authUser != null) {
      return UserModel(
        id: authUser.id,
        name:
            (authUser.userMetadata?['display_name'] ??
                    authUser.userMetadata?['nome'] ??
                    authUser.userMetadata?['name'] ??
                    'Usuário')
                .toString(),
        email: authUser.email ?? '',
        avatarUrl: authUser.userMetadata?['avatar_url'] as String?,
        isResponsavel: true,
      );
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      navigatorObservers: [routeObserver, topRouteTracker],
      // Botão de emergência sobre todas as telas após o login (item 5).
      builder: (context, child) => EmergencyButtonOverlay(
        navigatorKey: navigatorKey,
        child: child ?? const SizedBox.shrink(),
      ),
      title: 'Voxa - CAA',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/welcome': (context) => const WelcomeScreen(),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        // Aberta pelo cadastro: sem botão Home (veja settings.dart para o
        // modo com botão Home).
        '/terms': (context) => const TermsAndConditionsScreen(),
        '/forgot-password': (context) => const ForgotPasswordScreen(),
        '/new-password': (context) => const NewPasswordScreen(),
        '/home': (context) => HomePage(user: _resolveUser(context)),
        '/profile-access': (context) => const ProfileAccessScreen(),
        '/profile': (context) => ProfilePage(user: _resolveUser(context)),
        '/settings': (context) => const SettingsPage(),
      },
    );
  }
}
