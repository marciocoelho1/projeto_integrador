# Ajuda e Suporte — Área do Colaborador (Flutter)

Tela convertida dos arquivos Angular enviados.

## Funcionalidades
- Carrega somente os chamados do usuário autenticado usando `GET /chamados?meus=true`.
- Permite abrir chamado usando `POST /chamados` com `tipo` e `descricao`.
- Exibe Tipo, Descrição, Usuário e Status.
- Não permite ao colaborador alterar o status.

## API
Por padrão, a tela usa `http://localhost:3000/api`.
Se necessário, altere `apiBaseUrl` em `lib/main.dart` ao instanciar
`AjudaSuporteColaboradorScreen`.

## Executar
Dentro da pasta do projeto:

```bash
flutter create --platforms=web .
flutter pub get
flutter run -d chrome
```

Em Android Emulator, `localhost` normalmente deve ser substituído por
`10.0.2.2` para acessar a máquina host.
