# Flutter & Dart Architectural Guidelines

Guidelines for AI agents writing production-quality Flutter and Dart code.

---

## 1. State Management Discipline

- **Vanilla First**: Prefer `ChangeNotifier` and `ValueNotifier` over third-party state managers.
- **Single Source of Truth**: Controllers own mutable business logic; widgets remain as thin display layers.
- **Disposal**: Always implement `dispose()` on controllers, focus nodes, text editing controllers, and streams to prevent memory leaks.

```dart
class CounterController extends ChangeNotifier {
  int _count = 0;
  int get count => _count;

  void increment() {
    _count++;
    notifyListeners();
  }
}
```

---

## 2. Widget Tree Optimization

- **Const Constructors**: Always use `const` widgets whenever properties are immutable. This avoids unnecessary widget rebuilds.
- **Extract Subtrees**: Break down deep widget trees into small, focused private widgets or helper classes rather than massive nested `build()` methods.
- **Builder Pattern**: Use `ListView.builder` or `CustomScrollView` with `SliverList` for long or dynamic collections. Avoid instantiating hundreds of widgets in standard `Column` or `Row`.

---

## 3. Cross-Platform Guarding

- Standard `dart:io` APIs (such as `Directory`, `File`, `Process.run`) fail on Flutter Web.
- Guard desktop-only or filesystem code:

```dart
import 'package:flutter/foundation.dart';
import 'dart:io' as io;

bool get isDesktopPlatform =>
    !kIsWeb && (io.Platform.isWindows || io.Platform.isMacOS || io.Platform.isLinux);
```

---

## 4. Error Handling and Null Safety

- Use Dart 3.x patterns and exhaustive `switch` statements over enums and sealed classes.
- Avoid force unwraps (`!`) unless guaranteed by prior null check logic.
- Wrap asynchronous operations in `try / catch` blocks and provide user feedback via `SnackBar` or status surfaces.

---

## 5. Verification Commands

Always run these verification commands before marking a task complete:

```powershell
# Format code
dart format .

# Check for warnings and lints
flutter analyze
dart analyze

# Run unit tests
flutter test
```
