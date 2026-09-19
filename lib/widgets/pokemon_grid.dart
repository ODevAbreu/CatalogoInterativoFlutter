import 'package:flutter/material.dart';

import '../models/pokemon_summary.dart';
import 'pokemon_card.dart';

/// Delegate compartilhado pelas grades do app.
///
/// Acessibilidade (RF10): a altura de cada card é calculada a partir do
/// fator de escala de texto do sistema. Quando o usuário aumenta a fonte, a
/// célula cresce junto e o nome do Pokémon não é cortado.
SliverGridDelegate pokemonGridDelegate(BuildContext context) {
  const double tileWidth = 172;

  // Espaço do rótulo: duas linhas de nome + a linha do número, tudo
  // multiplicado pela escala de fonte, mais o padding fixo do card.
  const double textHeight = 56;
  const double padding = 12;

  final textScale = MediaQuery.textScalerOf(context).scale(14) / 14;
  final tileHeight = tileWidth + padding + textHeight * textScale;

  return SliverGridDelegateWithMaxCrossAxisExtent(
    maxCrossAxisExtent: tileWidth,
    childAspectRatio: tileWidth / tileHeight,
    crossAxisSpacing: 12,
    mainAxisSpacing: 12,
  );
}

/// Grade simples usada nas telas de favoritos (RF05) e capturados (RF07).
class PokemonGrid extends StatelessWidget {
  const PokemonGrid({super.key, required this.pokemons});

  final List<PokemonSummary> pokemons;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: pokemonGridDelegate(context),
      itemCount: pokemons.length,
      itemBuilder: (context, index) => PokemonCard(pokemon: pokemons[index]),
    );
  }
}
