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

  String _initialName = '';
  String _initialPhone = '';
  String _initialEmail = '';

  String? _avatarUrl;
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
      _initialName = widget.user?.name ?? 'Perfil';
      _avatarUrl = widget.user?.avatarUrl;
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
              .select()
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
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
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
                      fontSize: 16,
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
                      fontSize: 16,
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
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    onTap: () {
                      Navigator.of(bottomSheetContext).pop();
                      setState(() {
                        _avatarUrl = null;
                      });
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

  @override
  Widget build(BuildContext context) {
    return BaseScreenLayout(
      title: 'Editar meu Perfil',
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
              Positioned(
                right: 0,
                bottom: 0,
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

                    Text(
                      'Configuração de Perfil',
                      style: GoogleFonts.poppins(
                        color: AppColors.titleColor,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 20),

                    _buildFidelityField(
                      label: 'Nome',
                      controller: _nameController,
                      onChanged: (val) => setState(() {}),
                    ),
                    const SizedBox(height: 16),

                    if (_isMaster) ...[
                      _buildFidelityField(
                        label: 'Telefone',
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 16),
                      _buildFidelityField(
                        label: 'Email',
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
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
                              borderRadius: BorderRadius.circular(22),
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

  Widget _buildFidelityField({
    required String label,
    required TextEditingController controller,
    TextInputType? keyboardType,
    void Function(String)? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 6.0, bottom: 6.0),
          child: Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: AppColors.titleColor,
            ),
          ),
        ),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          onChanged: onChanged,
          style: GoogleFonts.poppins(
            color: AppColors.textColor,
            fontSize: 14,
            fontWeight: FontWeight.w400,
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.fieldFillColor,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 18,
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
        ),
      ],
    );
  }

  Future<void> _save() async {
    final client = Supabase.instance.client;
    final authUser = client.auth.currentUser;
    if (authUser == null) {
      _showMessage('Sua sessão expirou. Entre novamente.');
      return;
    }

    setState(() => _isSaving = true);
    try {
      final name = _nameController.text.trim().isEmpty
          ? _initialName
          : _nameController.text.trim();

      if (!_isMaster) {
        await client
            .from('perfil')
            .update({'nome': name, 'avatar_url': _avatarUrl})
            .eq('id', widget.user!.id);

        final updatedProfile = UserModel(
          id: widget.user!.id,
          name: name,
          avatarUrl: _avatarUrl,
          isResponsavel: false,
        );

        if (!mounted) return;
        _showMessage('Perfil salvo com sucesso!');
        Navigator.of(context).pop(updatedProfile);
      } else {
        final phone = _phoneController.text.trim().isEmpty
            ? _initialPhone
            : _phoneController.text.trim();

        final email = _emailController.text.trim().isEmpty
            ? _initialEmail
            : _emailController.text.trim();

        await client
            .from('usuario')
            .update({
              'nome': name,
              'email': email,
              'telefone': phone,
              'avatar_url': _avatarUrl,
            })
            .eq('id', authUser.id);

        await client
            .from('perfil')
            .update({'nome': name, 'avatar_url': _avatarUrl})
            .eq('usuario_id', authUser.id)
            .eq('is_responsavel', true);

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

        final updatedProfile = UserModel(
          id: widget.user?.id ?? authUser.id,
          name: name,
          email: email,
          phone: phone,
          birthDate: widget.user?.birthDate,
          avatarUrl: _avatarUrl,
          isResponsavel: true,
        );

        if (!mounted) return;
        _showMessage('Perfil salvo com sucesso!');
        Navigator.of(context).pop(updatedProfile);
      }
    } catch (error) {
      if (mounted) _showMessage('Não foi possível salvar o perfil: $error');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
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
      _showMessage('Foto carregada. Toque em salvar para aplicar.');
    } catch (error) {
      if (mounted) _showMessage('Não foi possível carregar a foto: $error');
    } finally {
      if (mounted) setState(() => _isUploadingPhoto = false);
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

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }
}
