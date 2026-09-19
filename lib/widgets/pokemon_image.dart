import 'package:flutter/material.dart';

/// Imagem de um Pokémon com três garantias:
///
/// * **placeholder** quando a URL é vazia ou o download falha — nenhum item
///   sem imagem quebra a tela (RF01);
/// * `CircularProgressIndicator` enquanto baixa (RF09);
/// * `semanticLabel` descritivo para leitores de tela (RF10).
class PokemonImage extends StatelessWidget {
  const PokemonImage({
    super.key,
    required this.imageUrl,
    required this.semanticLabel,
    this.padding = const EdgeInsets.all(8),
  });

  final String imageUrl;
  final String semanticLabel;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    if (imageUrl.isEmpty) {
      return _Placeholder(semanticLabel: '$semanticLabel (imagem indisponível)');
    }

    return Padding(
      padding: padding,
      child: Image.network(
        imageUrl,
        fit: BoxFit.contain,
        semanticLabel: semanticLabel,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return const Center(
            child: SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) => _Placeholder(
          semanticLabel: '$semanticLabel (imagem indisponível)',
        ),
      ),
    );
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder({required this.semanticLabel});

  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Semantics(
      label: semanticLabel,
      image: true,
      child: Container(
        color: colors.surfaceContainerHighest,
        alignment: Alignment.center,
        child: FittedBox(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Icon(
              Icons.catching_pokemon,
              color: colors.onSurfaceVariant,
              size: 48,
            ),
          ),
        ),
      ),
    );
  }
}
