# SGSST — Sistema de Gestão de Saúde e Segurança do Trabalho

Projeto Integrador desenvolvido para o curso do Senac, com foco nos processos de Saúde e Segurança do Trabalho do Essenza Supermercados Ltda.

A aplicação reúne interfaces para gestão de colaboradores, treinamentos e equipamentos de proteção individual (EPIs), além de indicadores, cadastros e áreas de acesso para administradores e colaboradores.

---

## Estado Atual e Integração com o Backend

A versão publicada neste repositório contém o frontend Angular e o backend Java, com integração ao PostgreSQL de colaboradores, treinamentos, estoque e entregas de EPIs, vínculos de treinamento, certificações, cargos/LNT, turmas de reciclagem, usuários e grupos de acesso, auditoria, chamados de suporte, importação em massa, parâmetros/regras de alerta, indicadores do dashboard e relatórios em CSV.

A base local utiliza **Spring Boot e PostgreSQL**, com código Java em `src/main/java/br/com/senac/sgsst/`. As configurações ficam em [application.properties](src/main/resources/application.properties). O schema é versionado por **Flyway**: as migrações ficam em `src/main/resources/db/migration` e o perfil `demo` acrescenta dados fictícios de `src/main/resources/db/demo`. O script histórico [criar-tabelas.sql](src/sql/criar-tabelas.sql) e os scripts de `src/sql/migracoes/` permanecem no repositório para os bancos criados à mão antes do Flyway. Consulte também as [instruções de execução dos CRUDs](docs/cruds-execucao.md).

O login é real: `POST /api/auth/login` devolve um token de sessão que o frontend envia em `Authorization: Bearer <token>`, e as demais rotas de `/api/**` respondem 401 sem ele (ficam livres `health`, `auth/login`, `auth/bootstrap` e a recuperação de senha). As senhas são gravadas com BCrypt e a sessão fica na tabela `sessoes`, válida por 8 horas.

O frontend também tem um **modo demonstração** (`npm run demo`) que responde toda a API na memória do navegador, com dados de exemplo, para as telas serem apresentadas sem Java e sem PostgreSQL — veja [Modo demonstração](#modo-demonstração-visualizar-o-frontend-sem-o-banco-de-dados). Não confundir com o perfil `demo` do backend: aquele popula o banco PostgreSQL de verdade.

### Escopo da Integração

| Recurso | Operações implementadas | URL da API local |
| :--- | :--- | :--- |
| Colaboradores | Cadastrar, listar, consultar por ID, editar e excluir | `/api/colaboradores` |
| Catálogo de treinamentos | Cadastrar, listar, consultar por ID, editar e excluir | `/api/treinamentos` |
| Estoque de EPIs | Cadastrar, listar, consultar por ID, editar e excluir | `/api/epis` |
| Entregas de EPI | Registrar (com baixa de estoque), listar, consultar por ID, editar e excluir | `/api/entregas-epis` |
| Vínculos colaborador × treinamento | Criar, listar, consultar por ID, editar e excluir | `/api/vinculos` |
| Certificações | Criar, listar, consultar por ID, editar e excluir | `/api/certificacoes` |
| Cargos e matriz LNT | Criar, listar, consultar por ID, editar, excluir e substituir a matriz do cargo | `/api/cargos`, `/api/lnt` |
| Turmas de reciclagem | Criar, listar, consultar por ID, editar e excluir | `/api/turmas-reciclagem` |
| Reciclagens a vencer | Consultar prazos na janela de 60 dias | `/api/reciclagens` |
| Usuários, grupos e módulos | Criar, listar, consultar por ID, editar, excluir, trocar senha e liberar módulos do grupo | `/api/usuarios`, `/api/grupos`, `/api/modulos` |
| Autenticação e sessão | Entrar, sair, consultar sessão, primeiro acesso e recuperação de senha | `/api/auth/*` |
| Auditoria | Consultar com filtros de termo/data e registrar evento manual | `/api/auditoria` |
| Chamados de suporte | Abrir, listar (visão do colaborador e visão completa), consultar, mudar status e excluir | `/api/chamados` |
| Importação em massa | Importar colaboradores, treinamentos e EPIs com relatório por linha (até 500 linhas por lote) | `/api/importacao/*` |
| Parâmetros e regras de alerta | Consultar e atualizar | `/api/parametros`, `/api/regras-alerta` |
| Indicadores do dashboard | Consultar (números contados no banco, sem valor fixo na tela) | `/api/dashboard/indicadores` |
| Relatórios em CSV | Baixar dashboard, matriz de treinamentos, colaboradores, EPIs, certificações e entregas | `/api/relatorios/*.csv` |
| Saúde da aplicação e do banco | Consultar disponibilidade | `/api/health` |

Na base local, a API atende em `http://localhost:8080`, e o frontend em `http://localhost:4200`.

---

## Tecnologias Utilizadas

- **Frontend:** Angular 22 e TypeScript 6.
- **Componentes e rotas:** componentes standalone e Angular Router.
- **Estado e comunicação:** Angular Signals, RxJS e HttpClient.
- **Estilização:** SCSS, variáveis CSS e Bootstrap 5.
- **Planilhas:** SheetJS (`xlsx`) para os fluxos de leitura de arquivos.
- **Ferramentas de desenvolvimento:** Angular CLI local, npm e Prettier.
- **Testes do frontend:** Vitest e jsdom.
- **Backend:** Java 17, Spring Boot, Spring Data JPA, Bean Validation e Maven.
- **Banco da integração local:** PostgreSQL.

---

## Telas e Funcionalidades

### Perfil Administrador / Técnico de SST

- **Dashboard:** indicadores calculados no banco (colaboradores por situação, certificações ativas/vencidas, unidades de EPI em estoque, a vencer e vencidas, entregas dos últimos 30 dias, progresso dos treinamentos) com alertas por criticidade e exportação do relatório em CSV.
- **Colaboradores:** consulta do quadro de funcionários, filtros e situação cadastral.
- **Matriz de treinamentos:** interface para catálogo de capacitações e acompanhamento de normas regulamentadoras.
- **EPIs:** telas de estoque, Certificado de Aprovação (CA) e entregas de equipamentos.
- **Cadastramentos:** formulários de colaboradores, treinamentos e EPIs.
- **Importação em massa:** interface de leitura e pré-visualização de planilhas CSV e Excel.
- **Configurações:** interfaces de usuários, permissões e auditoria.
- **Ajuda e suporte:** abertura e acompanhamento de chamados persistidos, com visão completa para o administrador.

### Perfil Colaborador

- **Área do colaborador:** interface de consulta de treinamentos, certificações e EPIs.
- **Ajuda e suporte:** interface para dúvidas e solicitações internas.

---

## Estrutura de Pastas Principais

```text
projeto_integrador/
├── public/                          # Logo e favicon
├── src/
│   ├── app/
│   │   ├── componentes/             # Componentes compartilhados, como toast
│   │   ├── demo/                    # API em memória do modo demonstração (dados de exemplo)
│   │   ├── layout-padrao/           # Layout, navegação e menu lateral
│   │   ├── service/                 # Serviços de dados e funcionalidades
│   │   ├── tela-login/              # Autenticação contra a API
│   │   ├── tela-recuperar-senha/    # Recuperação de acesso com token
│   │   ├── tela-dashboard/          # Indicadores gerais
│   │   ├── tela-colaboradores/      # Gestão de colaboradores
│   │   ├── tela-matriz-treinamento/ # Catálogo, vínculos, certificações, LNT e reciclagens
│   │   ├── tela-epis/               # Estoque, CA e entregas de EPIs
│   │   ├── tela-cadastramentos/     # Formulários de cadastro
│   │   ├── tela-importacao-massa/   # Importação de planilhas
│   │   ├── tela-configuracoes/      # Usuários, permissões, parâmetros e auditoria
│   │   ├── tela-area-colaborador/  # Área do colaborador
│   │   ├── tela-ajuda-suporte/      # Suporte administrativo
│   │   ├── tela-ajuda-suporte-colaborador/
│   │   ├── app.routes.ts            # Rotas da aplicação
│   │   ├── auth.service.ts          # Sessão por token no navegador
│   │   └── auth.guard.ts            # Verificação de sessão nas rotas
│   ├── main/
│   │   ├── java/br/com/senac/sgsst/ # Aplicação Spring Boot e camadas da API
│   │   └── resources/              # Configuração do backend
│   ├── sql/                         # Script do esquema PostgreSQL
│   ├── environments/                # Configuração de API: desenvolvimento, produção e demo
│   ├── test/java/                   # Testes do backend
│   ├── main.ts                      # Inicialização do Angular
│   └── styles.scss                  # Estilos e tokens globais
├── docs/                            # Instruções de execução dos CRUDs
├── pom.xml                          # Dependências e build do backend
├── angular.json                     # Configuração do Angular CLI
└── package.json                     # Dependências e scripts
```

---

## Como Executar o Projeto

### Pré-requisitos

- **Node.js 24**, a partir da versão **24.15.0**.
- **npm**; o `package.json` declara a versão **11.16.0**.
- **Git** para clonar o repositório.
- **Java 17, Maven e PostgreSQL** apenas para executar o backend e os CRUDs integrados. O modo demonstração descrito abaixo não precisa de nenhum deles.

Os scripts utilizam o Angular CLI instalado no projeto, sem necessidade de instalação global.

### Modo demonstração (visualizar o frontend sem o banco de dados)

Para apresentar ou revisar as telas sem subir Java e PostgreSQL, o frontend tem um modo demonstração: o build `demo` usa `src/environments/environment.demo.ts` e registra o `demoApiInterceptor`, que responde **todas** as chamadas de `/api/**` a partir de dados de exemplo guardados na memória do navegador (código em `src/app/demo/`).

1. Clone o repositório e entre na pasta:

   ```bash
   git clone https://github.com/marciocoelho1/projeto_integrador.git
   cd projeto_integrador
   ```

2. Instale as dependências a partir do arquivo de versões:

   ```bash
   npm ci
   ```

3. Suba o frontend no modo demonstração (não precisa de backend):

   ```bash
   npm run demo
   ```

4. Acesse [http://localhost:4200/login](http://localhost:4200/login) e entre com uma das contas:

   | Perfil | Usuário | Senha | Rota inicial |
   | :--- | :--- | :--- | :--- |
   | Administrador | `admin` | `123456` | `/dashboard` |
   | Colaborador | `colaborador` | `123456` | `/area-colaborador` |

O que funciona nesse modo: login e sessão, todas as listagens, inclusão, edição e exclusão, mudança de status dos chamados, importação em massa e exportação dos relatórios em CSV. Os números do dashboard são calculados a partir dos mesmos dados de exemplo, como o backend faz no banco.

O que muda em relação ao backend real:

- Nada é persistido: recarregar a página devolve os dados de exemplo ao estado inicial.
- Nenhuma requisição sai para a rede — nem para `localhost:8080`, nem para a API publicada. O console registra `[demo] rota não atendida: ...` caso alguma rota usada pela tela ainda não exista no modo demonstração.
- Os dados são fictícios (16 colaboradores, 8 EPIs, 8 treinamentos, 24 vínculos, 12 certificações, 5 chamados em andamento e 6 meses de entregas).

Para gerar um build estático do modo demonstração (útil para publicar em qualquer host estático ou abrir em outro computador):

```bash
npm run build:demo
# o resultado fica em dist/frontend_angular/browser
python3 -m http.server 4200 --directory dist/frontend_angular/browser
```

### Passo a Passo com o backend local

Use estes passos quando precisar do banco de verdade (Java 17, Maven e PostgreSQL instalados):

1. Clone o repositório e entre na pasta:

   ```bash
   git clone https://github.com/marciocoelho1/projeto_integrador.git
   cd projeto_integrador
   ```

2. Instale as dependências a partir do arquivo de versões:

   ```bash
   npm ci
   ```

3. Suba a API (`mvn spring-boot:run` na raiz) — instruções de banco e Flyway em [Backend Local](#backend-local).

4. Inicie o servidor de desenvolvimento do frontend, que aponta para `http://localhost:8080/api`:

   ```bash
   npm start
   ```

5. Acesse [http://localhost:4200/login](http://localhost:4200/login) e utilize uma das contas demonstrativas abaixo.

### Backend Local

A configuração do banco utiliza as seguintes variáveis de ambiente:

| Variável | Finalidade | Valor padrão |
| :--- | :--- | :--- |
| `DB_URL` | URL JDBC do PostgreSQL | `jdbc:postgresql://127.0.0.1:5432/sgsst` |
| `DB_USERNAME` | Usuário do banco | `sgsst_app` |
| `DB_PASSWORD` | Senha do usuário do banco | Vazia; preencher no ambiente local |

Prepare o banco `sgsst`, configure as variáveis de ambiente e execute `SgsstApplication` no IntelliJ ou `mvn spring-boot:run` na raiz. **As tabelas são criadas pelo Flyway na inicialização** (`spring.flyway.enabled=true`, migrações `V1` a `V9` em `src/main/resources/db/migration`). Em um banco que já existia com o script aplicado à mão, o Flyway faz `baseline` na versão 1 e aplica apenas o que falta; a `V2` é idempotente e não falha se `src/sql/migracoes/001-unicidade-colaborador-epi.sql` já tiver sido executado. O Hibernate está configurado com `ddl-auto=validate`: as tabelas precisam existir antes da inicialização — em banco vazio é o próprio Flyway que as cria.

Para subir com dados fictícios de demonstração, use o perfil `demo` (`SPRING_PROFILES_ACTIVE=demo`): ele acrescenta `src/main/resources/db/demo` às locations do Flyway e cria três colaboradores, três treinamentos, três EPIs e as duas contas de acesso abaixo. O perfil não altera bancos sem a variável.

A configuração CORS da base local permite as origens de `app.cors.origins` (`http://localhost:4200` e `https://sgsst-frontend-mvbu.onrender.com` por padrão; ajuste com `CORS_ORIGINS`). A disponibilidade da API e do banco pode ser consultada em `http://localhost:8080/api/health`.

### Login e sessão

O primeiro administrador é criado por `POST /api/auth/bootstrap` (sem senha versionada no repositório). Depois disso, `POST /api/auth/login` devolve `{ token, expiraEm, usuario }` e as rotas de `/api/**` esperam `Authorization: Bearer <token>`. A senha é gravada como hash BCrypt; a recuperação de senha grava um token na tabela `redefinicoes_senha` e o exibe ao administrador em `GET /api/auth/redefinicoes` (não há envio de e-mail no projeto).

### Relatórios em CSV

`GET /api/relatorios/{dashboard,matriz-treinamentos,colaboradores,epis,certificacoes,entregas-epis}.csv` geram o arquivo no servidor, com separador `;` e BOM UTF-8 (abre direto no Excel em português). O botão **Exportar** do dashboard e o de exportação da matriz usam esses endpoints, então o arquivo reflete o banco e não apenas o que a tela carregou.

---

## Deploy no Render com Neon

O ambiente publicado usa dois serviços no Render e um PostgreSQL gerenciado no Neon:

| Peça | Onde roda | Como está configurado |
| :--- | :--- | :--- |
| API Spring Boot | Render, **Web Service** a partir do `Dockerfile` do repositório | `DB_URL`, `DB_USERNAME`, `DB_PASSWORD`, `CORS_ORIGINS` |
| Frontend Angular | Render, **Static Site** (`npm ci` + `npm run build`) | build de produção usa `src/environments/environment.ts` |
| Banco | Neon (PostgreSQL) | connection string do Neon convertida para JDBC |

Endereços em uso: API em `https://sgsst-api-r3iv.onrender.com`, frontend em `https://sgsst-frontend-mvbu.onrender.com`.

### Variáveis de ambiente da API

| Variável | Valor |
| :--- | :--- |
| `DB_URL` | `jdbc:postgresql://<host-do-neon>/<banco>?sslmode=require` |
| `DB_USERNAME` | usuário do Neon (`<usuario>` do painel do Neon) |
| `DB_PASSWORD` | senha do Neon — somente no painel do Render (Environment), nunca no repositório |
| `CORS_ORIGINS` | `https://sgsst-frontend-mvbu.onrender.com,http://localhost:4200` |

O `PORT` é injetado pelo Render e lido por `server.port=${PORT:8080}`. O `Dockerfile` compila com Maven/Java 17 e limita a JVM a 60% da memória, porque o plano free tem 512 MB.

### Migrações no Neon

Não é preciso rodar DDL à mão: **na primeira inicialização o Flyway aplica `V1`…`V9`**. Se o banco do Neon já tinha as tabelas criadas pelo `src/sql/criar-tabelas.sql`, o Flyway marca a versão 1 como *baseline* e aplica somente o que falta; a `V2` é idempotente em relação a `src/sql/migracoes/001-unicidade-colaborador-epi.sql`. Se a `V2` falhar por dois e-mails que colidem ao passar para minúsculas, rode antes as quatro conferências do script `001` — ele lista os registros problemáticos.

### Primeiro acesso depois do deploy

O banco publicado **não tem contas**: as contas demonstrativas vêm da migração `V900`/`V901`, aplicada só com o perfil `demo`. Duas opções:

1. **Criar o primeiro administrador pela API** (o endpoint funciona exatamente quando não existe usuário):

   ```bash
   curl -X POST https://sgsst-api-r3iv.onrender.com/api/auth/bootstrap \
     -H 'Content-Type: application/json' \
     -d '{"nomeCompleto":"Administrador TST","login":"admin","email":"admin@empresa.com.br",
          "cpf":"00000000001","grupoId":1,"status":"Ativo","senha":"<sua-senha>"}'
   ```

   O `grupoId` 1 é o grupo `Administrador TST`, criado pela migração `V3`; a senha precisa de 6 a 72 caracteres.

2. **Subir a API com o perfil `demo`** (`SPRING_PROFILES_ACTIVE=demo` no Environment do Render) para ganhar os dados fictícios e as contas `admin`/`colaborador` da tabela de credenciais deste README — prático para apresentar, sabendo que ele grava registros fictícios no banco publicado.

### Detalhes que atrapalham na hora de demonstrar

- O plano free do Render hiberna o serviço: a primeira requisição depois de um tempo parado levou **115 s** aqui. Abra a API antes de apresentar.
- A partir do deploy desta versão, as rotas de `/api/**` exigem `Authorization: Bearer <token>` (ficam livres `health`, `auth/login`, `auth/bootstrap` e a recuperação de senha). Um `GET /api/colaboradores` direto no navegador passa a responder **401** em vez de 200.
- O frontend publicado chama a API por `https://sgsst-api-r3iv.onrender.com/api` (o `environment.ts` de produção). Se a URL do serviço mudar, ajuste esse arquivo **e** `CORS_ORIGINS`.

---

## Credenciais de Demonstração

| Perfil | Usuário | Senha | Rota Inicial |
| :--- | :--- | :--- | :--- |
| Administrador | `admin` | `123456` | `/dashboard` |
| Colaborador | `colaborador` | `123456` | `/area-colaborador` |

As duas contas são criadas pelo perfil `demo` (migração `V901`) na tabela `usuarios`, com o hash BCrypt da senha `123456`. O frontend autentica em `POST /api/auth/login` e guarda o token da sessão no navegador; sem o perfil `demo`, cadastre o primeiro administrador por `POST /api/auth/bootstrap`.

---

## Comandos Úteis

| Comando | Finalidade |
| :--- | :--- |
| `npm run demo` | Executar o frontend no modo demonstração, sem backend e sem banco |
| `npm run build:demo` | Gerar o build estático do modo demonstração |
| `npm start` | Executar o frontend em desenvolvimento, consumindo a API em `localhost:8080` |
| `npm run build` | Gerar o build do frontend |
| `npm run watch` | Recompilar o frontend ao alterar arquivos |
| `npm test` | Executar os testes do frontend |
| `mvn spring-boot:run` | Executar a API local |
| `mvn test` | Executar os testes do backend |
| `mvn package` | Gerar o JAR do backend |

---

## Referência

A organização deste documento foi adaptada do [README do projeto SGSST frontend](https://github.com/marciocoelho1/projeto-integrador-frontend/blob/feat/base-backend-mysql/README.md), com informações específicas deste repositório e da integração local com PostgreSQL.
