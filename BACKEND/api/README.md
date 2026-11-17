# Voxa API

API REST e servidor WebSocket/STOMP do Voxa.

- Java 17
- Spring Boot 3.3.5
- Spring Data JPA
- Spring Security OAuth2 Resource Server
- H2 em desenvolvimento e PostgreSQL/Supabase em produção
- SpringDoc OpenAPI

## Estrutura

```text
BACKEND/api/
├── docs/                              # Coleção Postman
├── src/main/java/br/edu/ifsp/voxa/
│   ├── config/                        # Segurança e CORS
│   ├── controller/                    # Endpoints REST
│   ├── dto/                           # Objetos de entrada e saída
│   ├── model/                         # Entidades JPA
│   ├── repository/                    # Repositórios Spring Data
│   ├── service/                       # Regras de negócio
│   ├── sms/                           # Gateways de SMS
│   └── websocket/                     # STOMP e mensagens de alerta
└── src/main/resources/
    ├── application.yml                # Perfis e configuração
    ├── data.sql                       # Dados iniciais do perfil dev
    └── static/index.html              # Painel do cuidador
```

## Pré-requisitos

- JDK 17
- Maven
- PostgreSQL/Supabase, apenas ao usar o perfil `supabase`

Verifique as instalações:

```bash
java -version
mvn -version
```

## Executar localmente

Acesse a pasta da API:

```bash
cd BACKEND/api
```

O perfil `dev` é usado por padrão. Ele cria um banco H2 em memória e carrega dados de exemplo.

```bash
mvn spring-boot:run
```

URLs disponíveis:

| Recurso | URL |
|---|---|
| API | http://localhost:8080 |
| Swagger UI | http://localhost:8080/swagger-ui.html |
| Painel WebSocket do cuidador | http://localhost:8080/ |
| Console H2 | http://localhost:8080/h2-console |
| WebSocket SockJS/WebSocket | ws://localhost:8080/ws |

Dados do console H2:

- JDBC: `jdbc:h2:mem:voxa`
- Usuário: `sa`
- Senha: vazia

## Perfis

| Perfil | Banco | Inicialização JPA | Dados iniciais |
|---|---|---|---|
| `dev` | H2 em memória | `create-drop` | `data.sql` |
| `supabase` | PostgreSQL/Supabase | `none` | nenhuma |

O perfil pode ser informado pela variável `SPRING_PROFILES_ACTIVE`.

## Configurar o Supabase

No Supabase, execute os scripts SQL em `BACKEND/database/`, nesta ordem:

1. `supabase_content.sql`
2. `voxa_migracao_v2.sql`
3. `fix_auth_user_trigger.sql`

No PowerShell:

```powershell
$env:SPRING_PROFILES_ACTIVE = "supabase"
$env:SUPABASE_URL = "https://SEU-PROJETO.supabase.co"
$env:SUPABASE_ANON_KEY = "chave-publica-anon-ou-publishable"
$env:SUPABASE_DB_URL = "jdbc:postgresql://db.SEU-PROJETO.supabase.co:5432/postgres"
$env:SUPABASE_DB_USER = "postgres"
$env:SUPABASE_DB_PASSWORD = "sua-senha-do-banco"

# Necessário apenas para projetos Supabase que emitam tokens HS256:
$env:SUPABASE_JWT_SECRET = "seu-segredo-jwt"

mvn spring-boot:run
```

No Bash/Git Bash:

```bash
export SPRING_PROFILES_ACTIVE=supabase
export SUPABASE_URL="https://SEU-PROJETO.supabase.co"
export SUPABASE_ANON_KEY="chave-publica-anon-ou-publishable"
export SUPABASE_DB_URL="jdbc:postgresql://db.SEU-PROJETO.supabase.co:5432/postgres"
export SUPABASE_DB_USER=postgres
export SUPABASE_DB_PASSWORD="sua-senha-do-banco"
# export SUPABASE_JWT_SECRET="seu-segredo-jwt"
mvn spring-boot:run
```

O backend aceita a chave pública/Publishable para consultar o JWKS. Nunca exponha uma chave `service_role` ou o segredo JWT em clientes Flutter ou JavaScript.

## Autenticação

Os recursos REST abaixo exigem um access token Supabase no header:

```http
Authorization: Bearer <access-token>
```

- `/api/v1/pranchas/**`
- `/api/v1/cartoes/**`
- `/api/v1/usuarios/**`
- `/api/v1/perfis/**`

Os demais endpoints, incluindo `/api/v1/alertas/**`, são públicos pela configuração atual.

Quando `SUPABASE_URL` é configurada e não há segredo HS256, a API obtém as chaves públicas do JWKS do projeto. Tokens precisam usar o emissor:

```text
https://SEU-PROJETO.supabase.co/auth/v1
```

O cadastro de usuário usa o `subject` do JWT como ID e os recursos são isolados pelo usuário responsável associado ao token.

## Endpoints REST

| Recurso | Operações principais |
|---|---|
| Usuários | `POST /api/v1/usuarios`, `GET /api/v1/usuarios`, `GET /api/v1/usuarios/{id}`, `PUT /api/v1/usuarios/{id}`, `DELETE /api/v1/usuarios/{id}`, `GET /api/v1/usuarios/{id}/perfis` |
| Perfis | `POST /api/v1/perfis`, `GET /api/v1/perfis`, `GET /api/v1/perfis/{id}`, `PUT /api/v1/perfis/{id}`, `DELETE /api/v1/perfis/{id}` |
| Pranchas | `POST /api/v1/pranchas`, `GET /api/v1/pranchas`, `GET /api/v1/pranchas/{id}`, `PUT /api/v1/pranchas/{id}`, `DELETE /api/v1/pranchas/{id}` |
| Cartões | `POST /api/v1/cartoes`, `GET /api/v1/cartoes`, `GET /api/v1/cartoes/{id}`, `PUT /api/v1/cartoes/{id}`, `DELETE /api/v1/cartoes/{id}` |
| Associação prancha/cartão | `GET /api/v1/pranchas/{id}/cartoes`, `PUT /api/v1/pranchas/{id}/cartoes/{cartaoId}`, `DELETE /api/v1/pranchas/{id}/cartoes/{cartaoId}`, `GET /api/v1/cartoes/{id}/pranchas` |
| Alertas | `GET /api/v1/alertas?perfilId={perfilId}`, `GET /api/v1/alertas/{id}` |

O catálogo completo de requisições e respostas está no Swagger.

## WebSocket/STOMP

O servidor usa o broker simples em `/topic` e `/queue`.

- Conexão: `/ws`
- Destinos enviados pelo cliente: `/app/**`
- Inscrições públicas: `/topic/**`
- Erros privados: `/user/queue/erros`
- Evento de emergência: enviar para `/app/alerta`
- Receber alertas: inscrever-se em `/topic/alertas/{perfilId}`

Exemplo de payload enviado pelo STOMP:

```json
{
  "clienteId": "uuid-opcional",
  "usuarioId": "11111111-1111-4111-8111-111111111111",
  "perfilId": "22222222-2222-4222-8222-222222222222",
  "perfilNome": "Leo",
  "mensagem": "Preciso de ajuda",
  "enviadoEm": "2026-11-17T20:30:01.870-03:00"
}
```

Os campos `usuarioId` e `perfilId` são obrigatórios. Erros de validação ou negócio são enviados ao remetente em `/user/queue/erros`.

## SMS do botão de emergência

Por padrão, o gateway é `log`: nenhuma mensagem é enviada externamente e o alerta aparece no console como `[SMS SIMULADO]`.

Para enviar SMS pela Twilio:

```bash
VOXA_SMS_PROVIDER=twilio \
TWILIO_ACCOUNT_SID="..." \
TWILIO_AUTH_TOKEN="..." \
TWILIO_FROM_NUMBER="+1..." \
mvn spring-boot:run
```

No PowerShell:

```powershell
$env:VOXA_SMS_PROVIDER = "twilio"
$env:TWILIO_ACCOUNT_SID = "..."
$env:TWILIO_AUTH_TOKEN = "..."
$env:TWILIO_FROM_NUMBER = "+1..."
mvn spring-boot:run
```

Em contas de teste da Twilio, o destinatário precisa estar verificado.

## Configurações adicionais

| Variável | Padrão | Uso |
|---|---|---|
| `PORT` | `8080` | Porta HTTP |
| `SPRING_PROFILES_ACTIVE` | `dev` | Perfil `dev` ou `supabase` |
| `SUPABASE_URL` | vazio | URL do projeto e emissor JWT |
| `SUPABASE_ANON_KEY` | vazio | Chave pública usada para consultar o JWKS |
| `SUPABASE_JWT_SECRET` | vazio | Segredo para tokens HS256 |
| `SUPABASE_DB_URL` | obrigatório no perfil supabase | JDBC PostgreSQL |
| `SUPABASE_DB_USER` | `postgres` | Usuário do banco |
| `SUPABASE_DB_PASSWORD` | obrigatório no perfil supabase | Senha do banco |
| `VOXA_SMS_PROVIDER` | `log` | `log` ou `twilio` |
| `VOXA_CORS_ORIGINS` | `*` | Origens permitidas, separadas por vírgula |

## App Flutter

No `.env` do app, configure:

```env
BACKEND_API_URL=http://10.0.2.2:8080/api/v1
BACKEND_WS_URL=ws://10.0.2.2:8080
```

- Emulador Android: use `10.0.2.2`.
- Celular físico: use o IP da máquina na rede local.
- Web/navegador: use `http://localhost:8080/api/v1` e `ws://localhost:8080/ws`.
- Não use a chave `service_role` nem o segredo JWT no aplicativo Flutter.

## Build e testes

Executar testes:

```bash
mvn test
```

Gerar o artefato:

```bash
mvn clean package
java -jar target/voxa-api-1.0.0.jar
```

Os testes de integração cobrem autenticação, isolamento por responsável, CRUD, relações entre entidades e validações.

## Testes funcionais no Postman

1. Inicie a API com o perfil `dev`.
2. Importe `docs/voxa-api.postman_collection.json`.
3. Confirme que a variável `base` usa `http://localhost:8080/api/v1`.
4. Configure um access token válido no ambiente da coleção quando executadas as rotas protegidas.
5. Execute a coleção com **Run collection**.

Os IDs fixos usados pelo H2 estão em `src/main/resources/data.sql`.

## Modelo de dados

| Entidade | Tabela | Relacionamentos |
|---|---|---|
| Usuario | `usuario` | 1:N Perfil |
| Perfil | `perfil` | N:1 Usuario; 1:N Prancha; 1:N Cartao |
| Prancha | `prancha` | N:N Cartao via `PranchaCartao`, com `ordem` |
| Cartao | `cartao` | N:N Prancha |
| PranchaCartao | `prancha_cartao` | tabela associativa |
| AlertaEmergencia | `alerta_emergencia` | N:1 Usuario; N:1 Perfil |
