import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:voxa/core/widgets/app_colors.dart';
import 'package:voxa/models/user_model.dart';

import '../../../core/widgets/base_screen_layout.dart';
import '../../../core/widgets/curved_content_panel.dart';
import '../../../core/widgets/home_navigation_bar.dart';

class AddDependentProfileScreen extends StatefulWidget {
  const AddDependentProfileScreen({super.key});

  @override
  State<AddDependentProfileScreen> createState() =>
      _AddDependentProfileScreenState();
}

class _AddDependentProfileScreenState extends State<AddDependentProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BaseScreenLayout(
      title: 'Adicionar Perfil',
      body: CurvedContentPanel(
        contentTopPadding: 34,
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Novo perfil dependente',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  color: AppColors.titleColor,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Informe o nome do perfil.'
                    : null,
                decoration: InputDecoration(
                  labelText: 'Nome',
                  filled: true,
                  fillColor: AppColors.fieldFillColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 22),
              Center(
                child: FilledButton(
                  onPressed: _isSaving ? null : _save,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.headerGreen,
                    foregroundColor: AppColors.titleColor,
                  ),
                  child: _isSaving
                      ? const SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Salvar perfil'),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const HomeNavigationBar(),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final client = Supabase.instance.client;
    final authUser = client.auth.currentUser;
    if (authUser == null) {
      _showMessage('Sua sessão expirou. Entre novamente.');
      return;
    }

    setState(() => _isSaving = true);
    try {
      final metadata = authUser.userMetadata ?? const <String, dynamic>{};
      final existingProfiles = metadata['dependentes'];
      final dependents = existingProfiles is List
          ? existingProfiles
                .whereType<Map>()
                .map((profile) => Map<String, dynamic>.from(profile))
                .toList()
          : <Map<String, dynamic>>[];
      final profile = UserModel(
        id: _createProfileId(),
        name: _nameController.text.trim(),
        email: '',
        isDependent: true,
      );

      dependents.add(profile.toMetadataMap());
      await client.auth.updateUser(
        UserAttributes(data: {'dependentes': dependents}),
      );

      if (!mounted) return;
      Navigator.of(context).pop(profile);
    } catch (error) {
      _showMessage('Não foi possível adicionar o perfil: $error');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  String _createProfileId() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    final hex = bytes.map((byte) => byte.toRadixString(16).padLeft(2, '0'));
    final value = hex.join();
    return '${value.substring(0, 8)}-${value.substring(8, 12)}-'
        '${value.substring(12, 16)}-${value.substring(16, 20)}-'
        '${value.substring(20)}';
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
    );
  }
}
