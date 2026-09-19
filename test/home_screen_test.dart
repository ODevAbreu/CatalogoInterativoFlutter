import 'dart:convert';

import 'package:catalogo_pokemon/providers/catalog_provider.dart';
import 'package:catalogo_pokemon/providers/collection_provider.dart';
import 'package:catalogo_pokemon/screens/home_screen.dart';
import 'package:catalogo_pokemon/services/local_storage_service.dart';
import 'package:catalogo_pokemon/services/pokeapi_service.dart';
import 'package:catalogo_pokemon/services/sync_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';

/// Resposta fixa da listagem, com [count] itens começando em [startId].
String _pageJson({required int startId, required int count}) => jsonEncode({
      'count': 1302,
      'results': [
        for (var i = 0; i < count; i++)
          {
            'name': 'pokemon-${startId + i}',
            'url': 'https://pokeapi.co/api/v2/pokemon/${startId + i}/',
          },
      ],
    });

Widget _wrapHome(PokeApiService api, {TextScaler? textScaler}) {
  return MultiProvider(
    providers: [
      Provider<PokeApiService>.value(value: api),
      ChangeNotifierProvider<CatalogProvider>(
        create: (_) => CatalogProvider(api),
      ),
      ChangeNotifierProvider<CollectionProvider>(
        create: (_) => CollectionProvider(LocalStorageService(), SyncService()),
      ),
    ],
    child: MaterialApp(
      home: textScaler == null
          ? const HomeScreen()
          : MediaQuery(
              data: MediaQueryData(textScaler: textScaler),
              child: const HomeScreen(),
            ),
    ),
  );
}

/// Tela grande o bastante para a grade de 20 cards e o botão
/// "Carregar mais" caberem no viewport do teste.
void _useTabletView(WidgetTester tester) {
  tester.view.physicalSize = const Size(1200, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

void main() {
  testWidgets('carrega a primeira página e oferece "Carregar mais"',
      (tester) async {
    _useTabletView(tester);

    final api = PokeApiService(
      client: MockClient(
        (_) async => http.Response(_pageJson(startId: 1, count: 20), 200),
      ),
    );

    await tester.pumpWidget(_wrapHome(api));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Pokemon 1'), findsOneWidget);
    expect(find.text('Carregar mais'), findsOneWidget);
  });

  testWidgets('"Carregar mais" acrescenta a próxima página à lista',
      (tester) async {
    _useTabletView(tester);
    var requests = 0;
    final api = PokeApiService(
      client: MockClient((request) async {
        requests++;
        final offset =
            int.parse(request.url.queryParameters['offset'] ?? '0');
        return http.Response(
          _pageJson(startId: offset + 1, count: 20),
          200,
        );
      }),
    );

    await tester.pumpWidget(_wrapHome(api));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(requests, 1);

    await tester.tap(find.text('Carregar mais'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(requests, 2);
    // Os 20 primeiros continuam na lista e os novos foram acrescentados.
    final provider = tester
        .element(find.byType(HomeScreen))
        .read<CatalogProvider>();
    expect(provider.items, hasLength(40));
    expect(provider.items.first.id, 1);
    expect(provider.items.last.id, 40);
  });

  testWidgets('falha de rede mostra erro amigável com "Tentar novamente"',
      (tester) async {
    final api = PokeApiService(
      client: MockClient(
        (_) async => throw http.ClientException('sem rede'),
      ),
    );

    await tester.pumpWidget(_wrapHome(api));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Não foi possível carregar'), findsOneWidget);
    expect(find.text('Tentar novamente'), findsOneWidget);
  });

  testWidgets('layout do catálogo sobrevive à fonte do sistema em 200%',
      (tester) async {
    // RF10: com a fonte dobrada nenhum RenderFlex pode estourar — se estourar,
    // o teste falha com a exceção de overflow.
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    final api = PokeApiService(
      client: MockClient(
        (_) async => http.Response(_pageJson(startId: 1, count: 20), 200),
      ),
    );

    await tester.pumpWidget(
      _wrapHome(api, textScaler: const TextScaler.linear(2)),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(tester.takeException(), isNull);
    expect(find.text('Pokemon 1'), findsOneWidget);
  });
}
