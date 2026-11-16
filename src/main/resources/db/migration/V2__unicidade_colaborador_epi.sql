-- Unicidade de CPF/e-mail do colaborador, de CA do EPI e período do EPI.
-- Idempotente: os blocos DO não fazem nada se a constraint já existir, então serve tanto
-- para o banco que ainda não recebeu as constraints quanto para quem já rodou
-- src/sql/migracoes/001-unicidade-colaborador-epi.sql à mão no DBeaver.
--
-- Se houver duplicidade nos dados existentes, esta migração FALHA no ALTER e a aplicação não
-- sobe (é proposital: o Hibernate roda com ddl-auto=validate). Rode antes as conferências de
-- src/sql/migracoes/001-unicidade-colaborador-epi.sql e corrija o que aparecer.

UPDATE colaboradores SET email = lower(email) WHERE email <> lower(email);

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'colaboradores_cpf_key') THEN
    ALTER TABLE colaboradores ADD CONSTRAINT colaboradores_cpf_key UNIQUE (cpf);
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'colaboradores_email_key') THEN
    ALTER TABLE colaboradores ADD CONSTRAINT colaboradores_email_key UNIQUE (email);
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'epis_ca_key') THEN
    ALTER TABLE epis ADD CONSTRAINT epis_ca_key UNIQUE (ca);
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'epis_periodo_check') THEN
    ALTER TABLE epis ADD CONSTRAINT epis_periodo_check CHECK (validade >= inclusao);
  END IF;
END $$;
