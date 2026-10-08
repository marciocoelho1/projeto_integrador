# SGSST — Sistema de Gestão de Saúde e Segurança do Trabalho

Projeto Integrador desenvolvido para o curso do Senac, com foco nos processos de Saúde e Segurança do Trabalho do Essenza Supermercados Ltda.

A aplicação reúne interfaces para gestão de colaboradores, treinamentos e equipamentos de proteção individual (EPIs), além de indicadores, cadastros e áreas de acesso para administradores e colaboradores.

---

## Estado Atual e Integração com o Backend

A versão publicada neste repositório contém o frontend Angular. O backend Java e a integração dos CRUDs de colaboradores, catálogo de treinamentos e estoque de EPIs estão em desenvolvimento local e aguardam versionamento.

A base local utiliza **Spring Boot e PostgreSQL**, com código Java em `src/main/java/br/com/senac/sgsst/`. As configurações ficam em `src/main/resources/application.properties`, e o esquema do banco em `src/sql/criar-tabelas.sql`. Esses arquivos estarão disponíveis no repositório após a publicação da integração.

O login é demonstrativo, com sessão armazenada no navegador. Dashboard, certificações, vínculos de treinamentos, entregas de EPIs, importação, configurações e suporte apresentam fluxos de protótipo; sua presença na interface não significa que estejam integrados ao banco.

### Escopo da Integração

| Recurso | Operações previstas na integração | URL da API local |
| :--- | :--- | :--- |
| Colaboradores | Cadastrar, listar, consultar por ID, editar e excluir | `/api/colaboradores` |
| Catálogo de treinamentos | Cadastrar, listar, consultar por ID, editar e excluir | `/api/treinamentos` |
| Estoque de EPIs | Cadastrar, listar, consultar por ID, editar e excluir | `/api/epis` |
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
- **Backend em desenvolvimento:** Java 17, Spring Boot, Spring Data JPA, Bean Validation e Maven.
- **Banco da integração local:** PostgreSQL.

---

## Telas e Funcionalidades do Protótipo

### Perfil Administrador / Técnico de SST

- **Dashboard:** visão de indicadores de treinamentos, certificações e EPIs.
- **Colaboradores:** consulta do quadro de funcionários, filtros e situação cadastral.
- **Matriz de treinamentos:** interface para catálogo de capacitações e acompanhamento de normas regulamentadoras.
- **EPIs:** telas de estoque, Certificado de Aprovação (CA) e entregas de equipamentos.
- **Cadastramentos:** formulários de colaboradores, treinamentos e EPIs.
- **Importação em massa:** interface de leitura e pré-visualização de planilhas CSV e Excel.
- **Configurações:** interfaces de usuários, permissões e auditoria.
- **Ajuda e suporte:** visualização e acompanhamento demonstrativo de chamados.

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
│   │   ├── layout-padrao/           # Layout, navegação e menu lateral
│   │   ├── service/                 # Serviços de dados e funcionalidades
│   │   ├── tela-login/              # Acesso demonstrativo
│   │   ├── tela-recuperar-senha/    # Interface de recuperação de acesso
│   │   ├── tela-dashboard/          # Indicadores gerais
│   │   ├── tela-colaboradores/      # Gestão de colaboradores
│   │   ├── tela-matriz-treinamento/ # Catálogo e matriz de treinamentos
│   │   ├── tela-epis/               # Estoque e interface de entregas
│   │   ├── tela-cadastramentos/     # Formulários de cadastro
│   │   ├── tela-importacao-massa/   # Importação de planilhas
│   │   ├── tela-configuracoes/      # Configurações e auditoria
│   │   ├── tela-area-colaborador/  # Área do colaborador
│   │   ├── tela-ajuda-suporte/      # Suporte administrativo
│   │   ├── tela-ajuda-suporte-colaborador/
│   │   ├── app.routes.ts            # Rotas da aplicação
│   │   ├── auth.service.ts          # Sessão demonstrativa no navegador
│   │   └── auth.guard.ts            # Verificação de sessão nas rotas
│   ├── main.ts                      # Inicialização do Angular
│   └── styles.scss                  # Estilos e tokens globais
├── angular.json                     # Configuração do Angular CLI
└── package.json                     # Dependências e scripts
```

---

## Como Executar o Projeto

### Pré-requisitos

- **Node.js 24**, a partir da versão **24.15.0**.
- **npm**; o `package.json` declara a versão **11.16.0**.
- **Git** para clonar o repositório.

Os scripts utilizam o Angular CLI instalado no projeto, sem necessidade de instalação global.

### Passo a Passo

1. Clone o repositório e entre na pasta:

   ```bash
   git clone https://github.com/marciocoelho1/projeto_integrador.git
   cd projeto_integrador
   ```

2. Instale as dependências a partir do arquivo de versões:

   ```bash
   npm ci
   ```

3. Inicie o servidor de desenvolvimento:

   ```bash
   npm start
   ```

4. Acesse [http://localhost:4200/login](http://localhost:4200/login) e utilize uma das contas demonstrativas abaixo.

### Backend em Desenvolvimento Local

Após o versionamento dos arquivos de integração, a execução completa também exigirá Java 17, Maven e PostgreSQL. A configuração local utiliza:

| Variável | Finalidade | Valor padrão |
| :--- | :--- | :--- |
| `DB_URL` | URL JDBC do PostgreSQL | `jdbc:postgresql://127.0.0.1:5432/sgsst` |
| `DB_USERNAME` | Usuário do banco | `sgsst_app` |
| `DB_PASSWORD` | Senha do usuário do banco | Vazia; preencher no ambiente local |

Prepare o banco `sgsst` e as tabelas do script SQL, configure as variáveis de ambiente e execute `SgsstApplication` no IntelliJ ou `mvn spring-boot:run` na raiz. O Hibernate está configurado com `ddl-auto=validate`: as tabelas precisam existir antes da inicialização.

A configuração CORS da base local permite a origem `http://localhost:4200`. A disponibilidade da API e do banco pode ser consultada em `http://localhost:8080/api/health`.

---

## Credenciais de Demonstração

| Perfil | Usuário | Senha | Rota Inicial |
| :--- | :--- | :--- | :--- |
| Administrador | `admin` | `123456` | `/dashboard` |
| Colaborador | `colaborador` | `123456` | `/area-colaborador` |

Essas contas são verificadas pelo frontend e não representam autenticação no backend.

---

## Comandos Úteis

| Comando | Finalidade |
| :--- | :--- |
| `npm start` | Executar o frontend em desenvolvimento |
| `npm run build` | Gerar o build do frontend |
| `npm run watch` | Recompilar o frontend ao alterar arquivos |
| `npm test` | Executar os testes do frontend |

---

## Referência

A organização deste documento foi adaptada do [README do projeto SGSST frontend](https://github.com/marciocoelho1/projeto-integrador-frontend/blob/feat/base-backend-mysql/README.md), com informações específicas deste repositório e da integração local com PostgreSQL.
