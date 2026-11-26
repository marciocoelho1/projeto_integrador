# SGSST Flutter

Projeto convertido para Flutter/Dart, com interface adaptável para celular e computador.

## Estrutura

- `lib/main.dart`: ponto de entrada isolado do restante da aplicação.
- `lib/features/configuracoes/configuracoes_page.dart`: tela e componentes da área de configurações.

## Executar

Instale o Flutter SDK e, na pasta do projeto, rode:

```bash
flutter pub get
flutter run -d chrome       # navegador no computador
flutter run -d windows      # aplicativo desktop Windows (requer toolchain C++)
flutter run                 # selecione um dispositivo conectado
```

Para gerar versão web:

```bash
flutter build web
```

## Sobre os dados

A tela contém dados demonstrativos locais para validar a navegação e os formulários. O TypeScript recebido usa serviços externos (`AcessoService`, `AuditService` e `ConfiguracoesGlobaisService`) e endpoints da API. Como os arquivos desses serviços e os contratos completos da API não foram enviados, a persistência/autenticação não foi inventada nem conectada. Os pontos de integração devem ser adicionados em uma camada `services/` quando esses contratos estiverem disponíveis.

A interface aplica a paleta petróleo/areia da referência e reorganiza navegação, tabelas e formulários para telas pequenas e grandes.
