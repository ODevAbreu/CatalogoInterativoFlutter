import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/catalog_provider.dart';
import '../providers/collection_provider.dart';
import '../services/pokeapi_service.dart';
import '../widgets/pokemon_card.dart';
import '../widgets/pokemon_grid.dart';
import '../widgets/state_views.dart';
import 'captured_screen.dart';
import 'detail_screen.dart';
import 'favorites_screen.dart';

/// Tela Principal — catálogo paginado (RF01) e busca (RF08).
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _searchController = TextEditingController();
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    // Primeira página logo após o primeiro frame (não dá para notificar
    // listeners durante o build).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final catalog = context.read<CatalogProvider>();
      if (catalog.isEmpty) catalog.loadFirstPage();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// RF08: busca pelo endpoint da API e, ao encontrar, vai direto para a
  /// Tela de Detalhes. O detalhe já baixado é repassado para não refazer a
  /// mesma requisição.
  Future<void> _search() async {
    final term = _searchController.text.trim();
    if (term.isEmpty) {
      _showMessage('Digite o nome ou o número de um Pokémon para buscar.');
      return;
    }

    setState(() => _isSearching = true);
    try {
      final detail = await context.read<PokeApiService>().search(term);
      if (!mounted) return;
      FocusScope.of(context).unfocus();
      await DetailScreen.open(context, detail.toSummary(), detail: detail);
    } on PokeApiException catch (error) {
      if (!mounted) return;
      _showMessage(error.message);
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _confirmSignOut() async {
    final shouldSignOut = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Sair da conta?'),
        content: const Text(
          'Sua coleção continua salva e volta quando você entrar de novo.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Sair'),
          ),
        ],
      ),
    );

    if (shouldSignOut == true && mounted) {
      await context.read<AuthProvider>().signOut();
    }
  }

  @override
  Widget build(BuildContext context) {
    final collection = context.watch<CollectionProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pokédex Interativa'),
        actions: [
          IconButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const FavoritesScreen()),
            ),
            icon: const Icon(Icons.star),
            tooltip: 'Favoritos (${collection.favoritesCount})',
          ),
          IconButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const CapturedScreen()),
            ),
            icon: const Icon(Icons.catching_pokemon),
            tooltip: 'Capturados (${collection.capturedCount})',
          ),
          IconButton(
            onPressed: _confirmSignOut,
            icon: const Icon(Icons.logout),
            tooltip: 'Sair da conta',
          ),
        ],
      ),
      body: Column(
        children: [
          _SearchBar(
            controller: _searchController,
            isSearching: _isSearching,
            onSearch: _search,
          ),
          if (collection.syncMessage != null)
            _SyncWarning(
              message: collection.syncMessage!,
              onDismiss: collection.clearSyncMessage,
            ),
          const Expanded(child: _CatalogView()),
        ],
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({
    required this.controller,
    required this.isSearching,
    required this.onSearch,
  });

  final TextEditingController controller;
  final bool isSearching;
  final Future<void> Function() onSearch;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => onSearch(),
              enabled: !isSearching,
              decoration: const InputDecoration(
                labelText: 'Buscar Pokémon',
                hintText: 'pikachu ou 25',
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // RF09: o botão de busca mostra progresso enquanto a requisição
          // está no ar.
          SizedBox(
            height: 56,
            child: ElevatedButton(
              onPressed: isSearching ? null : () => onSearch(),
              child: isSearching
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    )
                  : const Text('Buscar'),
            ),
          ),
        ],
      ),
    );
  }
}

class _SyncWarning extends StatelessWidget {
  const _SyncWarning({required this.message, required this.onDismiss});

  final String message;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
      decoration: BoxDecoration(
        color: colors.secondaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.cloud_off, color: colors.onSecondaryContainer),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: colors.onSecondaryContainer),
            ),
          ),
          IconButton(
            onPressed: onDismiss,
            icon: const Icon(Icons.close),
            tooltip: 'Dispensar aviso',
          ),
        ],
      ),
    );
  }
}

/// Grade do catálogo + botão "Carregar mais" (RF01) com os estados de
/// carregamento e erro do RF09.
class _CatalogView extends StatelessWidget {
  const _CatalogView();

  @override
  Widget build(BuildContext context) {
    final catalog = context.watch<CatalogProvider>();

    if (catalog.isLoadingFirstPage && catalog.isEmpty) {
      return const LoadingView(message: 'Carregando a Pokédex...');
    }

    if (catalog.isEmpty) {
      final message = catalog.errorMessage;
      if (message != null) {
        return ErrorView(
          message: message,
          onRetry: context.read<CatalogProvider>().loadFirstPage,
        );
      }
      return const EmptyView(
        icon: Icons.catching_pokemon,
        title: 'Nada por aqui',
        message: 'Nenhum Pokémon retornado pela PokéAPI.',
      );
    }

    final items = catalog.items;

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(12),
          sliver: SliverGrid.builder(
            gridDelegate: pokemonGridDelegate(context),
            itemCount: items.length,
            itemBuilder: (context, index) =>
                PokemonCard(pokemon: items[index]),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            child: _LoadMoreFooter(catalog: catalog),
          ),
        ),
      ],
    );
  }
}

class _LoadMoreFooter extends StatelessWidget {
  const _LoadMoreFooter({required this.catalog});

  final CatalogProvider catalog;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (catalog.isLoadingMore) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(8),
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Column(
      children: [
        // Falha no "Carregar mais": a lista já carregada continua na tela e o
        // usuário pode tentar de novo.
        if (catalog.errorMessage != null) ...[
          Text(
            catalog.errorMessage!,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: theme.colorScheme.error),
          ),
          const SizedBox(height: 12),
        ],
        if (catalog.hasMore)
          ElevatedButton.icon(
            onPressed: catalog.loadMore,
            icon: const Icon(Icons.expand_more),
            label: const Text('Carregar mais'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
            ),
          )
        else
          Text(
            'Você chegou ao fim da Pokédex.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium,
          ),
      ],
    );
  }
}
