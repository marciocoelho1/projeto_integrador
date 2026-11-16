-- Contas de demonstração (perfil "demo"). Senha das duas: 123456.
-- O hash BCrypt abaixo foi gerado para essa senha; trocar a senha pela tela atualiza o hash.

INSERT INTO usuarios (nome_completo, login, email, cpf, senha_hash, grupo_id, status)
SELECT 'Administrador TST', 'admin', 'admin@essenza.com.br', '00000000001',
       '$2a$10$l9E7xCu3V8ba.qRNDEasa.gg4Wml9/m0oGxXgH/9H6rI.qlYaw4Ta',
       g.id, 'Ativo'
FROM grupos_acesso g WHERE g.nomenclatura = 'Administrador TST'
ON CONFLICT (login) DO NOTHING;

INSERT INTO usuarios (nome_completo, login, email, cpf, senha_hash, grupo_id, status)
SELECT 'Colaborador Demonstração', 'colaborador', 'colaborador@essenza.com.br', '00000000002',
       '$2a$10$l9E7xCu3V8ba.qRNDEasa.gg4Wml9/m0oGxXgH/9H6rI.qlYaw4Ta',
       g.id, 'Ativo'
FROM grupos_acesso g WHERE g.nomenclatura = 'Colaborador'
ON CONFLICT (login) DO NOTHING;
