# Ajuda e suporte - Flutter

Projeto Flutter independente contendo somente a tela Ajuda e suporte e um `main.dart` para executá-la diretamente.

## Executar

```bash
flutter pub get
flutter run -d chrome
```

A tela usa `http` e espera os endpoints abaixo por padrão:

- `GET /chamados`
- `POST /chamados`
- `PUT /chamados/{id}`

A URL base padrão está configurada como `http://localhost:3000/api` no widget. Ajuste-a em `lib/main.dart` ou na chamada de `AjudaSuporteScreen` conforme sua API.
