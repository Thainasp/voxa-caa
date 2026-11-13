import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:voxa/core/data/remote/profile_api.dart';
import 'package:voxa/core/services/app_services.dart';
import 'package:voxa/core/state/active_profile.dart';
import 'package:voxa/core/widgets/app_colors.dart';
import 'package:voxa/core/widgets/base_screen_layout.dart';
import 'package:voxa/core/widgets/curved_content_panel.dart';
import 'package:voxa/core/widgets/custom_text_field.dart';
import 'package:voxa/core/widgets/home_navigation_bar.dart';
import 'package:voxa/models/user_model.dart';

class DeleteDependentScreen extends StatefulWidget {
  const DeleteDependentScreen({super.key});

  @override
  State<DeleteDependentScreen> createState() => _DeleteDependentScreenState();
}

class _DeleteDependentScreenState extends State<DeleteDependentScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  ProfileApi get _profileApi =>
      AppServices.isReady ? AppServices.instance.profileApi : ProfileApi();

  List<UserModel> _dependents = [];
  final Set<String> _selectedProfileIds = {};

  bool _isLoading = true;
  bool _isDeleting = false;

  /// Titular (master) para o qual o app volta depois da exclusão.
  UserModel? _master;

  @override
  void initState() {
    super.initState();
    _fetchDependents();
  }

  Future<void> _fetchDependents() async {
    final authUser = _supabase.auth.currentUser;
    if (authUser == null) {
      // Antes ficava em carregamento infinito quando a sessão expirava.
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      final list = await _profileApi.fetchDependents(authUser.id);

      if (mounted) {
        setState(() {
          _dependents = list;
          _isLoading = false;
        });
      }
    } catch (error) {
      if (mounted) setState(() => _isLoading = false);
      _showMessage('Não foi possível carregar os perfis: $error');
    }
  }

  void _toggleSelection(String profileId) {
    setState(() {
      if (_selectedProfileIds.contains(profileId)) {
        _selectedProfileIds.remove(profileId);
      } else {
        _selectedProfileIds.add(profileId);
      }
    });
  }

  void _showDeleteConfirmationModal() {
    if (_selectedProfileIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecione ao menos um perfil para excluir.'),
          backgroundColor: Colors.orangeAccent,
        ),
      );
      return;
    }

    final passwordController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Dialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28.0),
              ),
              insetPadding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    top: 14,
                    right: 14,
                    child: InkWell(
                      onTap: _isDeleting
                          ? null
                          : () => Navigator.of(dialogContext).pop(),
                      borderRadius: BorderRadius.circular(16),
                      child: const Padding(
                        padding: EdgeInsets.all(4.0),
                        child: Icon(
                          Icons.close,
                          size: 24,
                          color: Color(0xFF0F3A2E),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
                    child: Form(
                      key: formKey,
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
                            'Tem certeza que deseja excluir?\nessa ação nao podera ser desfeita e excluirá os dados permanentemente.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              color: AppColors.titleColor,
                              height: 1.35,
                            ),
                          ),
                          const SizedBox(height: 22),
                          CustomTextField(
                            controller: passwordController,
                            hintText: '••••••••',
                            isPassword: true,
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) {
                                return 'Informe sua senha para confirmar';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton(
                              onPressed: _isDeleting
                                  ? null
                                  : () async {
                                      if (!formKey.currentState!.validate()) {
                                        return;
                                      }

                                      setModalState(() => _isDeleting = true);
                                      final success = await _executeDeletion(
                                        passwordController.text.trim(),
                                      );

                                      // O diálogo pode já ter sido fechado.
                                      if (dialogContext.mounted) {
                                        setModalState(
                                          () => _isDeleting = false,
                                        );
                                      }

                                      if (success && dialogContext.mounted) {
                                        Navigator.of(dialogContext).pop();
                                      }
                                      if (success) _goBackToMaster();
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.headerGreen,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(24),
                                ),
                              ),
                              child: _isDeleting
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(
                                          Colors.white,
                                        ),
                                      ),
                                    )
                                  : Text(
                                      'Excluir',
                                      style: GoogleFonts.poppins(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.white,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    ).whenComplete(
      // Espera a animação de fechamento do diálogo antes de liberar o
      // controller (o campo ainda é desenhado durante a transição).
      () => Future<void>.delayed(
        const Duration(milliseconds: 400),
        passwordController.dispose,
      ),
    );
  }

  Future<bool> _executeDeletion(String password) async {
    final authUser = _supabase.auth.currentUser;
    if (authUser == null || authUser.email == null) {
      _showMessage('Sessão expirada. Faça login novamente.');
      return false;
    }

    try {
      final authResponse = await _supabase.auth.signInWithPassword(
        email: authUser.email!,
        password: password,
      );

      if (authResponse.user == null) {
        _showMessage('Senha incorreta.');
        return false;
      }

      final idsToDelete = _selectedProfileIds.toList();

      // Função transacional do banco (excluir_dependente): valida dono e
      // "não responsável" e apaga o conteúdo do perfil numa única transação.
      // Antes o DELETE direto em cascata estourava o tempo (erro 57014).
      for (final id in idsToDelete) {
        await _profileApi.deleteDependent(id, authUser.id);
        if (AppServices.isReady) {
          await AppServices.instance.store.deleteProfile(id);
        }
      }

      // Volta para o titular (master) como perfil ativo do app.
      _master =
          await ActiveProfile.loadMaster() ??
          UserModel(
            id: authUser.id,
            name: 'Titular',
            email: authUser.email ?? '',
            isResponsavel: true,
          );
      ActiveProfile.set(_master);

      if (mounted) {
        setState(() {
          _dependents.removeWhere((d) => idsToDelete.contains(d.id));
          _selectedProfileIds.clear();
        });
      }

      _showMessage('Perfil(is) dependente(s) excluído(s) com sucesso.');
      return true;
    } on TimeoutException {
      _showMessage(
        'O servidor demorou para responder. Verifique a conexão e tente de novo.',
      );
      return false;
    } on PostgrestException catch (e) {
      _showMessage(
        e.code == '57014'
            ? 'A exclusão demorou demais no banco. Aplique a migração '
                  'voxa_migracao_v2.sql no Supabase e tente novamente.'
            : 'Não foi possível excluir: ${e.message}',
      );
      return false;
    } on AuthException catch (e) {
      _showMessage(
        e.message == 'Invalid login credentials'
            ? 'Senha incorreta. Tente novamente.'
            : 'Erro na autenticação: ${e.message}',
      );
      return false;
    } catch (e) {
      _showMessage('Não foi possível excluir: $e');
      return false;
    }
  }

  /// Fecha esta tela devolvendo o titular (master) para a tela de Perfil.
  void _goBackToMaster() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Navigator.of(context).pop(_master);
    });
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.headerGreen,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BaseScreenLayout(
      title: 'Selecione Um\nPerfil Para Excluir',
      body: CurvedContentPanel(
        contentTopPadding: 24,
        child: _isLoading
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: CircularProgressIndicator(color: AppColors.headerGreen),
                ),
              )
            : _dependents.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 48.0),
                      child: Text(
                        'Nenhum perfil dependente cadastrado.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: AppColors.titleColor.withValues(alpha: 0.6),
                        ),
                      ),
                    ),
                  )
                : Column(
                    children: [
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final tileWidth = (constraints.maxWidth - 20) / 2;
                          return Wrap(
                            alignment: WrapAlignment.center,
                            spacing: 20,
                            runSpacing: 24,
                            children: _dependents.map((dependent) {
                              final isSelected =
                                  _selectedProfileIds.contains(dependent.id);
                              return SizedBox(
                                width: tileWidth,
                                child: _DependentSelectionTile(
                                  dependent: dependent,
                                  isSelected: isSelected,
                                  onTap: () => _toggleSelection(dependent.id),
                                ),
                              );
                            }).toList(),
                          );
                        },
                      ),
                      const SizedBox(height: 36),
                      Center(
                        child: Material(
                          color: AppColors.headerGreen,
                          shape: const CircleBorder(),
                          elevation: 0,
                          child: InkWell(
                            customBorder: const CircleBorder(),
                            onTap: _showDeleteConfirmationModal,
                            child: const Padding(
                              padding: EdgeInsets.all(22.0),
                              child: Icon(
                                Icons.delete_outline,
                                color: Color(0xFF0F3A2E),
                                size: 36,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
      ),
      bottomNavigationBar: const HomeNavigationBar(),
    );
  }
}

class _DependentSelectionTile extends StatelessWidget {
  final UserModel dependent;
  final bool isSelected;
  final VoidCallback onTap;

  const _DependentSelectionTile({
    required this.dependent,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? Colors.redAccent : Colors.transparent,
                      width: 3,
                    ),
                  ),
                  child: CircleAvatar(
                    radius: 36,
                    backgroundColor: AppColors.categoryBlue,
                    child: dependent.avatarUrl == null
                        ? const Icon(
                            Icons.person,
                            size: 40,
                            color: AppColors.contentBackground,
                          )
                        : ClipOval(
                            child: Image.network(
                              dependent.avatarUrl!,
                              width: 72,
                              height: 72,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Icon(
                                Icons.person,
                                size: 40,
                                color: AppColors.contentBackground,
                              ),
                            ),
                          ),
                  ),
                ),
                if (isSelected)
                  const Positioned(
                    top: 0,
                    right: 0,
                    child: CircleAvatar(
                      radius: 12,
                      backgroundColor: Colors.redAccent,
                      child: Icon(Icons.check, size: 16, color: Colors.white),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              dependent.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.titleColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}