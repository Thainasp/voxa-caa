import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
  String? _avatarUrl;
  bool _isSaving = false;
  bool _isUploadingPhoto = false;

  @override
  void initState() {
    super.initState();
    final authUser = Supabase.instance.client.auth.currentUser;
    _nameController = TextEditingController(
      text:
          widget.user?.name ??
          authUser?.userMetadata?['display_name'] as String? ??
          'Usuário',
    );
    _phoneController = TextEditingController(
      text:
          widget.user?.phone ??
          authUser?.userMetadata?['telefone'] as String? ??
          '',
    );
    _emailController = TextEditingController(
      text: widget.user?.email ?? authUser?.email ?? '',
    );
    _avatarUrl =
        widget.user?.avatarUrl ??
        (widget.user?.isDependent == true
            ? null
            : authUser?.userMetadata?['avatar_url'] as String?);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BaseScreenLayout(
      title: 'Editar Meu Perfil',
      body: CurvedContentPanel(
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
                        size: 48,
                      )
                    : ClipOval(
                        child: Image.network(
                          _avatarUrl!,
                          width: 104,
                          height: 104,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(
                                Icons.person,
                                color: AppColors.contentBackground,
                                size: 48,
                              ),
                        ),
                      ),
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Material(
                  color: AppColors.headerGreen,
                  shape: const CircleBorder(),
                  child: IconButton(
                    onPressed: _isUploadingPhoto ? null : _changeProfilePhoto,
                    tooltip: 'Trocar foto de perfil',
                    icon: _isUploadingPhoto
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.camera_alt_outlined, size: 20),
                  ),
                ),
              ),
            ],
          ),
        ),
        contentTopPadding: 72,
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                _nameController.text,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  color: AppColors.titleColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 26),
              Text(
                'Configuração de Perfil',
                style: GoogleFonts.poppins(
                  color: AppColors.titleColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              _buildField(
                label: 'Nome',
                controller: _nameController,
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Informe seu nome.'
                    : null,
              ),
              const SizedBox(height: 14),
              _buildField(
                label: 'Telefone',
                controller: _phoneController,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 14),
              if (widget.user?.isDependent != true) ...[
                _buildField(
                  label: 'Email',
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) => value == null || !value.contains('@')
                      ? 'Informe um e-mail válido.'
                      : null,
                ),
                const SizedBox(height: 22),
              ] else
                const SizedBox(height: 8),
              Center(
                child: SizedBox(
                  width: 124,
                  height: 42,
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
                        : Text(
                            'Salvar',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
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

  Widget _buildField({
    required String label,
    required TextEditingController controller,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      style: GoogleFonts.poppins(color: AppColors.titleColor, fontSize: 13),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.poppins(
          color: AppColors.titleColor,
          fontSize: 13,
        ),
        filled: true,
        fillColor: AppColors.fieldFillColor,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 11,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.headerGreen),
        ),
      ),
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
      final name = _nameController.text.trim();
      final email = _emailController.text.trim();
      final phone = _phoneController.text.trim();

      final updatedProfile = UserModel(
        id: widget.user?.id ?? authUser.id,
        name: name,
        email: widget.user?.isDependent == true ? '' : email,
        phone: phone,
        birthDate: widget.user?.birthDate,
        isResponsavel: widget.user?.isResponsavel ?? false,
        avatarUrl: _avatarUrl,
        isDependent: widget.user?.isDependent ?? false,
      );

      if (updatedProfile.isDependent) {
        await _saveDependentProfile(client, authUser, updatedProfile);
      } else {
        await client
            .from('usuario')
            .update({'nome': name, 'email': email})
            .eq('id', authUser.id);

        await client.auth.updateUser(
          UserAttributes(
            email: email == authUser.email ? null : email,
            data: {
              'display_name': name,
              'nome': name,
              'telefone': phone,
              'avatar_url': _avatarUrl,
            },
          ),
        );
      }

      if (!mounted) return;
      Navigator.of(context).pop(updatedProfile);
    } catch (error) {
      if (mounted) _showMessage('Não foi possível salvar o perfil: $error');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _changeProfilePhoto() async {
    final authUser = Supabase.instance.client.auth.currentUser;
    if (authUser == null) {
      _showMessage('Sua sessão expirou. Entre novamente.');
      return;
    }

    setState(() => _isUploadingPhoto = true);
    try {
      final selectedImage = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (selectedImage == null || !mounted) return;

      final extension = _imageExtension(selectedImage.name);
      final contentType =
          selectedImage.mimeType ?? _imageContentType(extension);
      final ownerId = authUser.id;
      final profileId = widget.user?.id ?? ownerId;
      final path = '$ownerId/$profileId/avatar.$extension';
      final storage = Supabase.instance.client.storage.from('profile-photos');
      await storage.uploadBinary(
        path,
        await selectedImage.readAsBytes(),
        fileOptions: FileOptions(contentType: contentType, upsert: true),
      );
      final photoUrl =
          '${storage.getPublicUrl(path)}?v=${DateTime.now().microsecondsSinceEpoch}';

      if (!mounted) return;
      setState(() => _avatarUrl = photoUrl);
      _showMessage('Foto carregada. Toque em Salvar para aplicar.');
    } catch (error) {
      if (mounted) _showMessage('Não foi possível carregar a foto: $error');
    } finally {
      if (mounted) setState(() => _isUploadingPhoto = false);
    }
  }

  Future<void> _saveDependentProfile(
    SupabaseClient client,
    User user,
    UserModel profile,
  ) async {
    final metadata = user.userMetadata ?? const <String, dynamic>{};
    final existingProfiles = metadata['dependentes'];
    final dependents = existingProfiles is List
        ? existingProfiles
              .whereType<Map>()
              .map((item) => Map<String, dynamic>.from(item))
              .toList()
        : <Map<String, dynamic>>[];
    final profileIndex = dependents.indexWhere(
      (item) => item['id'] == profile.id,
    );
    if (profileIndex == -1) {
      throw StateError('O perfil dependente não foi encontrado.');
    }

    dependents[profileIndex] = profile.toMetadataMap();
    await client.auth.updateUser(
      UserAttributes(data: {'dependentes': dependents}),
    );
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

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }
}
