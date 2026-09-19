import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/collection_provider.dart';
import '../widgets/pokemon_grid.dart';
import '../widgets/state_views.dart';

/// Tela dos itens "consumidos" do enunciado (RF07). No tema Pokémon, o verbo
/// é **capturar**: esta é a Pokédex pessoal do usuário.
class CapturedScreen extends StatelessWidget {
  const CapturedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final collection = context.watch<CollectionProvider>();
    final captured = collection.captured;

    return Scaffold(
      appBar: AppBar(
        title: Text('Capturados (${captured.length})'),
      ),
      body: collection.isLoading
          ? const LoadingView(message: 'Carregando sua coleção...')
          : captured.isEmpty
              ? const EmptyView(
                  icon: Icons.catching_pokemon,
                  title: 'Sua Pokédex está vazia',
                  message: 'Abra um Pokémon no catálogo e toque em "Capturar" '
                      'para registrá-lo aqui.',
                )
              : PokemonGrid(pokemons: captured),
    );
  }
}
