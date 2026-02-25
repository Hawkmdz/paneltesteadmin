-- ============================================================
-- BOOSTPANEL — SQL SETUP COMPLETO PARA SUPABASE
-- Execute este script no SQL Editor do Supabase
-- Dashboard → SQL Editor → New query → Cole e clique em Run
-- ============================================================

-- ============================================================
-- 1. TABELA: profiles (dados dos usuários)
-- ============================================================
create table if not exists public.profiles (
  id          uuid        references auth.users(id) on delete cascade primary key,
  name        text,
  email       text,
  whatsapp    text,
  role        text        not null default 'user',
  level       int         not null default 1,
  total_spent numeric     not null default 0,
  total_orders int        not null default 0,
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);

-- RLS
alter table public.profiles enable row level security;

create policy "Usuário vê próprio perfil"
  on public.profiles for select
  using (auth.uid() = id);

create policy "Usuário edita próprio perfil"
  on public.profiles for update
  using (auth.uid() = id);

create policy "Usuário insere próprio perfil"
  on public.profiles for insert
  with check (auth.uid() = id);

create policy "Admin vê todos os perfis"
  on public.profiles for select
  using (exists (
    select 1 from public.profiles p
    where p.id = auth.uid() and p.role = 'admin'
  ));


-- ============================================================
-- 2. TABELA: orders (pedidos)
-- ============================================================
create table if not exists public.orders (
  id             bigint      generated always as identity primary key,
  user_id        uuid        references public.profiles(id) on delete set null,
  api_order_id   text,
  service_id     text,
  service_name   text,
  platform       text,
  link           text,
  qty            int,
  price          numeric,
  client_name    text,
  client_email   text,
  segmentation   text,
  coupon         text,
  status         text        not null default 'pending',
  pay_status     text        not null default 'awaiting',
  created_at     timestamptz not null default now(),
  updated_at     timestamptz not null default now()
);

-- RLS
alter table public.orders enable row level security;

create policy "Usuário vê próprios pedidos"
  on public.orders for select
  using (auth.uid() = user_id);

create policy "Usuário cria próprios pedidos"
  on public.orders for insert
  with check (auth.uid() = user_id);

create policy "Usuário atualiza próprios pedidos"
  on public.orders for update
  using (auth.uid() = user_id);

create policy "Admin gerencia todos os pedidos"
  on public.orders for all
  using (exists (
    select 1 from public.profiles p
    where p.id = auth.uid() and p.role = 'admin'
  ));


-- ============================================================
-- 3. TABELA: services (cache do catálogo de serviços da API)
-- ============================================================
create table if not exists public.services (
  service_id  text        primary key,
  name        text,
  category    text,
  rate        numeric,
  min_qty     int,
  max_qty     int,
  active      boolean     not null default true,
  updated_at  timestamptz not null default now()
);

-- RLS
alter table public.services enable row level security;

create policy "Usuários autenticados veem serviços"
  on public.services for select
  using (auth.role() = 'authenticated');

create policy "Admin gerencia serviços"
  on public.services for all
  using (exists (
    select 1 from public.profiles p
    where p.id = auth.uid() and p.role = 'admin'
  ));


-- ============================================================
-- 4. TABELA: config (configurações do painel — chave/valor)
-- ============================================================
create table if not exists public.config (
  key         text        primary key,
  value       text,
  updated_at  timestamptz not null default now()
);

-- RLS: usuários autenticados leem; apenas admin escreve
alter table public.config enable row level security;

create policy "Usuários autenticados leem config"
  on public.config for select
  using (auth.role() = 'authenticated');

create policy "Admin escreve config (insert)"
  on public.config for insert
  with check (exists (
    select 1 from public.profiles p
    where p.id = auth.uid() and p.role = 'admin'
  ));

create policy "Admin escreve config (update)"
  on public.config for update
  using (exists (
    select 1 from public.profiles p
    where p.id = auth.uid() and p.role = 'admin'
  ));

create policy "Admin apaga config"
  on public.config for delete
  using (exists (
    select 1 from public.profiles p
    where p.id = auth.uid() and p.role = 'admin'
  ));


-- ============================================================
-- 5. TABELA: coupons (cupons de desconto)
-- ============================================================
create table if not exists public.coupons (
  id          bigint      generated always as identity primary key,
  code        text        unique not null,
  discount    numeric     not null,
  active      boolean     not null default true,
  created_at  timestamptz not null default now()
);

-- RLS
alter table public.coupons enable row level security;

create policy "Usuários autenticados veem cupons ativos"
  on public.coupons for select
  using (auth.role() = 'authenticated' and active = true);

create policy "Admin gerencia cupons"
  on public.coupons for all
  using (exists (
    select 1 from public.profiles p
    where p.id = auth.uid() and p.role = 'admin'
  ));


-- ============================================================
-- 6. TRIGGER: cria perfil automático no cadastro
--    O PRIMEIRO usuário recebe role 'admin' automaticamente
-- ============================================================
create or replace function public.handle_new_user()
returns trigger as $$
declare
  user_count int;
  user_name  text;
begin
  select count(*) into user_count from public.profiles;
  user_name := coalesce(
    new.raw_user_meta_data->>'name',
    split_part(new.email, '@', 1)
  );
  insert into public.profiles (id, email, name, role)
  values (
    new.id,
    new.email,
    user_name,
    case when user_count = 0 then 'admin' else 'user' end
  );
  return new;
end;
$$ language plpgsql security definer;

-- Garante que o trigger não existe antes de criar
drop trigger if exists on_auth_user_created on auth.users;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();


-- ============================================================
-- 7. DADOS INICIAIS: cupons de exemplo
-- ============================================================
insert into public.coupons (code, discount) values
  ('PROMO10', 10),
  ('BOOST20', 20),
  ('SMM15',   15)
on conflict (code) do nothing;


-- ============================================================
-- PRONTO! Execute o script e volte ao painel.
-- O primeiro usuário a se cadastrar será admin automaticamente.
-- ============================================================
