import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:voxa/core/state/active_profile.dart';
import 'package:voxa/core/widgets/app_colors.dart';

import '../../../core/widgets/base_screen_layout.dart';
import '../../../core/widgets/curved_content_panel.dart';
import '../../../core/widgets/home_navigation_bar.dart';
import '../../../models/user_model.dart';

class EditProfileScreen extends StatefulWidget {
  final UserModel? user;

  const EditProfileScreen({super.key, this.user});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;

  String _initialName = '';
  String _initialPhone = '';
  String _initialEmail = '';

  String? _avatarUrl;
  String? _initialAvatarUrl;

  /// Fotos enviadas ao Storage nesta sessão de edição. Se a pessoa sair sem
  /// salvar, elas são apagadas (best-effort) para não ficarem órfãs.
  final List<String> _sessionUploads = [];
  bool _saved = false;

  static const String _bucket = 'profile-photos';

  bool _isLoading = true;
  bool _isSaving = false;
  bool _isUploadingPhoto = false;

  bool get _isMaster => widget.user?.isResponsavel ?? true;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _phoneController = TextEditingController();
    _emailController = TextEditingController();

    _loadData();
  }

  Future<void> _loadData() async {
    final client = Supabase.instance.client;
    final authUser = client.auth.currentUser;

    if (!_isMaster) {
      String name = widget.user?.name ?? 'Perfil';
      String? avatar = widget.user?.avatarUrl;

      if (widget.user != null) {
        try {
          final perfilData = await client
              .from('perfil')
              .select('nome, avatar_url')
              .eq('id', widget.user!.id)
              .maybeSingle();

          if (perfilData != null) {
            name = perfilData['nome'] ?? name;
            avatar = perfilData['avatar_url'] ?? avatar;
          }
        } catch (_) {}
      }

      _initialName = name;
      _avatarUrl = avatar;
      _initialAvatarUrl = avatar;
      _nameController.text = _initialName;
    } else {
      String name = widget.user?.name ?? '';
      String phone = widget.user?.phone ?? '';
      String email = widget.user?.email ?? authUser?.email ?? '';
      String? avatar = widget.user?.avatarUrl;

      if (authUser != null) {
        try {
          final data = await client
              .from('usuario')
              .select('nome, email, telefone, avatar_url')
              .eq('id', authUser.id)
              .maybeSingle();

          if (data != null) {
            if ((data['nome'] as String?)?.isNotEmpty ?? false) {
              name = data['nome'];
            }
            if ((data['email'] as String?)?.isNotEmpty ?? false) {
              email = data['email'];
            }
            if (data['telefone'] != null) {
              phone = data['telefone'].toString();
            }
            if (data['avatar_url'] != null) {
              avatar = data['avatar_url'].toString();
            }
          }
        } catch (_) {}

        final meta = authUser.userMetadata;
        if (meta != null) {
          if (name.isEmpty) {
            name =
                (meta['display_name'] ??
                        meta['nome'] ??
                        meta['name'] ??
                        'Usuário')
                    .toString();
          }
          if (phone.isEmpty && meta['telefone'] != null) {
            phone = meta['telefone'].toString();
          }
          if (avatar == null && meta['avatar_url'] != null) {
            avatar = meta['avatar_url'].toString();
          }
        }
      }

      _initialName = name.isEmpty ? 'Usuário' : name;
      _initialPhone = phone;
      _initialEmail = email;

      _nameController.text = _initialName;
      _phoneController.text = _initialPhone;
      _emailController.text = _initialEmail;
      _avatarUrl = avatar;
      _initialAvatarUrl = avatar;
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    if (!_saved) {
      for (final url in _sessionUploads) {
        unawaited(_removeStoredAvatar(url));
      }
    }
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _showImagePickerModal() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.contentBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (BuildContext bottomSheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(
                    Icons.camera_alt_outlined,
                    color: AppColors.titleColor,
                    size: 26,
                  ),
                  title: Text(
                    'Tirar foto',
                    style: GoogleFonts.poppins(
                      color: AppColors.titleColor,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  onTap: () {
                    Navigator.of(bottomSheetContext).pop();
                    _pickAndUploadPhoto(ImageSource.camera);
                  },
                ),
                const Divider(
                  color: Colors.black12,
                  thickness: 0.8,
                  height: 1,
                  indent: 16,
                  endIndent: 16,
                ),
                ListTile(
                  leading: const Icon(
                    Icons.image_outlined,
                    color: AppColors.titleColor,
                    size: 26,
                  ),
                  title: Text(
                    'Escolher foto',
                    style: GoogleFonts.poppins(
                      color: AppColors.titleColor,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  onTap: () {
                    Navigator.of(bottomSheetContext).pop();
                    _pickAndUploadPhoto(ImageSource.gallery);
                  },
                ),
                if (_avatarUrl != null && _avatarUrl!.isNotEmpty) ...[
                  const Divider(
                    color: Colors.black12,
                    thickness: 0.8,
                    height: 1,
                    indent: 16,
                    endIndent: 16,
                  ),
                  ListTile(
                    leading: const Icon(
                      Icons.delete_outline,
                      color: Colors.redAccent,
                      size: 26,
                    ),
                    title: Text(
                      'Excluir foto',
                      style: GoogleFonts.poppins(
                        color: Colors.redAccent,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    onTap: () {
                      Navigator.of(bottomSheetContext).pop();
                      setState(() => _avatarUrl = null);
                      _showMessage(
                        'Foto removida. Toque em salvar para aplicar.',
                      );
                    },
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickAndUploadPhoto(ImageSource source) async {
    final authUser = Supabase.instance.client.auth.currentUser;
    if (authUser == null) {
      _showMessage('Sua sessão expirou. Entre novamente.');
      return;
    }

    setState(() => _isUploadingPhoto = true);
    try {
      final selectedImage = await ImagePicker().pickImage(
        source: source,
        imageQuality: 85,
      );
      if (selectedImage == null || !mounted) return;

      final extension = _imageExtension(selectedImage.name);
      final contentType =
          selectedImage.mimeType ?? _imageContentType(extension);
      final ownerId = authUser.id;
      final profileId = widget.user?.id ?? ownerId;
      final stamp = DateTime.now().millisecondsSinceEpoch;
      final path = '$ownerId/$profileId/avatar_$stamp.$extension';
      final storage = Supabase.instance.client.storage.from(_bucket);

      await storage.uploadBinary(
        path,
        await selectedImage.readAsBytes(),
        fileOptions: FileOptions(contentType: contentType, upsert: false),
      );

      final photoUrl = storage.getPublicUrl(path);
      _sessionUploads.add(photoUrl);

      if (!mounted) return;
      setState(() => _avatarUrl = photoUrl);
      _showMessage('Foto carregada. Toque em salvar para aplicar.');
    } catch (error) {
      if (mounted) _showMessage('Não foi possível carregar a foto: $error');
    } finally {
      if (mounted) setState(() => _isUploadingPhoto = false);
    }
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
      final newName = _nameController.text.trim().isEmpty
          ? _initialName
          : _nameController.text.trim();

      if (!_isMaster) {
        final profileId = widget.user!.id;

        await client
            .from('perfil')
            .update({'nome': newName, 'avatar_url': _avatarUrl})
            .eq('id', profileId)
            .eq('usuario_id', authUser.id);

        final updatedProfile = UserModel(
          id: profileId,
          name: newName,
          avatarUrl: _avatarUrl,
          isResponsavel: false,
        );

        await _finishSave(
          updatedProfile,
          'Perfil dependente atualizado com sucesso!',
        );
      } else {
        final newPhone = _phoneController.text.trim().isEmpty
            ? _initialPhone
            : _phoneController.text.trim();
        final newEmail = _emailController.text.trim().isEmpty
            ? _initialEmail
            : _emailController.text.trim();

        final emailChanged =
            newEmail.isNotEmpty && newEmail != (authUser.email ?? '');

        // 1º Supabase Auth (é a etapa que mais costuma falhar). Assim, se der
        //    erro, nenhuma tabela foi alterada.
        await client.auth.updateUser(
          UserAttributes(
            email: emailChanged ? newEmail : null,
            data: {
              'display_name': newName,
              'nome': newName,
              'telefone': newPhone,
              'avatar_url': _avatarUrl,
            },
          ),
        );

        // 2º Tabelas. O e-mail NÃO é gravado em `usuario` aqui: a troca só
        //    vale depois que a pessoa confirmar o link enviado ao novo e-mail.
        await client
            .from('usuario')
            .update({
              'nome': newName,
              'telefone': newPhone,
              'avatar_url': _avatarUrl,
            })
            .eq('id', authUser.id);

        await client
            .from('perfil')
            .update({'nome': newName, 'avatar_url': _avatarUrl})
            .eq('usuario_id', authUser.id)
            .eq('is_responsavel', true);

        final updatedProfile = UserModel(
          id: widget.user?.id ?? authUser.id,
          name: newName,
          email: emailChanged ? (authUser.email ?? _initialEmail) : newEmail,
          phone: newPhone,
          birthDate: widget.user?.birthDate,
          avatarUrl: _avatarUrl,
          isResponsavel: true,
        );

        await _finishSave(
          updatedProfile,
          emailChanged
              ? 'Perfil atualizado! Enviamos um link de confirmação para o novo e-mail.'
              : 'Perfil atualizado com sucesso!',
        );
      }
    } on PostgrestException catch (e) {
      if (mounted) _showMessage('Erro ao salvar no banco: ${e.message}');
    } on AuthException catch (e) {
      if (mounted) _showMessage('Erro de autenticação: ${e.message}');
    } catch (e) {
      if (mounted) _showMessage('Não foi possível salvar as alterações: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  String _imageExtension(String fileName) {
    final extension = fileName.contains('.')
        ? fileName.split('.').last.toLowerCase()
        : 'jpg';
    const supportedExtensions = {'jpg', 'jpeg', 'png', 'webp', 'heic', 'heif'};
    return supportedExtensions.contains(extension) ? extension : 'jpg';
  }

  String _imageContentType(String extension) {
    return switch (extension) {
      'png' => 'image/png',
      'webp' => 'image/webp',
      'heic' => 'image/heic',
      'heif' => 'image/heif',
      _ => 'image/jpeg',
    };
  }

  /// Conclui o salvamento: limpa fotos antigas/órfãs, atualiza o perfil ativo
  /// do app (a Home e o Perfil reagem) e fecha a tela devolvendo o perfil.
  Future<void> _finishSave(UserModel updated, String message) async {
    _saved = true;

    final toRemove = <String>{
      ..._sessionUploads,
      if (_initialAvatarUrl != null && _initialAvatarUrl!.isNotEmpty)
        _initialAvatarUrl!,
    }..remove(_avatarUrl);
    for (final url in toRemove) {
      unawaited(_removeStoredAvatar(url));
    }

    final active = ActiveProfile.current;
    if (active == null || active.id == updated.id) {
      ActiveProfile.set(updated);
    }

    if (!mounted) return;
    _showMessage(message);
    Navigator.of(context).pop(updated);
  }

  /// Apaga um arquivo do bucket a partir da URL pública (best-effort).
  Future<void> _removeStoredAvatar(String url) async {
    final marker = '/$_bucket/';
    final index = url.indexOf(marker);
    if (index == -1) return;

    var path = url.substring(index + marker.length);
    final query = path.indexOf('?');
    if (query != -1) path = path.substring(0, query);
    if (path.isEmpty) return;

    try {
      await Supabase.instance.client.storage.from(_bucket).remove([
        Uri.decodeComponent(path),
      ]);
    } catch (_) {
      // Sem permissão ou arquivo inexistente: ignora.
    }
  }

  Widget _buildCameraButton() {
    return Positioned(
      right: 0,
      bottom: 0,
      child: Tooltip(
        message: 'Trocar foto de perfil',
        child: Material(
          color: AppColors.headerGreen,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: _isUploadingPhoto ? null : _showImagePickerModal,
            child: Padding(
              padding: const EdgeInsets.all(6.0),
              child: _isUploadingPhoto
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(
                      Icons.camera_alt_outlined,
                      size: 18,
                      color: Colors.white,
                    ),
            ),
          ),
        ),
      ),
    );
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.headerGreen),
    );
  }

  Widget _buildFieldTitle(String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 6.0, bottom: 6.0),
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
    TextInputType? keyboardType,
    void Function(String)? onChanged,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      onChanged: onChanged,
      validator: validator,
      style: GoogleFonts.poppins(
        color: AppColors.textColor,
        fontSize: 14,
        fontWeight: FontWeight.w400,
      ),
      decoration: InputDecoration(
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
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: const BorderSide(
            color: AppColors.headerGreen,
            width: 1.2,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BaseScreenLayout(
      title: 'Editar',
      body: CurvedContentPanel(
        contentTopPadding: 72,
        topOverlay: Container(
          width: 104,
          height: 104,
          padding: const EdgeInsets.all(3),
          decoration: const BoxDecoration(
            color: AppColors.contentBackground,
            shape: BoxShape.circle,
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              CircleAvatar(
                backgroundColor: AppColors.categoryBlue,
                child: _avatarUrl == null
                    ? const Icon(
                        Icons.person,
                        color: AppColors.contentBackground,
                        size: 52,
                      )
                    : ClipOval(
                        child: Image.network(
                          _avatarUrl!,
                          width: 104,
                          height: 104,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.person,
                            color: AppColors.contentBackground,
                            size: 52,
                          ),
                        ),
                      ),
              ),
              _buildCameraButton(),
            ],
          ),
        ),
        child: _isLoading
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: CircularProgressIndicator(
                    color: AppColors.headerGreen,
                  ),
                ),
              )
            : Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      _nameController.text.isEmpty
                          ? _initialName
                          : _nameController.text,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        color: AppColors.titleColor,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 28),

                    _buildFieldTitle('Nome'),
                    _buildPillTextField(
                      controller: _nameController,
                      onChanged: (val) => setState(() {}),
                      validator: (val) => val == null || val.trim().isEmpty
                          ? 'Informe o nome.'
                          : null,
                    ),
                    const SizedBox(height: 18),

                    if (_isMaster) ...[
                      _buildFieldTitle('Telefone'),
                      _buildPillTextField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 18),

                      _buildFieldTitle('Email'),
                      _buildPillTextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        validator: (val) {
                          if (val != null &&
                              val.isNotEmpty &&
                              !val.contains('@')) {
                            return 'Informe um e-mail válido.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 32),
                    ] else
                      const SizedBox(height: 24),

                    Center(
                      child: SizedBox(
                        width: 140,
                        height: 44,
                        child: ElevatedButton(
                          onPressed: _isSaving ? null : _save,
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
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
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
