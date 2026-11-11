import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:voxa/core/navigation/route_observer.dart';
import 'package:voxa/core/state/active_profile.dart';
import 'package:voxa/models/user_model.dart';
import 'package:voxa/core/widgets/app_colors.dart';
import '../../../../core/widgets/base_screen_layout.dart';
// O arquivo se chama "Cartao_padrao.dart" (com C maiúsculo). Em Linux/CI o
// nome precisa ser idêntico.
import '../../../../core/widgets/Cartao_padrao.dart';
import '../../../profile/presentation/profile_access.dart';
import '../controllers/home_content_controller.dart';
import '../widgets/category_navigation.dart';

class HomePage extends StatefulWidget {
  final UserModel? user;

  const HomePage({Key? key, this.user}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with RouteAware {
  /// Quem está com a orientação horizontal travada no momento. Evita que uma
  /// Home antiga, ao ser descartada, force a vertical por cima de uma Home nova.
  static _HomePageState? _landscapeOwner;

  final List _fraseSelecionada = [];
  String _categoriaAtual = 'Principal';
  late UserModel? _activeUser;
  bool _isLoadingContent = false;
  String? _pendingSwitchNotification;

  @override
  void initState() {
    super.initState();
    _activeUser = widget.user ?? ActiveProfile.current;
    ActiveProfile.notifier.addListener(_onActiveProfileChanged);
    _initActiveProfile();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute<dynamic>) {
      routeObserver.subscribe(this, route);
    }
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    ActiveProfile.notifier.removeListener(_onActiveProfileChanged);
    _lockPortrait();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Orientação: horizontal SOMENTE enquanto a Home está visível.
  // ---------------------------------------------------------------------------

  void _lockLandscape() {
    _landscapeOwner = this;
    SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  void _lockPortrait() {
    if (_landscapeOwner != null && _landscapeOwner != this) return;
    _landscapeOwner = null;
    SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  @override
  void didPush() => _lockLandscape(); // Home apareceu

  @override
  void didPopNext() {
    // Voltou para a Home (outra tela foi fechada)
    _lockLandscape();
    _showPendingNotification();
  }

  @override
  void didPushNext() => _lockPortrait(); // outra tela abriu por cima

  @override
  void didPop() => _lockPortrait();

  // ---------------------------------------------------------------------------
  // Perfil ativo
  // ---------------------------------------------------------------------------

  Future<void> _initActiveProfile() async {
    final client = Supabase.instance.client;
    final authUser = client.auth.currentUser;
    if (authUser == null) return;

    _isLoadingContent = true;

    var user = _activeUser;

    // O titular precisa usar o id da tabela `perfil` (e não o id de `usuario`)
    // para que as pranchas e cartões sejam carregados corretamente.
    if (user == null || user.isResponsavel) {
      final master = await ActiveProfile.loadMaster();
      if (master != null) {
        user = user == null
            ? master
            : user.copyWith(
                id: master.id,
                avatarUrl: user.avatarUrl ?? master.avatarUrl,
              );
      }
    }

    user ??= UserModel(
      id: authUser.id,
      name: 'Titular',
      email: authUser.email ?? '',
      isResponsavel: true,
    );

    _activeUser = user;
    ActiveProfile.set(user);

    await HomeContentController.loadContentForProfile(user.id);

    if (mounted) {
      setState(() => _isLoadingContent = false);
    }
  }

  /// Chamado quando outra tela (Trocar de perfil, Editar perfil, Excluir
  /// dependente...) altera o perfil ativo.
  Future<void> _onActiveProfileChanged() async {
    final selected = ActiveProfile.current;
    if (!mounted || selected == null || identical(selected, _activeUser)) {
      return;
    }

    final isDifferentUser = _activeUser?.id != selected.id;

    if (!isDifferentUser) {
      // Mesmo perfil, só dados novos (nome/foto): atualiza sem recarregar.
      setState(() => _activeUser = selected);
      return;
    }

    setState(() {
      _activeUser = selected;
      _categoriaAtual = 'Principal';
      _fraseSelecionada.clear();
      _isLoadingContent = true;
    });

    await HomeContentController.loadContentForProfile(selected.id);

    if (!mounted) return;
    setState(() => _isLoadingContent = false);

    _pendingSwitchNotification = selected.name;
    if (ModalRoute.of(context)?.isCurrent ?? false) {
      _showPendingNotification();
    }
  }

  void _showPendingNotification() {
    final name = _pendingSwitchNotification;
    if (name == null || !mounted) return;
    _pendingSwitchNotification = null;
    _showProfileSwitchNotification(name);
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
    // A troca/edição de perfil chega até aqui pelo ActiveProfile, não mais
    // pelo resultado do Navigator (que se perdia com o botão Home).
    await Navigator.of(context).push<UserModel>(
      MaterialPageRoute(
        builder: (_) => ProfileAccessScreen(currentUser: _activeUser),
      ),
    );
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