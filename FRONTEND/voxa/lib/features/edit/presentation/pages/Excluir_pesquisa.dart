import 'package:flutter/material.dart';

import '../../../../core/widgets/base_screen_layout.dart';
import '../../../../core/widgets/curved_content_panel.dart';
import '../../../../core/widgets/home_navigation_bar.dart';

class Excluir_pesquisa extends StatelessWidget {
  const Excluir_pesquisa({super.key});

  @override
  Widget build(BuildContext context) {
    return BaseScreenLayout(
      title: 'Escolha qual quer editar',
      body: const CurvedContentPanel(
        child: Center(child: Text('Em construção')),
      ),
      bottomNavigationBar: const HomeNavigationBar(),
    );
  }
}
