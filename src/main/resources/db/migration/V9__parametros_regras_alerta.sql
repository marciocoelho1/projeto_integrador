-- Parâmetros globais e regras de alerta da tela Configurações → Configurações Globais.
-- São dados de referência do sistema (as três regras e os parâmetros iniciais já existem no
-- front-end), por isso entram na migração e não no perfil de demonstração.
-- Valores iniciais dos parâmetros entram como ponto de partida: o administrador ajusta na tela.

CREATE TABLE parametros (
  chave VARCHAR(60) PRIMARY KEY,
  valor VARCHAR(255) NOT NULL,
  descricao VARCHAR(255) NOT NULL
);

CREATE TABLE regras_alerta (
  codigo VARCHAR(40) PRIMARY KEY
      CHECK (codigo IN ('estoqueEpi', 'vencimentoEpi', 'treinamentoVencido')),
  nome_regra VARCHAR(120) NOT NULL,
  descricao_regra VARCHAR(255) NOT NULL,
  ativa BOOLEAN NOT NULL DEFAULT true
);

INSERT INTO parametros (chave, valor, descricao) VALUES
  ('estoqueMinimoEpi', '5', 'Quantidade mínima em estoque de EPI para o alerta de ruptura.'),
  ('diasAvisoVencimentoEpi', '30', 'Antecedência, em dias, do aviso de vencimento do CA do EPI.'),
  ('diasAvisoReciclagem', '60', 'Antecedência, em dias, do aviso de reciclagem de treinamento.');

INSERT INTO regras_alerta (codigo, nome_regra, descricao_regra, ativa) VALUES
  ('estoqueEpi', 'Ruptura de Estoque (EPI)', 'Notificar quando luvas, botas, etc., atingirem estoque mínimo.', true),
  ('vencimentoEpi', 'Validade de CA', 'Aviso de vencimento do Certificado de Aprovação (30 dias).', true),
  ('treinamentoVencido', 'Reciclagem de NRs', 'Aviso sobre vencimento de NR-35, NR-10, etc.', false);
