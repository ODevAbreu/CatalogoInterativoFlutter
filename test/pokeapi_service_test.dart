import 'dart:convert';

import 'package:catalogo_pokemon/services/pokeapi_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// Testes do service com `MockClient`: nenhuma chamada real sai para a
/// internet, então os casos de erro (404, 500, sem rede) podem ser
/// verificados de forma determinística.
void main() {
  group('PokeApiService.fetchPage', () {
    test('converte a listagem paginada em PokemonSummary', () async {
      final service = PokeApiService(
        client: MockClient((request) async {
          expect(request.url.queryParameters['offset'], '20');
          expect(request.url.queryParameters['limit'], '20');
          return http.Response(
            jsonEncode({
              'count': 1302,
              'results': [
                {
                  'name': 'bulbasaur',
                  'url': 'https://pokeapi.co/api/v2/pokemon/1/',
                },
                {
                  'name': 'ivysaur',
                  'url': 'https://pokeapi.co/api/v2/pokemon/2/',
                },
              ],
            }),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }),
      );

      final page = await service.fetchPage(offset: 20);

      expect(page, hasLength(2));
      expect(page.first.id, 1);
      expect(page.last.displayName, 'Ivysaur');
    });

    test('erro 500 vira PokeApiException com mensagem amigável', () async {
      final service = PokeApiService(
        client: MockClient((_) async => http.Response('boom', 500)),
      );

      await expectLater(
        service.fetchPage(offset: 0),
        throwsA(
          isA<PokeApiException>().having(
            (error) => error.message,
            'message',
            contains('500'),
          ),
        ),
      );
    });

    test('falha de rede vira mensagem de "sem conexão"', () async {
      final service = PokeApiService(
        client: MockClient(
          (_) async => throw http.ClientException('falha de socket'),
        ),
      );

      await expectLater(
        service.fetchPage(offset: 0),
        throwsA(
          isA<PokeApiException>()
              .having((e) => e.message, 'message', contains('Sem conexão'))
              .having((e) => e.isNotFound, 'isNotFound', isFalse),
        ),
      );
    });
  });

  group('PokeApiService.search', () {
    test('normaliza o termo digitado antes de chamar a API', () async {
      final requested = <String>[];
      final service = PokeApiService(
        client: MockClient((request) async {
          requested.add(request.url.path);
          if (request.url.path.contains('pokemon-species')) {
            return http.Response(jsonEncode({'genera': []}), 200);
          }
          return http.Response(
            jsonEncode({
              'id': 25,
              'name': 'pikachu',
              'species': {
                'url': 'https://pokeapi.co/api/v2/pokemon-species/25/',
              },
            }),
            200,
          );
        }),
      );

      final detail = await service.search('  PikaChu  ');

      expect(detail.id, 25);
      expect(requested.first, '/api/v2/pokemon/pikachu');
    });

    test('404 marca isNotFound para a UI diferenciar do erro de rede',
        () async {
      final service = PokeApiService(
        client: MockClient((_) async => http.Response('Not Found', 404)),
      );

      await expectLater(
        service.search('naoexiste'),
        throwsA(
          isA<PokeApiException>()
              .having((e) => e.isNotFound, 'isNotFound', isTrue),
        ),
      );
    });

    test('termo vazio nem chega a fazer requisição', () async {
      final service = PokeApiService(
        client: MockClient((_) async {
          fail('não deveria chamar a API');
        }),
      );

      await expectLater(service.search('   '), throwsA(isA<PokeApiException>()));
    });
  });

  group('PokeApiService.fetchDetail', () {
    test('segue funcionando quando /pokemon-species falha', () async {
      final service = PokeApiService(
        client: MockClient((request) async {
          if (request.url.path.contains('pokemon-species')) {
            return http.Response('erro', 500);
          }
          return http.Response(
            jsonEncode({
              'id': 1,
              'name': 'bulbasaur',
              'types': [
                {
                  'type': {'name': 'grass'},
                },
              ],
              'species': {
                'url': 'https://pokeapi.co/api/v2/pokemon-species/1/',
              },
            }),
            200,
          );
        }),
      );

      final detail = await service.fetchDetail(1);

      expect(detail.displayName, 'Bulbasaur');
      expect(detail.types, ['grass']);
      expect(detail.description, isEmpty);
    });
  });
}
