import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:voxa/features/auth/presentation/login.dart';
import 'package:voxa/features/home/presentation/pages/home.dart';
import 'package:voxa/features/profile/presentation/profile.dart';
import 'package:voxa/main.dart';
import 'package:voxa/models/user_model.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();

    // Inicialização segura para o ambiente de testes (não realiza requisições reais)
    // Permite que widgets que escutam o Supabase (como o initState do login) não deem erro
    try {
      await Supabase.initialize(
        url: 'https://fake-project.supabase.co',
        publishableKey: 'fake-anon-key',
      );
    } catch (_) {
      // Evita erro caso já tenha sido inicializado durante a execução da suíte
    }
  });

  testWidgets('abre o login e permite acessar o cadastro', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const VoxaApp());

    expect(find.text('Bem Vindo'), findsOneWidget);
    expect(find.text('Criar Conta'), findsNothing);

    final registerButton = find.text('Cadastre-se').first;
    await tester.ensureVisible(registerButton);
    await tester.tap(registerButton);
    await tester.pumpAndSettle();

    expect(find.text('Criar Conta'), findsOneWidget);
  });

  testWidgets('sair do perfil retorna para o login', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: const ProfilePage(),
        routes: {'/login': (context) => const LoginScreen()},
      ),
    );

    final logoutButton = find.text('Sair');
    await tester.ensureVisible(logoutButton);
    await tester.tap(logoutButton);
    await tester.pumpAndSettle();

    expect(find.text('Bem Vindo'), findsOneWidget);
  });

  testWidgets('perfil mostra o nome do UserModel recebido pela Home', (
    WidgetTester tester,
  ) async {
    // Instância fictícia representando o usuário que viria do Supabase
    final user = UserModel(
      id: 'a1b2c3d4-e5f6-7890-1234-56789abcdef0',
      name: 'Maria da Silva',
      email: 'maria@voxa.com',
      phone: '11999999999',
      birthDate: '01/01/2000',
      isResponsavel: true,
    );

    await tester.pumpWidget(MaterialApp(home: HomePage(user: user)));
    await tester.tap(find.byTooltip('Perfil'));
    await tester.pumpAndSettle();

    expect(find.text('Maria da Silva'), findsOneWidget);
    expect(find.bySemanticsLabel('Foto de perfil genérica'), findsOneWidget);
  });
}