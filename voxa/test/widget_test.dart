// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:voxa/main.dart';

void main() {
  testWidgets('abre o cadastro e permite acessar o login', (WidgetTester tester) async {
    await tester.pumpWidget(const VoxaApp());

    expect(find.text('Criar Conta'), findsOneWidget);

    final accessText = find.text('Acesse');
    await tester.ensureVisible(accessText);
    await tester.tap(accessText);
    await tester.pumpAndSettle();

    expect(find.text('Bem Vindo'), findsOneWidget);
  });
}
