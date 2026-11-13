-- Dados de exemplo do perfil "dev" (H2). Ids fixos para usar no Postman e no
-- cliente web (static/index.html).
INSERT INTO usuario (id, nome, email, telefone, data_nascimento, avatar_url, is_responsavel) VALUES
  ('11111111-1111-4111-8111-111111111111', 'Thaina de Souza', 'thaina@voxa.app', '(11) 99999-0000', DATE '1998-04-10', NULL, TRUE);

INSERT INTO perfil (id, usuario_id, nome, avatar_url, is_responsavel) VALUES
  ('22222222-2222-4222-8222-222222222221', '11111111-1111-4111-8111-111111111111', 'Thaina', NULL, TRUE),
  ('22222222-2222-4222-8222-222222222222', '11111111-1111-4111-8111-111111111111', 'Leo', NULL, FALSE);

INSERT INTO prancha (id, perfil_id, chave, nome, icone, imagem_url, caminho_audio, ordem, catalogo_arasaac) VALUES
  ('33333333-3333-4333-8333-333333333331', '22222222-2222-4222-8222-222222222222', 'rotina', 'Rotina', 'bed', NULL, NULL, 0, FALSE),
  ('33333333-3333-4333-8333-333333333332', '22222222-2222-4222-8222-222222222222', 'alimentacao', 'Alimentação', 'restaurant', NULL, NULL, 1, FALSE);

INSERT INTO cartao (id, perfil_id, texto, caminho_imagem, caminho_audio, icone, cor_hex, arasaac_id, is_favorito, frequencia_uso) VALUES
  ('44444444-4444-4444-8444-444444444441', '22222222-2222-4222-8222-222222222222', 'Eu',       'assets/arasaac/6632.png', NULL, 'person',      '#ffe8a900', '6632', TRUE,  12),
  ('44444444-4444-4444-8444-444444444442', '22222222-2222-4222-8222-222222222222', 'Quero',    'assets/arasaac/5441.png', NULL, 'pan_tool',    '#ff2e9e4f', '5441', TRUE,  9),
  ('44444444-4444-4444-8444-444444444443', '22222222-2222-4222-8222-222222222222', 'Comer',    'assets/arasaac/6456.png', NULL, 'restaurant',  '#ff2e9e4f', '6456', FALSE, 4),
  ('44444444-4444-4444-8444-444444444444', '22222222-2222-4222-8222-222222222222', 'Água',     'assets/arasaac/2248.png', NULL, 'local_drink', '#fff08a3c', '2248', FALSE, 6),
  ('44444444-4444-4444-8444-444444444445', '22222222-2222-4222-8222-222222222222', 'Banheiro', 'assets/arasaac/8142.png', NULL, 'wc',          '#fff08a3c', '8142', FALSE, 3);

-- N:N: "Quero" está nas duas pranchas
INSERT INTO prancha_cartao (prancha_id, cartao_id, ordem) VALUES
  ('33333333-3333-4333-8333-333333333331', '44444444-4444-4444-8444-444444444441', 0),
  ('33333333-3333-4333-8333-333333333331', '44444444-4444-4444-8444-444444444442', 1),
  ('33333333-3333-4333-8333-333333333331', '44444444-4444-4444-8444-444444444445', 2),
  ('33333333-3333-4333-8333-333333333332', '44444444-4444-4444-8444-444444444442', 0),
  ('33333333-3333-4333-8333-333333333332', '44444444-4444-4444-8444-444444444443', 1),
  ('33333333-3333-4333-8333-333333333332', '44444444-4444-4444-8444-444444444444', 2);
