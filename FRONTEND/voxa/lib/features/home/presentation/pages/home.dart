import 'package:flutter/material.dart';
import 'package:voxa/models/user_model.dart';

import '../../../../theme/app_colors.dart';
import '../../../../core/widgets/base_screen_layout.dart';
import '../../../../core/widgets/cartao_padrao.dart';
import '../../../profile/presentation/profile.dart';
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

  final Map<String, List<Map<String, dynamic>>> _tabelasSimbolos = {
    'Principal': [
      {
        'label': 'Quero',
        'color': Colors.amber.shade600,
        'icon': Icons.pan_tool,
      },
      {'label': 'Comer', 'color': Colors.green, 'icon': Icons.restaurant},
      {'label': 'Ir', 'color': Colors.orange, 'icon': Icons.directions_bus},
      {'label': 'Ajuda', 'color': Colors.blue.shade900, 'icon': Icons.help},
      {
        'label': 'Água',
        'color': Colors.blue.shade400,
        'icon': Icons.local_drink,
      },
      {'label': 'Fruta', 'color': Colors.green.shade600, 'icon': Icons.apple},
      {'label': 'Mamãe', 'color': Colors.pink.shade400, 'icon': Icons.woman},
      {'label': 'Papai', 'color': Colors.indigo.shade400, 'icon': Icons.man},
      {'label': 'Escola', 'color': Colors.teal.shade500, 'icon': Icons.school},
      {
        'label': 'Remédio',
        'color': Colors.red.shade400,
        'icon': Icons.medication,
      },
      {
        'label': 'Dormir',
        'color': Colors.deepPurple.shade300,
        'icon': Icons.bed,
      },
      {'label': 'Banheiro', 'color': Colors.cyan.shade600, 'icon': Icons.wc},
    ],
    'Comida': [
      {
        'label': 'Arroz',
        'color': Colors.amber.shade200,
        'icon': Icons.rice_bowl,
      },
      {
        'label': 'Feijão',
        'color': Colors.brown.shade300,
        'icon': Icons.soup_kitchen,
      },
      {
        'label': 'Frango',
        'color': Colors.orange.shade300,
        'icon': Icons.dinner_dining,
      },
      {
        'label': 'Suco',
        'color': Colors.orange.shade600,
        'icon': Icons.local_bar,
      },
      {
        'label': 'Água',
        'color': Colors.blue.shade400,
        'icon': Icons.local_drink,
      },
      {'label': 'Maçã', 'color': Colors.red.shade500, 'icon': Icons.apple},
    ],
    'Sentimentos': [
      {
        'label': 'Feliz',
        'color': Colors.yellow.shade700,
        'icon': Icons.sentiment_satisfied,
      },
      {
        'label': 'Triste',
        'color': Colors.blue.shade600,
        'icon': Icons.sentiment_dissatisfied,
      },
      {
        'label': 'Cansado',
        'color': Colors.purple.shade300,
        'icon': Icons.battery_full,
      },
      {'label': 'Com dor', 'color': Colors.red.shade700, 'icon': Icons.healing},
      {'label': 'Bravo', 'color': Colors.red.shade400, 'icon': Icons.mood_bad},
    ],
    'Atividades': [
      {
        'label': 'Brincar',
        'color': Colors.purple,
        'icon': Icons.sports_esports,
      },
      {'label': 'Estudar', 'color': Colors.teal, 'icon': Icons.menu_book},
      {'label': 'Desenhar', 'color': Colors.pink.shade300, 'icon': Icons.brush},
      {'label': 'Música', 'color': Colors.indigo, 'icon': Icons.music_note},
      {'label': 'Assistir TV', 'color': Colors.blueGrey, 'icon': Icons.tv},
    ],
    'Pessoas': [
      {'label': 'Mamãe', 'color': Colors.pink, 'icon': Icons.woman},
      {'label': 'Papai', 'color': Colors.indigo, 'icon': Icons.man},
      {'label': 'Amigo', 'color': Colors.blue, 'icon': Icons.person},
      {'label': 'Professora', 'color': Colors.teal, 'icon': Icons.school},
      {'label': 'Médico', 'color': Colors.red, 'icon': Icons.medical_services},
      {'label': 'Família', 'color': Colors.orange, 'icon': Icons.groups},
    ],
    'Lugares': [
      {'label': 'Casa', 'color': Colors.brown, 'icon': Icons.home},
      {'label': 'Escola', 'color': Colors.blue, 'icon': Icons.school},
      {'label': 'Parque', 'color': Colors.green, 'icon': Icons.park},
      {'label': 'Banheiro', 'color': Colors.cyan, 'icon': Icons.wc},
      {'label': 'Hospital', 'color': Colors.red, 'icon': Icons.local_hospital},
      {'label': 'Loja', 'color': Colors.deepPurple, 'icon': Icons.store},
    ],
    'Necessidades': [
      {'label': 'Sim', 'color': Colors.green, 'icon': Icons.check_circle},
      {'label': 'Não', 'color': Colors.red, 'icon': Icons.cancel},
      {'label': 'Mais', 'color': Colors.orange, 'icon': Icons.add_circle},
      {
        'label': 'Acabou',
        'color': Colors.blueGrey,
        'icon': Icons.remove_circle,
      },
      {'label': 'Espera', 'color': Colors.amber, 'icon': Icons.hourglass_top},
      {'label': 'Socorro', 'color': Colors.redAccent, 'icon': Icons.warning},
    ],
    'Objetos': [
      {
        'label': 'Celular',
        'color': Colors.blueGrey,
        'icon': Icons.phone_android,
      },
      {'label': 'Livro', 'color': Colors.indigo, 'icon': Icons.book},
      {'label': 'Brinquedo', 'color': Colors.pink, 'icon': Icons.toys},
      {'label': 'Bola', 'color': Colors.green, 'icon': Icons.sports_soccer},
      {'label': 'Roupa', 'color': Colors.purple, 'icon': Icons.checkroom},
      {'label': 'Música', 'color': Colors.orange, 'icon': Icons.headphones},
    ],
  };

  final List<Map<String, dynamic>> _bottomCategories = [
    {'key': 'Principal', 'icon': Icons.home, 'label': 'Início'},
    {'key': 'Comida', 'icon': Icons.restaurant_menu, 'label': 'Comida'},
    {
      'key': 'Sentimentos',
      'icon': Icons.emoji_emotions,
      'label': 'Sentimentos',
    },
    {'key': 'Atividades', 'icon': Icons.sports_esports, 'label': 'Atividades'},
    {'key': 'Pessoas', 'icon': Icons.groups, 'label': 'Pessoas'},
    {'key': 'Lugares', 'icon': Icons.place, 'label': 'Lugares'},
    {
      'key': 'Necessidades',
      'icon': Icons.volunteer_activism,
      'label': 'Necessidades',
    },
    {'key': 'Objetos', 'icon': Icons.category, 'label': 'Objetos'},
  ];

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
        _tabelasSimbolos[_categoriaAtual] ?? _tabelasSimbolos['Principal']!;

    return BaseScreenLayout(
      appBar: AppBar(//cabecalho
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
                    builder: (_) => ProfilePage(user: widget.user),//usando o Navigator.push para sair da Home e abrir a ProfilePage.
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
      body: LayoutBuilder(// responsividade
        builder: (context, constraints) {
          final isLandscape = constraints.maxWidth > constraints.maxHeight;// verifica se esta em paisagem
          final crossAxisCount = constraints.maxWidth < 480
              ? 4
              : isLandscape && constraints.maxWidth >= 700
              ? 8
              : 6;// define a quantidade de colunas com base no tamanho da tela

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
                            return Cartao_Padrao(// pega o padrao do core
                              backgroundColor: symbol['color'],
                              label: symbol['label'],
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
                      CategoryNavigation(// nagevacao inferior
                        categories: _bottomCategories,
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
