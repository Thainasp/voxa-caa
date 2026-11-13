# voxa

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Fotos de perfil

As fotos são enviadas ao bucket público `profile-photos` do Supabase Storage.
Crie esse bucket no projeto Supabase com acesso público de leitura. No SQL
Editor do Supabase, configure as políticas abaixo para que usuários autenticados
possam ler, criar e atualizar arquivos somente na própria pasta:

```sql
create policy "Read own profile photos"
on storage.objects for select to authenticated
using (
  bucket_id = 'profile-photos'
  and (storage.foldername(name))[1] = (select auth.uid()::text)
);

create policy "Upload own profile photos"
on storage.objects for insert to authenticated
with check (
  bucket_id = 'profile-photos'
  and (storage.foldername(name))[1] = (select auth.uid()::text)
);

create policy "Update own profile photos"
on storage.objects for update to authenticated
using (
  bucket_id = 'profile-photos'
  and (storage.foldername(name))[1] = (select auth.uid()::text)
)
with check (
  bucket_id = 'profile-photos'
  and (storage.foldername(name))[1] = (select auth.uid()::text)
);
```

Os dados dos perfis dependentes são armazenados nos metadados do usuário
responsável no Supabase Auth.

## Pranchas, cartões e pictogramas

As operações de criar, consultar, editar e excluir pranchas e cartões são
persistidas no Supabase nas tabelas existentes `prancha`, `cartao` e
`prancha_cartao`, protegidas por políticas RLS por responsável/perfil. A tabela
de associação mantém o relacionamento muitos-para-muitos entre pranchas e
cartões. Execute `BACKEND/database/supabase_content.sql` no SQL Editor do
Supabase para adicionar os campos complementares, as políticas e as funções de
inicialização/sincronização. O conteúdo inicial contém oito pranchas e 150
cartões gerados dos metadados e imagens do catálogo local
`BACKEND/arasaac_dataset/catalogo.json`. Para regenerar os arquivos Flutter
selecionados, execute `node BACKEND/arasaac_dataset/prepare_flutter_catalog.js`
na raiz do projeto. A sincronização inicial migra os cartões padrão antigos
identificados pelo caminho e pelos IDs conhecidos do semeador anterior; não
remove cartões com imagens enviadas pelo usuário ou URLs externas. A tela de
adição não pesquisa no catálogo online do ARASAAC.

Na criação ou edição de cartões e tábuas, é possível usar uma URL de imagem ou
escolher uma imagem do dispositivo/tirar uma foto. Imagens do dispositivo são
enviadas ao bucket privado `content-images`; URLs informadas são mantidas como
endereços externos. Os pictogramas padrões devem manter a atribuição ao
ARASAAC e respeitar a licença CC BY-NC-SA.

Atribuição exibida no app: pictogramas de Sergio Palao para ARASAAC
(arasaac.org), propriedade do Governo de Aragão, sob licença Creative Commons
BY-NC-SA. A cópia da licença está em `assets/arasaac/LICENCA.txt`; o uso é não
comercial e obras derivadas devem usar a mesma licença.
