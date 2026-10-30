import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:voxa/core/widgets/app_colors.dart';

import '../../../../core/widgets/base_screen_layout.dart';
import '../../../../core/widgets/curved_content_panel.dart';
import '../../../../core/widgets/home_navigation_bar.dart';

class EditTabuaPage extends StatefulWidget {
  final Map<String, dynamic> board;

  const EditTabuaPage({super.key, required this.board});

  @override
  State<EditTabuaPage> createState() => _EditTabuaPageState();
}

class _EditTabuaPageState extends State<EditTabuaPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nomeController;
  late final TextEditingController _imagemController;
  late final TextEditingController _audioController;

  @override
  void initState() {
    super.initState();
    _nomeController = TextEditingController(text: widget.board['label'] ?? '');
    _imagemController = TextEditingController(
      text: widget.board['imagePath'] ?? '',
    );
    _audioController = TextEditingController(
      text: widget.board['audioPath'] ?? '',
    );
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _imagemController.dispose();
    _audioController.dispose();
    super.dispose();
  }

  void _salvar() {
    if (!_formKey.currentState!.validate()) return;

    final updatedBoard = {
      ...widget.board,
      'label': _nomeController.text.trim(),
      'imagePath': _imagemController.text.trim().isEmpty
          ? null
          : _imagemController.text.trim(),
      'audioPath': _audioController.text.trim().isEmpty
          ? null
          : _audioController.text.trim(),
    };

    Navigator.of(context).pop(updatedBoard);
  }

  Widget _buildFieldTitle(String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 4.0, bottom: 6.0),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: AppColors.titleColor,
        ),
      ),
    );
  }

  Widget _buildPillTextField({
    required TextEditingController controller,
    String? hintText,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      style: GoogleFonts.poppins(fontSize: 14, color: AppColors.textColor),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: GoogleFonts.poppins(fontSize: 13, color: Colors.black26),
        filled: true,
        fillColor: AppColors.fieldFillColor,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BaseScreenLayout(
      title: 'Editar',
      body: CurvedContentPanel(
        contentTopPadding: 28,
        maxContentWidth: 540,
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildFieldTitle('Nome'),
              _buildPillTextField(
                controller: _nomeController,
                validator: (val) =>
                    val == null || val.trim().isEmpty ? 'Informe o nome' : null,
              ),
              const SizedBox(height: 18),

              _buildFieldTitle('Imagem'),
              _buildPillTextField(
                controller: _imagemController,
                hintText: 'JPG/JPEG',
              ),
              const SizedBox(height: 18),

              _buildFieldTitle('Audio'),
              _buildPillTextField(
                controller: _audioController,
                hintText: 'MP3',
              ),
              const SizedBox(height: 36),

              Center(
                child: SizedBox(
                  width: 140,
                  height: 44,
                  child: ElevatedButton(
                    onPressed: _salvar,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.headerGreen,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    child: Text(
                      'Salvar',
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const HomeNavigationBar(),
    );
  }
}
