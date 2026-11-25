# 🗣️ Prancha de Comunicação Aumentativa e Alternativa (CAA)

Aplicação mobile interativa e acessível desenvolvida para Comunicação Aumentativa e Alternativa (CAA). O sistema permite que usuários com dificuldades ou ausência de fala verbal componham mensagens por meio de pictogramas organizados em múltiplos níveis, com sintetização de voz em tempo real.

---

## 🎯 Sobre o Projeto

Este projeto está sendo desenvolvido em âmbito acadêmico com foco em **acessibilidade digital**, **arquitetura de informação inclusiva** e **usabilidade**. A aplicação irá organizar o vocabulário através do **Sistema Fitzgerald Modificado**, equilibrando termos essenciais de alta frequência na tela principal e categorias temáticas organizadas em pastas e subpastas de fácil navegação.

> **Projeto Multidisciplinar — 5º Período (2026)**
>
> **Instituição:** Instituto Federal de São Paulo (IFSP) — Câmpus Bragança Paulista
>
> **Curso:** Tecnologia em Análise e Desenvolvimento de Sistemas (ADS)
>
> **Disciplinas integradas:** Projeto de Tecnologia da Informação e Comunicação (`BRAOTI1`), Desenvolvimento para Dispositivos Móveis (`BRADEMO`), Desenvolvimento Web Back-end (`BRADWBK`) e Desenvolvimento de Componentes (`BRADEPO`).

## Integrantes

| Nome | Prontuário |
| :--- | :--- |
| Mariane Fátima Silva | `BP3053474` |
| Thaina de Souza Pereira | `BP3053423` |

### ✨ Principais Funcionalidades

* **Arquitetura Multinível:** Tela inicial com vocabulário essencial (*Core Vocabulary*) e navegação intuitiva para categorias periféricas (Alimentação, Sentimentos, Rotinas, Lugares, etc.).
* **Código Visual Fitzgerald Modificado:** Identificação cromática para categorias gramaticais (Pessoas = Amarelo, Verbos = Verde, Descritores = Azul, Social = Rosa/Roxo, Substantivos = Laranja).
* **Text-to-Speech (TTS):** 
  * Leitura contínua da frase completa montada na barra de mensagens.
  * Suporte prioritário para Português Brasileiro (`pt-BR`).
* **Busca Inteligente:** Campo de pesquisa com *debounce* e normalização de caracteres (insensível a maiúsculas e acentos), permitindo encontrar palavras rapidamente e visualizar o caminho hierárquico da pasta.
* **Customização e Gerenciamento de Cartões:** Modo de edição para adicionar, personalizar rótulos, pictogramas/imagens e categorias de cores.
* **Barra de Composição:** Área fixa para montagem de frases com funções de apagar, limpar e disparar a leitura por voz.

---

## 🛠️ Tecnologias Utilizadas

* **Front-end:** Dart / Flutter (Android e Web)
* **Voz:** flutter_tts (motor nativo, pt-BR)
* **Ícones & Pictogramas:** Biblioteca de CAA aberta **ARASAAC** (catálogo local em SQLite)
* **Gerenciamento de Estado:** Provider (SyncService, ProfileProvider, EmergencyService)
* **Offline:** SQLite no mobile, armazenamento local no Web e fila de sincronização enviada somente em Wi-Fi
* **Notificações:** flutter_local_notifications (barra de progresso da sincronização)
* **Nuvem:** Supabase (Auth, PostgreSQL, Storage)
* **Back-end:** Java 17 / Spring Boot 3 / JPA / WebSocket STOMP (`BACKEND/api`)
* **Banco de Dados:** PostgreSQL (Supabase); H2 na demonstração da API

## ▶️ Como executar

### Pré-requisitos
* **Java 17+** e **Maven 3.9+**
* **Flutter SDK 3.x+** e **Android Studio / SDK Android** (para compilar o app mobile)


1. **Supabase:** rode no SQL Editor `BACKEND/database/supabase_content.sql`, depois
   `BACKEND/database/voxa_migracao_v2.sql` e
   `BACKEND/database/fix_auth_user_trigger.sql`. Em Authentication > URL Configuration >
   Redirect URLs adicione `io.supabase.voxa://login-callback/**`.
2. **App:** em `FRONTEND/voxa`, copie `.env.example` para `.env`, preencha a URL e
   a chave pública (anon) do Supabase e ajuste os endereços da API para o seu
   ambiente. Rode `flutter pub get`, `flutter analyze`, `flutter test` e
   `flutter build apk --release`. Para assinar o release, veja
   `android/key.properties.example`.
3. **API:** configure `SUPABASE_URL` e, para tokens HS256, `SUPABASE_JWT_SECRET`
   no ambiente do backend. Rode `mvn spring-boot:run` em `BACKEND/api` para usar
   H2 com dados de exemplo ou configure também as credenciais do PostgreSQL e o
   perfil `supabase` (veja `BACKEND/api/README.md`). Painel do cuidador em
   http://localhost:8080/ e Swagger em http://localhost:8080/swagger-ui.html.

> **Nota para Avaliação Rápida:** Os testes automatizados (`flutter test`) rodam localmente sem necessidade de conexão com o Supabase, e a versão compilada (`flutter build apk --release`) pode ser instalada diretamente em dispositivos Android para testes funcionais sem configuração de ambiente de desenvolvimento.

## Testes e Qualidade

* **Testes Unitários e de Widget (Flutter):**
  ```bash
  cd FRONTEND/voxa
  flutter analyze
  flutter test
  ```
  Cobre navegação, regras de termos e perfil ativo, deep link, CRUD offline com relação `N:N`, código de cores Fitzgerald e sincronização em Wi-Fi (`widget_test.dart`, `home_content_controller_test.dart` e `offline_sync_test.dart`).

* **Testes de Integração da API (Spring Boot / MockMvc):**
  ```bash
  cd BACKEND/api
  mvn test
  ```

O catálogo ARASAAC fica no SQLite do aparelho (não é mais copiado para cada
perfil no Supabase). As linhas abaixo descrevem o conteúdo criado pelo usuário.

Pranchas e cartões são consultados e persistidos pela API REST Spring, que usa
as tabelas PostgreSQL `prancha`, `cartao` e `prancha_cartao`. O app envia o
access token do Supabase; a API valida a identidade e limita as operações aos
dados do responsável autenticado. A conexão JDBC do backend não depende de RLS
para autorizar essas operações. A tabela de associação mantém o relacionamento
muitos-para-muitos. O catálogo
ARASAAC vem de `BACKEND/arasaac_dataset/catalogo.json` (convertido em
`assets/arasaac/catalogo_inicial.json` por `prepare_flutter_catalog.js`, que também
classifica cada pictograma na chave de cores Fitzgerald). Imagens do dispositivo são enviadas ao bucket privado
`content-images`; imagens da internet podem ser informadas por URL.


## Catálogo ARASAAC e Licença de Uso

O vocabulário visual padrão do **Voxa** integra o catálogo de pictogramas **ARASAAC** é propriedade do Governo de Aragão, criado por Serigio Palao e contém **610 categorias** e **13.767 pictogramas** organizados localmente no banco SQLite e na pasta `BACKEND/arasaac_dataset/`, com mapeamento automático para o **Sistema de Cores de Fitzgerald**.

### Atribuição Obrigatória
* **Autor dos pictogramas:** Sergio Palao
* **Origem / Propriedade:** ARASAAC ([http://www.arasaac.org](http://www.arasaac.org)) — Governo de Aragão (Espanha)
* **Licença:** **Creative Commons Attribution-NonCommercial-ShareAlike (CC BY-NC-SA)**
  * **Atribuição (BY):** É obrigatório dar o devido crédito ao autor (Sergio Palao) e ao portal ARASAAC.
  * **Uso Não Comercial (NC):** Os pictogramas e este projeto não podem ser utilizados para fins comerciais.
  * **Compartilha Igual (SA):** Obras derivadas devem ser distribuídas sob a mesma licença Creative Commons.

---

## 📁 Estrutura de Categorização (Fitzgerald Modificado)

| Cor | Categoria Gramatical / Função | Exemplos |
| :--- | :--- | :--- |
| **Amarelo** | Pessoas e Pronomes | Ex. Eu, Você, Família, Terapeuta |
| **Verde** | Ações e Verbos | Ex. Querer, Ir, Comer, Brincar, Parar |
| **Azul** | Descritores e Sentimentos | Ex. Feliz, Triste, Dor, Grande, Frio |
| **Rosa/Roxo** | Social e Cortesia | Ex. Sim, Não, Oi, Por Favor, Obrigado |
| **Laranja** | Pastas Temáticas / Substantivos | Ex. Comidas, Lugares, Vestuário, Brinquedos |
| **Cinza/Branco**| Controle e Estruturais | Ex. Apagar, Falar Tudo, Em, Para, O que |


## Privacidade e Conformidade (LGPD)

* **Proteção de Dados Sensíveis:** Por atender menores e pessoas vulneráveis, o sistema aplica coleta mínima de dados pessoais, controle parental autenticado para ações administrativas, armazenamento de imagens em buckets privados com URLs assinadas e mascaramento automático do telefone do responsável (`telefoneMascarado`) nos eventos transmitidos via WebSocket (`RN-04`).

---
