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

A configuração do banco usa as variáveis de ambiente abaixo. Elas podem chegar por
`application-local.properties` (recomendado no dia a dia) ou pelo próprio ambiente:

| Variável | Finalidade | Valor padrão |
| :--- | :--- | :--- |
| `DB_URL` | URL JDBC do PostgreSQL | `jdbc:postgresql://127.0.0.1:5432/sgsst` |
| `DB_USERNAME` | Usuário do banco | `sgsst_app` |
| `DB_PASSWORD` | Senha do usuário do banco | Vazia; **precisa ser definida** |
| `CORS_ORIGINS` | Origens liberadas, separadas por vírgula | `http://localhost:4200,https://sgsst-frontend-mvbu.onrender.com` |

#### Configurando as credenciais localmente

Crie um arquivo **`application-local.properties` na raiz do projeto** (o mesmo diretório do
`pom.xml`) com as suas credenciais:

```properties
spring.datasource.url=jdbc:postgresql://SEU_HOST/SEU_BANCO?sslmode=require
spring.datasource.username=SEU_USUARIO
spring.datasource.password=SUA_SENHA
```

O arquivo é **carregado automaticamente** — não é preciso ativar perfil nem exportar variável de
ambiente. Isso é feito por `spring.config.import` no `application.properties`, com o prefixo
`optional:` para que a ausência do arquivo não quebre CI nem o deploy no Render (lá as variáveis
do painel continuam sendo usadas).

O `.env.example` na raiz documenta as mesmas variáveis, caso prefira fornecê-las pelo ambiente.

> **O arquivo está no `.gitignore`** e nunca deve ser versionado. Se você definir a senha por
> engenharia reversa no histórico do Git, rotacione a credencial no painel do banco: remover a
> linha depois não apaga o valor dos commits antigos.
>
> **Formato da URL:** o Neon entrega `postgresql://...`; converta para `jdbc:postgresql://...` e
> mantenha `?sslmode=require` (o Neon recusa conexões sem TLS).

Se a senha estiver ausente, a aplicação aborta na inicialização com uma mensagem explícita
(`ValidacaoConfiguracaoBanco`) apontando a variável e a URL que seria usada, em vez de uma cascata
de erros do Flyway/Hibernate.

#### Subindo a API

Execute `SgsstApplication` no IntelliJ ou `./mvnw spring-boot:run` na raiz. **As tabelas são criadas pelo Flyway na inicialização** (`spring.flyway.enabled=true`, migrações `V1` a `V9` em `src/main/resources/db/migration`). Em um banco que já existia com o script aplicado à mão, o Flyway faz `baseline` na versão 1 e aplica apenas o que falta; a `V2` é idempotente e não falha se `src/sql/migracoes/001-unicidade-colaborador-epi.sql` já tiver sido executado. O Hibernate está configurado com `ddl-auto=validate`: as tabelas precisam existir antes da inicialização — em banco vazio é o próprio Flyway que as cria.

Para subir com dados fictícios de demonstração, use o perfil `demo` (`SPRING_PROFILES_ACTIVE=demo`): ele acrescenta `src/main/resources/db/demo` às locations do Flyway e cria três colaboradores, três treinamentos, três EPIs e as duas contas de acesso abaixo. O perfil não altera bancos sem a variável.

A disponibilidade da API e do banco pode ser consultada em `http://localhost:8080/api/health`. **As tabelas são criadas pelo Flyway na inicialização** (`spring.flyway.enabled=true`, migrações `V1` a `V9` em `src/main/resources/db/migration`). Em um banco que já existia com o script aplicado à mão, o Flyway faz `baseline` na versão 1 e aplica apenas o que falta; a `V2` é idempotente e não falha se `src/sql/migracoes/001-unicidade-colaborador-epi.sql` já tiver sido executado. O Hibernate está configurado com `ddl-auto=validate`: as tabelas precisam existir antes da inicialização — em banco vazio é o próprio Flyway que as cria.

Para subir com dados fictícios de demonstração, use o perfil `demo` (`SPRING_PROFILES_ACTIVE=demo`): ele acrescenta `src/main/resources/db/demo` às locations do Flyway e cria três colaboradores, três treinamentos, três EPIs e as duas contas de acesso abaixo. O perfil não altera bancos sem a variável.

A configuração CORS da base local permite as origens de `app.cors.origins` (`http://localhost:4200` e `https://sgsst-frontend-mvbu.onrender.com` por padrão; ajuste com `CORS_ORIGINS`). A disponibilidade da API e do banco pode ser consultada em `http://localhost:8080/api/health`.

### App Mobile (Flutter)

O app fica em `mobile/` e consome a mesma API do backend. O endereço é resolvido
automaticamente por `mobile/lib/config/api_config.dart`: no emulador Android ele usa
`10.0.2.2:8080` (alias do emulador para a máquina que roda a API) e no desktop usa
`localhost:8080`. Para apontar para outro endereço:

```bash
flutter run --dart-define=API_BASE_URL=http://192.168.0.10:8080/api
```

#### Rodando pelo VS Code (recomendado)

O repositório já traz as configurações em `.vscode/`. Com o emulador ligado, use
**F5** e escolha **app_sgsst (mobile)** — ou **Ctrl+Shift+P → Tasks: Run Task**:

| Task | O que faz |
| :--- | :--- |
| `android: iniciar emulador` | Sobe o AVD escolhido (deixe rodando; ~1 min para bootar) |
| `backend: subir com dados demo` | Sobe a API com o perfil `demo` (contas `admin` / `123456` e `colaborador` / `123456`) |
| `flutter: run android` | Instala, abre o app e **mantém o hot reload** — a forma normal de ver suas mudanças |
| `flutter: atualizar app no emulador` | Compila o APK, instala por cima e reabre (sem hot reload) |
| `flutter: reinstalar no emulador` | Remove o app antes de instalar (use quando a tela não mudar) |
| `flutter: devices` | Lista os devices disponíveis |
| `flutter: analyze` / `flutter: test` | Análise estática e testes |

O binário `emulator` **não está no PATH** — as tasks usam `$ANDROID_HOME/emulator/emulator`.
Se o seu AVD tiver outro nome, inclua-o no `input` `avd` em `.vscode/tasks.json`
(liste com `flutter emulators`).

As tasks de execução fixam o device com `-d emulator-5554`. Isso é necessário porque
`flutter devices` também lista **Linux (desktop)** e, sem `-d`, o `flutter run` pode
escolher esse device — que falha neste repositório por falta do toolchain de desktop
(`clang++` e GTK 3). Se o emulador aparecer com outro id, ajuste o `-d` em
`.vscode/tasks.json`.

##### Atualizar a versão do app no emulador

Há três formas, da mais leve para a mais pesada:

1. **Hot reload (o dia a dia).** Deixe a task `flutter: run android` rodando e salve um
   arquivo Dart: o emulador atualiza em ~1 s. No terminal onde o `flutter run` está
   aberto, `r` recarrega e `R` reinicia o app.
2. **Nova instalação sem desinstalar.** Rode a task `flutter: atualizar app no emulador`.
   É o caminho quando o hot reload caiu ou quando o app está em outro estado (por
   exemplo, logado). Equivale a:

   ```bash
   cd mobile
   flutter build apk --debug --dart-define=API_BASE_URL=http://10.0.2.2:8080/api
   adb install -r build/app/outputs/flutter-apk/app-debug.apk
   adb shell am force-stop br.com.senac.sgsst.app_sgsst
   adb shell am start -n br.com.senac.sgsst.app_sgsst/.MainActivity
   ```

3. **Instalação limpa.** Use a task `flutter: reinstalar no emulador` quando a tela
   ainda mostrar a versão antiga ou a sessão estiver atrapalhando:

   ```bash
   cd mobile
   adb uninstall br.com.senac.sgsst.app_sgsst
   flutter run -d emulator-5554 --dart-define=API_BASE_URL=http://10.0.2.2:8080/api
   ```

   Para voltar à tela de login sem desinstalar, `adb shell pm clear br.com.senac.sgsst.app_sgsst`.

Para conferir qual versão está instalada, `adb shell dumpsys package br.com.senac.sgsst.app_sgsst | grep lastUpdateTime`.

##### Duas causas de "a tela não atualizou"

1. **O emulador guarda um snapshot.** Ele "acorda" com o app já instalado na versão
   antiga; por isso a atualização precisa ser explícita (hot reload ou reinstalação).
2. **O aplicativo está falando com outra API.** A task aponta para
   `http://10.0.2.2:8080/api` — o `10.0.2.2` é o apelido da sua máquina dentro do
   emulador. Se o backend não estiver no ar, o login falha com *Usuário ou senha
   inválidos* ou erro de conexão mesmo com a senha certa. Suba o backend
   (`backend: subir com dados demo`) antes de testar. No perfil `demo`, as contas são
   `admin` / `123456` e `colaborador` / `123456`.

#### Emulador no Android Studio (Flatpak)

**O emulador não inicia pelo Android Studio instalado como Flatpak.** Ele aparece como
`terminated` e o log (`~/.var/app/com.google.AndroidStudio/cache/Google/AndroidStudio*/log/idea.log`)
mostra o motivo:

```
Warning: Could not find the Qt platform plugin "wayland"
Could not load the Qt platform plugin "xcb" ... even though it was found
Fatal: This application failed to start because no Qt platform plugin could be initialized.
Process finished with exit code 134 (interrupted by signal 6:SIGABRT)
```

A causa não é o AVD nem o projeto: dentro do sandbox do Flatpak, o emulador não consegue
inicializar o plugin Qt. O Flatpak expõe os sockets `wayland` e `fallback-x11`, mas o
emulador do SDK é compilado sem o plugin Wayland e o fallback X11 não carrega no sandbox.

**Soluções:**

1. **Inicie o emulador por fora do Studio** (a task do VS Code ou
   `$ANDROID_HOME/emulator/emulator -avd <nome>`). Ele herda a sessão gráfica do host e
   funciona; o Android Studio continua servindo para editar o código e o `adb` enxerga
   o device normalmente. **É o caminho recomendado.**
2. Instale o Android Studio pelo tarball oficial em vez do Flatpak.
3. Tente atualizar o emulador: `sdkmanager --update`.

Forçar renderização por software (`-gpu swiftshader_indirect`) **não resolve**: o emulador
já cai para software rendering por conta própria e aborta antes, na inicialização do Qt.

#### Telas portadas da versão web

O app mobile cobre as mesmas funcionalidades do frontend Angular, com o design do
dashboard ("Carteira digital"). A navegação fica em `mobile/lib/screens/main_screen.dart`
e tem dois níveis: a barra inferior traz os quatro atalhos do perfil, e o seletor
**Todas as telas** (ícone de grade no cabeçalho) mais o menu lateral expõem todas as
demais telas sem exigir gesto.

| Perfil | Telas |
| :--- | :--- |
| Administrador | Dashboard, Matriz de Treinamentos, EPIs, Colaboradores, Cadastramentos, Importação em Massa, Ajuda e Suporte, Configurações |
| Colaborador | Área do Colaborador, Ajuda e Suporte |

Comum aos dois perfis: Login e Recuperar Senha. A pasta `mobile/lib` segue a mesma
organização do web — `models/`, `services/`, `screens/` e `widgets/` — e os nomes dos
arquivos espelham os do Angular (`colaborador_service.dart` ↔ `colaborador.service.ts`).

Pontos de paridade que valem conferir numa apresentação:

| Recurso web | Equivalente mobile |
| :--- | :--- |
| Edição de colaborador (modal + validação) | `colaboradores_screen.dart`, `core/validacao.dart` |
| Entrega de EPI abate estoque; excluir estorna | `epis_screen.dart` (`EpiService.registrarEntrega`/`excluirEntrega`) |
| Matriz cruzada por NR e LNT | `matriz_treinamento_screen.dart` (mesma janela de 60 dias e status OK/Alerta/Vencido/N-A) |
| Importação em massa (CSV) | `importacao_massa_screen.dart` (mesmos cabeçalhos aceitos e normalização de acentos) |
| Chamados do colaborador só os próprios | `ajuda_suporte_colaborador_screen.dart` (`GET /api/chamados?meus=true`) |
| Menu por perfil (admin x colaborador) | `menu_sgsst.dart` + `AuthService.perfil` |
| Dashboard com 8 fontes e 8 blocos | `dashboard_screen.dart` + `widgets/blocos_dashboard.dart` (matriz de calor, setores, EPIs críticos, entregas por mês, últimas entregas e atividade recente) |
| Botão **Exportar** do dashboard | `DashboardService.baixarRelatorioCsv` + `salvarCsv` em `core/formatadores.dart` |
| Configurações com 5 abas | `configuracoes_screen.dart` (Usuários do Sistema, Grupos de Usuários, Matriz de Acessos, Configurações Globais, Logs de Auditoria) |
| Balão de Ajuda flutuante | `widgets/balao_ajuda.dart` — recolhe a só o ícone ao navegar ou rolar e volta inteiro após 4 s de tela parada |

O Excel (`.xlsx`) **não** é lido no celular: a importação em massa aceita CSV exportado do
Excel, mantendo os mesmos nomes de coluna e aliases da versão web.

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

## Como Contribuir (fluxo de pull request)

A branch `main` é protegida: **não** é possível enviar commit direto para ela. Todo trabalho entra por pull request, e nenhum PR é mesclado sem a aprovação do mantenedor do repositório (o `CODEOWNERS` do projeto aponta apenas para ele).

1. Faça o fork ou clone o repositório e crie uma branch com um nome descritivo:

   ```bash
   git clone https://github.com/marciocoelho1/projeto_integrador.git
   cd projeto_integrador
   git checkout -b feat/nome-da-sua-alteracao
   ```

2. Faça as alterações, rode os testes e envie a branch:

   ```bash
   npm ci
   npm test
   git add .
   git commit -m "frontend: descricao curta do que mudou"
   git push -u origin feat/nome-da-sua-alteracao
   ```

3. Abra o pull request para `main` pelo link que o `git push` devolve ou em **Pull requests → New pull request**.
4. Peça a aprovação do mantenedor. Depois do aceite, o próprio autor do PR pode concluir o merge (ou o mantenedor faz isso).

O que a regra da `main` exige, hoje:

- Pull request aberto e **1 aprovação válida** — que precisa vir do proprietário do código.
- Aprovações são descartadas se novos commits forem enviados ao PR depois do aceite.
- Sem force push e sem exclusão da branch.

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
| `cd mobile && flutter run` | Executar o app Flutter no device ligado |
| `cd mobile && flutter test` | Executar os testes do app |
| `$ANDROID_HOME/emulator/emulator -avd <nome>` | Iniciar o emulador Android (fora do Flatpak) |

---

## Referência

A organização deste documento foi adaptada do [README do projeto SGSST frontend](https://github.com/marciocoelho1/projeto-integrador-frontend/blob/feat/base-backend-mysql/README.md), com informações específicas deste repositório e da integração local com PostgreSQL.
