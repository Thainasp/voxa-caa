// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:voxa/features/auth/presentation/login.dart';
import 'package:voxa/features/home/presentation/pages/home.dart';
import 'package:voxa/features/profile/presentation/profile.dart';
import 'package:voxa/core/widgets/home_navigation_bar.dart';
import 'package:voxa/main.dart';
import 'package:voxa/models/user_model.dart';

void main() {
  testWidgets('barra de início executa o callback configurado', (
    WidgetTester tester,
  ) async {
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

  testWidgets('abre o login e permite acessar o cadastro', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const VoxaApp());

    expect(find.text('Bem Vindo'), findsOneWidget);
    expect(find.text('Criar Conta'), findsNothing);

    final registerButton = find.text('Cadastre - Se').first;
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
    final user = UserModel(
      name: 'Maria da Silva',
      email: 'maria@voxa.com',
      phone: '11999999999',
      birthDate: '01/01/2000',
      password: 'senha123',
    );

    await tester.pumpWidget(MaterialApp(home: HomePage(user: user)));
    await tester.tap(find.byTooltip('Perfil'));
    await tester.pumpAndSettle();

    expect(find.text('Maria da Silva'), findsOneWidget);
    expect(find.bySemanticsLabel('Foto de perfil genérica'), findsOneWidget);
  });
}
