-- Dados fictícios para demonstração. Só é aplicado com o perfil "demo"
-- (application-demo.properties acrescenta classpath:db/demo às locations do Flyway),
-- para não sujar o banco de trabalho com registros inventados.
-- Idempotente: ON CONFLICT DO NOTHING nas chaves únicas.

INSERT INTO colaboradores (matricula, nome, cpf, email, cargo, setor, status) VALUES
  ('DEMO-01', 'Ana Ribeiro',   '11111111111', 'ana.ribeiro@essenza.com.br',   'Operadora de Caixa', 'Frente de Loja', 'Ativo'),
  ('DEMO-02', 'Bruno Salles',  '22222222222', 'bruno.salles@essenza.com.br',  'Açougueiro',         'Açougue',        'Ativo'),
  ('DEMO-03', 'Carla Mendes',  '33333333333', 'carla.mendes@essenza.com.br',  'Repositora',         'Mercearia',      'Afastado')
ON CONFLICT (matricula) DO NOTHING;

INSERT INTO treinamentos (codigo, nome, classificacao, nr, carga_horaria, validade_meses, status) VALUES
  ('DEMO-NR35', 'NR-35 Trabalho em Altura', 'Norma Regulamentadora', 'NR-35', '8 horas', 24, 'Ativo'),
  ('DEMO-NR06', 'NR-06 Uso de EPI',         'Norma Regulamentadora', 'NR-06', '4 horas', 12, 'Ativo'),
  ('DEMO-NR10', 'NR-10 Segurança em Eletricidade', 'Norma Regulamentadora', 'NR-10', '40 horas', 24, 'Ativo')
ON CONFLICT (codigo) DO NOTHING;

INSERT INTO epis (descricao, ca, inclusao, validade, quantidade) VALUES
  ('Capacete de Segurança',  'DEMO-CA-498',  CURRENT_DATE, CURRENT_DATE + 730, 10),
  ('Óculos de Segurança',    'DEMO-CA-18103', CURRENT_DATE, CURRENT_DATE + 365, 20),
  ('Botina de Segurança',    'DEMO-CA-215',  CURRENT_DATE, CURRENT_DATE + 30,  5)
ON CONFLICT (ca) DO NOTHING;
