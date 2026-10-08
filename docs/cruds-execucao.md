# Executar os três CRUDs

## Escopo implementado

Cadastro, listagem, consulta por ID, edição e exclusão de colaboradores, catálogo de treinamentos e estoque de EPIs. Endpoints `/api/colaboradores`, `/api/treinamentos`, `/api/epis` com GET lista/ID, POST, PUT e DELETE. IDs são números; datas de EPI são ISO YYYY-MM-DD.

Entregas, vínculos, LNT, certificações, reciclagens, dashboard, importação/exportação e autenticação real não foram implementados. As áreas relacionadas nas telas CRUD indicam essa limitação. O login existente continua sendo protótipo; usar apenas localmente com dados fictícios.

## Banco principal (DBeaver)

Na conexão sgsst, conferir antes de executar DDL:

```sql
SELECT current_database(), current_schema(), current_user;
SELECT table_name, column_name, data_type, is_nullable, is_identity
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name IN ('colaboradores', 'treinamentos', 'epis')
ORDER BY table_name, ordinal_position;
```

O script de referência é `src/sql/criar-tabelas.sql`. Execute somente CREATE TABLE das tabelas ausentes, nunca recrie/apague tabelas existentes. IDs devem ser integer/identity. A role da aplicação precisa de acesso às tabelas e sequências. Não versionar senha.

## Backend (IntelliJ)

1. Pare a execução anterior de SgsstApplication no IntelliJ: processos já iniciados não recebem novos controllers automaticamente.
2. Recarregue Maven e compile.
3. Na configuração de execução, definir DB_URL=jdbc:postgresql://127.0.0.1:5432/sgsst e DB_USERNAME conforme a role real. Preencher DB_PASSWORD apenas na configuração local.
4. Execute SgsstApplication. O Hibernate valida o schema; se houver erro, conferir estrutura/permissões no DBeaver, não trocar validate por update para esconder o problema.
5. Confira http://localhost:8080/api/health e os GET de cada recurso.

## Frontend (VS Code)

```bash
npm start
```

Abra http://localhost:4200 (origem permitida por CORS). Use as abas de cadastramentos e as telas colaboradores, matriz-treinamentos e epis. Sucesso só é mostrado depois da resposta HTTP. Exclusões exigem confirmação.

## Verificações executadas

- Maven clean package: 64 testes passaram; JAR gerado.
- Angular: 43 testes passaram; build passou com avisos de orçamento de bundle/SCSS.
- PostgreSQL de teste isolado: schema criado e validado por Hibernate; criar/listar/consultar/editar/excluir dos três recursos; 400/404, conflitos de matrícula/código e CORS; persistência após reiniciar API.
- Chromium headless: cadastro/listagem/edição/reload/exclusão nas três telas com API real e PostgreSQL isolado. Requisições do navegador encaminhadas à porta de teste 18080 para não tocar a instância anterior na 8080. Sessão local de protótipo usada, sem validar autenticação real.
- Banco principal: API anterior /api/health respondeu UP e colaboradores respondeu 200; treinamentos/epis responderam 404 antes de reiniciar a instância. Não foram alterados dados do banco principal nem validado seu schema pela conexão administrativa.

## Testes locais

Frontend: npm test -- --watch=false e npm run build.
Backend: Maven test/package no IntelliJ. Os testes Java de service/controller não dependem do banco principal; persistência foi verificada separadamente no PostgreSQL isolado.
