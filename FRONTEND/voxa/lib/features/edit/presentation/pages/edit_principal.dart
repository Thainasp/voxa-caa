import 'package:flutter/material.dart';

import '../../../../theme/app_colors.dart';
import '../../../../core/widgets/base_screen_layout.dart';
import '../../../../core/widgets/curved_content_panel.dart';
import '../../../../core/widgets/home_navigation_bar.dart';
import 'Excluir_pesquisa.dart' as excluirPesquisaPage;
import 'edit_pesquisa.dart' as editPesquisaPage;

class _ProfileOptionData {
  final IconData icon;
  final String label;

  const _ProfileOptionData({required this.icon, required this.label});
}

class Edit_principal extends StatelessWidget {
  const Edit_principal({super.key});

  static const options = [
    _ProfileOptionData(
      icon: Icons.edit_square,
      label: 'Criar/editar tabua/cartão',
    ),
    _ProfileOptionData(icon: Icons.backspace, label: 'Excluir Cartão/Tabua'),
  ];

  @override
  Widget build(BuildContext context) {
    return BaseScreenLayout(
      title: 'Edição',
      body: CurvedContentPanel(
        panelTop: 50,
        scrollTop: 20,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: options
              .map(
                (option) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: InkWell(
                    onTap: () {
                      if (option.label == 'Criar/editar tabua/cartão') {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                const editPesquisaPage.Edit_pesquisa(),
                          ),
                        );
                      } else if (option.label == 'Excluir Cartão/Tabua') {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                const excluirPesquisaPage.Excluir_pesquisa(),
                          ),
                        );
                      }
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 12,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 45,
                            height: 45,
                            decoration: BoxDecoration(
                              color: AppColors.headerGreen,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Icon(
                              option.icon,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              option.label,
                              softWrap: true,
                              style: const TextStyle(
                                color: Color(0xFF24332E),
                                fontSize: 17,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              )
              .toList(),
        ),
      ),
      bottomNavigationBar: const HomeNavigationBar(),
    );
  }
}
