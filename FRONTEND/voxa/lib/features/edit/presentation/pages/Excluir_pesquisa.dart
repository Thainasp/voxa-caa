import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:voxa/core/widgets/app_colors.dart';
import '../../../../core/widgets/base_screen_layout.dart';
import '../../../../core/widgets/curved_content_panel.dart';
import '../../../../core/widgets/home_navigation_bar.dart';
import '../../../home/presentation/controllers/home_content_controller.dart';

class Excluir_pesquisa extends StatefulWidget {
  const Excluir_pesquisa({super.key});

  @override
  State<Excluir_pesquisa> createState() => _ExcluirPesquisaState();
}

class _ExcluirPesquisaState extends State<Excluir_pesquisa> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _confirmarExclusao({
    required String itemNome,
    required VoidCallback onConfirm,
  }) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24.0),
          ),
          insetPadding: const EdgeInsets.symmetric(horizontal: 36.0),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 28.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Excluir',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: AppColors.titleColor,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Tem certeza que deseja excluir?\nessa ação nao podera ser desfeita',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: AppColors.titleColor,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(dialogContext).pop();
                      onConfirm();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.headerGreen,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    child: Text(
                      'Sim, Excluir',
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.fieldFillColor,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    child: Text(
                      'Cancelar',
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: AppColors.titleColor,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _excluirTabua(String key) {
    setState(() {
      HomeContentController.boards.removeWhere((b) => b['key'] == key);
      HomeContentController.cardsByBoard.remove(key);
    });
  }

  void _excluirCartao(String label) {
    setState(() {
      for (final cards in HomeContentController.cardsByBoard.values) {
        cards.removeWhere((c) => c['label'] == label);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchQuery.toLowerCase();
    final boards = HomeContentController.boards.where((b) {
      return (b['label'] as String).toLowerCase().contains(query);
    }).toList();

    final allCards = [];
    for (final list in HomeContentController.cardsByBoard.values) {
      for (final card in list) {
        if (!allCards.any((c) => c['label'] == card['label'])) {
          allCards.add(card);
        }
      }
    }

    final filteredCards = allCards.where((c) {
      return (c['label'] as String).toLowerCase().contains(query);
    }).toList();

    return BaseScreenLayout(
      title: 'Escolha Qual Quer Editar',
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
                  itemCount: boards.length,
                  itemBuilder: (context, index) {
                    final board = boards[index];
                    return _ExcluirItemTile(
                      label: board['label'] ?? '',
                      icon: board['icon'] as IconData?,
                      imagePath: board['imagePath'] as String?,
                      color: AppColors.categoryBlue,
                      onTap: () {
                        _confirmarExclusao(
                          itemNome: board['label'] ?? '',
                          onConfirm: () => _excluirTabua(board['key']),
                        );
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
                  itemCount: filteredCards.length,
                  itemBuilder: (context, index) {
                    final card = filteredCards[index];
                    return _ExcluirItemTile(
                      label: card['label'] ?? '',
                      icon: card['icon'] as IconData?,
                      imagePath: card['imagePath'] as String?,
                      color: card['color'] as Color? ?? Colors.blue,
                      onTap: () {
                        _confirmarExclusao(
                          itemNome: card['label'] ?? '',
                          onConfirm: () => _excluirCartao(card['label']),
                        );
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

class _ExcluirItemTile extends StatelessWidget {
  final String label;
  final IconData? icon;
  final String? imagePath;
  final Color color;
  final VoidCallback onTap;

  const _ExcluirItemTile({
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