# Pokédex Interativa

Catálogo interativo de Pokémon em Flutter, desenvolvido como Projeto Somativo da disciplina
**Desenvolvimento Mobile Híbrido** (BSI). O enunciado completo está em
[docs/ENUNCIADO.md](docs/ENUNCIADO.md).

| | |
|---|---|
| **Tema** | Pokémon |
| **API pública** | [PokéAPI](https://pokeapi.co/) — `https://pokeapi.co/api/v2` (sem chave de API) |
| **Persistência** | Local (`shared_preferences`) **+ nuvem (Supabase/Postgres)** — bônus |
| **Login** | Local (hash SHA-256) **+ autenticação real (Supabase Auth)** — bônus |
| **Plataforma** | Android |

O verbo "consumido" do enunciado virou **capturado**: a lista de itens consumidos é a
Pokédex pessoal do usuário.

---

## Como rodar

```bash
flutter pub get
flutter run --dart-define-from-file=env.json
```

O `env.json` guarda as credenciais do Supabase e **não é versionado**. Copie
`env.example.json` para `env.json` e preencha:

```json
{
  "SUPABASE_URL": "https://SEU-PROJETO.supabase.co",
  "SUPABASE_ANON_KEY": "sua-anon-key"
}
```

Sem `env.json` o app roda normalmente em **modo local** (login local + `shared_preferences`),
que é o baseline obrigatório do enunciado:

```bash
flutter run
```

### Configuração do bônus de nuvem

1. Crie um projeto em [supabase.com](https://supabase.com).
2. No **SQL Editor**, rode [supabase/schema.sql](supabase/schema.sql) — cria a tabela
   `user_items` e as policies de Row Level Security (cada usuário só acessa as próprias linhas).
3. Em **Authentication → Sign In / Providers → Email**, desative *Confirm email* para que o
   cadastro já abra sessão na hora (ou confirme o e-mail antes de entrar).
4. Copie **Project URL** e **anon/publishable key** para o `env.json`.

### Testes

```bash
flutter analyze
flutter test
```

---

## Arquitetura

```
lib/
├── main.dart                     # bootstrap: Supabase opcional + MultiProvider
├── app.dart                      # MaterialApp + AuthGate (navegação condicional)
├── core/
│   ├── config/env.dart           # credenciais via --dart-define (nada commitado)
│   ├── theme/app_theme.dart      # Material 3, alvos de toque >= 48dp
│   └── utils/pokemon_utils.dart  # id da URL, artwork, tipos em PT, cores
├── models/                       # PokemonSummary, PokemonDetail, CollectionEntry, AppUser
├── services/                     # PokeApiService, LocalStorageService, AuthService, SyncService
├── providers/                    # AuthProvider, CatalogProvider, CollectionProvider
├── screens/                      # login, home (catálogo+busca), detail, favorites, captured
└── widgets/                      # PokemonCard, PokemonGrid, PokemonImage, TypeChip, state views
```

**Por que essa separação:** `services` não conhecem Flutter (são testáveis com `MockClient`),
`providers` guardam o estado global e traduzem erros para mensagens de UI, e `screens`/`widgets`
só desenham. Trocar a PokéAPI por outra API mexeria em um único arquivo.

**Fluxo de dados de uma marcação (favoritar/capturar):**

```
UI → CollectionProvider → 1. memória + notifyListeners  (instantâneo)
                          2. shared_preferences         (RF06 baseline)
                          3. Supabase upsert            (bônus, best-effort)
```

Estratégia **local-first**: se a nuvem falhar, a marcação continua salva no aparelho e um aviso
não-bloqueante aparece na tela principal. Ao logar em outro aparelho, local e nuvem são
mesclados pelo campo `updated_at` (vence a marcação mais recente).

---

## Autoavaliação dos Requisitos Funcionais

| RF | Implementado | Arquivo principal |
|----|--------------|-------------------|
| RF01 — Catálogo em GridView + "Carregar mais" | Sim | [lib/screens/home_screen.dart](lib/screens/home_screen.dart), [lib/providers/catalog_provider.dart](lib/providers/catalog_provider.dart) |
| RF02 — Navegação para detalhes (`Navigator.push`) | Sim | [lib/widgets/pokemon_card.dart](lib/widgets/pokemon_card.dart), [lib/screens/detail_screen.dart](lib/screens/detail_screen.dart) |
| RF03 — Tela de detalhes (2ª requisição: `/pokemon` + `/pokemon-species`) | Sim | [lib/screens/detail_screen.dart](lib/screens/detail_screen.dart), [lib/services/pokeapi_service.dart](lib/services/pokeapi_service.dart) |
| RF04 — Favoritos com Provider | Sim | [lib/providers/collection_provider.dart](lib/providers/collection_provider.dart) |
| RF05 — Tela de favoritos | Sim | [lib/screens/favorites_screen.dart](lib/screens/favorites_screen.dart) |
| RF06 — Persistência local + **nuvem (bônus)** | Sim | [lib/services/local_storage_service.dart](lib/services/local_storage_service.dart), [lib/services/sync_service.dart](lib/services/sync_service.dart) |
| RF07 — Login + capturados (**autenticação real, bônus**) | Sim | [lib/screens/login_screen.dart](lib/screens/login_screen.dart), [lib/screens/captured_screen.dart](lib/screens/captured_screen.dart), [lib/services/auth_service.dart](lib/services/auth_service.dart) |
| RF08 — Busca com navegação direta ao detalhe | Sim | [lib/screens/home_screen.dart](lib/screens/home_screen.dart) |
| RF09 — Feedback de UI (`CircularProgressIndicator`, `FutureBuilder`, erros) | Sim | [lib/widgets/state_views.dart](lib/widgets/state_views.dart), [lib/screens/detail_screen.dart](lib/screens/detail_screen.dart) |
| RF10 — Acessibilidade (`Semantics`, contraste, escala de fonte, toque) | Sim | transversal — [lib/widgets/pokemon_card.dart](lib/widgets/pokemon_card.dart), [lib/widgets/pokemon_grid.dart](lib/widgets/pokemon_grid.dart), [lib/core/theme/app_theme.dart](lib/core/theme/app_theme.dart) |

### Detalhes de acessibilidade (RF10)

* **Leitor de tela:** cada card é um único nó semântico que anuncia nome, número e marcações
  ("Pokémon Pikachu, número 25, favorito e capturado. Abrir detalhes."); imagens têm
  `semanticLabel`; todo `IconButton` tem `tooltip`.
* **Escala de fonte:** a altura das células da grade é calculada a partir de
  `MediaQuery.textScalerOf(context)` — com a fonte do sistema no máximo os cards crescem em vez
  de cortar o texto. Há um teste automatizado para isso (`test/home_screen_test.dart`).
* **Contraste:** paleta gerada por `ColorScheme.fromSeed` (pares cor/`onCor`) e cores de tipo
  escurecidas para manter >= 4.5:1 com texto branco.
* **Toque:** botões e ícones com no mínimo 48dp definidos no tema.

### Tratamento de falhas de rede

* Timeout de 15s em toda requisição.
* Falha na **primeira** página → tela de erro com "Tentar novamente".
* Falha no **"Carregar mais"** → a lista já carregada permanece; a mensagem aparece junto do botão.
* Falha na **busca** → `SnackBar`; 404 ("não encontrado") tem mensagem diferente de "sem conexão".
* Falha em `/pokemon-species` → o detalhe é exibido sem a descrição, em vez de quebrar.
* Pokémon sem artwork → placeholder no card (nenhum item sem imagem quebra a grade).

---

## Testes automatizados

`flutter test` — 24 testes, sem rede real (`MockClient`):

* `test/pokemon_models_test.dart` — parsing dos models, JSON incompleto, round-trip da persistência.
* `test/pokeapi_service_test.dart` — paginação, 404 vs. 500 vs. sem rede, normalização da busca.
* `test/home_screen_test.dart` — carga inicial, "Carregar mais" acrescentando à lista, tela de
  erro e layout com fonte em 200%.

---

## Sugestão de roteiro do vídeo (6–9 min)

| Tempo | Conteúdo |
|-------|----------|
| 0:00–0:30 | Nome completo de cada integrante |
| 0:30–2:00 | Demo: login → catálogo → carregar mais → detalhes → favoritar → capturar → as duas listas → fechar e reabrir (persistência) → busca |
| 2:00–5:30 | Cada integrante explica seu trecho, citando o RF |
| 5:30–8:00 | Explicação técnica (sugestões abaixo) |

Temas de explicação técnica que este código sustenta bem:

* **Provider vs. setState** — por que favoritos/capturados são estado global (`CollectionProvider`)
  enquanto o texto da busca é estado local do `HomeScreen`.
* **FutureBuilder vs. then/catchError** — a tela de detalhes usa `FutureBuilder`; o catálogo usa
  `ChangeNotifier`, porque "carregar mais" acumula resultados entre requisições.
* **Local vs. nuvem** — o pipeline local-first dos três passos acima: latência, offline e conflito.
