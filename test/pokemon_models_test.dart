import 'package:catalogo_pokemon/core/utils/pokemon_utils.dart';
import 'package:catalogo_pokemon/models/collection_entry.dart';
import 'package:catalogo_pokemon/models/pokemon_detail.dart';
import 'package:catalogo_pokemon/models/pokemon_summary.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PokemonUtils', () {
    test('extrai o id da URL da listagem', () {
      expect(
        PokemonUtils.idFromUrl('https://pokeapi.co/api/v2/pokemon/25/'),
        25,
      );
      expect(PokemonUtils.idFromUrl('url-invalida'), 0);
    });

    test('formata nome e número para exibição', () {
      expect(PokemonUtils.displayName('mr-mime'), 'Mr Mime');
      expect(PokemonUtils.displayName('pikachu'), 'Pikachu');
      expect(PokemonUtils.formattedId(25), '#025');
    });

    test('limpa os caracteres de controle do texto da Pokédex', () {
      expect(
        PokemonUtils.cleanFlavorText('Quando\nváriasdestas   criaturas'),
        'Quando várias destas criaturas',
      );
    });

    test('traduz tipos conhecidos e não quebra com desconhecidos', () {
      expect(PokemonUtils.typeLabel('water'), 'Água');
      expect(PokemonUtils.typeLabel('tipo-novo'), 'Tipo Novo');
    });
  });

  group('PokemonSummary', () {
    test('monta a partir de um item da listagem', () {
      final pokemon = PokemonSummary.fromListItem({
        'name': 'bulbasaur',
        'url': 'https://pokeapi.co/api/v2/pokemon/1/',
      });

      expect(pokemon.id, 1);
      expect(pokemon.displayName, 'Bulbasaur');
      expect(pokemon.imageUrl, contains('official-artwork/1.png'));
    });

    test('sem id válido fica sem imagem (cai no placeholder da UI)', () {
      final pokemon = PokemonSummary.fromListItem({'name': 'x', 'url': ''});
      expect(pokemon.id, 0);
      expect(pokemon.imageUrl, isEmpty);
    });

    test('sobrevive a um round-trip de JSON (persistência local)', () {
      const original =
          PokemonSummary(id: 4, name: 'charmander', imageUrl: 'http://x/4.png');
      final copy = PokemonSummary.fromJson(original.toJson());

      expect(copy.id, original.id);
      expect(copy.name, original.name);
      expect(copy.imageUrl, original.imageUrl);
    });
  });

  group('PokemonDetail.fromApi', () {
    final pokemonJson = <String, dynamic>{
      'id': 25,
      'name': 'pikachu',
      'height': 4,
      'weight': 60,
      'base_experience': 112,
      'types': [
        {
          'slot': 1,
          'type': {'name': 'electric'},
        },
      ],
      'abilities': [
        {
          'ability': {'name': 'static'},
        },
        {
          'ability': {'name': 'lightning-rod'},
        },
      ],
      'stats': [
        {
          'base_stat': 35,
          'stat': {'name': 'hp'},
        },
        {
          'base_stat': 55,
          'stat': {'name': 'attack'},
        },
      ],
      'sprites': {
        'front_default': 'http://sprites/25.png',
        'other': {
          'official-artwork': {'front_default': 'http://artwork/25.png'},
        },
      },
      'species': {'url': 'https://pokeapi.co/api/v2/pokemon-species/25/'},
    };

    final speciesJson = <String, dynamic>{
      'flavor_text_entries': [
        {
          'flavor_text': 'Texto em japonês',
          'language': {'name': 'ja'},
        },
        {
          'flavor_text': 'When several of\nthese POKéMON gather,',
          'language': {'name': 'en'},
        },
      ],
      'genera': [
        {
          'genus': 'Mouse Pokémon',
          'language': {'name': 'en'},
        },
      ],
    };

    test('combina /pokemon e /pokemon-species', () {
      final detail =
          PokemonDetail.fromApi(pokemonJson, speciesJson: speciesJson);

      expect(detail.displayName, 'Pikachu');
      expect(detail.types, ['electric']);
      expect(detail.abilities, ['Static', 'Lightning Rod']);
      expect(detail.stats.first.label, 'PS');
      expect(detail.imageUrl, 'http://artwork/25.png');
      expect(detail.genus, 'Mouse Pokémon');
      // Preferiu inglês (não há português na API) e limpou o \n.
      expect(detail.description, 'When several of these POKéMON gather,');
    });

    test('converte altura e peso para as unidades legíveis', () {
      final detail = PokemonDetail.fromApi(pokemonJson);
      expect(detail.heightLabel, '0,4 m');
      expect(detail.weightLabel, '6,0 kg');
    });

    test('funciona sem species: detalhe exibido sem descrição', () {
      final detail = PokemonDetail.fromApi(pokemonJson);
      expect(detail.description, isEmpty);
      expect(detail.genus, isEmpty);
      expect(detail.types, ['electric']);
    });

    test('tolera JSON incompleto sem lançar exceção', () {
      final detail = PokemonDetail.fromApi({'id': 1, 'name': 'bulbasaur'});
      expect(detail.types, isEmpty);
      expect(detail.stats, isEmpty);
      expect(detail.imageUrl, contains('official-artwork/1.png'));
    });
  });

  group('CollectionEntry', () {
    const pokemon =
        PokemonSummary(id: 7, name: 'squirtle', imageUrl: 'http://x/7.png');

    test('entrada sem nenhuma marcação é considerada vazia', () {
      final entry = CollectionEntry(
        pokemon: pokemon,
        isFavorite: false,
        isCaptured: false,
        updatedAt: DateTime(2026, 9, 16),
      );

      expect(entry.isEmpty, isTrue);
      expect(entry.copyWith(isFavorite: true).isEmpty, isFalse);
    });

    test('round-trip do formato da tabela do Supabase', () {
      final entry = CollectionEntry(
        pokemon: pokemon,
        isFavorite: true,
        isCaptured: false,
        updatedAt: DateTime(2026, 9, 16, 10, 30),
      );

      final remote = CollectionEntry.fromRemoteJson(
        entry.toRemoteJson('user-123'),
      );

      expect(remote.id, 7);
      expect(remote.pokemon.name, 'squirtle');
      expect(remote.isFavorite, isTrue);
      expect(remote.isCaptured, isFalse);
      expect(remote.updatedAt, entry.updatedAt);
    });
  });
}
