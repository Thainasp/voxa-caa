-- =====================================================================
-- VOXA — Migração v2 (rodar DEPOIS de supabase_content.sql)
-- Supabase > SQL Editor. Pode ser executada mais de uma vez.
--
-- 1. Índices nas FKs ............ corrige o erro 57014 ao excluir dependente
-- 2. RPC excluir_dependente ..... exclusão numa única transação
-- 3. Tabela alerta_emergencia ... histórico do botão de emergência (back-end)
-- 4. Limpeza (opcional) ......... remove as cópias do catálogo ARASAAC por
--                                  perfil, que o app não usa mais (o catálogo
--                                  agora fica no SQLite do aparelho)
-- =====================================================================


-- ---------------------------------------------------------------------
-- 1. ÍNDICES
-- O Postgres não indexa colunas FK sozinho. Cada perfil tinha ~13,7 mil
-- cartões e ~26,8 mil vínculos; sem índice em prancha_cartao(cartao_id),
-- cada cartão apagado varria a tabela inteira de vínculos, e a exclusão
-- do perfil era cancelada pelo statement_timeout (57014).
-- (prancha_cartao(prancha_id) já é coberto pela PK/índice composto e
--  prancha(perfil_id) pelo índice prancha_perfil_chave_idx.)
-- ---------------------------------------------------------------------
create index if not exists prancha_cartao_cartao_idx
  on public.prancha_cartao (cartao_id);
create index if not exists cartao_perfil_idx
  on public.cartao (perfil_id);
create index if not exists perfil_usuario_idx
  on public.perfil (usuario_id);

analyze public.prancha_cartao;
analyze public.cartao;
analyze public.prancha;
analyze public.perfil;


-- ---------------------------------------------------------------------
-- 2. RPC excluir_dependente
-- Usada pelo app (ProfileApi.deleteDependent). A senha é confirmada no app
-- (reautenticação) antes da chamada. Só exclui perfil NÃO responsável que
-- pertença ao usuário logado.
-- ---------------------------------------------------------------------
create or replace function public.excluir_dependente(p_perfil_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if auth.uid() is null or not exists (
    select 1
    from public.perfil p
    where p.id = p_perfil_id
      and p.usuario_id = auth.uid()
      and p.is_responsavel = false
  ) then
    raise exception 'Dependente não encontrado ou sem permissão'
      using errcode = '42501';
  end if;

  delete from public.prancha_cartao pc
   using public.prancha pr
   where pc.prancha_id = pr.id
     and pr.perfil_id = p_perfil_id;

  delete from public.prancha_cartao pc
   using public.cartao c
   where pc.cartao_id = c.id
     and c.perfil_id = p_perfil_id;

  delete from public.prancha where perfil_id = p_perfil_id;
  delete from public.cartao  where perfil_id = p_perfil_id;
  delete from public.perfil_catalogo_versao where perfil_id = p_perfil_id;
  delete from public.perfil  where id = p_perfil_id;
end;
$$;

revoke all on function public.excluir_dependente(uuid) from public, anon;
grant execute on function public.excluir_dependente(uuid) to authenticated;


-- ---------------------------------------------------------------------
-- 3. ALERTA DE EMERGÊNCIA (usado pelo back-end Spring Boot – BRADWBK)
-- O back-end conecta direto no Postgres do Supabase, então ignora o RLS.
-- O RLS fica ligado sem políticas para o app não ler/escrever direto.
-- ---------------------------------------------------------------------
create table if not exists public.alerta_emergencia (
  id               uuid primary key default gen_random_uuid(),
  cliente_id       uuid,
  usuario_id       uuid not null references public.usuario (id) on delete cascade,
  perfil_id        uuid not null references public.perfil  (id) on delete cascade,
  mensagem         text not null,
  telefone_destino text,
  status           text not null default 'RECEBIDO'
                   check (status in ('RECEBIDO', 'SMS_ENVIADO', 'SMS_FALHOU')),
  criado_em        timestamptz not null default now()
);
create index if not exists alerta_emergencia_perfil_idx
  on public.alerta_emergencia (perfil_id, criado_em desc);
create index if not exists alerta_emergencia_usuario_idx
  on public.alerta_emergencia (usuario_id);
alter table public.alerta_emergencia enable row level security;


-- ---------------------------------------------------------------------
-- 4. LIMPEZA OPCIONAL das cópias antigas do catálogo
-- Rode no SQL Editor (sem o limite de tempo do app). Não afeta pranchas e
-- cartões criados pelo usuário nem fotos enviadas (imagem_storage_path).
-- Depois disto as funções sincronizar_catalogo_arasaac* ficam sem uso.
-- ---------------------------------------------------------------------
-- begin;
--
-- delete from public.prancha_cartao pc
--  using public.prancha p
--  where pc.prancha_id = p.id
--    and p.catalogo_arasaac;
--
-- delete from public.prancha p
--  where p.catalogo_arasaac;
--
-- delete from public.cartao c
--  where c.imagem_storage_path is null
--    and (c.caminho_imagem like 'arasaac-catalog/%'
--         or c.caminho_imagem like 'assets/arasaac/%')
--    and not exists (
--      select 1 from public.prancha_cartao pc where pc.cartao_id = c.id
--    );
--
-- delete from public.perfil_catalogo_versao;
--
-- commit;
