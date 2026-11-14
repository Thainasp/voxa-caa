# Voxa API (BRADWBK)

API REST + WebSocket/STOMP do Voxa em Java 17 / Spring Boot 3 / Spring Data JPA.

## Executar

```bash
# Demonstração (H2 em memória já com dados de exemplo).
# Configure SUPABASE_URL e, para tokens HS256, SUPABASE_JWT_SECRET
# antes de iniciar; veja os detalhes abaixo.
mvn spring-boot:run
```

As rotas `/api/v1/pranchas`, `/cartoes`, `/usuarios` e `/perfis` exigem um
access token Supabase válido. Configure `SUPABASE_URL` também no perfil `dev`;
ela identifica o emissor esperado. Para projetos que assinam tokens com HS256,
configure ainda `SUPABASE_JWT_SECRET` no backend. Para tokens assimétricos, a
API obtém as chaves públicas do JWKS do projeto. Nunca configure o segredo JWT
ou a chave `service_role` no app Flutter.

Para usar o PostgreSQL do Supabase, rode antes
`BACKEND/database/supabase_content.sql`,
`BACKEND/database/voxa_migracao_v2.sql` e
`BACKEND/database/fix_auth_user_trigger.sql` no SQL Editor, nesta ordem, e
configure as variáveis no PowerShell:

```powershell
$env:SPRING_PROFILES_ACTIVE = "supabase"
$env:SUPABASE_URL = "https://SEU-PROJETO.supabase.co"
# Necessário apenas quando o projeto usa tokens HS256:
$env:SUPABASE_JWT_SECRET = "seu-segredo-jwt"
$env:SUPABASE_DB_URL = "jdbc:postgresql://db.SEU-PROJETO.supabase.co:5432/postgres"
$env:SUPABASE_DB_USER = "postgres"
$env:SUPABASE_DB_PASSWORD = "sua-senha-do-banco"
mvn spring-boot:run
```

- Para usar H2 com autenticação, mantenha o perfil `dev` e configure
  `SUPABASE_URL` e, se necessário, `SUPABASE_JWT_SECRET`.
- Swagger UI: http://localhost:8080/swagger-ui.html
- Cliente web do WebSocket (painel do cuidador): http://localhost:8080/
- Console H2 (perfil dev): http://localhost:8080/h2-console (JDBC `jdbc:h2:mem:voxa`, usuário `sa`)
- Testes automáticos: `mvn test`
- Testes funcionais (CR9): importe `docs/voxa-api.postman_collection.json` no Postman
  (ou Thunder Client) e use **Run collection**. Guarde as capturas de tela para o PDF.

## SMS do botão de emergência

Por padrão o SMS é **simulado** (aparece no console como `[SMS SIMULADO]`).
Para envio real pela Twilio:

```bash
VOXA_SMS_PROVIDER=twilio TWILIO_ACCOUNT_SID=... TWILIO_AUTH_TOKEN=... TWILIO_FROM_NUMBER=+1... mvn spring-boot:run
```

Na conta de teste da Twilio só é possível enviar para números verificados.

## App Flutter

No `.env` do app, configure `BACKEND_API_URL` para
`http://10.0.2.2:8080/api/v1` no emulador Android ou use o IP do computador na
rede em um celular físico. Configure também `BACKEND_WS_URL` com o mesmo host e
o caminho `/ws`. No navegador, use `http://localhost:8080`.

## Modelo

| Entidade | Tabela | Relacionamentos |
|---|---|---|
| Usuario | usuario | 1:N Perfil |
| Perfil | perfil | N:1 Usuario · 1:N Prancha · 1:N Cartao |
| Prancha | prancha | N:N Cartao (via PranchaCartao, com `ordem`) |
| Cartao | cartao | N:N Prancha |
| PranchaCartao | prancha_cartao | tabela associativa |
| AlertaEmergencia | alerta_emergencia | N:1 Usuario · N:1 Perfil |
