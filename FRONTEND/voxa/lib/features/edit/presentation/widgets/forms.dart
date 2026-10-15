import 'package:flutter/material.dart';

class FormularioPadrao extends StatelessWidget {
  final List<Widget> campos;
  final VoidCallback onEnviar;
  final String textoBotao;

  const FormularioPadrao({
    super.key,
    required this.campos,
    required this.onEnviar,
    this.textoBotao = 'Salvar',
  });

  @override
  Widget build(BuildContext context) {
    return Form(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ...campos,

          const SizedBox(height: 24),

          SizedBox(
            height: 50,
            child: ElevatedButton(
              onPressed: onEnviar,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                textoBotao,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
