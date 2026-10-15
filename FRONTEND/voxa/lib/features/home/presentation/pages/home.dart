import 'package:flutter/material.dart';
import 'package:voxa/models/user_model.dart';

import '../../../../theme/app_colors.dart';
import '../../../../core/widgets/base_screen_layout.dart';
import '../../../../core/widgets/cartao_padrao.dart';
import '../../../profile/presentation/profile.dart';
import '../controllers/home_content_controller.dart';
import '../widgets/category_navigation.dart';

class HomePage extends StatefulWidget {
  final UserModel? user;

  const HomePage({Key? key, this.user}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final List<Map<String, dynamic>> _fraseSelecionada = [];
  String _categoriaAtual = 'Principal';

  void _falarFrase() {
    if (_fraseSelecionada.isEmpty) return;
    String fraseCompleta = _fraseSelecionada
        .map((item) => item['label'])
        .join(' ');

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Falando: "$fraseCompleta"'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _apagarUltimaPalavra() {
    setState(() {
      if (_fraseSelecionada.isNotEmpty) {
        _fraseSelecionada.removeLast();
      }
    });
  }

  void _voltarInicio() {
    setState(() {
      _categoriaAtual = 'Principal';
      _fraseSelecionada.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> simbolosAtuais =
        HomeContentController.cardsByBoard[_categoriaAtual] ??
        HomeContentController.cardsByBoard['Principal']!;

    return BaseScreenLayout(
      appBar: AppBar(
        //cabecalho
        backgroundColor: AppColors.headerGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        toolbarHeight: 64,
        automaticallyImplyLeading: false,
        titleSpacing: 0,
        leadingWidth: 104,
        leading: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.person_outline, size: 26),
              tooltip: 'Perfil',
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => ProfilePage(user: widget.user), //usando o Navigator.push para sair da Home e abrir a ProfilePage.
                  ),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.home_outlined, size: 28),
              tooltip: 'Início',
              onPressed: _voltarInicio,
            ),
          ],
        ),
        title: Container(
          height: 42,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: Colors.white, width: 1)),
          ),
          child: _fraseSelecionada.isEmpty
              ? const Center(
                  child: Text(
                    'Toque nos cartões para formar a frase...',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                )
              : ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _fraseSelecionada.length,
                  itemBuilder: (context, index) {
                    final item = _fraseSelecionada[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      child: Center(
                        child: Text(
                          item['label'],
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.play_circle_outline, size: 26),
            tooltip: 'Falar frase',
            onPressed: _falarFrase,
          ),
          IconButton(
            icon: const Icon(Icons.backspace_outlined, size: 24),
            tooltip: 'Apagar',
            onPressed: _apagarUltimaPalavra,
          ),
        ],
      ),
      body: LayoutBuilder(
        // responsividade
        builder: (context, constraints) {
          final isLandscape =
              constraints.maxWidth >
              constraints.maxHeight; // verifica se esta em paisagem
          final crossAxisCount = constraints.maxWidth < 480
              ? 4
              : isLandscape && constraints.maxWidth >= 700
              ? 8
              : 6; // define a quantidade de colunas com base no tamanho da tela

          return Column(
            children: [
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: AppColors.contentBackground,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(30),
                    ),
                  ),
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Column(
                    children: [
                      Expanded(
                        child: GridView.builder(
                          padding: const EdgeInsets.all(4.0),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: crossAxisCount,
                                crossAxisSpacing: 10,
                                mainAxisSpacing: 10,
                                childAspectRatio: 1.0,
                              ),
                          itemCount: simbolosAtuais.length,
                          itemBuilder: (context, index) {
                            final symbol = simbolosAtuais[index];
                            return Cartao_Padrao(
                              // pega o padrao do core
                              backgroundColor: symbol['color'],
                              label: symbol['label'],
                              imagePath: symbol['imagePath'] as String?,
                              iconData: symbol['icon'],
                              onTap: () {
                                setState(() {
                                  _fraseSelecionada.add(symbol);
                                });
                              },
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 8),
                      CategoryNavigation(
                        // nagevacao inferior
                        categories: HomeContentController.boards,
                        selectedKey: _categoriaAtual,
                        height: isLandscape ? 64 : 96,
                        iconSize: isLandscape ? 36 : 52,
                        onCategorySelected: (category) {
                          setState(() => _categoriaAtual = category);
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
