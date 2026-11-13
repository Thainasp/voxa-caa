import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:voxa/core/data/sync/sync_service.dart';
import 'package:voxa/core/services/app_services.dart';
import 'package:voxa/core/services/connectivity_service.dart';
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

  const HomePage({super.key, this.user});

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
  SyncService? _sync;
  int _seenContentVersion = 0;

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
    final sync = context.read<SyncService>();
    if (!identical(sync, _sync)) {
      _sync?.removeListener(_onSyncChanged);
      _sync = sync..addListener(_onSyncChanged);
      _seenContentVersion = sync.contentVersion;
    }
    final route = ModalRoute.of(context);
    if (route is PageRoute<dynamic>) {
      routeObserver.subscribe(this, route);
    }
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    _sync?.removeListener(_onSyncChanged);
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

  /// A sincronização trouxe conteúdo novo da nuvem: recarrega do SQLite.
  Future<void> _onSyncChanged() async {
    final sync = _sync;
    if (sync == null || sync.contentVersion == _seenContentVersion) return;
    _seenContentVersion = sync.contentVersion;
    await HomeContentController.reloadFromLocal();
    if (mounted) setState(() {});
  }

  Future<void> _initActiveProfile() async {
    setState(() => _isLoadingContent = true);
    try {
      await _loadContentForActiveProfile(_activeUser);
    } catch (error) {
      _showContentError(error);
    } finally {
      if (mounted) setState(() => _isLoadingContent = false);
    }
  }

  Future<void> _loadContentForActiveProfile(UserModel? requestedProfile) async {
    final client = Supabase.instance.client;
    final authUser = client.auth.currentUser;
    if (authUser == null) {
      throw const AuthException(
        'Entre na sua conta para carregar suas tábuas e cartões.',
      );
    }

    final metadata = authUser.userMetadata ?? const <String, dynamic>{};
    final fallbackName =
        requestedProfile?.name ??
        (metadata['display_name'] ??
                metadata['nome'] ??
                metadata['name'] ??
                authUser.email?.split('@').first ??
                'Titular')
            .toString();
    _activeUser = await HomeContentController.resolveActiveProfile(
      authUserId: authUser.id,
      email: authUser.email ?? '',
      requestedProfile: requestedProfile,
      fallbackName: fallbackName,
      avatarUrl:
          requestedProfile?.avatarUrl ?? metadata['avatar_url'] as String?,
    );
    ActiveProfile.set(_activeUser);
    await HomeContentController.loadContentForProfile(_activeUser!.id);
  }

  void _showContentError(Object error) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Falha ao carregar pranchas e cartões: $error')),
    );
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

    try {
      await HomeContentController.loadContentForProfile(selected.id);
    } catch (error) {
      _showContentError(error);
    }

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
            const Icon(
              Icons.swap_horiz,
              color: AppColors.headerGreen,
              size: 24,
            ),
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

  /// RF01: lê a frase inteira montada na barra (motor TTS nativo, pt-BR).
  void _falarFrase() {
    if (_fraseSelecionada.isEmpty) return;
    final fraseCompleta = _fraseSelecionada
        .map((item) => item['label'] ?? '')
        .join(' ');
    AppServices.instance.tts.speak(fraseCompleta);
  }

  /// RF01: vocaliza o cartão no momento do toque e o adiciona à frase (RF02).
  void _tocarCartao(Map symbol) {
    setState(() => _fraseSelecionada.add(symbol));
    AppServices.instance.tts.speak(symbol['label']?.toString() ?? '');
  }

  void _limparFrase() {
    setState(_fraseSelecionada.clear);
  }

  Widget _buildSyncBanner(SyncService sync) {
    final String? message;
    final IconData icon;
    if (sync.status == SyncStatus.syncing) {
      message =
          'Sincronizando com a nuvem (${sync.progressDone}/${sync.progressTotal})...';
      icon = Icons.sync;
    } else if (sync.network == NetworkStatus.offline) {
      message = sync.pending > 0
          ? 'Offline: ${sync.pending} alteração(ões) salvas no aparelho.'
          : 'Offline: usando os dados salvos no aparelho.';
      icon = Icons.cloud_off;
    } else if (sync.pending > 0 && !sync.isOnWifi) {
      message =
          '${sync.pending} alteração(ões) aguardando Wi-Fi para sincronizar.';
      icon = Icons.wifi_off;
    } else {
      message = null;
      icon = Icons.check;
    }
    if (message == null) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.categoryBlue.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.titleColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: AppColors.titleColor,
              ),
            ),
          ),
        ],
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

  void _showArasaacCredits() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Créditos dos pictogramas'),
        content: const Text(
          'Pictogramas criados por Sergio Palao para ARASAAC '
          '(arasaac.org), propriedade do Governo de Aragão. '
          'Licença Creative Commons BY-NC-SA '
          '(Atribuição–NãoComercial–CompartilhaIgual).',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  void _voltarInicio() {
    setState(() {
      _categoriaAtual = 'Principal';
      _fraseSelecionada.clear();
    });
  }

  List<Map<String, dynamic>> get _visibleCategories {
    final allBoards = HomeContentController.boardsWithUserCreatedFirst;
    return allBoards
        .where(
          (board) =>
              board['key'] != 'Principal' &&
              (board['catalogoArasaac'] == true || board['parentKey'] == null),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isCompactAppBar = screenWidth < 480;
    final isVeryNarrowAppBar = screenWidth < 360;
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
        leadingWidth: isVeryNarrowAppBar ? 56 : 104,
        leading: isVeryNarrowAppBar
            ? PopupMenuButton<String>(
                tooltip: 'Navegação',
                icon: const Icon(Icons.menu),
                onSelected: (action) {
                  if (action == 'profile') {
                    _openProfile();
                  } else {
                    _voltarInicio();
                  }
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(value: 'profile', child: Text('Perfil')),
                  PopupMenuItem(value: 'home', child: Text('Início')),
                ],
              )
            : Row(
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
        actions: isCompactAppBar
            ? [
                PopupMenuButton<String>(
                  tooltip: 'Mais opções',
                  icon: const Icon(Icons.more_vert),
                  onSelected: (action) {
                    switch (action) {
                      case 'credits':
                        _showArasaacCredits();
                      case 'speak':
                        _falarFrase();
                      case 'delete':
                        _apagarUltimaPalavra();
                      case 'clear':
                        _limparFrase();
                    }
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(
                      value: 'credits',
                      child: Text('Créditos dos pictogramas'),
                    ),
                    PopupMenuItem(value: 'speak', child: Text('Falar frase')),
                    PopupMenuItem(
                      value: 'delete',
                      child: Text('Apagar última palavra'),
                    ),
                    PopupMenuItem(value: 'clear', child: Text('Limpar frase')),
                  ],
                ),
              ]
            : [
                IconButton(
                  icon: const Icon(Icons.info_outline, size: 24),
                  tooltip: 'Créditos dos pictogramas',
                  onPressed: _showArasaacCredits,
                ),
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
                IconButton(
                  icon: const Icon(Icons.clear_all, size: 26),
                  tooltip: 'Limpar frase',
                  onPressed: _limparFrase,
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
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(30),
                          ),
                        ),
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                        child: Column(
                          children: [
                            Consumer<SyncService>(
                              builder: (_, sync, _) => _buildSyncBanner(sync),
                            ),
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
                                    onTap: () => _tocarCartao(symbol),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 8),
                            CategoryNavigation(
                              categories: _visibleCategories,
                              selectedKey: _categoriaAtual,
                              height: isLandscape ? 82 : 96,
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
