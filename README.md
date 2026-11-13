# 🗣️ Prancha de Comunicação Aumentativa e Alternativa (CAA)

Aplicação mobile interativa e acessível desenvolvida para Comunicação Aumentativa e Alternativa (CAA). O sistema permite que usuários com dificuldades ou ausência de fala verbal componham mensagens por meio de pictogramas organizados em múltiplos níveis, com sintetização de voz em tempo real.

---

## 🎯 Sobre o Projeto

Este projeto está sendo desenvolvido em âmbito acadêmico com foco em **acessibilidade digital**, **arquitetura de informação inclusiva** e **usabilidade**. A aplicação irá organizar o vocabulário através do **Sistema Fitzgerald Modificado**, equilibrando termos essenciais de alta frequência na tela principal e categorias temáticas organizadas em pastas e subpastas de fácil navegação.

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

* **Front-end:** Dart / Flutter (Android)
* **Voz:** flutter_tts (motor nativo, pt-BR)
* **Ícones & Pictogramas:** Biblioteca de CAA aberta **ARASAAC** (catálogo local em SQLite)
* **Gerenciamento de Estado:** Provider (SyncService, ProfileProvider, EmergencyService)
* **Offline:** SQLite (sqflite) + fila de sincronização enviada somente em Wi-Fi
* **Notificações:** flutter_local_notifications (barra de progresso da sincronização)
* **Nuvem:** Supabase (Auth, PostgreSQL, Storage)
* **Back-end:** Java 17 / Spring Boot 3 / JPA / WebSocket STOMP (`BACKEND/api`)
* **Banco de Dados:** PostgreSQL (Supabase); H2 na demonstração da API

## ▶️ Como executar

1. **Supabase:** rode no SQL Editor `BACKEND/database/supabase_content.sql` e depois
   `BACKEND/database/voxa_migracao_v2.sql`. Em Authentication > URL Configuration >
   Redirect URLs adicione `io.supabase.voxa://login-callback/**`.
2. **App:** em `FRONTEND/voxa`, copie `.env.example` para `.env`, preencha e rode
   `flutter pub get`, `flutter analyze`, `flutter test` e `flutter build apk --release`.
   Para assinar o release, veja `android/key.properties.example`.
3. **API:** em `BACKEND/api`, `mvn spring-boot:run` (H2 com dados de exemplo) ou o
   perfil `supabase` (veja `BACKEND/api/README.md`). Painel do cuidador em
   http://localhost:8080/ e Swagger em http://localhost:8080/swagger-ui.html.

O catálogo ARASAAC fica no SQLite do aparelho (não é mais copiado para cada
perfil no Supabase). As linhas abaixo descrevem o conteúdo criado pelo usuário.

Pranchas e cartões são persistidos no Supabase usando as tabelas existentes
`prancha`, `cartao` e `prancha_cartao`, com acesso protegido por políticas RLS.
A tabela de associação mantém o relacionamento muitos-para-muitos. O catálogo
ARASAAC vem de `BACKEND/arasaac_dataset/catalogo.json` (convertido em
`assets/arasaac/catalogo_inicial.json` por `prepare_flutter_catalog.js`, que também
classifica cada pictograma na chave de cores Fitzgerald). Imagens do dispositivo são enviadas ao bucket privado
`content-images`; imagens da internet podem ser informadas por URL.

Os pictogramas utilizados foram criados por Sergio Palao para ARASAAC
(https://arasaac.org), são propriedade do Governo de Aragão e estão sob licença
Creative Commons BY-NC-SA. O app apresenta essa atribuição na tela inicial e
inclui a licença fornecida com o conjunto em
`FRONTEND/voxa/assets/arasaac/LICENCA.txt`.
Essa licença exige atribuição, uso não comercial e compartilhamento de obras
derivadas sob a mesma licença.

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

---
