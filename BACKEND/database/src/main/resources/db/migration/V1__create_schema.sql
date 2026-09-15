-- =====================================================================
-- V1__create_schema.sql
-- Esquema do Quadro de Comunicacao Alternativa (CAA)
-- Entidades: Usuario, Categoria, Prancha, Cartao
-- =====================================================================

-- ---------------------------------------------------------------------
-- Tabela USUARIO
-- ---------------------------------------------------------------------
CREATE TABLE usuario (
    id                BIGSERIAL PRIMARY KEY,
    nome              VARCHAR(150)  NOT NULL,
    email             VARCHAR(150)  NOT NULL,
    senha             VARCHAR(255)  NOT NULL,
    data_nascimento   DATE          NOT NULL,
    is_responsavel    BOOLEAN       NOT NULL DEFAULT FALSE,

    CONSTRAINT uq_usuario_email UNIQUE (email)
);

COMMENT ON TABLE usuario IS 'Usuarios do sistema (responsaveis e dependentes)';

-- ---------------------------------------------------------------------
-- Tabela CATEGORIA
-- ---------------------------------------------------------------------
CREATE TABLE categoria (
    id                     BIGSERIAL PRIMARY KEY,
    nome                   VARCHAR(100)  NOT NULL,
    is_controle_parental   BOOLEAN       NOT NULL DEFAULT FALSE,

    CONSTRAINT uq_categoria_nome UNIQUE (nome)
);

COMMENT ON TABLE categoria IS 'Categorias usadas para classificar os cartoes';

-- ---------------------------------------------------------------------
-- Tabela PRANCHA
-- 1 Usuario -> * Pranchas
-- ---------------------------------------------------------------------
CREATE TABLE prancha (
    id           BIGSERIAL PRIMARY KEY,
    nome         VARCHAR(150) NOT NULL,
    usuario_id   BIGINT       NOT NULL,

    CONSTRAINT fk_prancha_usuario
        FOREIGN KEY (usuario_id) REFERENCES usuario (id)
        ON DELETE CASCADE
);

COMMENT ON TABLE prancha IS 'Pranchas de comunicacao pertencentes a um usuario';

-- ---------------------------------------------------------------------
-- Tabela CARTAO
-- 1 Categoria -> * Cartoes
-- 1 Prancha   -> * Cartoes
-- ---------------------------------------------------------------------
CREATE TABLE cartao (
    id                BIGSERIAL PRIMARY KEY,
    texto             VARCHAR(255)  NOT NULL,
    caminho_imagem    VARCHAR(500),
    caminho_audio     VARCHAR(500),
    is_favorito       BOOLEAN       NOT NULL DEFAULT FALSE,
    frequencia_uso    INTEGER       NOT NULL DEFAULT 0,
    categoria_id      BIGINT        NOT NULL,
    prancha_id        BIGINT        NOT NULL,

    CONSTRAINT fk_cartao_categoria
        FOREIGN KEY (categoria_id) REFERENCES categoria (id)
        ON DELETE RESTRICT,

    CONSTRAINT fk_cartao_prancha
        FOREIGN KEY (prancha_id) REFERENCES prancha (id)
        ON DELETE CASCADE,

    CONSTRAINT ck_cartao_frequencia_uso CHECK (frequencia_uso >= 0)
);

COMMENT ON TABLE cartao IS 'Cartoes (pictogramas) exibidos em uma prancha';

-- ---------------------------------------------------------------------
-- Indices para as chaves estrangeiras e colunas de filtro frequente
-- (uq_usuario_email e uq_categoria_nome ja criam indice implicitamente)
-- ---------------------------------------------------------------------
CREATE INDEX idx_prancha_usuario_id  ON prancha (usuario_id);
CREATE INDEX idx_cartao_categoria_id ON cartao (categoria_id);
CREATE INDEX idx_cartao_prancha_id   ON cartao (prancha_id);
CREATE INDEX idx_cartao_favorito     ON cartao (is_favorito);
