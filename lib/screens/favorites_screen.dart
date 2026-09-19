import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/collection_provider.dart';
import '../widgets/pokemon_grid.dart';
import '../widgets/state_views.dart';

/// Tela de Favoritos (RF05).
///
/// Lê a lista direto do [CollectionProvider] com `context.watch`, então ela
/// se atualiza sozinha quando o usuário desfavorita algo — aqui ou na tela de
/// detalhes.
class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final collection = context.watch<CollectionProvider>();
    final favorites = collection.favorites;

    return Scaffold(
      appBar: AppBar(
        title: Text('Favoritos (${favorites.length})'),
      ),
      body: collection.isLoading
          ? const LoadingView(message: 'Carregando sua coleção...')
          : favorites.isEmpty
              ? const EmptyView(
                  icon: Icons.star_border,
                  title: 'Nenhum favorito ainda',
                  message: 'Abra um Pokémon no catálogo e toque na estrela '
                      'para salvá-lo aqui.',
                )
              : PokemonGrid(pokemons: favorites),
    );
  }
}
