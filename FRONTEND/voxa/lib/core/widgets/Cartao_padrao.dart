import 'package:flutter/material.dart';

class Cartao_Padrao extends StatelessWidget {
  final Color backgroundColor;
  final String label; // Novo: Nome/Texto do cartão
  final String? imagePath; // Novo: Caminho da imagem (opcional)
  final IconData? iconData; // Mantido caso queira usar ícone em vez de imagem
  final VoidCallback onTap; // Ação ao clicar (inclui tocar som)

  const Cartao_Padrao({
    Key? key,
    required this.backgroundColor,
    required this.label,
    this.imagePath,
    this.iconData,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.black12,
            width: 1,
          ), // Borda sutil para destaque
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // --- ÁREA DA IMAGEM OU ÍCONE ---
            Expanded(
              child: Center(
                child: imagePath != null
                    ? Image.asset(
                        imagePath!,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          // Fallback se a imagem não carregar
                          return const Icon(
                            Icons.broken_image,
                            color: Colors.white,
                            size: 30,
                          );
                        },
                      )
                    : Icon(
                        iconData ?? Icons.help_outline,
                        color: Colors.white,
                        size: 32,
                      ),
              ),
            ),
            const SizedBox(height: 4),
            // --- NOME / TEXTO DO CARTÃO ---
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
                shadows: [
                  Shadow(
                    offset: Offset(0, 1),
                    blurRadius: 2,
                    color: Colors.black45, // Sombra para o texto destacar no fundo colorido
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
