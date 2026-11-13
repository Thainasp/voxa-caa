# Correções finais – v2 (12/11/2026)

## App (FRONTEND/voxa)
- **Item 1** – Linha entre a barra inferior e o conteúdo: faixa de 2 px cobre a emenda (`home_navigation_bar.dart`).
- **Item 2** – Exclusão de dependente (erro 57014): catálogo deixou de ser copiado por perfil; RPC `excluir_dependente`; limite de 20 s (`profile_api.dart`, `delete_dependent.dart`).
- **Item 3** – SQLite offline: catálogo ARASAAC local, espelho do perfil e fila `sync_outbox`; sincronização só em Wi-Fi (`lib/core/data/**`, `home_content_controller.dart`).
- **Item 4** – Notificações MSG01 (barra de progresso) e MSG02 (`notification_service.dart`, `res/drawable-*`).
- **Item 5** – Botão de emergência global via STOMP com SMS; plano B com SMS nativo (`emergency_button.dart`, `emergency_service.dart`).
- **Item 6** – APK: `applicationId br.edu.ifsp.voxa`, assinatura por `key.properties`, desugaring, `POST_NOTIFICATIONS`, `widget_test.dart` restaurado.
- RF01 voz real (TTS), RF03 cores Fitzgerald, Provider, camada de rede, RN-03 (senha ≥ 8, 18+), regex de e-mail.
- Testes: `offline_sync_test.dart` e teste do catálogo local.

## Back-end (BACKEND/api) – novo
Spring Boot 3: CRUD Usuario/Perfil/Prancha/Cartao, 1:N, N:N (PranchaCartao), WebSocket `/ws` · `/app/alerta` · `/topic/alertas/{perfilId}`, SMS (simulado ou Twilio), painel web, Swagger, coleção Postman e testes MockMvc.

## Banco (BACKEND/database)
`voxa_migracao_v2.sql`: índices, `excluir_dependente`, `alerta_emergencia` e limpeza opcional do catálogo antigo.

## Validar localmente
`flutter pub get && flutter analyze && flutter test && flutter build apk --release` · `mvn test` · coleção Postman.
