import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HomeContentController {
  static List boards = [];
  static Map<String, List> cardsByBoard = {};

  static final Map<String, List> _boardsByProfile = {};
  static final Map<String, Map<String, List>> _cardsByProfile = {};

  static IconData _getIconData(String? iconName) {
    switch (iconName) {
      case 'home': return Icons.home;
      case 'restaurant':
      case 'restaurant_menu': return Icons.restaurant;
      case 'directions_bus': return Icons.directions_bus;
      case 'help': return Icons.help;
      case 'local_drink': return Icons.local_drink;
      case 'apple': return Icons.apple;
      case 'woman': return Icons.woman;
      case 'man': return Icons.man;
      case 'school': return Icons.school;
      case 'medication': return Icons.medication;
      case 'bed': return Icons.bed;
      case 'wc': return Icons.wc;
      case 'pan_tool': return Icons.pan_tool;
      case 'emoji_emotions':
      case 'sentiment_satisfied': return Icons.sentiment_satisfied;
      case 'sentiment_dissatisfied': return Icons.sentiment_dissatisfied;
      case 'battery_full': return Icons.battery_full;
      case 'healing': return Icons.healing;
      case 'mood_bad': return Icons.mood_bad;
      case 'sports_esports': return Icons.sports_esports;
      case 'menu_book': return Icons.menu_book;
      case 'brush': return Icons.brush;
      case 'music_note': return Icons.music_note;
      case 'tv': return Icons.tv;
      case 'person': return Icons.person;
      case 'medical_services': return Icons.medical_services;
      case 'groups': return Icons.groups;
      case 'place': return Icons.place;
      case 'volunteer_activism': return Icons.volunteer_activism;
      case 'check_circle': return Icons.check_circle;
      case 'cancel': return Icons.cancel;
      case 'add_circle': return Icons.add_circle;
      case 'remove_circle': return Icons.remove_circle;
      case 'hourglass_top': return Icons.hourglass_top;
      case 'warning': return Icons.warning;
      case 'category': return Icons.category;
      case 'phone_android': return Icons.phone_android;
      case 'toys': return Icons.toys;
      case 'sports_soccer': return Icons.sports_soccer;
      case 'checkroom': return Icons.checkroom;
      case 'headphones': return Icons.headphones;
      case 'rice_bowl': return Icons.rice_bowl;
      case 'soup_kitchen': return Icons.soup_kitchen;
      case 'dinner_dining': return Icons.dinner_dining;
      case 'local_bar': return Icons.local_bar;
      default: return Icons.image_outlined;
    }
  }

  static Color _hexToColor(String? hexString) {
    if (hexString == null || hexString.isEmpty) return Colors.teal;
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }

  static Future<void> loadContentForProfile(String profileId) async {
    final client = Supabase.instance.client;

    try {
      final pranchasData = await client
          .from('prancha')
          .select()
          .eq('perfil_id', profileId)
          .order('ordem', ascending: true);

      if (pranchasData.isNotEmpty && pranchasData.length >= 8) {
        boards = (pranchasData as List).map((b) {
          return {
            'id': b['id'],
            'key': b['chave'],
            'label': b['nome'],
            'icon': _getIconData(b['icone']),
          };
        }).toList();

        cardsByBoard = {};
        for (final p in pranchasData) {
          final pId = p['id'] as String;
          final pKey = p['chave'] as String;

          final vinculos = await client
              .from('prancha_cartao')
              .select('ordem, cartao:cartao_id (*)')
              .eq('prancha_id', pId)
              .order('ordem', ascending: true);

          final List cards = [];
          for (final item in (vinculos as List)) {
            final c = item['cartao'];
            if (c != null && c is Map<String, dynamic>) {
              cards.add({
                'id': c['id'],
                'label': c['texto'],
                'color': _hexToColor(c['cor_hex']),
                'icon': _getIconData(c['icone']),
                'imagePath': c['caminho_imagem'],
                'audioPath': c['caminho_audio'],
              });
            }
          }
          cardsByBoard[pKey] = cards;
        }

        _boardsByProfile[profileId] = boards;
        _cardsByProfile[profileId] = cardsByBoard;
        return;
      }
    } catch (_) {}

    if (_boardsByProfile.containsKey(profileId) && _cardsByProfile.containsKey(profileId)) {
      boards = _boardsByProfile[profileId]!;
      cardsByBoard = _cardsByProfile[profileId]!;
      return;
    }

    final initialBoards = _getDefaultBoards();
    final initialCards = _getDefaultCards();

    _boardsByProfile[profileId] = initialBoards;
    _cardsByProfile[profileId] = initialCards;

    boards = initialBoards;
    cardsByBoard = initialCards;
  }

  // Lista com as 8 tábuas completas originais
  static List _getDefaultBoards() {
    return [
      {'key': 'Principal', 'icon': Icons.home, 'label': 'Início'},
      {'key': 'Comida', 'icon': Icons.restaurant_menu, 'label': 'Comida'},
      {'key': 'Sentimentos', 'icon': Icons.emoji_emotions, 'label': 'Sentimentos'},
      {'key': 'Atividades', 'icon': Icons.sports_esports, 'label': 'Atividades'},
      {'key': 'Pessoas', 'icon': Icons.groups, 'label': 'Pessoas'},
      {'key': 'Lugares', 'icon': Icons.place, 'label': 'Lugares'},
      {'key': 'Necessidades', 'icon': Icons.volunteer_activism, 'label': 'Necessidades'},
      {'key': 'Objetos', 'icon': Icons.category, 'label': 'Objetos'},
    ];
  }

  static Map<String, List> _getDefaultCards() {
    return {
      'Principal': [
        {'label': 'Quero', 'color': Colors.amber.shade600, 'icon': Icons.pan_tool},
        {'label': 'Comer', 'color': Colors.green, 'icon': Icons.restaurant},
        {'label': 'Ir', 'color': Colors.orange, 'icon': Icons.directions_bus},
        {'label': 'Ajuda', 'color': Colors.blue.shade900, 'icon': Icons.help},
        {'label': 'Água', 'color': Colors.blue.shade400, 'icon': Icons.local_drink},
        {'label': 'Fruta', 'color': Colors.green.shade600, 'icon': Icons.apple},
        {'label': 'Mamãe', 'color': Colors.pink.shade400, 'icon': Icons.woman},
        {'label': 'Papai', 'color': Colors.indigo.shade400, 'icon': Icons.man},
        {'label': 'Escola', 'color': Colors.teal.shade500, 'icon': Icons.school},
        {'label': 'Remédio', 'color': Colors.red.shade400, 'icon': Icons.medication},
        {'label': 'Dormir', 'color': Colors.deepPurple.shade300, 'icon': Icons.bed},
        {'label': 'Banheiro', 'color': Colors.cyan.shade600, 'icon': Icons.wc},
      ],
      'Comida': [
        {'label': 'Arroz', 'color': Colors.amber.shade200, 'icon': Icons.rice_bowl},
        {'label': 'Feijão', 'color': Colors.brown.shade300, 'icon': Icons.soup_kitchen},
        {'label': 'Frango', 'color': Colors.orange.shade300, 'icon': Icons.dinner_dining},
        {'label': 'Suco', 'color': Colors.orange.shade600, 'icon': Icons.local_bar},
        {'label': 'Água', 'color': Colors.blue.shade400, 'icon': Icons.local_drink},
        {'label': 'Maçã', 'color': Colors.red.shade500, 'icon': Icons.apple},
      ],
      'Sentimentos': [
        {'label': 'Feliz', 'color': Colors.yellow.shade700, 'icon': Icons.sentiment_satisfied},
        {'label': 'Triste', 'color': Colors.blue.shade600, 'icon': Icons.sentiment_dissatisfied},
        {'label': 'Cansado', 'color': Colors.purple.shade300, 'icon': Icons.battery_full},
        {'label': 'Com dor', 'color': Colors.red.shade700, 'icon': Icons.healing},
        {'label': 'Bravo', 'color': Colors.red.shade400, 'icon': Icons.mood_bad},
      ],
      'Atividades': [
        {'label': 'Brincar', 'color': Colors.purple, 'icon': Icons.sports_esports},
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
        {'label': 'Acabou', 'color': Colors.blueGrey, 'icon': Icons.remove_circle},
        {'label': 'Espera', 'color': Colors.amber, 'icon': Icons.hourglass_top},
        {'label': 'Socorro', 'color': Colors.redAccent, 'icon': Icons.warning},
      ],
      'Objetos': [
        {'label': 'Celular', 'color': Colors.blueGrey, 'icon': Icons.phone_android},
        {'label': 'Livro', 'color': Colors.indigo, 'icon': Icons.menu_book},
        {'label': 'Brinquedo', 'color': Colors.pink, 'icon': Icons.toys},
        {'label': 'Bola', 'color': Colors.green, 'icon': Icons.sports_soccer},
        {'label': 'Roupa', 'color': Colors.purple, 'icon': Icons.checkroom},
        {'label': 'Música', 'color': Colors.orange, 'icon': Icons.headphones},
      ],
    };
  }
}