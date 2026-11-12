alter table public.prancha
  add column if not exists imagem_storage_path text,
  add column if not exists caminho_audio text,
  add column if not exists catalogo_arasaac boolean not null default false,
  add column if not exists catalogo_pai_chave text;

alter table public.cartao
  add column if not exists imagem_storage_path text,
  add column if not exists arasaac_id text,
  alter column categoria_id drop not null;

grant select, insert, update, delete
  on public.prancha, public.cartao, public.prancha_cartao
  to authenticated;

alter table public.prancha enable row level security;
alter table public.cartao enable row level security;
alter table public.prancha_cartao enable row level security;

create index if not exists prancha_perfil_chave_idx
  on public.prancha (perfil_id, chave);
create index if not exists cartao_perfil_arasaac_idx
  on public.cartao (perfil_id, arasaac_id)
  where arasaac_id is not null;
create index if not exists prancha_cartao_prancha_cartao_idx
  on public.prancha_cartao (prancha_id, cartao_id);

drop policy if exists "Voxa profile owners manage boards" on public.prancha;
create policy "Voxa profile owners manage boards"
  on public.prancha for all to authenticated
  using (
    exists (
      select 1
      from public.perfil p
      where p.id = perfil_id
        and p.usuario_id = (select auth.uid())
    )
  )
  with check (
    exists (
      select 1
      from public.perfil p
      where p.id = perfil_id
        and p.usuario_id = (select auth.uid())
    )
  );

drop policy if exists "Voxa profile owners manage cards" on public.cartao;
create policy "Voxa profile owners manage cards"
  on public.cartao for all to authenticated
  using (
    exists (
      select 1
      from public.perfil p
      where p.id = perfil_id
        and p.usuario_id = (select auth.uid())
    )
  )
  with check (
    exists (
      select 1
      from public.perfil p
      where p.id = perfil_id
        and p.usuario_id = (select auth.uid())
    )
  );

drop policy if exists "Voxa profile owners manage board cards"
  on public.prancha_cartao;
create policy "Voxa profile owners manage board cards"
  on public.prancha_cartao for all to authenticated
  using (
    exists (
      select 1
      from public.prancha p
      join public.cartao c on c.id = cartao_id
      join public.perfil perfil on perfil.id = p.perfil_id
      where p.id = prancha_id
        and c.perfil_id = p.perfil_id
        and perfil.usuario_id = (select auth.uid())
    )
  )
  with check (
    exists (
      select 1
      from public.prancha p
      join public.cartao c on c.id = cartao_id
      join public.perfil perfil on perfil.id = p.perfil_id
      where p.id = prancha_id
        and c.perfil_id = p.perfil_id
        and perfil.usuario_id = (select auth.uid())
    )
  );

create or replace function public.inicializar_conteudo_padrao(
  novo_perfil_id uuid,
  dados jsonb
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  board_data jsonb;
  card_data jsonb;
  board_id uuid;
  card_id uuid;
begin
  if auth.uid() is null or not exists (
    select 1
    from public.perfil p
    where p.id = novo_perfil_id
      and p.usuario_id = auth.uid()
  ) then
    raise exception 'Perfil não autorizado' using errcode = '42501';
  end if;

  if exists (
    select 1
    from public.prancha p
    where p.perfil_id = novo_perfil_id
  ) then
    return;
  end if;

  if jsonb_typeof(dados -> 'boards') <> 'array' then
    raise exception 'Dados iniciais inválidos' using errcode = '22023';
  end if;

  for board_data in
    select value from jsonb_array_elements(dados -> 'boards')
  loop
    insert into public.prancha (
      perfil_id,
      chave,
      nome,
      icone,
      imagem_url,
      imagem_storage_path,
      caminho_audio,
      ordem
    )
    values (
      novo_perfil_id,
      board_data ->> 'key',
      board_data ->> 'label',
      coalesce(board_data ->> 'icon', 'dashboard_customize'),
      board_data ->> 'imagePath',
      null,
      board_data ->> 'audioPath',
      coalesce((board_data ->> 'order')::integer, 0)
    )
    returning id into board_id;

    for card_data in
      select value
      from jsonb_array_elements(coalesce(board_data -> 'cards', '[]'::jsonb))
    loop
      insert into public.cartao (
        perfil_id,
        categoria_id,
        texto,
        caminho_imagem,
        imagem_storage_path,
        caminho_audio,
        icone,
        cor_hex,
        arasaac_id,
        is_favorito,
        frequencia_uso
      )
      values (
        novo_perfil_id,
        null,
        card_data ->> 'label',
        card_data ->> 'imagePath',
        null,
        card_data ->> 'audioPath',
        coalesce(card_data ->> 'icon', 'image_outlined'),
        coalesce(card_data ->> 'color', '#ff00896b'),
        card_data ->> 'arasaacId',
        false,
        0
      )
      returning id into card_id;

      insert into public.prancha_cartao (prancha_id, cartao_id, ordem)
      values (
        board_id,
        card_id,
        coalesce((card_data ->> 'order')::integer, 0)
      );
    end loop;
  end loop;
end;
$$;

revoke all on function public.inicializar_conteudo_padrao(uuid, jsonb)
  from public, anon;
grant execute on function public.inicializar_conteudo_padrao(uuid, jsonb)
  to authenticated;

create table if not exists public.perfil_catalogo_versao (
  perfil_id uuid primary key references public.perfil(id) on delete cascade,
  versao text not null,
  atualizado_em timestamptz not null default now()
);

alter table public.perfil_catalogo_versao enable row level security;
revoke all on public.perfil_catalogo_versao from public, anon, authenticated;

create or replace function public.sincronizar_catalogo_arasaac(
  novo_perfil_id uuid,
  versao text,
  dados jsonb
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  board_data jsonb;
  card_data jsonb;
  board_id uuid;
  card_id uuid;
  installed_version text;
begin
  if auth.uid() is null or not exists (
    select 1
    from public.perfil p
    where p.id = novo_perfil_id
      and p.usuario_id = auth.uid()
  ) then
    raise exception 'Perfil não autorizado' using errcode = '42501';
  end if;

  if versao is null or versao = ''
    or jsonb_typeof(dados -> 'boards') <> 'array' then
    raise exception 'Catálogo ARASAAC inválido' using errcode = '22023';
  end if;

  select v.versao
  into installed_version
  from public.perfil_catalogo_versao v
  where v.perfil_id = novo_perfil_id;

  if installed_version = versao then
    return;
  end if;

  delete from public.prancha_cartao pc
  using public.prancha p, public.cartao c
  where pc.prancha_id = p.id
    and pc.cartao_id = c.id
    and p.perfil_id = novo_perfil_id
    and p.chave = any(array[
      'Principal', 'Comida', 'Sentimentos', 'Atividades',
      'Pessoas', 'Lugares', 'Necessidades', 'Objetos'
    ])
    and c.perfil_id = novo_perfil_id
    and c.arasaac_id = any(array[
      '5441', '4609', '8142', '19524', '2248', '4653', '2458',
      '31146', '32446', '8163', '6479', '5921', '6911', '8337',
      '4952', '4732', '2462', '35533', '35545', '35537', '2367',
      '2374', '23392', '6495', '8088', '11311', '29123', '25790',
      '2456', '2467', '2392', '6964', '2859', '37408', '35695',
      '5584', '5526', '3220', '16091', '2586', '25191', '9813',
      '3241', '7233'
    ])
    and c.imagem_storage_path is null
    and c.caminho_imagem = 'assets/arasaac/' || c.arasaac_id || '.png';

  delete from public.cartao c
  where c.perfil_id = novo_perfil_id
    and c.imagem_storage_path is null
    and c.caminho_imagem = 'assets/arasaac/' || c.arasaac_id || '.png'
    and not exists (
      select 1
      from public.prancha_cartao pc
      where pc.cartao_id = c.id
    );

  for board_data in
    select value from jsonb_array_elements(dados -> 'boards')
  loop
    board_id := null;
    select p.id
    into board_id
    from public.prancha p
    where p.perfil_id = novo_perfil_id
      and p.chave = board_data ->> 'key'
    limit 1;

    if board_id is null then
      insert into public.prancha (
        perfil_id, chave, nome, icone, imagem_url,
        imagem_storage_path, caminho_audio, ordem
      )
      values (
        novo_perfil_id,
        board_data ->> 'key',
        board_data ->> 'label',
        coalesce(board_data ->> 'icon', 'dashboard_customize'),
        board_data ->> 'imagePath',
        null,
        board_data ->> 'audioPath',
        coalesce((board_data ->> 'order')::integer, 0)
      )
      returning id into board_id;
    end if;

    for card_data in
      select value
      from jsonb_array_elements(coalesce(board_data -> 'cards', '[]'::jsonb))
    loop
      if coalesce(card_data ->> 'arasaacId', '') = '' then
        raise exception 'Cartão sem identificador ARASAAC'
          using errcode = '22023';
      end if;

      card_id := null;
      select c.id
      into card_id
      from public.cartao c
      where c.perfil_id = novo_perfil_id
        and c.arasaac_id = card_data ->> 'arasaacId'
      limit 1;

      if card_id is null then
        insert into public.cartao (
          perfil_id, categoria_id, texto, caminho_imagem,
          imagem_storage_path, caminho_audio, icone, cor_hex,
          arasaac_id, is_favorito, frequencia_uso
        )
        values (
          novo_perfil_id,
          null,
          card_data ->> 'label',
          card_data ->> 'imagePath',
          null,
          card_data ->> 'audioPath',
          coalesce(card_data ->> 'icon', 'image_outlined'),
          coalesce(card_data ->> 'color', '#ff00896b'),
          card_data ->> 'arasaacId',
          false,
          0
        )
        returning id into card_id;
      else
        update public.cartao
        set texto = card_data ->> 'label',
            caminho_imagem = card_data ->> 'imagePath',
            caminho_audio = card_data ->> 'audioPath',
            icone = coalesce(card_data ->> 'icon', 'image_outlined'),
            cor_hex = coalesce(card_data ->> 'color', '#ff00896b')
        where id = card_id
          and imagem_storage_path is null
          and caminho_imagem like 'assets/arasaac/%';
      end if;

      if not exists (
        select 1
        from public.prancha_cartao pc
        where pc.prancha_id = board_id
          and pc.cartao_id = card_id
      ) then
        insert into public.prancha_cartao (prancha_id, cartao_id, ordem)
        values (
          board_id,
          card_id,
          coalesce((card_data ->> 'order')::integer, 0)
        );
      end if;
    end loop;
  end loop;

  insert into public.perfil_catalogo_versao (perfil_id, versao)
  values (novo_perfil_id, versao)
  on conflict (perfil_id) do update
  set versao = excluded.versao,
      atualizado_em = now();
end;
$$;

revoke all on function public.sincronizar_catalogo_arasaac(uuid, text, jsonb)
  from public, anon;
grant execute on function public.sincronizar_catalogo_arasaac(uuid, text, jsonb)
  to authenticated;

create or replace function public.catalogo_arasaac_completo_necessita_sync(
  p_perfil_id uuid,
  p_versao text
)
returns boolean
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
  ) then
    raise exception 'Perfil não autorizado' using errcode = '42501';
  end if;

  return not exists (
    select 1
    from public.perfil_catalogo_versao v
    where v.perfil_id = p_perfil_id
      and v.versao = p_versao
  );
end;
$$;

revoke all on function public.catalogo_arasaac_completo_necessita_sync(uuid, text)
  from public, anon;
grant execute on function public.catalogo_arasaac_completo_necessita_sync(uuid, text)
  to authenticated;

create or replace function public.sincronizar_catalogo_arasaac_completo(
  p_perfil_id uuid,
  p_versao text,
  p_dados jsonb
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  category_data jsonb;
  pictogram_data jsonb;
  board_id uuid;
  card_id uuid;
  pictogram_id text;
  board_key text;
  parent_key text;
  item_order integer;
begin
  if auth.uid() is null or not exists (
    select 1
    from public.perfil p
    where p.id = p_perfil_id
      and p.usuario_id = auth.uid()
  ) then
    raise exception 'Perfil não autorizado' using errcode = '42501';
  end if;

  if p_versao is null or p_versao = ''
    or jsonb_typeof(p_dados -> 'categories') <> 'array'
    or jsonb_typeof(p_dados -> 'pictograms') <> 'array'
    or jsonb_typeof(p_dados -> 'principalIds') <> 'array' then
    raise exception 'Catálogo ARASAAC inválido' using errcode = '22023';
  end if;

  if not exists (
    select 1
    from public.perfil_catalogo_versao v
    where v.perfil_id = p_perfil_id
      and v.versao = p_versao
  ) then
    delete from public.prancha_cartao pc
    using public.prancha p, public.cartao c
    where pc.prancha_id = p.id
      and pc.cartao_id = c.id
      and p.perfil_id = p_perfil_id
      and p.catalogo_arasaac
      and c.perfil_id = p_perfil_id
      and (
        c.caminho_imagem like 'arasaac-catalog/%'
        or c.caminho_imagem like 'assets/arasaac/%'
      );

    delete from public.prancha p
    where p.perfil_id = p_perfil_id
      and p.catalogo_arasaac
      and p.chave <> 'Principal'
      and not exists (
        select 1 from public.prancha_cartao pc where pc.prancha_id = p.id
      );

    delete from public.cartao c
    where c.perfil_id = p_perfil_id
      and c.imagem_storage_path is null
      and (
        c.caminho_imagem like 'arasaac-catalog/%'
        or c.caminho_imagem like 'assets/arasaac/%'
      )
      and not exists (
        select 1 from public.prancha_cartao pc where pc.cartao_id = c.id
      );

    select p.id
    into board_id
    from public.prancha p
    where p.perfil_id = p_perfil_id
      and p.chave = 'Principal'
    limit 1;

    if board_id is null then
      insert into public.prancha (
        perfil_id, chave, nome, icone, imagem_url, caminho_audio, ordem,
        catalogo_arasaac, catalogo_pai_chave
      )
      values (
        p_perfil_id, 'Principal', 'Início', 'home', null, null, 0, true, null
      )
      returning id into board_id;
    else
      update public.prancha
      set catalogo_arasaac = true,
          catalogo_pai_chave = null
      where id = board_id;
    end if;

    for pictogram_data in
      select value from jsonb_array_elements(p_dados -> 'pictograms')
    loop
      pictogram_id := pictogram_data ->> 'id';
      if pictogram_id is null or pictogram_data ->> 'label' is null then
        raise exception 'Pictograma ARASAAC inválido'
          using errcode = '22023';
      end if;

      card_id := null;
      select c.id
      into card_id
      from public.cartao c
      where c.perfil_id = p_perfil_id
        and c.arasaac_id = pictogram_id
        and c.imagem_storage_path is null
        and (
          c.caminho_imagem like 'assets/arasaac/%'
          or c.caminho_imagem like 'arasaac-catalog/%'
        )
      limit 1;

      if card_id is null then
        insert into public.cartao (
          perfil_id, categoria_id, texto, caminho_imagem, imagem_storage_path,
          caminho_audio, icone, cor_hex, arasaac_id, is_favorito, frequencia_uso
        )
        values (
          p_perfil_id, null, pictogram_data ->> 'label',
          'arasaac-catalog/' || pictogram_id || '.png', null, null,
          'image_outlined', '#ff00896b', pictogram_id, false, 0
        )
        returning id into card_id;
      else
        update public.cartao
        set texto = pictogram_data ->> 'label',
            caminho_imagem = 'arasaac-catalog/' || pictogram_id || '.png',
            caminho_audio = null,
            icone = 'image_outlined'
        where id = card_id;
      end if;
    end loop;

    for category_data in
      select value from jsonb_array_elements(p_dados -> 'categories')
    loop
      board_key := category_data ->> 'key';
      parent_key := category_data ->> 'parentKey';
      item_order := coalesce((category_data ->> 'order')::integer, 0);
      if board_key is null or category_data ->> 'label' is null then
        raise exception 'Categoria ARASAAC inválida'
          using errcode = '22023';
      end if;

      board_id := null;
      select p.id
      into board_id
      from public.prancha p
      where p.perfil_id = p_perfil_id
        and p.chave = board_key
      limit 1;

      if board_id is null then
        insert into public.prancha (
          perfil_id, chave, nome, icone, imagem_url, caminho_audio, ordem,
          catalogo_arasaac, catalogo_pai_chave
        )
        values (
          p_perfil_id, board_key, category_data ->> 'label', 'folder',
          null, null, item_order, true, parent_key
        )
        returning id into board_id;
      else
        update public.prancha
        set nome = category_data ->> 'label',
            icone = 'folder',
            ordem = item_order,
            catalogo_arasaac = true,
            catalogo_pai_chave = parent_key
        where id = board_id;
      end if;

      for pictogram_id, item_order in
        select value, ordinal::integer - 1
        from jsonb_array_elements_text(
          coalesce(category_data -> 'pictogramIds', '[]'::jsonb)
        ) with ordinality as pictograms(value, ordinal)
      loop
        select c.id
        into card_id
        from public.cartao c
        where c.perfil_id = p_perfil_id
          and c.arasaac_id = pictogram_id
          and c.imagem_storage_path is null
          and c.caminho_imagem =
            'arasaac-catalog/' || pictogram_id || '.png'
        limit 1;

        if card_id is null then
          raise exception 'Cartão do catálogo não encontrado: %', pictogram_id
            using errcode = '22023';
        end if;

        insert into public.prancha_cartao (prancha_id, cartao_id, ordem)
        values (board_id, card_id, item_order)
        on conflict (prancha_id, cartao_id) do update
        set ordem = excluded.ordem;
      end loop;
    end loop;

    for pictogram_id, item_order in
      select value, ordinal::integer - 1
      from jsonb_array_elements_text(p_dados -> 'principalIds')
        with ordinality as principal(value, ordinal)
    loop
      select c.id
      into card_id
      from public.cartao c
      where c.perfil_id = p_perfil_id
        and c.arasaac_id = pictogram_id
        and c.imagem_storage_path is null
        and c.caminho_imagem =
          'arasaac-catalog/' || pictogram_id || '.png'
      limit 1;

      if card_id is null then
        raise exception 'Pictograma da prancha Principal não encontrado: %',
          pictogram_id using errcode = '22023';
      end if;

      insert into public.prancha_cartao (prancha_id, cartao_id, ordem)
      values (board_id, card_id, item_order)
      on conflict (prancha_id, cartao_id) do update
      set ordem = excluded.ordem;
    end loop;

    insert into public.perfil_catalogo_versao (perfil_id, versao)
    values (p_perfil_id, p_versao)
    on conflict (perfil_id) do update
    set versao = excluded.versao,
        atualizado_em = now();
  end if;
end;
$$;

revoke all on function public.sincronizar_catalogo_arasaac_completo(uuid, text, jsonb)
  from public, anon;
grant execute on function public.sincronizar_catalogo_arasaac_completo(uuid, text, jsonb)
  to authenticated;

create or replace function public.catalogo_arasaac_completo_necessita_sync(
  p_perfil_id uuid,
  p_versao text
)
returns boolean
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
  ) then
    raise exception 'Perfil não autorizado' using errcode = '42501';
  end if;

  return not exists (
    select 1
    from public.perfil_catalogo_versao v
    where v.perfil_id = p_perfil_id
      and v.versao = p_versao
  );
end;
$$;

revoke all on function public.catalogo_arasaac_completo_necessita_sync(uuid, text)
  from public, anon;
grant execute on function public.catalogo_arasaac_completo_necessita_sync(uuid, text)
  to authenticated;

create or replace function public.sincronizar_catalogo_arasaac_completo(
  p_perfil_id uuid,
  p_versao text,
  p_dados jsonb
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  category_data jsonb;
  pictogram_data jsonb;
  board_id uuid;
  card_id uuid;
  pictogram_id text;
  board_key text;
  parent_key text;
  item_order integer;
begin
  if auth.uid() is null or not exists (
    select 1
    from public.perfil p
    where p.id = p_perfil_id
      and p.usuario_id = auth.uid()
  ) then
    raise exception 'Perfil não autorizado' using errcode = '42501';
  end if;

  if p_versao is null or p_versao = ''
    or jsonb_typeof(p_dados -> 'categories') <> 'array'
    or jsonb_typeof(p_dados -> 'pictograms') <> 'array'
    or jsonb_typeof(p_dados -> 'principalIds') <> 'array' then
    raise exception 'Catálogo ARASAAC inválido' using errcode = '22023';
  end if;

  if not exists (
    select 1
    from public.perfil_catalogo_versao v
    where v.perfil_id = p_perfil_id
      and v.versao = p_versao
  ) then
    delete from public.prancha_cartao pc
    using public.prancha p, public.cartao c
    where pc.prancha_id = p.id
      and pc.cartao_id = c.id
      and p.perfil_id = p_perfil_id
      and c.perfil_id = p_perfil_id
      and (
        (p.catalogo_arasaac and (
          c.caminho_imagem like 'arasaac-catalog/%'
          or c.caminho_imagem like 'assets/arasaac/%'
        ))
        or (
          p.chave = any(array[
            'Principal', 'Comida', 'Sentimentos', 'Atividades',
            'Pessoas', 'Lugares', 'Necessidades', 'Objetos'
          ])
          and c.arasaac_id = any(array[
            '5441', '4609', '8142', '19524', '2248', '4653', '2458',
            '31146', '32446', '8163', '6479', '5921', '6911', '8337',
            '4952', '4732', '2462', '35533', '35545', '35537', '2367',
            '2374', '23392', '6495', '8088', '11311', '29123', '25790',
            '2456', '2467', '2392', '6964', '2859', '37408', '35695',
            '5584', '5526', '3220', '16091', '2586', '25191', '9813',
            '3241', '7233'
          ])
          and c.imagem_storage_path is null
          and c.caminho_imagem = 'assets/arasaac/' || c.arasaac_id || '.png'
        )
      );

    delete from public.prancha p
    where p.perfil_id = p_perfil_id
      and p.catalogo_arasaac
      and p.chave <> 'Principal'
      and not exists (
        select 1 from public.prancha_cartao pc where pc.prancha_id = p.id
      );

    delete from public.cartao c
    where c.perfil_id = p_perfil_id
      and c.imagem_storage_path is null
      and (
        c.caminho_imagem like 'arasaac-catalog/%'
        or (
          c.arasaac_id = any(array[
            '5441', '4609', '8142', '19524', '2248', '4653', '2458',
            '31146', '32446', '8163', '6479', '5921', '6911', '8337',
            '4952', '4732', '2462', '35533', '35545', '35537', '2367',
            '2374', '23392', '6495', '8088', '11311', '29123', '25790',
            '2456', '2467', '2392', '6964', '2859', '37408', '35695',
            '5584', '5526', '3220', '16091', '2586', '25191', '9813',
            '3241', '7233'
          ])
          and c.caminho_imagem =
            'assets/arasaac/' || c.arasaac_id || '.png'
        )
      )
      and not exists (
        select 1 from public.prancha_cartao pc where pc.cartao_id = c.id
      );

    select p.id
    into board_id
    from public.prancha p
    where p.perfil_id = p_perfil_id
      and p.chave = 'Principal'
    limit 1;

    if board_id is null then
      insert into public.prancha (
        perfil_id, chave, nome, icone, imagem_url, caminho_audio, ordem,
        catalogo_arasaac, catalogo_pai_chave
      )
      values (
        p_perfil_id, 'Principal', 'Início', 'home', null, null, 0, true, null
      )
      returning id into board_id;
    else
      update public.prancha
      set catalogo_arasaac = true,
          catalogo_pai_chave = null
      where id = board_id;
    end if;

    for pictogram_data in
      select value from jsonb_array_elements(p_dados -> 'pictograms')
    loop
      pictogram_id := pictogram_data ->> 'id';
      if pictogram_id is null or pictogram_data ->> 'label' is null then
        raise exception 'Pictograma ARASAAC inválido'
          using errcode = '22023';
      end if;

      card_id := null;
      select c.id
      into card_id
      from public.cartao c
      where c.perfil_id = p_perfil_id
        and c.arasaac_id = pictogram_id
        and c.imagem_storage_path is null
        and (
          c.caminho_imagem like 'assets/arasaac/%'
          or c.caminho_imagem like 'arasaac-catalog/%'
        )
      limit 1;

      if card_id is null then
        insert into public.cartao (
          perfil_id, categoria_id, texto, caminho_imagem, imagem_storage_path,
          caminho_audio, icone, cor_hex, arasaac_id, is_favorito, frequencia_uso
        )
        values (
          p_perfil_id, null, pictogram_data ->> 'label',
          'arasaac-catalog/' || pictogram_id || '.png', null, null,
          'image_outlined', '#ff00896b', pictogram_id, false, 0
        )
        returning id into card_id;
      else
        update public.cartao
        set texto = pictogram_data ->> 'label',
            caminho_imagem = 'arasaac-catalog/' || pictogram_id || '.png',
            caminho_audio = null,
            icone = 'image_outlined'
        where id = card_id;
      end if;
    end loop;

    for category_data in
      select value from jsonb_array_elements(p_dados -> 'categories')
    loop
      board_key := category_data ->> 'key';
      parent_key := category_data ->> 'parentKey';
      item_order := coalesce((category_data ->> 'order')::integer, 0);
      if board_key is null or category_data ->> 'label' is null then
        raise exception 'Categoria ARASAAC inválida'
          using errcode = '22023';
      end if;

      board_id := null;
      select p.id
      into board_id
      from public.prancha p
      where p.perfil_id = p_perfil_id
        and p.chave = board_key
      limit 1;

      if board_id is null then
        insert into public.prancha (
          perfil_id, chave, nome, icone, imagem_url, caminho_audio, ordem,
          catalogo_arasaac, catalogo_pai_chave
        )
        values (
          p_perfil_id, board_key, category_data ->> 'label', 'folder',
          null, null, item_order, true, parent_key
        )
        returning id into board_id;
      else
        update public.prancha
        set nome = category_data ->> 'label',
            icone = 'folder',
            ordem = item_order,
            catalogo_arasaac = true,
            catalogo_pai_chave = parent_key
        where id = board_id;
      end if;

      for pictogram_id, item_order in
        select value, ordinal::integer - 1
        from jsonb_array_elements_text(
          coalesce(category_data -> 'pictogramIds', '[]'::jsonb)
        ) with ordinality as category_pictograms(value, ordinal)
      loop
        select c.id
        into card_id
        from public.cartao c
        where c.perfil_id = p_perfil_id
          and c.arasaac_id = pictogram_id
          and c.imagem_storage_path is null
          and c.caminho_imagem =
            'arasaac-catalog/' || pictogram_id || '.png'
        limit 1;

        if card_id is null then
          raise exception 'Cartão do catálogo não encontrado: %', pictogram_id
            using errcode = '22023';
        end if;

        insert into public.prancha_cartao (prancha_id, cartao_id, ordem)
        select board_id, card_id, item_order
        where not exists (
          select 1
          from public.prancha_cartao pc
          where pc.prancha_id = board_id
            and pc.cartao_id = card_id
        );
      end loop;
    end loop;

    select p.id
    into board_id
    from public.prancha p
    where p.perfil_id = p_perfil_id
      and p.chave = 'Principal'
    limit 1;

    for pictogram_id, item_order in
      select value, ordinal::integer - 1
      from jsonb_array_elements_text(p_dados -> 'principalIds')
        with ordinality as principal(value, ordinal)
    loop
      select c.id
      into card_id
      from public.cartao c
      where c.perfil_id = p_perfil_id
        and c.arasaac_id = pictogram_id
        and c.imagem_storage_path is null
        and c.caminho_imagem =
          'arasaac-catalog/' || pictogram_id || '.png'
      limit 1;

      if card_id is null then
        raise exception 'Pictograma da prancha Principal não encontrado: %',
          pictogram_id using errcode = '22023';
      end if;

      insert into public.prancha_cartao (prancha_id, cartao_id, ordem)
      select board_id, card_id, item_order
      where not exists (
        select 1
        from public.prancha_cartao pc
        where pc.prancha_id = board_id
          and pc.cartao_id = card_id
      );
    end loop;

    insert into public.perfil_catalogo_versao (perfil_id, versao)
    values (p_perfil_id, p_versao)
    on conflict (perfil_id) do update
    set versao = excluded.versao,
        atualizado_em = now();
  end if;
end;
$$;

revoke all on function public.sincronizar_catalogo_arasaac_completo(uuid, text, jsonb)
  from public, anon;
grant execute on function public.sincronizar_catalogo_arasaac_completo(uuid, text, jsonb)
  to authenticated;

insert into storage.buckets (id, name, public)
values ('arasaac-catalog', 'arasaac-catalog', true)
on conflict (id) do update set public = true;

insert into storage.buckets (
  id, name, public, file_size_limit, allowed_mime_types
)
values (
  'content-images',
  'content-images',
  false,
  5242880,
  array['image/jpeg', 'image/png', 'image/webp', 'image/gif']
)
on conflict (id) do update
set public = false,
    file_size_limit = excluded.file_size_limit,
    allowed_mime_types = excluded.allowed_mime_types;

drop policy if exists "Voxa profile owners read content images"
  on storage.objects;
create policy "Voxa profile owners read content images"
  on storage.objects for select to authenticated
  using (
    bucket_id = 'content-images'
    and exists (
      select 1 from public.perfil p
      where p.id::text = (storage.foldername(name))[1]
        and p.usuario_id = (select auth.uid())
    )
  );

drop policy if exists "Voxa profile owners upload content images"
  on storage.objects;
create policy "Voxa profile owners upload content images"
  on storage.objects for insert to authenticated
  with check (
    bucket_id = 'content-images'
    and exists (
      select 1 from public.perfil p
      where p.id::text = (storage.foldername(name))[1]
        and p.usuario_id = (select auth.uid())
    )
  );

drop policy if exists "Voxa profile owners update content images"
  on storage.objects;
create policy "Voxa profile owners update content images"
  on storage.objects for update to authenticated
  using (
    bucket_id = 'content-images'
    and exists (
      select 1 from public.perfil p
      where p.id::text = (storage.foldername(name))[1]
        and p.usuario_id = (select auth.uid())
    )
  )
  with check (
    bucket_id = 'content-images'
    and exists (
      select 1 from public.perfil p
      where p.id::text = (storage.foldername(name))[1]
        and p.usuario_id = (select auth.uid())
    )
  );

drop policy if exists "Voxa profile owners delete content images"
  on storage.objects;
create policy "Voxa profile owners delete content images"
  on storage.objects for delete to authenticated
  using (
    bucket_id = 'content-images'
    and exists (
      select 1 from public.perfil p
      where p.id::text = (storage.foldername(name))[1]
        and p.usuario_id = (select auth.uid())
    )
  );
