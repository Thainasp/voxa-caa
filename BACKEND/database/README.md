# Quadro de Comunicacao (CAA) — API Spring Boot

Implementacao do diagrama UML (Usuario, Categoria, Prancha, Cartao) usando
Spring Boot 3.5 + Spring Data JPA + PostgreSQL + Flyway.

## Estrutura do banco

| Tabela     | Chave estrangeira            | Regra de exclusao |
|------------|-------------------------------|--------------------|
| usuario    | —                              | —                  |
| categoria  | —                              | —                  |
| prancha    | usuario_id -> usuario(id)      | ON DELETE CASCADE  |
| cartao     | categoria_id -> categoria(id)  | ON DELETE RESTRICT |
| cartao     | prancha_id -> prancha(id)      | ON DELETE CASCADE  |

O schema completo (tabelas, PKs, FKs, indices e constraints) esta em
`src/main/resources/db/migration/V1__create_schema.sql` e e aplicado
automaticamente pelo Flyway na primeira execucao.

## Pre-requisitos

- Java 25+
- Maven 3.9+
- PostgreSQL rodando localmente (ou ajuste `DB_URL`/`DB_USER`/`DB_PASSWORD`)

## Configuracao

Crie o banco antes de subir a aplicacao (o Flyway cria as *tabelas*, mas nao
o *banco de dados* em si):

```sql
CREATE DATABASE quadro_comunicacao;
```

Por padrao a aplicacao usa `jdbc:postgresql://localhost:5432/quadro_comunicacao`
com usuario/senha `postgres`/`postgres`. Para sobrescrever, exporte variaveis
de ambiente antes de rodar:

```bash
export DB_URL=jdbc:postgresql://localhost:5432/quadro_comunicacao
export DB_USER=postgres
export DB_PASSWORD=sua_senha
```

## Rodando a aplicacao

```bash
mvn spring-boot:run
```

A API sobe em `http://localhost:8080`. O Flyway roda a migration
automaticamente no startup.

### Subindo com dados de exemplo

```bash
mvn spring-boot:run -Dspring-boot.run.profiles=seed
```

Isso ativa o `JsonSeedLoader`, que le `src/main/resources/data/seed.json` e
insere usuarios, categorias, pranchas e cartoes de exemplo via as mesmas
regras de negocio dos services (senha e hasheada, FKs sao validadas, etc.).

## Endpoints principais

| Metodo | Rota                                | Descricao                     |
|--------|--------------------------------------|--------------------------------|
| POST   | /api/usuarios                        | Cadastrar usuario              |
| POST   | /api/usuarios/login                  | Login                          |
| PUT    | /api/usuarios/{id}                   | Gerenciar perfil               |
| POST   | /api/categorias                      | Criar categoria                |
| GET    | /api/categorias                      | Listar categorias              |
| DELETE | /api/categorias/{id}                 | Excluir categoria              |
| POST   | /api/pranchas                        | Criar prancha                  |
| GET    | /api/pranchas/usuario/{usuarioId}    | Listar pranchas de um usuario  |
| POST   | /api/pranchas/{id}/compartilhar      | Gerar link de compartilhamento |
| POST   | /api/cartoes                         | Adicionar cartao                |
| PUT    | /api/cartoes/{id}                    | Editar cartao                   |
| DELETE | /api/cartoes/{id}                    | Excluir cartao                  |
| GET    | /api/cartoes/prancha/{pranchaId}     | Listar cartoes de uma prancha  |
| POST   | /api/cartoes/{id}/reproduzir         | Reproduzir audio (+1 uso)      |

## Observacao sobre serializacao JSON

As entidades usam `@JsonManagedReference`/`@JsonBackReference` para evitar
recursao infinita ao serializar os relacionamentos bidirecionais
(Usuario<->Prancha, Categoria<->Cartao, Prancha<->Cartao). Isso depende do
`open-in-view` padrao do Spring Boot (ativo) para carregar colecoes lazy
durante a serializacao — uma simplificacao adequada para um projeto
academico. Em uma API de producao, o recomendado seria substituir por DTOs
de resposta dedicados.
