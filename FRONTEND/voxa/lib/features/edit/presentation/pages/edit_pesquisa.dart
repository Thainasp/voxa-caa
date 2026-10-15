import 'package:flutter/material.dart';

import '../../../../theme/app_colors.dart';
import '../../../../core/widgets/base_screen_layout.dart';
import '../../../../core/widgets/curved_content_panel.dart';
import '../../../../core/widgets/home_navigation_bar.dart';
import '../../../home/presentation/controllers/home_content_controller.dart';

class Edit_pesquisa extends StatefulWidget {
  const Edit_pesquisa({super.key});

  @override
  State<Edit_pesquisa> createState() => _EditPesquisaState();
}

class _EditPesquisaState extends State<Edit_pesquisa> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedBoard = 'Principal';

  Future<void> _openBoardForm({Map<String, dynamic>? board}) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => _ItemEditorPage(
          itemType: 'tábua',
          item: board,
          initialBoardKey: board?['key'] as String?,
          onSave: (values, _) {
            final key =
                board?['key'] as String? ?? _newBoardKey(values['name']!);
            final savedBoard = {
              ...?board,
              'key': key,
              'label': values['name'],
              'icon': board?['icon'] ?? Icons.dashboard_customize,
              'imagePath': values['imagePath'],
              'audioPath': values['audioPath'],
            };

            if (board == null) {
              HomeContentController.boards.add(savedBoard);
              HomeContentController.cardsByBoard[key] = [];
            } else {
              final index = HomeContentController.boards.indexWhere(
                (item) => item['key'] == key,
              );
              if (index != -1) HomeContentController.boards[index] = savedBoard;
            }
          },
        ),
      ),
    );
    if (mounted) setState(() {});
  }

  Future<void> _openCardForm({Map<String, dynamic>? card}) async {
    final sourceBoardKey = _selectedBoard;
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => _ItemEditorPage(
          itemType: 'cartão',
          item: card,
          initialBoardKey: sourceBoardKey,
          onSave: (values, destinationBoardKey) {
            if (destinationBoardKey == null) return;
            _selectedBoard = destinationBoardKey;
            if (card != null) {
              for (final cards in HomeContentController.cardsByBoard.values) {
                cards.removeWhere((item) => identical(item, card));
              }
            }

            HomeContentController.cardsByBoard
                .putIfAbsent(destinationBoardKey, () => [])
                .add({
                  ...?card,
                  'label': values['name'],
                  'color': card?['color'] ?? Colors.blue,
                  'icon': card?['icon'] ?? Icons.image_outlined,
                  'imagePath': values['imagePath'],
                  'audioPath': values['audioPath'],
                });
          },
        ),
      ),
    );
    if (mounted) setState(() {});
  }

  String _newBoardKey(String name) {
    final baseKey = name
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-|-$'), '');
    final base = baseKey.isEmpty ? 'tabua' : baseKey;
    var key = base;
    var suffix = 2;
    while (HomeContentController.cardsByBoard.containsKey(key)) {
      key = '$base-$suffix';
      suffix++;
    }
    return key;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BaseScreenLayout(
      appBar: AppBar(
        toolbarHeight: 64,
        backgroundColor: AppColors.headerGreen,
        foregroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          tooltip: 'Voltar',
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const Text(
          'Escolha Qual\nQuer Editar',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            height: 1.1,
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(28, 0, 28, 10),
            child: SizedBox(
              height: 36,
              child: TextField(
                controller: _searchController,
                onChanged: (value) =>
                    setState(() => _searchQuery = value.trim()),
                decoration: InputDecoration(
                  hintText: 'Pesquisar',
                  prefixIcon: const Icon(Icons.search, size: 18),
                  suffixIcon: _searchQuery.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Limpar pesquisa',
                          icon: const Icon(Icons.close, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(22),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: AppColors.contentBackground,
                ),
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ),
        ),
      ),
      body: CurvedContentPanel(
        panelTop: 0,
        scrollTop: 0,
        contentTopPadding: 16,
        contentBottomPadding: 20,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth < 480
                ? 3
                : constraints.maxWidth < 800
                ? 4
                : 5;
            final query = _searchQuery.toLowerCase();
            final boards = HomeContentController.boards.where((board) {
              return (board['label'] as String).toLowerCase().contains(query);
            }).toList();
            final cards =
                HomeContentController.cardsByBoard[_selectedBoard] ??
                const <Map<String, dynamic>>[];
            final filteredCards = cards.where((card) {
              return (card['label'] as String).toLowerCase().contains(query);
            }).toList();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _SectionTitle(title: 'Tábuas'),
                const SizedBox(height: 14),
                _ItemsGrid(
                  columns: columns,
                  itemCount: boards.length + 1,
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return _AddItemTile(
                        label: 'Nova Tábua',
                        onTap: _openBoardForm,
                      );
                    }
                    final board = boards[index - 1];
                    final key = board['key'] as String;
                    return _SelectionTile(
                      label: board['label'] as String,
                      icon: board['icon'] as IconData,
                      imagePath: board['imagePath'] as String?,
                      color: AppColors.categoryBlue,
                      selected: key == _selectedBoard,
                      onTap: () => _openBoardForm(board: board),
                    );
                  },
                ),
                const SizedBox(height: 22),
                _SectionTitle(title: 'Cartões'),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  initialValue: _selectedBoard,
                  decoration: const InputDecoration(
                    labelText: 'Tábua dos cartões',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                  ),
                  items: HomeContentController.boards
                      .map(
                        (board) => DropdownMenuItem<String>(
                          value: board['key'] as String,
                          child: Text(board['label'] as String),
                        ),
                      )
                      .toList(),
                  onChanged: (key) {
                    if (key != null) setState(() => _selectedBoard = key);
                  },
                ),
                const SizedBox(height: 14),
                _ItemsGrid(
                  columns: columns,
                  itemCount: filteredCards.length + 1,
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return _AddItemTile(
                        label: 'Novo Cartão',
                        onTap: _openCardForm,
                      );
                    }
                    final card = filteredCards[index - 1];
                    return _SelectionTile(
                      label: card['label'] as String,
                      icon: card['icon'] as IconData,
                      imagePath: card['imagePath'] as String?,
                      color: card['color'] as Color,
                      onTap: () => _openCardForm(card: card),
                    );
                  },
                ),
                if (filteredCards.isEmpty && _searchQuery.isNotEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      'Nenhum cartão encontrado nesta tábua.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.black54),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
      bottomNavigationBar: const HomeNavigationBar(),
    );
  }
}

class _ItemEditorPage extends StatefulWidget {
  final String itemType;
  final Map<String, dynamic>? item;
  final String? initialBoardKey;
  final void Function(Map<String, String?> values, String? boardKey) onSave;

  const _ItemEditorPage({
    required this.itemType,
    required this.item,
    required this.initialBoardKey,
    required this.onSave,
  });

  @override
  State<_ItemEditorPage> createState() => _ItemEditorPageState();
}

class _ItemEditorPageState extends State<_ItemEditorPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _imageController;
  late final TextEditingController _audioController;
  late String? _selectedBoardKey;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.item?['label'] as String? ?? '',
    );
    _imageController = TextEditingController(
      text: widget.item?['imagePath'] as String? ?? '',
    );
    _audioController = TextEditingController(
      text: widget.item?['audioPath'] as String? ?? '',
    );
    _selectedBoardKey = widget.initialBoardKey;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _imageController.dispose();
    _audioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isCard = widget.itemType == 'cartão';
    final boards = HomeContentController.boards;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.headerGreen,
        title: Text(
          '${widget.item == null ? 'Novo' : 'Editar'} ${widget.itemType}',
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  TextFormField(
                    controller: _nameController,
                    autofocus: true,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      labelText: 'Nome *',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Informe o nome.'
                        : null,
                  ),
                  const SizedBox(height: 18),
                  if (isCard) ...[
                    DropdownButtonFormField<String>(
                      initialValue: _selectedBoardKey,
                      decoration: const InputDecoration(
                        labelText: 'Tábua',
                        border: OutlineInputBorder(),
                      ),
                      items: boards
                          .map(
                            (board) => DropdownMenuItem<String>(
                              value: board['key'] as String,
                              child: Text(board['label'] as String),
                            ),
                          )
                          .toList(),
                      onChanged: (value) => _selectedBoardKey = value,
                      validator: (value) =>
                          value == null ? 'Selecione uma tábua.' : null,
                    ),
                    const SizedBox(height: 18),
                  ],
                  TextFormField(
                    controller: _imageController,
                    keyboardType: TextInputType.url,
                    decoration: const InputDecoration(
                      labelText: 'Imagem (opcional)',
                      hintText: 'URL ou caminho do arquivo',
                      prefixIcon: Icon(Icons.image_outlined),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 18),
                  TextFormField(
                    controller: _audioController,
                    keyboardType: TextInputType.url,
                    decoration: const InputDecoration(
                      labelText: 'Áudio (opcional)',
                      hintText: 'URL ou caminho do arquivo',
                      prefixIcon: Icon(Icons.audiotrack),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: _save,
                    icon: const Icon(Icons.save_outlined),
                    label: const Text('Salvar'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    widget.onSave({
      'name': _nameController.text.trim(),
      'imagePath': _imageController.text.trim().isEmpty
          ? null
          : _imageController.text.trim(),
      'audioPath': _audioController.text.trim().isEmpty
          ? null
          : _audioController.text.trim(),
    }, _selectedBoardKey);
    Navigator.of(context).pop();
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 12, bottom: 8),
          child: Text(
            title,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ),
        const Divider(height: 1, thickness: 1, color: AppColors.headerGreen),
      ],
    );
  }
}

class _ItemsGrid extends StatelessWidget {
  final int columns;
  final int itemCount;
  final Widget Function(BuildContext, int) itemBuilder;

  const _ItemsGrid({
    required this.columns,
    required this.itemCount,
    required this.itemBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        mainAxisExtent: 100,
      ),
      itemCount: itemCount,
      itemBuilder: itemBuilder,
    );
  }
}

class _AddItemTile extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _AddItemTile({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(17),
        child: Column(
          children: [
            Container(
              width: 70,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.categoryBlue,
                borderRadius: BorderRadius.circular(17),
              ),
              child: const Icon(Icons.add, color: Colors.white, size: 38),
            ),
            const SizedBox(height: 5),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }
}

class _SelectionTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final String? imagePath;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _SelectionTile({
    required this.label,
    required this.icon,
    this.imagePath,
    required this.color,
    required this.onTap,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(17),
        child: Column(
          children: [
            Container(
              width: 70,
              height: 64,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(17),
                border: selected
                    ? Border.all(color: Colors.white, width: 2)
                    : null,
              ),
              child: imagePath == null || imagePath!.isEmpty
                  ? Icon(icon, color: Colors.white, size: 31)
                  : imagePath!.startsWith('http://') ||
                        imagePath!.startsWith('https://')
                  ? Image.network(
                      imagePath!,
                      fit: BoxFit.contain,
                      errorBuilder: (_, _, _) =>
                          Icon(icon, color: Colors.white, size: 31),
                    )
                  : Image.asset(
                      imagePath!,
                      fit: BoxFit.contain,
                      errorBuilder: (_, _, _) =>
                          Icon(icon, color: Colors.white, size: 31),
                    ),
            ),
            const SizedBox(height: 5),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }
}
