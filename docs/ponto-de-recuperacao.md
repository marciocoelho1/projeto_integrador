# Ponto de recuperação — 23/11/2026

Documento de retomada do trabalho. Leia isto antes de continuar.

> **Máquina de origem:** PC do Senac, usuário `marcio.elias.SENACRJEDU`.
> **Projeto:** `C:\Users\marcio.elias.SENACRJEDU\Documents\projeto_integrador`
> Ao continuar em outra máquina, clone o repositório e refaça o ambiente (seção 8).

---

## 1. Objetivo do trabalho

Projeto Integrador do curso do Senac: **SGSST** (Sistema de Gestão de Saúde e Segurança do Trabalho).
A versão web já existe e está publicada. Agora estamos criando a **versão mobile em Flutter**,
dentro da pasta `mobile/` do mesmo repositório (monorepo, no mesmo padrão do repositório de aulas
`aulasFlutterDart`, que tem a API na raiz e o app em `app_epi/`).

**Divisão de trabalho combinada:**
- **Eu (Marcio)** mexo no backend Java e no mobile. Os colegas do grupo **não** mexem no backend
  (por medo de quebrá-lo). Eles entregam as telas e nós integramos.
- O app precisa estar pronto para receber os arquivos dos colegas e para subir no Render/Neon,
  além de gerar APK.

---

## 2. Estado atual do git

- Branch de trabalho: `main`, sincronizada com `origin/main`.
- 2 commits locais à frente do remoto:
  - `35e7ed0` chore: ignore de artefatos Flutter e checagens do app no checklist
  - `b1d0799` mobile: projeto Flutter inicial do app SGSST
- **O que foi alterado depois desses commits** (ainda precisa ser commitado):
  - `mvnw`, `mvnw.cmd`, `.mvn/wrapper/maven-wrapper.properties` — Maven Wrapper criado agora
  - `mobile/lib/**` — toda a base do app (config, core, models, services, screens, widgets)
  - `mobile/android/app/src/main/AndroidManifest.xml` — permissão INTERNET + cleartext
  - `mobile/pubspec.yaml`, `pubspec.lock`, `windows/flutter/generated_plugins.cmake`
  - `mobile/test/widget_test.dart` — testes novos
- Autor configurado localmente: `marciocoelho1 <marcio.coelho.jr1@gmail.com>`.

---

## 3. Backend Java — problemas resolvidos

| Problema | Causa | Solução aplicada |
| :--- | :--- | :--- |
| 100 erros "package org.springframework.http does not exist" | `JAVA_HOME` apontava para o **JDK 11** e o `pom.xml` exige `java.version=17` | Usar **JDK 24** (`C:\Program Files\Java\jdk-24`) |
| Projeto não compilava por falta de Maven | Não existia `mvnw` nem Maven no PATH (o repo nunca teve wrapper) | **Maven Wrapper criado** (`mvnw`, `mvnw.cmd`, `.mvn/`) |

**Verificado:** `mvnw.cmd -B -q clean compile` compilou **150 classes** sem erro, com JDK 24.

O Spring Boot do projeto é o **4.1.1**, que roda em Java 17+ (portanto 24 funciona). O
`<java.version>17</java.version>` é só o alvo de compilação — **não mudar**.

O `Dockerfile` continua em Java 17 (`maven:3.9-eclipse-temurin-17` / `eclipse-temurin:17-jre`),
então o deploy no Render não muda. Desenvolvimento local em 24, produção em 17.

**Comandos do backend (da raiz do projeto):**

```bat
set JAVA_HOME=C:\Program Files\Java\jdk-24
mvnw.cmd clean compile
mvnw.cmd spring-boot:run
mvnw.cmd spring-boot:run -Dspring-boot.run.profiles=demo
```

---

## 4. Banco de dados — PENDENTE

**Situação encontrada:**
- Dois PostgreSQL rodando:
  - **9.6** na porta **5432** (é quem o projeto usa por padrão)
  - **15** na porta **5433**
- A senha do usuário `postgres` **não é a padrão** e não foi obtida — é aqui que o trabalho parou.

**O que falta fazer:**

1. Acessar o PostgreSQL 9.6 (porta 5432) como `postgres`.
2. Criar o banco e o usuário que o projeto espera:

```sql
CREATE DATABASE sgsst;
CREATE USER sgsst_app WITH PASSWORD 'senha_forte_aqui';
GRANT ALL PRIVILEGES ON DATABASE sgsst TO sgsst_app;
\c sgsst
GRANT ALL ON SCHEMA public TO sgsst_app;
```

3. As **tabelas não precisam ser criadas**: o Flyway cria sozinho na primeira inicialização
   (`src/main/resources/db/migration/V1…V9`).

**Variáveis de ambiente do backend** (com os defaults do `application.properties`):

| Variável | Default | Observação |
| :--- | :--- | :--- |
| `DB_URL` | `jdbc:postgresql://127.0.0.1:5432/sgsst` | |
| `DB_USERNAME` | `sgsst_app` | |
| `DB_PASSWORD` | vazio | **precisa ser definida** |
| `PORT` | 8080 | o Render injeta |

**Contas de demonstração:** só existem com o perfil `demo`
(`SPRING_PROFILES_ACTIVE=demo`): `admin` / `123456` e `colaborador` / `123456`.
Sem o perfil, criar o primeiro admin por `POST /api/auth/bootstrap` (exemplo no README).

---

## 5. Mobile Flutter — o que já está feito

Estrutura criada (padrão das aulas: `models/`, `services/`, `screens/`, mais `widgets/`,
`config/` e `core/`):

```text
mobile/lib/
├── main.dart                          # inicializa intl pt_BR, restaura sessão, decide login/MainScreen
├── config/api_config.dart             # localhost no web, 10.0.2.2 no emulador, --dart-define
├── core/app_theme.dart                # design system do mockup (cores, tipografia, CartaoSgsst)
├── models/
│   ├── indicador.dart                 # espelho do DashboardIndicadoresResponse do Java
│   └── sessao.dart                    # token + usuário
├── services/
│   ├── auth_service.dart              # login, persistência do token (shared_preferences), logout
│   └── dashboard_service.dart         # GET /api/dashboard/indicadores com Bearer
├── screens/
│   ├── login_screen.dart              # visual do mockup
│   ├── main_screen.dart               # tabbar de 4 destinos; só Painel ativo
│   └── dashboard_screen.dart          # KPIs + conformidade + alertas
└── widgets/
    ├── kpi_card.dart
    ├── conformidade_card.dart
    └── alerta_card.dart
```

**Dependências no `pubspec.yaml`:** `http ^1.6.0`, `shared_preferences ^2.5.6`, `intl ^0.20.3`.

**Verificado:** `flutter analyze` → *No issues found*; `flutter test` → 2 testes passando.

### Design system (extraído do mockup `opcao-1-carteira-digital.html`)

| Token | Cor |
| :--- | :--- |
| petróleo (primária) | `#0B3B4A` |
| areia (fundo) | `#F6F1E7` |
| cartão | `#FFFFFF` |
| cinza (texto secundário) | `#5A6B70` |
| válido | `#1B7F5A` |
| vencendo | `#B8860B` |
| vencido | `#B3392F` |
| hairline | `#EAE3D6` |

Tipografia Inter (700/600/400), cartões com raio 20, tabbar de 52 px, botões de 56 px.

> **Pendência da fonte:** o mockup usa **Inter**, mas o app ainda usa a fonte do sistema.
> Para ter paridade visual, baixar `Inter-Regular/SemiBold/Bold.ttf` em `mobile/assets/fonts/`
> e registrar em `flutter.fonts` no `pubspec.yaml`.

### Escopo da tela de Dashboard

O Dashboard **web** (`src/app/tela-dashboard/`) tem 8 blocos e carrega **8 rotas em paralelo**
(`forkJoin`). No mobile só foram implementados os 3 blocos que usam **apenas**
`GET /api/dashboard/indicadores`:

1. KPIs (colaboradores, EPIs, certificações, entregas)
2. Conformidade de treinamentos
3. Precisa de atenção (alertas)

**Faltam os blocos que dependem de outras rotas:** heatmap NR × setor, colaboradores por setor,
EPIs em estoque crítico, entregas por mês, últimas entregas e atividade recente. Eles exigem
`/api/colaboradores`, `/api/epis`, `/api/entregas-epis`, `/api/vinculos`, `/api/treinamentos`,
`/api/auditoria`.

**Recomendação registrada:** criar no backend um endpoint `GET /api/dashboard/mobile` que devolva
tudo já agregado numa resposta, em vez do app fazer 8 requisições. Isso é mudança no Java.

---

## 6. Erros já investigados (para não repetir diagnóstico)

| Sintoma | Causa | Solução |
| :--- | :--- | :--- |
| `ERR_CONNECTION_REFUSED` em `:8080/api/auth/login` | (a) backend não estava no ar; (b) `--dart-define` enviava `:8080/api` **sem host** | Subir o backend; rodar sem `--dart-define` ou com a URL completa |
| 100 erros de `org.springframework.*` | `JAVA_HOME` no JDK 11 | JDK 24 |
| `mvn` não reconhecido | sem Maven / sem wrapper | `mvnw` criado |
| `flutter create` travando em pipe | encadeamento de `flutter` com pipe no terminal do agente | redirecionar saída para arquivo |

**Cuidado com o `--dart-define`:** o `ApiConfig` usa `String.fromEnvironment`. Se a variável for
passada malformada, `baseUrl` fica sem host e toda chamada falha. Formato correto:

```bat
flutter run -d chrome --web-port=4200 --dart-define=API_BASE_URL=http://localhost:8080/api
```

**Porta 4200 é obrigatória no Flutter Web**, porque o `CorsConfig` do backend libera exatamente
`http://localhost:4200`. Outra porta = bloqueio de CORS.

---

## 7. Comandos do mobile

```bat
cd mobile
flutter pub get
flutter analyze
flutter test
flutter run -d chrome --web-port=4200
flutter build apk --release --dart-define=API_BASE_URL=https://sgsst-api-r3iv.onrender.com/api
```

**Ambiente verificado nesta máquina:** Flutter 3.47.7 / Dart 3.13.5, Android SDK 36.1.0,
Android Studio com JDK 17 embutido (usado pelo Gradle). Emulador Android **não criado**
(`flutter emulators --create --name pixel_sgsst`). Windows desktop **não funciona** aqui
(falta o workload "Desenvolvimento para desktop com C++" no Visual Studio).

---

## 8. Retomar em outra máquina — checklist

1. `git clone https://github.com/marciocoelho1/projeto_integrador.git`
2. `git config user.name "marciocoelho1"` e `user.email "marcio.coelho.jr1@gmail.com"`
3. Instalar: **JDK 17 ou 24**, **Flutter 3.47+**, **PostgreSQL**, **Android Studio** (para o APK).
4. Backend: `mvnw.cmd clean compile` (no Linux/macOS: `./mvnw clean compile`).
5. Banco: criar `sgsst` + usuário `sgsst_app` (seção 4) e definir `DB_PASSWORD`.
6. `mvnw.cmd spring-boot:run -Dspring-boot.run.profiles=demo`
7. Testar: `curl http://localhost:8080/api/health`
8. Mobile: `cd mobile && flutter pub get && flutter run -d chrome --web-port=4200`
9. Login com `admin` / `123456`.

---

## 9. Deploy (Render / Neon)

| Peça | Onde | Detalhe |
| :--- | :--- | :--- |
| API Java | Render Web Service via `Dockerfile` | Java 17, `DB_URL`/`DB_USERNAME`/`DB_PASSWORD`/`CORS_ORIGINS` |
| Frontend Angular | Render Static Site | `npm ci` + `npm run build` |
| Banco | Neon (PostgreSQL) | connection string convertida para JDBC |
| **App Flutter Web** | Render Static Site **(não configurado ainda)** | Precisa do Flutter no build ou de um Dockerfile |
| **APK** | **build local** | assinatura com keystore (ainda não configurada) |

Endereços em uso: API `https://sgsst-api-r3iv.onrender.com`, frontend
`https://sgsst-frontend-mvbu.onrender.com`.

**Atenção:** se o app Flutter Web for publicado num domínio novo, adicionar essa origem em
`CORS_ORIGINS` na API. Se o app Flutter Web subir no Render, lembrar de
`--dart-define=API_BASE_URL=...` no build command. O APK **não** precisa de CORS.

**Ponto delicado:** o plano free do Render hiberna; a primeira requisição pode levar ~115 s.
O `ApiConfig.timeout` está em 15 s — para builds de produção, aumentar.

---

## 10. Pendências em aberto (ordem sugerida)

1. **Criar o banco `sgsst` e o usuário `sgsst_app`** (bloqueia o backend). Seção 4.
2. Subir o backend com perfil `demo` e validar o login no app.
3. Baixar e registrar a fonte **Inter**.
4. Configurar a **keystore** para gerar o APK de release.
5. Decidir sobre o `GET /api/dashboard/mobile` para os 5 blocos restantes do Dashboard.
6. Integrar as telas dos colegas na `MainScreen` (destinos Treinamentos, EPIs, Perfil).
