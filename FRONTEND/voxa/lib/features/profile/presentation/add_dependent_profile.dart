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
      final nome = _nameController.text.trim();

      final novoPerfil = await client
          .from('perfil')
          .insert({
            'usuario_id': authUser.id,
            'nome': nome,
            'is_responsavel': false,
          })
          .select()
          .single();

      final perfilId = novoPerfil['id'] as String;

      await client.rpc(
        'criar_conteudo_padrao_perfil',
        params: {'novo_perfil_id': perfilId},
      );

      final profile = UserModel(id: perfilId, name: nome, isResponsavel: false);

      if (!mounted) return;
      Navigator.of(context).pop(profile);
    } catch (error) {
      _showMessage('Não foi possível adicionar o perfil: $error');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
    );
  }
}
