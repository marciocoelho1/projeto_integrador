# Meu SGSST

Sistema de Gestão de Saúde e Segurança do Trabalho — projeto integrador do Senac para a
**Essenza Supermercados Ltda.**

Três versões: app web (Angular), app mobile (Flutter) e API (Spring Boot).

---

## Acessos rápidos

| O que | Endereço |
| :--- | :--- |
| 🌐 **App web** | **https://sgsst-frontend-mvbu.onrender.com** |
| 📱 **App mobile (APK)** | **[Baixar](https://github.com/marciocoelho1/projeto_integrador/releases/download/v1.0.0/app-release.apk)** |
| 🔌 API | `https://sgsst-api-r3iv.onrender.com/api` |

### Contas para entrar

| Perfil | Usuário | Senha |
| :--- | :--- | :--- |
| Administrador TST | `admin` | `123456` |
| Colaborador | `colaborador` | `123456` |

> As contas acima existem no ambiente publicado (perfil `demo`). Os membros do grupo
> têm credenciais individuais de administrador.

**App no celular:** baixe o APK pelo link, permita "instalar de fontes desconhecidas" e
abra. Requer Android 7.0 ou superior.

> ⚠️ O plano gratuito do Render hiberna. A primeira abertura pode levar até **2 minutos**
> — o app avisa "Acordando o servidor…" e espera. Abra o site alguns minutos antes de
> apresentar.

---

## O que o sistema faz

| Módulo | Recursos |
| :--- | :--- |
| Dashboard | Indicadores, conformidade e exportação de relatórios |
| Colaboradores | Cadastro, edição, exclusão e matriz de SST |
| EPIs | Estoque, entregas com baixa automática e controle de validade |
| Treinamentos | Vínculos, certificações, cargos/LNT e reciclagens |
| Cadastramentos | Cargos, LNT, reciclagem e turmas |
| Importação em massa | Planilha CSV com relatório por linha (até 500 linhas) |
| Configurações | Usuários, grupos de acesso e parâmetros |
| Ajuda e Suporte | Chamados com acompanhamento de status |

Dois perfis de acesso: **Administrador TST** (todos os módulos) e **Colaborador**
(apenas a área pessoal).

---

## Rodando localmente

### Pré-requisitos

Java 17+, Node.js 20+, PostgreSQL 14+ e, para o mobile, Flutter 3.35+.

### App web

```bash
npm ci
npm run demo      # sem backend: dados de exemplo na memória do navegador
```

Acesse http://localhost:4200/login.

Para usar a API de verdade, suba o backend (abaixo) e rode `npm start`.

### API

```bash
# 1. configure o banco (não versionado)
echo 'spring.datasource.url=jdbc:postgresql://localhost:5432/sgsst' > application-local.properties
echo 'spring.datasource.username=seu_usuario' >> application-local.properties
echo 'spring.datasource.password=sua_senha' >> application-local.properties

# 2. suba
./mvnw spring-boot:run
```

O Flyway cria as tabelas na primeira execução. API em http://localhost:8080.

Teste: `curl http://localhost:8080/api/health` → `{"status":"UP","database":"UP"}`

### App mobile

```bash
cd mobile
flutter run                                    # emulador (usa 10.0.2.2:8080)
flutter build apk --release \
  --dart-define=API_BASE_URL=https://sgsst-api-r3iv.onrender.com/api
```

### Comandos úteis

| Comando | Finalidade |
| :--- | :--- |
| `npm run demo` | Frontend com dados de exemplo, sem backend |
| `npm start` | Frontend consumindo a API local |
| `npm test` | Testes do frontend |
| `mvn spring-boot:run` | API local |
| `mvn test` | Testes do backend |
| `cd mobile && flutter test` | Testes do app |
| `cd mobile && flutter analyze` | Análise estática do app |

---

## Como o projeto está organizado

```
src/app/              Frontend Angular
  tela-*/             Uma pasta por tela
  service/            Comunicação com a API
  demo/               Dados do modo demonstração

src/main/java/br/com/senac/sgsst/
  api/                Controllers REST
  config/             Segurança, CORS, auditoria
  domain/             Entidades e repositórios

src/main/resources/
  db/migration/       Migrações Flyway (V1…V9)
  db/demo/            Dados fictícios (perfil demo)

mobile/               App Flutter
  lib/screens/        Telas
  lib/services/       Serviços e cliente HTTP
  lib/widgets/        Componentes reutilizáveis
  lib/core/           Tema e design system
```

### Stack

- **Web:** Angular 22, TypeScript, Signals, RxJS, SCSS, Bootstrap 5
- **API:** Java 17, Spring Boot, JPA, Bean Validation, Flyway, Maven
- **Mobile:** Flutter 3.50, Dart 3.14
- **Banco:** PostgreSQL (Neon em produção)

---

## Deploy

| Peça | Serviço | Configuração |
| :--- | :--- | :--- |
| API | Render Web Service | `Dockerfile` do repositório |
| App web | Render Static Site | `npm ci && npm run build` |
| Banco | Neon PostgreSQL | Connection string convertida para JDBC |

Variáveis de ambiente da API no Render: `DB_URL`, `DB_USERNAME`, `DB_PASSWORD`,
`CORS_ORIGINS`. O `PORT` é injetado pelo Render.

**Segurança:** senhas com BCrypt, sessões de 8 horas, todas as rotas `/api/**` exigem
`Authorization: Bearer <token>` (livres: `health`, `auth/login`, `auth/bootstrap`).

**Primeiro admin:** `POST /api/auth/bootstrap` quando não existe nenhum usuário.

---

## Autenticação

`POST /api/auth/login` → `{ token, expiraEm, usuario }`

O token vai em `Authorization: Bearer <token>` nas demais rotas. Sessão de 8 horas,
gravada na tabela `sessoes`.

---

## Contribuindo

A branch `main` é protegida: todo trabalho entra por **pull request** com 1 aprovação.

```bash
git clone https://github.com/marciocoelho1/projeto_integrador.git
cd projeto_integrador
git checkout -b feat/nome-da-alteracao
# ... edite, teste ...
git push -u origin feat/nome-da-alteracao
```

Documentação adicional em [docs/](docs/).
