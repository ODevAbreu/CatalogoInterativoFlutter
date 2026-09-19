Projeto Somativo da Disciplina: Flutter
Desenvolvimento Mobile Híbrido
Curso

Bacharelado em Sistemas de Informação (BSI)

Disciplina

Desenvolvimento Mobile Híbrido

Professor Responsável

Mark Joselli

Peso na Nota Final

20% (Atividade Prática Somativa de Flutter)

Grupo

Pode ser feito em grupo de até 4 pessoas, onde um dos componentes deve postar no AVA.

Data de Entrega

20/09/2026

Título do Projeto: Catálogo Interativo — tema livre (exemplo de referência: "Estante Virtual", um catálogo de livros)

1. Contexto
Este projeto somativo consiste em desenvolver um aplicativo de catálogo interativo que consome uma API pública gratuita. O projeto foi desenhado para exigir a aplicação de todos os conceitos-chave vistos em aula: construção de widgets e layouts, navegação, consumo assíncrono de APIs, gerenciamento de estado compartilhado com Provider, persistência de dados e autenticação de usuário.

O tema é livre. O exemplo de referência usado neste documento é a "Estante Virtual" (catálogo de livros com a Open Library API), mas o grupo pode escolher qualquer outro tema, desde que o aplicativo implemente exatamente a mesma estrutura funcional (RF01–RF10) descrita abaixo, usando uma API pública gratuita equivalente (lista paginada + busca + detalhe). Exemplos de outros temas possíveis: PokéAPI (Pokémon), Rick and Morty API, TVMaze (séries), SWAPI (Star Wars), Jikan (animes), Studio Ghibli API, REST Countries.

Ao final deste projeto, você terá em seu portfólio um aplicativo completo que demonstra sua competência nas principais áreas do desenvolvimento com Flutter.

2. Descrição Geral do Projeto
O aplicativo terá múltiplas telas que permitirão aos usuários:

Fazer login antes de acessar o catálogo.
Visualizar uma lista de itens carregada da internet (livros, personagens, séries, etc., conforme o tema escolhido).
Buscar por um item específico.
Ver os detalhes de um item selecionado.
Marcar itens como favoritos e como "consumidos" (lidos/assistidos/capturados — o verbo se adapta ao tema).
Ter essas informações preservadas mesmo depois de fechar o app.
3. Requisitos Funcionais (RF)
O aplicativo deverá, obrigatoriamente, implementar as seguintes funcionalidades (exemplos abaixo usam o tema de livros; adaptem à API escolhida):

RF01 — Tela Principal (Catálogo)
Ao iniciar (após login), o app deve consumir a API escolhida para buscar uma lista inicial de itens.
Os itens devem ser exibidos em GridView, com imagem e nome/título.
Um ElevatedButton "Carregar Mais" deve buscar a próxima página e adicionar os resultados à lista existente.
Itens sem imagem disponível devem exibir um placeholder — não podem quebrar a tela.
RF02 — Navegação para Detalhes
Ao tocar em um item na grade, o usuário deve ser levado à Tela de Detalhes usando Navigator.
RF03 — Tela de Detalhes do Item
Deve buscar informações completas do item na API (pode exigir uma segunda requisição, conforme a API).
Deve exibir a imagem em tamanho maior e os principais atributos do item (nome, categoria/tipo, descrição, etc.).
RF04 — Gerenciamento de Estado (Favoritos) com Provider
Na Tela de Detalhes, um botão (ex: ícone de estrela) permite favoritar/desfavoritar o item.
O estado dos favoritos deve ser gerenciado globalmente usando o pacote provider.
RF05 — Tela de Favoritos
Acessível pela Tela Principal, lista os itens favoritados via Provider, atualizando-se automaticamente ao desfavoritar.
RF06 — Persistência de Dados (obrigatório)
Os favoritos e a lista de itens "consumidos" (RF07) devem persistir entre reinícios do app.
Baseline obrigatório — Persistência Local: usar shared_preferences, hive ou sqflite.
Bônus (+10%) — Persistência em Nuvem: sincronizar os dados usando Firebase OU Supabase OU API Própria
RF07 — Login e Lista de Itens "Consumidos" (obrigatório)
O app deve exigir login antes de exibir o catálogo (RF01).
Na Tela de Detalhes, deve haver uma opção para marcar o item como "consumido" (lido/assistido/etc.), com uma tela própria (ou aba) para visualizá-los.
Baseline obrigatório — Login Local: não precisa ser autenticação real contra um servidor — pode ser um cadastro/login simples salvo localmente. O foco é a navegação condicional e a gestão do estado de sessão.
Bônus (+10%, requer o bônus de nuvem do RF06) — Autenticação Real: Firebase Auth ou Supabase Auth, com a lista vinculada ao usuário autenticado e sincronizada na nuvem.
RF08 — Funcionalidade de Busca (obrigatório)
Um TextField + TextEditingController e um botão "Buscar" devem acionar o endpoint de busca da API, navegando direto para a Tela de Detalhes do item encontrado.
RF09 — Feedback de UI (obrigatório)
Enquanto requisições estiverem em andamento (carregamento inicial, carregar mais, busca, login), a interface deve exibir CircularProgressIndicator.
Em caso de falha de comunicação com a API, uma mensagem de erro amigável deve ser exibida. FutureBuilder é a ferramenta recomendada.
RF10 — Acessibilidade (obrigatório)
Imagens e ícones/botões interativos devem ter Semantics/semanticLabel descritivos, para uso com leitor de tela (TalkBack/VoiceOver).
Contraste de cores adequado entre texto e fundo (texto legível).
O layout não pode quebrar quando o usuário aumenta a fonte do sistema (respeitar MediaQuery.textScaleFactor, evitar tamanhos fixos que cortem texto).
Áreas de toque de botões/ícones com tamanho mínimo adequado (não muito pequenas para toque).
Recomenda-se testar ao menos as telas principais com um leitor de tela ativado.
4. Ferramentas e Recursos
API: qualquer API pública gratuita e adequada ao tema escolhido, que suporte listagem paginada, detalhe de item e busca (ex: Open Library, PokéAPI, Rick and Morty API, TVMaze, SWAPI, Jikan, Studio Ghibli API, REST Countries).
Framework: Flutter com Dart.
Pacotes obrigatórios: http, provider, e um pacote de persistência local (shared_preferences, hive ou sqflite).
Pacotes opcionais (bônus RF06/RF07): firebase_core + cloud_firestore + firebase_auth ou supabase_flutter.
5. Entregáveis
A entrega deve ser feita através do campo de submissão oficial da atividade no sistema da universidade, em um único arquivo PDF, seguindo o modelo abaixo.

Modelo do PDF de Entrega
Capa:

Disciplina, turma, data de entrega.
Nome do projeto e tema escolhido.
Nome completo de TODOS os integrantes do grupo (ver penalidade no item 8).
Seção 1 — Links:

Link do repositório GitHub (público).
Link do vídeo (YouTube, público).
Seção 2 — Tema e Configuração:

Tema escolhido e API utilizada.
Opção de persistência: Local ou Nuvem (qual serviço, se nuvem).
Opção de login: Local ou Autenticação real (qual serviço, se nuvem).
Seção 3 — Autoavaliação dos Requisitos Funcionais (RF01–RF10):

Tabela indicando: RF | Implementado (Sim/Não/Parcial) | Caminho do arquivo principal.
Seção 4 — Tema da Explicação Técnica (ver item 7):

Qual tema foi escolhido e em que minuto do vídeo ele é abordado.
Seção 5 — Screenshots das telas principais (login, catálogo, detalhes, favoritos, itens consumidos).

6. Critérios de Avaliação
Requisitos Funcionais obrigatórios (90%):

Critério

Peso

RF01 — Catálogo e Paginação

15%

RF02/RF03 — Navegação e Detalhes

10%

RF04/RF05 — Favoritos com Provider

15%

RF06 — Persistência de Dados (local)

10%

RF07 — Login e Itens Consumidos (local)

10%

RF08 — Busca

10%

RF09 — Feedback de UI

10%

RF10 — Acessibilidade

10%

Qualidade do Código e Organização (5%): legibilidade, boas práticas (separação em services, models, providers, screens), ausência de segredos expostos no repositório.

Qualidade da Interface (UI/UX) (5%): layout limpo, intuitivo e funcional.

Bônus (somados à nota, limitada a 100% no total):

Bônus

Peso

RF06 — Persistência em Nuvem

+10%

RF07 — Autenticação Real (requer bônus do RF06)

+10%

7. Apresentação em Vídeo (substitui a Defesa Técnica)
7.1. Justificativa: não haverá sessões individuais de defesa técnica com o professor neste semestre. Em substituição, cada grupo grava um vídeo de apresentação que cumpre o mesmo papel: comprovar que os conceitos foram compreendidos e aplicados por todos os integrantes.

7.2. Formato do vídeo:

Hospedagem: YouTube, Público.
Duração: 6 a 9 minutos.
Todos os integrantes devem aparecer e falar, cada um explicando ao menos uma parte que implementou.
No início do vídeo, antes de qualquer outra coisa, todos os integrantes devem se apresentar dizendo o nome completo (deve bater com os nomes listados na capa do PDF).
7.3. Roteiro obrigatório e cronometrado:

0:00–0:30 — Apresentação: cada integrante diz seu nome completo.
0:30–2:00 — Demonstração: o app rodando (login, catálogo, detalhes, favoritos, itens consumidos).
2:00–5:30 — Explicação de código: cada integrante explica o trecho de código sob sua responsabilidade, relacionando-o ao RF correspondente (~50s por pessoa, em um grupo de 4).
5:30–8:00 — Explicação Técnica (seção final): o grupo escolhe um tema técnico da lista abaixo (ou outro, combinado com o professor) e explica em profundidade, relacionando com decisões tomadas no próprio código.
Sugestões de temas para a Explicação Técnica:

Provider vs. setState — por que gerenciar favoritos/itens consumidos como estado global em vez de estado local de widget?
FutureBuilder vs. then/catchError direto — vantagens e desvantagens de cada abordagem para tratar carregamento e erro.
Escolha do mecanismo de persistência local (shared_preferences vs. hive vs. sqflite) — por que optaram por um e não outro?
Local vs. Nuvem (para quem fez o bônus) — trade-offs de latência, funcionamento offline, complexidade de configuração.
Organização do projeto (services/models/providers/screens) — por que estruturaram as pastas dessa forma?
Pilha de navegação — como decidiram o fluxo login → catálogo → detalhes usando Navigator (push, pop, replacement)?
Tratamento de falhas de rede — o que acontece se a API cair no meio de uma sessão (ex: durante "Carregar Mais")?
8. Regras de Entrega e Penalidades
Entrega por comentário: se a entrega for feita por comentário na atividade, em vez do campo de submissão oficial, será descontado -30% da nota final.
Item de entregável faltante: qualquer item ausente do PDF descrito no item 5 (links, seções, tabela, screenshots) resulta em -20% por item faltante.
Atraso: entregas feitas após 20/09/2026 sofrem desconto de -20% por semana de atraso (ou fração de semana).
Nome de integrante faltando: se o nome completo de algum integrante do grupo não constar na capa do PDF, esse integrante específico recebe nota ZERO, mesmo que apareça no vídeo de apresentação. Os demais integrantes do grupo (cujos nomes constam corretamente) não são afetados por essa penalidade.
Duração do vídeo fora do intervalo: o vídeo deve ter entre 6 e 9 minutos (ver item 7.2). Vídeos com menos de 6 minutos ou mais de 8 minutos sofrem desconto de -5% por minuto excedente (ex: um vídeo de 4 minutos tem 2 minutos abaixo do mínimo → -10%; um vídeo de 11 minutos tem 2 minutos acima do máximo → -10%).
