# Executar a aplicação (CRUDs e recursos integrados)

## Escopo implementado

Cadastro, listagem, consulta por ID, edição e exclusão de colaboradores, catálogo de treinamentos, estoque de EPIs, entregas de EPI (com baixa de estoque), vínculos colaborador × treinamento, certificações, cargos e matriz LNT, turmas de reciclagem, usuários/grupos/módulos, chamados de suporte e parâmetros/regras de alerta. Endpoints `/api/colaboradores`, `/api/treinamentos`, `/api/epis`, `/api/entregas-epis`, `/api/vinculos`, `/api/certificacoes`, `/api/cargos`, `/api/lnt`, `/api/turmas-reciclagem`, `/api/reciclagens`, `/api/usuarios`, `/api/grupos`, `/api/modulos`, `/api/chamados`, `/api/parametros`, `/api/regras-alerta`. IDs são números; datas são ISO YYYY-MM-DD.

Além dos CRUDs, ficam integrados ao banco: autenticação real (`/api/auth/*`, token de sessão de 8 horas), auditoria (`/api/auditoria`, com captura automática das escritas), importação em massa (`/api/importacao/colaboradores|treinamentos|epis`, até 500 linhas por lote, com relatório por linha), indicadores do dashboard (`/api/dashboard/indicadores`) e relatórios CSV gerados no servidor (`/api/relatorios/*.csv`).

Regras de unicidade conferidas na aplicação e no banco, com 409 na duplicidade: matrícula, CPF e e-mail do colaborador; código do treinamento; CA do EPI. O CPF é gravado apenas com dígitos e o e-mail em minúsculas. No EPI, a validade precisa ser igual ou posterior à inclusão (400). A entrega de EPI não deixa o saldo negativo: responde 409 informando o disponível.

Todas as rotas de `/api/**` exigem `Authorization: Bearer <token>`, exceto `health`, `auth/login`, `auth/bootstrap` e a recuperação de senha — que respondem sem sessão. O schema é versionado pelo Flyway (`src/main/resources/db/migration`, `V1` a `V9`); em banco criado à mão antes disso, o Flyway faz `baseline` na versão 1 e a `V2` é idempotente em relação a `src/sql/migracoes/001-unicidade-colaborador-epi.sql`.

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

Com o Flyway ligado (`spring.flyway.enabled=true`), **a aplicação cria/atualiza as tabelas sozinha na inicialização** — não é mais preciso rodar DDL à mão. O Flyway cria a tabela de histórico `flyway_schema_history`; para conferir o que foi aplicado:

```sql
SELECT version, description, success, installed_on FROM flyway_schema_history ORDER BY installed_rank;
```

O script `src/sql/criar-tabelas.sql` continua como referência do schema e serve para preparar um banco **antes** de subir a aplicação: nesse caso o Flyway marca a versão 1 como baseline e aplica somente o que falta. Ao usar DDL manual, execute apenas o CREATE TABLE das tabelas ausentes, nunca recrie/apague tabelas existentes. IDs devem ser integer/identity. A role da aplicação precisa de acesso às tabelas e sequências. Não versionar senha.

## Backend (IntelliJ)

1. Pare a execução anterior de SgsstApplication no IntelliJ: processos já iniciados não recebem novos controllers automaticamente.
2. Recarregue Maven e compile.
3. Na configuração de execução, definir DB_URL=jdbc:postgresql://127.0.0.1:5432/sgsst e DB_USERNAME conforme a role real. Preencher DB_PASSWORD apenas na configuração local. Para subir com os dados de demonstração (três colaboradores, três treinamentos, três EPIs e as contas `admin`/`colaborador`), acrescente `SPRING_PROFILES_ACTIVE=demo`.
4. Execute SgsstApplication. O Flyway aplica as migrações pendentes e o Hibernate valida o schema (`ddl-auto=validate`); se houver erro, conferir estrutura/permissões no DBeaver, não trocar validate por update para esconder o problema.
5. Confira http://localhost:8080/api/health (rota livre) e faça login em `POST /api/auth/login` com `{"login":"admin","senha":"123456"}` para obter o token. Em banco sem o perfil demo, crie o primeiro administrador com `POST /api/auth/bootstrap`.
6. Com o token no header `Authorization: Bearer <token>`, confira os GET de cada recurso e `GET /api/dashboard/indicadores`. Sem o header, essas rotas respondem 401.

## Frontend (VS Code)

```bash
npm start
```

Abra http://localhost:4200 (origem permitida por CORS). Use as abas de cadastramentos e as telas colaboradores, matriz-treinamentos e epis. Sucesso só é mostrado depois da resposta HTTP. Exclusões exigem confirmação.

## Verificações executadas

Rodada final (itens 1 a 12), todas depois da última alteração de código:

- Backend: `mvn -B test` no container Maven → **390 testes, 0 falhas** (40 arquivos). São testes de `service` com repositórios mockados e de `controller` com `MockMvc` standalone: nenhum sobe contexto Spring, então a suíte **não** depende do banco.
- Frontend: `npm test -- --watch=false` → **66 testes, 0 falhas** (15 arquivos); `ng build` OK, apenas com os avisos de orçamento de bundle/SCSS que já existiam.
- Ponta a ponta (`~/.hermes/cache/scratch/pi-backend/verifica-item7-12.sh`): PostgreSQL descartável na porta 55461 e API real na 18095 com `SPRING_PROFILES_ACTIVE=demo` → 11 migrações aplicadas em banco vazio (23 tabelas), `/api/health` 200, `/api/dashboard/indicadores` e `/api/relatorios/*.csv` respondendo **401 sem token** e 200 com `Authorization: Bearer`, login do perfil demo devolvendo token, indicadores recalculados depois de criar entrega de EPI, vínculo, certificação e chamado pela própria API (estoque de EPI 35 → 31, entregas do período 0 → 4, treinamentos 0 → 1 com 100% de progresso, alerta de suporte aparecendo) e os 6 CSVs conferidos (HTTP 200, `text/csv;charset=UTF-8`, `Content-Disposition` de anexo, BOM `EF BB BF`, cabeçalho e conteúdo com o dado real).
- Login: o hash BCrypt da migração `V900`/`V901` foi conferido com `BCrypt.checkpw("123456", hash)` — aceita a senha correta e recusa outra. (O hash publicado antes desta rodada não correspondia a `123456`, ou seja, as contas de demonstração não entravam.)
- Unicidade e período do EPI (item 1), mantidas: banco novo e banco criado com o script à mão terminaram com as mesmas 13 constraints (mesmos nomes e definições em `pg_constraint`); a migração foi exercitada em banco com dados sujos (as quatro conferências apontaram os registros; o `ALTER TABLE` falhou antes da correção dos dados e passou depois); a API contra o banco migrado respondeu 409 nos quatro casos de duplicidade e 400 no período inválido.
- Flyway (item 2), mantidas: banco vazio × banco com o script antigo × banco onde o script manual 001 já rodou × perfil demo — os quatro cenários terminaram com o histórico `ok`.

## Testes locais

Frontend: `npm test -- --watch=false` e `npm run build`.
Backend: `mvn test` / `mvn package` no IntelliJ ou no container (`docker.io/library/maven:3.9.11-eclipse-temurin-21`) — esta máquina não tem `mvn` nem `javac` no host. Os testes Java não dependem do banco principal; a persistência é verificada separadamente em PostgreSQL descartável.
