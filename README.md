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

* **Front-end:** Dart / Flutter
* **Áudio:** Ainda não definido
* **Ícones & Pictogramas:** Biblioteca de CAA aberta **ARASAAC**
* **Gerenciamento de Estado & Estrutura:** Árvore de dados em JSON estruturada hierarquicamente
* **Back-end:** Spring Boot / Java
* **Banco de Dados:** PostgreSQL

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
