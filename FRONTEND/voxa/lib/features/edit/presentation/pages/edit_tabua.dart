import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:voxa/core/widgets/app_colors.dart';

import '../../../../core/widgets/base_screen_layout.dart';
import '../../../../core/widgets/curved_content_panel.dart';
import '../../../../core/widgets/home_navigation_bar.dart';
import '../widgets/device_image_picker.dart';

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
  String? _imageStoragePath;
  String? _previewImagePath;
  String? _originalImagePath;
  Uint8List? _imageBytes;
  String? _imageContentType;
  bool _imageChanged = false;

  @override
  void initState() {
    super.initState();
    _nomeController = TextEditingController(text: widget.board['label'] ?? '');
    _originalImagePath = widget.board['imagePath'] as String?;
    _previewImagePath = _originalImagePath;
    _imagemController = TextEditingController(
      text:
          widget.board['imageStoragePath'] != null ||
              _originalImagePath?.startsWith('assets/') == true
          ? ''
          : _originalImagePath ?? '',
    );
    _imageStoragePath = widget.board['imageStoragePath'] as String?;
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
      'imagePath': _imageChanged
          ? (_imageBytes != null || _imagemController.text.trim().isEmpty
                ? null
                : _imagemController.text.trim())
          : _originalImagePath,
      'imageStoragePath': _imageChanged
          ? _imageStoragePath
          : widget.board['imageStoragePath'],
      '_imageBytes': _imageBytes,
      '_imageContentType': _imageContentType,
      'audioPath': _audioController.text.trim().isEmpty
          ? null
          : _audioController.text.trim(),
    };

    Navigator.of(context).pop(updatedBoard);
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
                  setState(() => _imageChanged = true);
                  if (value.trim().isNotEmpty) {
                    setState(() {
                      _imageBytes = null;
                      _imageContentType = null;
                      _imageStoragePath = null;
                      _previewImagePath = value.trim();
                    });
                  }
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
