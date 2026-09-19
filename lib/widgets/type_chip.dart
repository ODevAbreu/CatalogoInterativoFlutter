import 'package:flutter/material.dart';

import '../core/utils/pokemon_utils.dart';

/// Etiqueta do tipo do Pokémon (Fogo, Água, ...).
///
/// A cor do texto é escolhida a partir do brilho do fundo para manter
/// contraste legível (RF10), e o rótulo é traduzido localmente.
class TypeChip extends StatelessWidget {
  const TypeChip({super.key, required this.rawType});

  final String rawType;

  @override
  Widget build(BuildContext context) {
    final background = PokemonUtils.typeColor(rawType);
    final foreground =
        ThemeData.estimateBrightnessForColor(background) == Brightness.dark
            ? Colors.white
            : Colors.black;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        PokemonUtils.typeLabel(rawType),
        style: TextStyle(
          color: foreground,
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
      ),
    );
  }
}
