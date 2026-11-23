# Controle de EPIs — Flutter

Projeto mínimo com a tela de gestão de EPIs.

## Executar

```bash
flutter pub get
flutter run -d chrome
```

A tela espera uma API HTTP. Por padrão, usa `http://localhost:3000/api`.
Para configurar outra URL:

```bash
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:3000/api
```

Se ainda não tiver as plataformas web/windows no projeto, dentro desta pasta execute:

```bash
flutter create --platforms=web,windows .
```
