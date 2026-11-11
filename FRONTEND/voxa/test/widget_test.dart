import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:voxa/core/config/app_config.dart';
import 'package:voxa/core/presentation/terms_and_conditions.dart';
import 'package:voxa/core/state/active_profile.dart';
import 'package:voxa/core/widgets/home_navigation_bar.dart';
import 'package:voxa/features/auth/presentation/forgot_password.dart';
import 'package:voxa/features/auth/presentation/new_password.dart';
import 'package:voxa/features/profile/presentation/edit_profile.dart';
import 'package:voxa/features/profile/presentation/switch_profile.dart';
import 'package:voxa/models/user_model.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});

    // As fontes vêm da pasta /google_fonts (assets). Sem rede em testes.
    GoogleFonts.config.allowRuntimeFetching = false;

    // Inicialização segura para testes: não faz requisições reais e não
    // depende de sessão salva.
    try {
      await Supabase.initialize(
        url: 'https://fake-project.supabase.co',
        publishableKey: 'fake-anon-key',
        authOptions: const FlutterAuthClientOptions(
          localStorage: EmptyLocalStorage(),
          autoRefreshToken: false,
        ),
      );
    } catch (_) {
      // Já inicializado em outra execução da suíte.
    }
  });

  setUp(() => ActiveProfile.clear());

  // Tamanho de celular em modo retrato (as telas fora da Home são verticais).
  void usePhoneScreen(WidgetTester tester) {
    tester.view.physicalSize = const Size(480, 960);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
  }

  group('HomeNavigationBar', () {
    testWidgets('executa o callback configurado', (tester) async {
      var wasPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            bottomNavigationBar: HomeNavigationBar(
              onHomePressed: () => wasPressed = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byTooltip('Início'));

      expect(wasPressed, isTrue);
    });

    testWidgets('sem sessão não navega para a Home', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          initialRoute: '/segunda',
          routes: {
            '/': (_) => const Scaffold(body: Text('Raiz')),
            '/segunda': (_) => const Scaffold(
              body: Text('Segunda'),
              bottomNavigationBar: HomeNavigationBar(),
            ),
            '/home': (_) => const Scaffold(body: Text('Home')),
          },
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Início'));
      await tester.pumpAndSettle();

      expect(find.text('Segunda'), findsOneWidget);
      expect(find.text('Home'), findsNothing);
    });
  });

  group('Termos e Condições', () {
    testWidgets('aberto pelo cadastro não mostra o botão Home e devolve true '
        'ao aceitar', (tester) async {
      usePhoneScreen(tester);
      bool? accepted;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: ElevatedButton(
                onPressed: () async {
                  accepted = await Navigator.of(context).push<bool>(
                    MaterialPageRoute(
                      builder: (_) => const TermsAndConditionsScreen(),
                    ),
                  );
                },
                child: const Text('abrir'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('abrir'));
      await tester.pumpAndSettle();

      expect(find.byType(HomeNavigationBar), findsNothing);
      expect(find.text('Li e aceito'), findsOneWidget);

      await tester.tap(find.text('Li e aceito'));
      await tester.pumpAndSettle();

      expect(accepted, isTrue);
    });

    testWidgets('aberto pelas Configurações mostra o botão Home', (
      tester,
    ) async {
      usePhoneScreen(tester);

      await tester.pumpWidget(
        const MaterialApp(
          home: TermsAndConditionsScreen(showHomeNavigation: true),
        ),
      );

      expect(find.byType(HomeNavigationBar), findsOneWidget);
      expect(find.text('Li e aceito'), findsNothing);
    });
  });

  group('ActiveProfile', () {
    test('notifica ao trocar e limpa ao sair', () {
      var notifications = 0;
      void listener() => notifications++;
      ActiveProfile.notifier.addListener(listener);
      addTearDown(() => ActiveProfile.notifier.removeListener(listener));

      const dependent = UserModel(id: 'dep-1', name: 'Dependente');
      ActiveProfile.set(dependent);
      expect(ActiveProfile.current?.id, 'dep-1');

      ActiveProfile.clear();
      expect(ActiveProfile.current, isNull);
      expect(notifications, 2);
    });
  });

  group('Recuperação de senha', () {
    test('o deep link do app bate com o configurado no AndroidManifest', () {
      expect(
        AppConfig.mobileAuthRedirect,
        'io.supabase.voxa://login-callback/',
      );
      // Nos testes (VM, não web) o redirect é o deep link do app.
      expect(AppConfig.authRedirectUrl, AppConfig.mobileAuthRedirect);
    });

    testWidgets('tela de esqueci a senha abre sem erros', (tester) async {
      usePhoneScreen(tester);
      await tester.pumpWidget(
        const MaterialApp(home: ForgotPasswordScreen()),
      );

      expect(find.byType(ForgotPasswordScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('tela de nova senha abre sem erros', (tester) async {
      usePhoneScreen(tester);
      await tester.pumpWidget(const MaterialApp(home: NewPasswordScreen()));

      expect(find.byType(NewPasswordScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('Perfis', () {
    testWidgets('adicionar perfil abre o cadastro de dependente', (
      tester,
    ) async {
      usePhoneScreen(tester);

      await tester.pumpWidget(
        MaterialApp(
          home: SwitchProfileScreen(
            user: const UserModel(
              id: 'responsavel',
              name: 'Responsável',
              email: '',
            ),
          ),
        ),
      );
      // Sem sessão a lista termina de carregar na hora (antes ficava em
      // carregamento infinito).
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Adicionar perfil'));
      await tester.pumpAndSettle();

      expect(find.text('Novo perfil dependente'), findsOneWidget);
    });

    testWidgets('edição de perfil mostra controle para trocar foto', (
      tester,
    ) async {
      usePhoneScreen(tester);

      await tester.pumpWidget(const MaterialApp(home: EditProfileScreen()));

      expect(find.byTooltip('Trocar foto de perfil'), findsOneWidget);
    });
  });
}
