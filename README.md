# Flutter Compositions Monorepo

[![Test](https://github.com/yoyo930021/flutter_compositions/actions/workflows/test.yml/badge.svg)](https://github.com/yoyo930021/flutter_compositions/actions/workflows/test.yml)
[![Documentation](https://github.com/yoyo930021/flutter_compositions/actions/workflows/docs.yml/badge.svg)](https://github.com/yoyo930021/flutter_compositions/actions/workflows/docs.yml)

This repository uses a Melos-style monorepo layout so related packages can evolve together.

- `packages/flutter_compositions`: Reactive composition primitives for Flutter inspired by the Vue 3 Composition API. Includes an `example/` Flutter app demonstrating usage.
- `packages/<future-packages>`: Add additional packages here (for example lint rules or tooling that builds on top of `flutter_compositions`).
- `templates/flutter_package_template`: Vanilla Flutter package scaffold generated via `flutter create --template=package` for quick reference.

## Getting Started

```sh
flutter pub global activate melos
melos bootstrap
```

After bootstrapping you can run the shared scripts:

```sh
melos run analyze
melos run test
```

Each package can still be managed directly with `flutter pub get`, `flutter test`, etc. The `example/` app inside `packages/flutter_compositions` is a full Flutter project you can run with `flutter run`.

## Acknowledgments

Flutter Compositions is built upon excellent work from the open source community:

- **[alien_signals](https://pub.dev/packages/alien_signals)** - Provides the core reactivity system with fine-grained signal-based state management
- **[flutter_hooks](https://pub.dev/packages/flutter_hooks)** - Inspired composable patterns and demonstrated the viability of composition APIs in Flutter

We are grateful to these projects and their maintainers for paving the way.
