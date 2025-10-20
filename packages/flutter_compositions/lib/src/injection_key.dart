import 'package:flutter/foundation.dart';

/// A symbol used as a key for injecting values with type safety.
///
/// Similar to Vue 3's `InjectionKey<T>`, this provides a type-safe way to
/// provide and inject values without relying on runtime types, which can
/// cause conflicts when using common types like `String` or `int`.
///
/// ## Why use InjectionKey?
///
/// **Problem with type-based injection:**
/// ```dart
/// // Parent
/// provide('dark');  // Type: String
///
/// // Child
/// final theme = inject<String>();  // Gets 'dark' - but which String?
/// final userName = inject<String>();  // Also gets 'dark' - conflict!
/// ```
///
/// **Solution with InjectionKey:**
/// ```dart
/// // Define keys with specific types
/// final themeKey = InjectionKey<String>('theme');
/// final userNameKey = InjectionKey<String>('userName');
///
/// // Parent
/// provide(themeKey, 'dark');
/// provide(userNameKey, 'Alice');
///
/// // Child
/// final theme = inject(themeKey);  // Gets 'dark'
/// final userName = inject(userNameKey);  // Gets 'Alice'
/// ```
///
/// ## Basic Example
///
/// ```dart
/// // 1. Define the injection key (usually as a global constant or static)
/// final counterKey = InjectionKey<Ref<int>>('counter');
///
/// // 2. Provide the value in a parent component
/// class ParentWidget extends CompositionWidget {
///   @override
///   Widget Function(BuildContext) setup() {
///     final count = ref(0);
///     provide(counterKey, count);
///
///     return (context) => ChildWidget();
///   }
/// }
///
/// // 3. Inject the value in a child component
/// class ChildWidget extends CompositionWidget {
///   @override
///   Widget Function(BuildContext) setup() {
///     final count = inject(counterKey);
///
///     return (context) => Text('Count: ${count.value}');
///   }
/// }
/// ```
///
/// ## Optional Injection
///
/// ```dart
/// final optionalKey = InjectionKey<String>('optional');
///
/// class ChildWidget extends CompositionWidget {
///   @override
///   Widget Function(BuildContext) setup() {
///     // Returns null if not provided
///     final value = inject(optionalKey, defaultValue: null);
///
///     return (context) => Text(value ?? 'No value');
///   }
/// }
/// ```
///
/// ## Complex Types
///
/// ```dart
/// // Define a custom type
/// class AppTheme {
///   const AppTheme(this.mode);
///   final String mode;
/// }
///
/// // Create a key for it
/// final themeKey = InjectionKey<Ref<AppTheme>>('theme');
///
/// // Use it
/// class ParentWidget extends CompositionWidget {
///   @override
///   Widget Function(BuildContext) setup() {
///     final theme = ref(AppTheme('dark'));
///     provide(themeKey, theme);
///
///     return (context) => ChildWidget();
///   }
/// }
///
/// class ChildWidget extends CompositionWidget {
///   @override
///   Widget Function(BuildContext) setup() {
///     final theme = inject(themeKey);
///
///     return (context) => Text('Theme: ${theme.value.mode}');
///   }
/// }
/// ```
///
/// ## Best Practices
///
/// 1. **Define keys as constants:**
///    ```dart
///    // ✅ Good: Reusable and consistent
///    final themeKey = InjectionKey<Ref<AppTheme>>('theme');
///    ```
///
/// 2. **Use descriptive names:**
///    ```dart
///    // ✅ Good: Clear purpose
///    final userAuthKey = InjectionKey<AuthService>('userAuth');
///
///    // ❌ Bad: Unclear
///    final key1 = InjectionKey<String>('k1');
///    ```
///
/// 3. **Group related keys:**
///    ```dart
///    class AppKeys {
///      static final theme = InjectionKey<Ref<AppTheme>>('app.theme');
///      static final locale = InjectionKey<Ref<String>>('app.locale');
///      static final user = InjectionKey<Ref<User?>>('app.user');
///    }
///    ```
///
/// 4. **Use meaningful symbols:**
///    ```dart
///    // ✅ Good: Namespaced and descriptive
///    final key = InjectionKey<T>('feature.component.value');
///
///    // ❌ Bad: Too generic
///    final key = InjectionKey<T>('value');
///    ```
/// {@template immutable}
/// Objects that are immutable cannot have their state changed
/// after construction.
/// {@endtemplate}
@immutable
class InjectionKey<T> {
  /// Creates an injection key with the given [symbol].
  ///
  /// The [symbol] should be unique and descriptive. It's recommended to use
  /// a namespaced format like 'feature.component.value' to avoid conflicts.
  ///
  /// Example:
  /// ```dart
  /// final themeKey = InjectionKey<Ref<AppTheme>>('app.theme');
  /// final counterKey = InjectionKey<Ref<int>>('counter.value');
  /// ```
  const InjectionKey(this.symbol);

  /// The unique symbol used to identify this key.
  final String symbol;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InjectionKey &&
          runtimeType == other.runtimeType &&
          symbol == other.symbol;

  @override
  int get hashCode => symbol.hashCode;

  @override
  String toString() => 'InjectionKey<$T>($symbol)';
}
