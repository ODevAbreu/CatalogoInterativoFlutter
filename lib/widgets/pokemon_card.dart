import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/pokemon_summary.dart';
import '../providers/collection_provider.dart';
import '../screens/detail_screen.dart';
import 'pokemon_image.dart';

/// Card da grade do catálogo (RF01) e das telas de favoritos/capturados.
///
/// Tocar no card leva à Tela de Detalhes com `Navigator.push` (RF02).
/// Os selos de favorito/capturado vêm do [CollectionProvider] via
/// `context.select`, então o card se atualiza sozinho quando a marcação muda
/// em qualquer outra tela (RF04).
class PokemonCard extends StatelessWidget {
  const PokemonCard({super.key, required this.pokemon});

  final PokemonSummary pokemon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isFavorite = context.select<CollectionProvider, bool>(
      (provider) => provider.isFavorite(pokemon.id),
    );
    final isCaptured = context.select<CollectionProvider, bool>(
      (provider) => provider.isCaptured(pokemon.id),
    );

    final marks = [
      if (isFavorite) 'favorito',
      if (isCaptured) 'capturado',
    ];

    return Semantics(
      button: true,
      // Um único rótulo para todo o card: o leitor de tela anuncia nome,
      // número e marcações em vez de ler cada pedaço separadamente.
      label: 'Pokémon ${pokemon.displayName}, '
          'número ${pokemon.id}'
          '${marks.isEmpty ? '' : ', ${marks.join(' e ')}'}'
          '. Abrir detalhes.',
      excludeSemantics: true,
      child: Card(
        child: InkWell(
          onTap: () => DetailScreen.open(context, pokemon),
          child: Column(
            children: [
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    PokemonImage(
                      imageUrl: pokemon.imageUrl,
                      semanticLabel: pokemon.displayName,
                    ),
                    if (marks.isNotEmpty)
                      Positioned(
                        top: 4,
                        right: 4,
                        child: Column(
                          children: [
                            if (isFavorite)
                              _Badge(
                                icon: Icons.star,
                                color: theme.colorScheme.tertiary,
                              ),
                            if (isCaptured)
                              _Badge(
                                icon: Icons.catching_pokemon,
                                color: theme.colorScheme.primary,
                              ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 6,
                ),
                child: Column(
                  children: [
                    Text(
                      pokemon.displayName,
                      // Duas linhas para que nomes longos ("Wigglytuff",
                      // "Nidoran M") continuem legíveis com a fonte do
                      // sistema aumentada (RF10).
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      pokemon.formattedId,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.85),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: 18, color: color),
    );
  }
}
