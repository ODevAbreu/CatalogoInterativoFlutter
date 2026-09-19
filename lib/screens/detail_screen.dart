import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/utils/pokemon_utils.dart';
import '../models/pokemon_detail.dart';
import '../models/pokemon_summary.dart';
import '../providers/collection_provider.dart';
import '../services/pokeapi_service.dart';
import '../widgets/pokemon_image.dart';
import '../widgets/state_views.dart';
import '../widgets/type_chip.dart';

/// Tela de Detalhes (RF03).
///
/// Busca os dados completos na PokéAPI com `FutureBuilder` (RF09) e concentra
/// as duas ações de coleção: favoritar (RF04) e capturar (RF07).
class DetailScreen extends StatefulWidget {
  const DetailScreen({super.key, required this.pokemon, this.preloaded});

  final PokemonSummary pokemon;

  /// Quando a tela é aberta pela busca (RF08) o detalhe já foi baixado, então
  /// não há motivo para pedir de novo à API.
  final PokemonDetail? preloaded;

  /// Empilha a tela de detalhes com `Navigator.push` (RF02).
  static Future<void> open(
    BuildContext context,
    PokemonSummary pokemon, {
    PokemonDetail? detail,
  }) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => DetailScreen(pokemon: pokemon, preloaded: detail),
      ),
    );
  }

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  late Future<PokemonDetail> _future;
  PokemonDetail? _detail;

  @override
  void initState() {
    super.initState();
    _detail = widget.preloaded;
    _future = _load();
  }

  Future<PokemonDetail> _load() {
    final preloaded = widget.preloaded;
    if (preloaded != null) return Future<PokemonDetail>.value(preloaded);

    return context
        .read<PokeApiService>()
        .fetchDetail(widget.pokemon.id)
        // Guardado para as ações de coleção usarem o nome/imagem oficiais.
        .then((detail) => _detail = detail);
  }

  void _retry() => setState(() => _future = _load());

  /// Enquanto o detalhe não chegou, as ações de coleção usam o resumo que veio
  /// da grade — favoritar não precisa esperar a segunda requisição.
  PokemonSummary get _summary => _detail?.toSummary() ?? widget.pokemon;

  @override
  Widget build(BuildContext context) {
    final collection = context.watch<CollectionProvider>();
    final isFavorite = collection.isFavorite(widget.pokemon.id);
    final isCaptured = collection.isCaptured(widget.pokemon.id);
    final name = _detail?.displayName ?? widget.pokemon.displayName;

    return Scaffold(
      appBar: AppBar(
        title: Text(name),
        actions: [
          IconButton(
            // RF04: a marcação de favorito vive no Provider global, então o
            // ícone reflete o estado em qualquer tela.
            onPressed: () => collection.toggleFavorite(_summary),
            icon: Icon(isFavorite ? Icons.star : Icons.star_border),
            tooltip: isFavorite
                ? 'Remover $name dos favoritos'
                : 'Adicionar $name aos favoritos',
          ),
        ],
      ),
      body: FutureBuilder<PokemonDetail>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return LoadingView(message: 'Carregando dados de $name...');
          }

          if (snapshot.hasError) {
            final error = snapshot.error;
            return ErrorView(
              message: error is PokeApiException
                  ? error.message
                  : 'Não foi possível carregar os detalhes deste Pokémon.',
              onRetry: _retry,
            );
          }

          final detail = snapshot.data;
          if (detail == null) {
            return const ErrorView(
              message: 'Nenhum dado retornado pela PokéAPI.',
            );
          }

          return _DetailBody(detail: detail);
        },
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: FilledButton.icon(
            onPressed: () async {
              await collection.toggleCaptured(_summary);
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    isCaptured
                        ? '$name foi solto.'
                        : '$name entrou na sua Pokédex!',
                  ),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            icon: Icon(
              isCaptured ? Icons.remove_circle_outline : Icons.catching_pokemon,
            ),
            label: Text(isCaptured ? 'Soltar $name' : 'Capturar $name'),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
            ),
          ),
        ),
      ),
    );
  }
}

class _DetailBody extends StatelessWidget {
  const _DetailBody({required this.detail});

  final PokemonDetail detail;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        // Imagem em tamanho maior (RF03).
        SizedBox(
          height: 240,
          child: PokemonImage(
            imageUrl: detail.imageUrl,
            semanticLabel: 'Imagem de ${detail.displayName}',
            padding: EdgeInsets.zero,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          '${detail.displayName} ${detail.formattedId}',
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineSmall
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        if (detail.genus.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            detail.genus,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium,
          ),
        ],
        const SizedBox(height: 16),
        Semantics(
          label: 'Tipos: '
              '${detail.types.map(PokemonUtils.typeLabel).join(', ')}',
          excludeSemantics: true,
          child: Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final type in detail.types) TypeChip(rawType: type),
            ],
          ),
        ),
        if (detail.description.isNotEmpty) ...[
          const SizedBox(height: 20),
          _Section(
            title: 'Descrição da Pokédex',
            child: Text(
              detail.description,
              style: theme.textTheme.bodyLarge,
            ),
          ),
        ],
        const SizedBox(height: 20),
        _Section(
          title: 'Características',
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _InfoTile(label: 'Altura', value: detail.heightLabel),
              _InfoTile(label: 'Peso', value: detail.weightLabel),
              _InfoTile(
                label: 'Exp. base',
                value: '${detail.baseExperience}',
              ),
            ],
          ),
        ),
        if (detail.abilities.isNotEmpty) ...[
          const SizedBox(height: 20),
          _Section(
            title: 'Habilidades',
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final ability in detail.abilities)
                  Chip(label: Text(ability)),
              ],
            ),
          ),
        ],
        if (detail.stats.isNotEmpty) ...[
          const SizedBox(height: 20),
          _Section(
            title: 'Status base',
            child: Column(
              children: [
                for (final stat in detail.stats) _StatBar(stat: stat),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      label: '$label: $value',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: theme.textTheme.labelMedium),
            Text(
              value,
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}

/// Barra de status. O rótulo fica acima da barra (e não ao lado) para não
/// haver largura fixa que corte o texto quando a fonte do sistema aumenta.
class _StatBar extends StatelessWidget {
  const _StatBar({required this.stat});

  final PokemonStat stat;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      label: '${stat.label}: ${stat.value} de 255',
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(stat.label, style: theme.textTheme.bodyMedium),
                ),
                Text(
                  '${stat.value}',
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 4),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: stat.progress,
                minHeight: 10,
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
