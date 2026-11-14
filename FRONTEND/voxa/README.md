# Voxa

Aplicativo Flutter de Comunicação Aumentativa e Alternativa (CAA).

## Configuração da API e modo offline

O frontend usa Supabase para autenticação e armazenamento de imagens, e a API
Spring (`/api/v1`) para consultar e alterar pranchas/cartões. A API valida o
access token do Supabase e limita operações ao responsável pelo perfil.

Configure no `.env` do Flutter:

```env
SUPABASE_URL=https://<projeto>.supabase.co
SUPABASE_ANON_KEY=<chave-publica>
BACKEND_API_URL=http://10.0.2.2:8080/api/v1
```

O endereço acima serve para o emulador Android. No navegador use
`http://localhost:8080/api/v1`; em aparelho físico, use o endereço LAN do
servidor. Para usar o PostgreSQL do Supabase, inicie o Spring com
`SPRING_PROFILES_ACTIVE=supabase` e configure no backend `SUPABASE_URL`,
`SUPABASE_DB_URL`, `SUPABASE_DB_USER` e `SUPABASE_DB_PASSWORD`. Para projetos
Supabase que usam tokens HS256, configure também `SUPABASE_JWT_SECRET` no
backend; nunca coloque esse segredo no app Flutter. Para tokens com assinatura
assimétrica, o backend valida usando o JWKS publicado pelo Supabase. O perfil
`dev` continua usando H2 local.

### Testar em um aparelho Android físico

1. Conecte o computador e o celular à mesma rede Wi-Fi. No Windows, execute
   `ipconfig` e anote o IPv4 do adaptador Wi-Fi do computador.
2. No arquivo `.env` do Flutter, use esse IP nos endereços do backend, por
   exemplo `http://192.168.1.20:8080/api/v1` e
   `http://192.168.1.20:8080/ws`. Mantenha `SUPABASE_URL` e
   `SUPABASE_ANON_KEY` preenchidos com os valores do seu projeto.
3. Se o Firewall do Windows perguntar, permita o Java/Maven na rede privada ou
   crie uma regra de entrada TCP para a porta `8080`. Não desative o firewall.
4. Ative a depuração USB no celular, conecte-o por cabo e confirme que aparece
   em `flutter devices`. Na pasta `FRONTEND/voxa`, execute
   `flutter run -d ID_DO_DISPOSITIVO`, substituindo o exemplo pelo ID exibido.
5. No celular, entre ou cadastre uma conta, crie/edite uma prancha e um cartão,
   feche e reabra o app e confirme que os dados continuam lá. Para validar o
   offline, desligue Wi-Fi e dados móveis, faça uma alteração e depois volte ao
   Wi-Fi; a fila deve sincronizar quando a conexão voltar.

O manifest de debug permite HTTP para acessar o backend local; essa permissão
não é incluída no manifest principal/release. Para um release, use um backend
com HTTPS. O aparelho precisa alcançar a internet para Supabase Auth/Storage;
confirmação de e-mail pode ser necessária conforme a configuração do projeto.

No mobile, o conteúdo e as alterações pendentes são salvos em SQLite; no
Flutter Web, são persistidos no armazenamento local do navegador. As alterações
são sincronizadas pela API quando houver Wi-Fi. No mobile, imagens escolhidas
offline ficam no dispositivo até serem enviadas ao Supabase Storage.

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

As operações de criar, consultar, editar e excluir pranchas e cartões passam
pela API REST Spring, que persiste os dados no PostgreSQL do Supabase nas
tabelas existentes `prancha`, `cartao` e `prancha_cartao`. A tabela
de associação mantém o relacionamento muitos-para-muitos entre pranchas e
cartões. Execute no SQL Editor do Supabase
`BACKEND/database/supabase_content.sql`,
`BACKEND/database/voxa_migracao_v2.sql` e
`BACKEND/database/fix_auth_user_trigger.sql` para configurar os campos,
políticas, funções e o gatilho de cadastro compatível com o esquema atual. O
conteúdo inicial contém oito pranchas e 150
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
