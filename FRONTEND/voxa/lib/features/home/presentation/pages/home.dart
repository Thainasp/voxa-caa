import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:voxa/models/user_model.dart';
import 'package:voxa/core/widgets/app_colors.dart';
import '../../../../core/widgets/base_screen_layout.dart';
import '../../../../core/widgets/cartao_padrao.dart';
import '../../../profile/presentation/profile_access.dart';
import '../controllers/home_content_controller.dart';
import '../widgets/category_navigation.dart';

class HomePage extends StatefulWidget {
  final UserModel? user;

  const HomePage({Key? key, this.user}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final List _fraseSelecionada = [];
  String _categoriaAtual = 'Principal';
  late UserModel? _activeUser;
  bool _isLoadingContent = false;

  @override
  void initState() {
    super.initState();
    _activeUser = widget.user;
    _initActiveProfile();
  }

  Future<void> _initActiveProfile() async {
    final client = Supabase.instance.client;
    final authUser = client.auth.currentUser;
    if (authUser == null) return;

    if (_activeUser == null) {
      setState(() => _isLoadingContent = true);
      try {
        final profileData = await client
            .from('perfil')
            .select()
            .eq('usuario_id', authUser.id)
            .eq('is_responsavel', true)
            .maybeSingle();

        if (profileData != null) {
          _activeUser = UserModel(
            id: profileData['id'],
            name: profileData['nome'],
            email: authUser.email ?? '',
            avatarUrl: profileData['avatar_url'],
            isResponsavel: true,
          );
        } else {
          _activeUser = UserModel(
            id: authUser.id,
            name: 'Titular',
            email: authUser.email ?? '',
            isResponsavel: true,
          );
        }
      } catch (_) {
        _activeUser = UserModel(
          id: authUser.id,
          name: 'Titular',
          email: authUser.email ?? '',
          isResponsavel: true,
        );
      }
    }

    if (_activeUser != null) {
      await HomeContentController.loadContentForProfile(_activeUser!.id);
    }

    if (mounted) {
      setState(() => _isLoadingContent = false);
    }
  }

  void _showProfileSwitchNotification(String profileName) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(bottom: 24, left: 16, right: 16),
        backgroundColor: const Color(0xFF24332E),
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        duration: const Duration(seconds: 3),
        content: Row(
          children: [
            const Icon(Icons.swap_horiz, color: AppColors.headerGreen, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Usando Voxa como $profileName',
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w300,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openProfile() async {
    final oldProfileId = _activeUser?.id;
    final selectedUser = await Navigator.of(context).push<UserModel>(
      MaterialPageRoute(
        builder: (_) => ProfileAccessScreen(currentUser: _activeUser),
      ),
    );

    if (selectedUser != null && mounted) {
      final isDifferentUser = oldProfileId != selectedUser.id;

      setState(() {
        _activeUser = selectedUser;
        _categoriaAtual = 'Principal';
        _fraseSelecionada.clear();
        _isLoadingContent = true;
      });

      await HomeContentController.loadContentForProfile(selectedUser.id);

      if (mounted) {
        setState(() => _isLoadingContent = false);
        if (isDifferentUser) {
          _showProfileSwitchNotification(selectedUser.name);
        }
      }
    }
  }

  void _falarFrase() {
    if (_fraseSelecionada.isEmpty) return;
    String fraseCompleta =
        _fraseSelecionada.map((item) => item['label'] ?? '').join(' ');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Falando: "$fraseCompleta"'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _apagarUltimaPalavra() {
    setState(() {
      if (_fraseSelecionada.isNotEmpty) {
        _fraseSelecionada.removeLast();
      }
    });
  }

  void _voltarInicio() {
    setState(() {
      _categoriaAtual = 'Principal';
      _fraseSelecionada.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final simbolosAtuais =
        HomeContentController.cardsByBoard[_categoriaAtual] ??
            HomeContentController.cardsByBoard['Principal'] ??
            [];

    return BaseScreenLayout(
      appBar: AppBar(
        backgroundColor: AppColors.headerGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        toolbarHeight: 64,
        automaticallyImplyLeading: false,
        titleSpacing: 0,
        leadingWidth: 104,
        leading: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.person_outline, size: 26),
              tooltip: 'Perfil',
              onPressed: _openProfile,
            ),
            IconButton(
              icon: const Icon(Icons.home_outlined, size: 28),
              tooltip: 'Início',
              onPressed: _voltarInicio,
            ),
          ],
        ),
        title: Container(
          height: 42,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: Colors.white, width: 1)),
          ),
          child: _fraseSelecionada.isEmpty
              ? const Center(
                  child: Text(
                    'Toque nos cartões para formar a frase...',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                )
              : ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _fraseSelecionada.length,
                  itemBuilder: (context, index) {
                    final item = _fraseSelecionada[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      child: Center(
                        child: Text(
                          item['label'] ?? '',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.play_circle_outline, size: 26),
            tooltip: 'Falar frase',
            onPressed: _falarFrase,
          ),
          IconButton(
            icon: const Icon(Icons.backspace_outlined, size: 24),
            tooltip: 'Apagar',
            onPressed: _apagarUltimaPalavra,
          ),
        ],
      ),
      body: _isLoadingContent
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.headerGreen),
            )
          : LayoutBuilder(
              builder: (context, constraints) {
                final isLandscape =
                    constraints.maxWidth > constraints.maxHeight;
                final crossAxisCount = constraints.maxWidth < 480
                    ? 4
                    : isLandscape && constraints.maxWidth >= 700
                        ? 8
                        : 6;

                return Column(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: const BoxDecoration(
                          color: AppColors.contentBackground,
                          borderRadius:
                              BorderRadius.vertical(top: Radius.circular(30)),
                        ),
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                        child: Column(
                          children: [
                            Expanded(
                              child: GridView.builder(
                                padding: const EdgeInsets.all(4.0),
                                gridDelegate:
                                    SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: crossAxisCount,
                                  crossAxisSpacing: 10,
                                  mainAxisSpacing: 10,
                                  childAspectRatio: 1.0,
                                ),
                                itemCount: simbolosAtuais.length,
                                itemBuilder: (context, index) {
                                  final symbol = simbolosAtuais[index];
                                  return Cartao_Padrao(
                                    backgroundColor: symbol['color'],
                                    label: symbol['label'],
                                    imagePath: symbol['imagePath'] as String?,
                                    iconData: symbol['icon'],
                                    onTap: () {
                                      setState(() {
                                        _fraseSelecionada.add(symbol);
                                      });
                                    },
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 8),
                            CategoryNavigation(
                              categories: List.from(
                                HomeContentController.boards,
                              ),
                              selectedKey: _categoriaAtual,
                              height: isLandscape ? 64 : 96,
                              iconSize: isLandscape ? 36 : 52,
                              onCategorySelected: (category) {
                                setState(() => _categoriaAtual = category);
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }
}