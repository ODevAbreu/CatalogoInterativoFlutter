-- Esquema do bônus de persistência em nuvem (RF06) e de autenticação real
-- (RF07). Rode este script no SQL Editor do painel do Supabase.
--
-- A tabela guarda UMA linha por (usuário, pokémon), com as duas marcações do
-- enunciado: favorito e capturado.

create table if not exists public.user_items (
  user_id     uuid        not null references auth.users (id) on delete cascade,
  pokemon_id  integer     not null,
  name        text        not null default '',
  image_url   text        not null default '',
  is_favorite boolean     not null default false,
  is_captured boolean     not null default false,
  updated_at  timestamptz not null default now(),
  primary key (user_id, pokemon_id)
);

-- Consulta mais comum do app: "tudo do usuário logado".
create index if not exists user_items_user_id_idx
  on public.user_items (user_id);

-- Row Level Security: cada usuário só enxerga e altera as próprias linhas.
-- Sem isso, a anon key permitiria ler a coleção de qualquer pessoa.
alter table public.user_items enable row level security;

drop policy if exists "user_items_select_own" on public.user_items;
create policy "user_items_select_own"
  on public.user_items for select
  using (auth.uid() = user_id);

drop policy if exists "user_items_insert_own" on public.user_items;
create policy "user_items_insert_own"
  on public.user_items for insert
  with check (auth.uid() = user_id);

drop policy if exists "user_items_update_own" on public.user_items;
create policy "user_items_update_own"
  on public.user_items for update
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

drop policy if exists "user_items_delete_own" on public.user_items;
create policy "user_items_delete_own"
  on public.user_items for delete
  using (auth.uid() = user_id);
