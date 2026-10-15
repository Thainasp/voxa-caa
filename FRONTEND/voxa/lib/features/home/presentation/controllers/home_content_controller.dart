import 'package:flutter/material.dart';

class HomeContentController {
  static final Map<String, List<Map<String, dynamic>>> cardsByBoard = {
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

  static final List<Map<String, dynamic>> boards = [
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
}
