import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:voxa/core/widgets/app_colors.dart';

import '../../../../core/widgets/base_screen_layout.dart';
import '../../../../core/widgets/curved_content_panel.dart';
import '../../../../core/widgets/home_navigation_bar.dart';
import '../../../home/presentation/controllers/home_content_controller.dart';

class CriarCartaoPage extends StatefulWidget {
  const CriarCartaoPage({super.key});

  @override
  State<CriarCartaoPage> createState() => _CriarCartaoPageState();
}

class _CriarCartaoPageState extends State<CriarCartaoPage> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _imagemController = TextEditingController();
  final _audioController = TextEditingController();
  String? _selectedBoardKey;

  @override
  void initState() {
    super.initState();
    if (HomeContentController.boards.isNotEmpty) {
      _selectedBoardKey = HomeContentController.boards.first['key'] as String;
    }
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _imagemController.dispose();
    _audioController.dispose();
    super.dispose();
  }

  void _salvar() {
    if (!_formKey.currentState!.validate() || _selectedBoardKey == null) return;

    final newCard = {
      'label': _nomeController.text.trim(),
      'color': AppColors.categoryBlue,
      'icon': Icons.image_outlined,
      'imagePath': _imagemController.text.trim().isEmpty
          ? null
          : _imagemController.text.trim(),
      'audioPath': _audioController.text.trim().isEmpty
          ? null
          : _audioController.text.trim(),
    };

    Navigator.of(context).pop({'card': newCard, 'boardKey': _selectedBoardKey});
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
      title: 'Criar',
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
              const SizedBox(height: 18),

              _buildFieldTitle('Adicionar A Tabua'),
              DropdownButtonFormField<String>(
                initialValue: _selectedBoardKey,
                icon: const Icon(
                  Icons.keyboard_arrow_down,
                  color: AppColors.headerGreen,
                ),
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: AppColors.textColor,
                ),
                decoration: InputDecoration(
                  hintText: 'Selecione tabua',
                  hintStyle: GoogleFonts.poppins(
                    fontSize: 13,
                    color: Colors.black26,
                  ),
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
                items: HomeContentController.boards
                    .map(
                      (b) => DropdownMenuItem<String>(
                        value: b['key'] as String,
                        child: Text(b['label'] as String),
                      ),
                    )
                    .toList(),
                onChanged: (val) => setState(() => _selectedBoardKey = val),
                validator: (val) => val == null ? 'Selecione uma tábua' : null,
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
