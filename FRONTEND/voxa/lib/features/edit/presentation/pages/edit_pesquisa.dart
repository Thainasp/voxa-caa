import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:voxa/core/widgets/app_colors.dart';
import '../../../../core/widgets/base_screen_layout.dart';
import '../../../../core/widgets/curved_content_panel.dart';
import '../../../../core/widgets/home_navigation_bar.dart';
import '../../../home/presentation/controllers/home_content_controller.dart';
import 'criar_cartao.dart';
import 'criar_tabua.dart';
import 'edit_cartao.dart';
import 'edit_tabua.dart';

class Edit_pesquisa extends StatefulWidget {
  const Edit_pesquisa({super.key});

  @override
  State<Edit_pesquisa> createState() => _EditPesquisaState();
}

class _EditPesquisaState extends State<Edit_pesquisa> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onBoardSaved(Map<String, dynamic> savedBoard, bool isNew) {
    setState(() {
      if (isNew) {
        HomeContentController.boards.add(savedBoard);
        HomeContentController.cardsByBoard[savedBoard['key']] = [];
      } else {
        final index = HomeContentController.boards.indexWhere(
          (b) => b['key'] == savedBoard['key'],
        );
        if (index != -1) HomeContentController.boards[index] = savedBoard;
      }
    });
  }

  void _onCardSaved(Map<String, dynamic> savedCard, String boardKey, bool isNew) {
    setState(() {
      if (!isNew) {
        for (final cards in HomeContentController.cardsByBoard.values) {
          cards.removeWhere((c) => c['label'] == savedCard['label']);
        }
      }
      HomeContentController.cardsByBoard.putIfAbsent(boardKey, () => []).add(savedCard);
    });
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchQuery.toLowerCase();
    final boards = HomeContentController.boards.where((b) {
      return (b['label'] as String).toLowerCase().contains(query);
    }).toList();

    final allCards = [];
    for (final entry in HomeContentController.cardsByBoard.entries) {
      for (final card in entry.value) {
        if (!allCards.any((c) => c['label'] == card['label'])) {
          final cardCopy = Map<String, dynamic>.from(card);
          cardCopy['boardKey'] = entry.key;
          allCards.add(cardCopy);
        }
      }
    }

    final filteredCards = allCards.where((c) {
      return (c['label'] as String).toLowerCase().contains(query);
    }).toList();

    return BaseScreenLayout(
      title: 'Escolha qual quer editar',
      body: CurvedContentPanel(
        contentTopPadding: 20,
        contentBottomPadding: 24,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: 40,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              child: TextField(
                controller: _searchController,
                onChanged: (val) => setState(() => _searchQuery = val.trim()),
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w300,
                  color: AppColors.textColor,
                ),
                decoration: InputDecoration(
                  hintText: 'Pesquisar',
                  hintStyle: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w300,
                    color: Colors.black38,
                  ),
                  prefixIcon: const Icon(Icons.search, size: 20, color: Colors.black45),
                  suffixIcon: _searchQuery.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.close, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        ),
                  filled: true,
                  fillColor: AppColors.fieldFillColor,
                  contentPadding: EdgeInsets.zero,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 8),
              child: Text(
                'Tabuas',
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: AppColors.titleColor,
                ),
              ),
            ),
            const Divider(color: AppColors.headerGreen, thickness: 1, height: 1),
            const SizedBox(height: 16),

            LayoutBuilder(
              builder: (context, constraints) {
                final crossAxisCount = constraints.maxWidth < 480 ? 3 : 4;
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.85,
                  ),
                  itemCount: boards.length + 1,
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return _AddSquareTile(
                        label: 'Nova Tábua',
                        onTap: () async {
                          final result = await Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const CriarTabuaPage()),
                          );
                          if (result != null) _onBoardSaved(result, true);
                        },
                      );
                    }
                    final board = boards[index - 1];
                    return _ItemDisplayTile(
                      label: board['label'] ?? '',
                      icon: board['icon'] as IconData?,
                      imagePath: board['imagePath'] as String?,
                      color: AppColors.categoryBlue,
                      onTap: () async {
                        final result = await Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => EditTabuaPage(board: board)),
                        );
                        if (result != null) _onBoardSaved(result, false);
                      },
                    );
                  },
                );
              },
            ),

            const SizedBox(height: 28),

            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 8),
              child: Text(
                'Cartões',
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: AppColors.titleColor,
                ),
              ),
            ),
            const Divider(color: AppColors.headerGreen, thickness: 1, height: 1),
            const SizedBox(height: 16),

            LayoutBuilder(
              builder: (context, constraints) {
                final crossAxisCount = constraints.maxWidth < 480 ? 3 : 4;
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.85,
                  ),
                  itemCount: filteredCards.length + 1,
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return _AddSquareTile(
                        label: 'Novo Cartão',
                        onTap: () async {
                          final result = await Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const CriarCartaoPage()),
                          );
                          if (result != null) {
                            _onCardSaved(result['card'], result['boardKey'], true);
                          }
                        },
                      );
                    }
                    final card = filteredCards[index - 1];
                    return _ItemDisplayTile(
                      label: card['label'] ?? '',
                      icon: card['icon'] as IconData?,
                      imagePath: card['imagePath'] as String?,
                      color: card['color'] as Color? ?? Colors.blue,
                      onTap: () async {
                        final result = await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => EditCartaoPage(
                              card: card,
                              initialBoardKey: card['boardKey'],
                            ),
                          ),
                        );
                        if (result != null) {
                          _onCardSaved(result['card'], result['boardKey'], false);
                        }
                      },
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
      bottomNavigationBar: const HomeNavigationBar(),
    );
  }
}

class _AddSquareTile extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _AddSquareTile({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Column(
        children: [
          Container(
            height: 78,
            width: 78,
            decoration: BoxDecoration(
              color: AppColors.headerGreen,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(Icons.add, color: Colors.white, size: 40),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: AppColors.titleColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _ItemDisplayTile extends StatelessWidget {
  final String label;
  final IconData? icon;
  final String? imagePath;
  final Color color;
  final VoidCallback onTap;

  const _ItemDisplayTile({
    required this.label,
    this.icon,
    this.imagePath,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Column(
        children: [
          Container(
            height: 78,
            width: 78,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(20),
            ),
            child: imagePath != null && imagePath!.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: imagePath!.startsWith('http')
                        ? Image.network(imagePath!, fit: BoxFit.contain)
                        : Image.asset(imagePath!, fit: BoxFit.contain),
                  )
                : Icon(icon ?? Icons.image_outlined, color: Colors.white, size: 36),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: AppColors.titleColor,
            ),
          ),
        ],
      ),
    );
  }
}