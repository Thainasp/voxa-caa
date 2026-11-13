# Voxa API (BRADWBK)

API REST + WebSocket/STOMP do Voxa em Java 17 / Spring Boot 3 / Spring Data JPA.

## Executar

```bash
# Demonstração (H2 em memória já com dados de exemplo)
mvn spring-boot:run

# Supabase (mesmo banco do app). Rode antes BACKEND/database/supabase_content.sql
# e BACKEND/database/voxa_migracao_v2.sql no SQL Editor.
SPRING_PROFILES_ACTIVE=supabase \
SUPABASE_DB_URL=jdbc:postgresql://db.SEU-PROJETO.supabase.co:5432/postgres \
SUPABASE_DB_PASSWORD=sua-senha \
mvn spring-boot:run
```

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

No `.env` do app, `BACKEND_WS_URL=http://10.0.2.2:8080/ws` (emulador) ou o IP do
computador na rede (`http://192.168.x.x:8080/ws`) para celular físico.

## Modelo

| Entidade | Tabela | Relacionamentos |
|---|---|---|
| Usuario | usuario | 1:N Perfil |
| Perfil | perfil | N:1 Usuario · 1:N Prancha · 1:N Cartao |
| Prancha | prancha | N:N Cartao (via PranchaCartao, com `ordem`) |
| Cartao | cartao | N:N Prancha |
| PranchaCartao | prancha_cartao | tabela associativa |
| AlertaEmergencia | alerta_emergencia | N:1 Usuario · N:1 Perfil |
