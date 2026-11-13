import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:voxa/core/widgets/app_colors.dart';

import '../../../../core/widgets/base_screen_layout.dart';
import '../../../../core/widgets/curved_content_panel.dart';
import '../../../../core/widgets/home_navigation_bar.dart';
import '../../../home/presentation/controllers/home_content_controller.dart';
import '../widgets/device_image_picker.dart';

class EditCartaoPage extends StatefulWidget {
  final Map<String, dynamic> card;
  final String? initialBoardKey;

  const EditCartaoPage({super.key, required this.card, this.initialBoardKey});

  @override
  State<EditCartaoPage> createState() => _EditCartaoPageState();
}

class _EditCartaoPageState extends State<EditCartaoPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nomeController;
  late final TextEditingController _imagemController;
  late final TextEditingController _audioController;
  late String? _selectedBoardKey;
  String? _arasaacId;
  String? _imageStoragePath;
  String? _previewImagePath;
  String? _originalImagePath;
  Uint8List? _imageBytes;
  String? _imageContentType;
  bool _isSaving = false;
  bool _imageChanged = false;

  @override
  void initState() {
    super.initState();
    _nomeController = TextEditingController(text: widget.card['label'] ?? '');
    _originalImagePath = widget.card['imagePath'] as String?;
    _previewImagePath = _originalImagePath;
    _imagemController = TextEditingController(
      text:
          widget.card['imageStoragePath'] != null ||
              _originalImagePath?.startsWith('assets/') == true
          ? ''
          : _originalImagePath ?? '',
    );
    _imageStoragePath = widget.card['imageStoragePath'] as String?;
    _audioController = TextEditingController(
      text: widget.card['audioPath'] ?? '',
    );
    _arasaacId = widget.card['arasaacId']?.toString();
    _selectedBoardKey =
        widget.initialBoardKey ??
        (HomeContentController.editableBoards.isNotEmpty
            ? HomeContentController.editableBoards.first['key']
            : null);
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _imagemController.dispose();
    _audioController.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate() || _selectedBoardKey == null) return;

    setState(() => _isSaving = true);
    final updatedCard = {
      ...widget.card,
      'label': _nomeController.text.trim(),
      'imagePath': _imageChanged
          ? (_imageBytes != null || _imagemController.text.trim().isEmpty
                ? null
                : _imagemController.text.trim())
          : _originalImagePath,
      'imageStoragePath': _imageChanged
          ? _imageStoragePath
          : widget.card['imageStoragePath'],
      'audioPath': _audioController.text.trim().isEmpty
          ? null
          : _audioController.text.trim(),
      'arasaacId': _arasaacId,
      '_imageBytes': _imageBytes,
      '_imageContentType': _imageContentType,
    };

    if (!mounted) return;
    Navigator.of(context)
        .pop({'card': updatedCard, 'boardKey': _selectedBoardKey});
  }

  Future<void> _selecionarImagem() async {
    try {
      final selection = await pickDeviceImage(context);
      if (selection == null || !mounted) return;
      setState(() {
        _imageBytes = Uint8List.fromList(selection.bytes);
        _imageContentType = selection.contentType;
        _imageStoragePath = null;
        _previewImagePath = null;
        _imageChanged = true;
        _arasaacId = null;
        _imagemController.clear();
      });
    } on Exception catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Não foi possível escolher a imagem: $error')),
      );
    }
  }

  String? _validateImageUrl(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final uri = Uri.tryParse(value.trim());
    if (uri == null ||
        !uri.hasAuthority ||
        (uri.scheme != 'http' && uri.scheme != 'https')) {
      return 'Informe uma URL de imagem HTTP ou HTTPS válida';
    }
    return null;
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
    ValueChanged<String>? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      onChanged: onChanged,
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
                hintText: 'URL da imagem (opcional)',
                validator: _validateImageUrl,
                onChanged: (value) {
                  setState(() {
                    _imageChanged = true;
                    if (value.trim().isNotEmpty) {
                      _imageBytes = null;
                      _imageContentType = null;
                      _imageStoragePath = null;
                      _previewImagePath = value.trim();
                      _arasaacId = null;
                    }
                  });
                },
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton.icon(
                  onPressed: _selecionarImagem,
                  icon: const Icon(Icons.add_photo_alternate_outlined),
                  label: const Text('Escolher do celular ou usar a câmera'),
                ),
              ),
              if (_imageBytes != null) ...[
                const SizedBox(height: 8),
                SizedBox(
                  height: 120,
                  child: Image.memory(_imageBytes!, fit: BoxFit.contain),
                ),
              ] else if (_previewImagePath != null &&
                  _previewImagePath!.isNotEmpty) ...[
                const SizedBox(height: 8),
                SizedBox(
                  height: 120,
                  child: _previewImagePath!.startsWith('http')
                      ? Image.network(
                          _previewImagePath!,
                          fit: BoxFit.contain,
                          errorBuilder: (_, _, _) =>
                              const Icon(Icons.broken_image_outlined),
                        )
                      : Image.asset(
                          _previewImagePath!,
                          fit: BoxFit.contain,
                          errorBuilder: (_, _, _) =>
                              const Icon(Icons.broken_image_outlined),
                        ),
                ),
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _previewImagePath = null;
                      _imageStoragePath = null;
                      _imageChanged = true;
                      _imagemController.clear();
                      _arasaacId = null;
                    });
                  },
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Remover imagem'),
                ),
              ],
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
                items: HomeContentController.editableBoards
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
                    onPressed: _isSaving ? null : _salvar,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.headerGreen,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    child: _isSaving
                        ? const SizedBox.square(
                            dimension: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(
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
