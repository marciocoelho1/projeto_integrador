-- Unicidade de CPF/e-mail do colaborador e de CA do EPI, e validação do período do EPI.
-- Aplicar SOMENTE em banco que já tem as tabelas criadas por criar-tabelas.sql.
-- Não recriar nem apagar tabela: aqui só entram constraints.
--
-- Os nomes usados aqui são explícitos e iguais aos de criar-tabelas.sql
-- (colaboradores_cpf_key, colaboradores_email_key, epis_ca_key, epis_periodo_check),
-- para que um banco novo e um banco migrado fiquem iguais.
-- atenção: CHECK com mais de uma coluna recebe o nome automático "<tabela>_check";
-- por isso o CHECK do período foi nomeado explicitamente nas duas pontas.
--
-- Limite conhecido: UNIQUE (email) compara maiúsculas/minúsculas. A aplicação grava sempre
-- em minúsculas (ColaboradorRequest), então a API não aceita variação de caixa; um INSERT
-- direto em SQL com e-mail em maiúscula passa pela constraint. O passo 2 abaixo padroniza
-- os registros antigos.
--
-- Ordem de execução: 1) conferências  2) padronização do e-mail  3) constraints  4) conferência final.

-- 1) Conferências. Cada SELECT precisa retornar ZERO linhas.
--    Se retornar linha, corrija os dados antes de criar a constraint:
--    a constraint falha e a aplicação fica com ddl-auto=validate sem subir.

-- 1.1 CPF repetido
SELECT cpf, COUNT(*) AS ocorrencias
FROM colaboradores
GROUP BY cpf
HAVING COUNT(*) > 1;

-- 1.2 E-mail repetido (comparação sem diferenciar maiúsculas/minúsculas)
SELECT lower(email) AS email, COUNT(*) AS ocorrencias
FROM colaboradores
GROUP BY lower(email)
HAVING COUNT(*) > 1;

-- 1.3 CA repetido
SELECT ca, COUNT(*) AS ocorrencias
FROM epis
GROUP BY ca
HAVING COUNT(*) > 1;

-- 1.4 EPI com validade anterior à inclusão
SELECT id, inclusao, validade
FROM epis
WHERE validade < inclusao;

-- 2) Padronizar o e-mail em minúsculas (a aplicação grava minúsculo; registros antigos
--    em maiúsculas escapariam da checagem de duplicidade). Rodar só depois de 1.2.
UPDATE colaboradores
SET email = lower(email)
WHERE email <> lower(email);

SELECT email, COUNT(*) AS ocorrencias
FROM colaboradores
GROUP BY email
HAVING COUNT(*) > 1;

-- 3) Constraints
ALTER TABLE colaboradores
  ADD CONSTRAINT colaboradores_cpf_key UNIQUE (cpf);

ALTER TABLE colaboradores
  ADD CONSTRAINT colaboradores_email_key UNIQUE (email);

ALTER TABLE epis
  ADD CONSTRAINT epis_ca_key UNIQUE (ca);

ALTER TABLE epis
  ADD CONSTRAINT epis_periodo_check CHECK (validade >= inclusao);

-- 4) Conferência final: deve listar as quatro constraints acima.
SELECT conrelid::regclass AS tabela, conname, contype
FROM pg_constraint
WHERE connamespace = 'public'::regnamespace
  AND conname IN (
    'colaboradores_cpf_key',
    'colaboradores_email_key',
    'epis_ca_key',
    'epis_periodo_check'
  )
ORDER BY conname;
