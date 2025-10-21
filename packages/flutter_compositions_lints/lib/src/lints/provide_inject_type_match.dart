import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

/// Validates that provide/inject calls use matching types.
///
/// This helps catch type mismatches at lint time rather than runtime.
///
/// **Bad:**
/// ```dart
/// // Parent
/// provide<Ref<String>>(myValue);
///
/// // Child
/// final value = inject<Ref<int>>(); // ❌ Type mismatch!
/// ```
///
/// **Good:**
/// ```dart
/// // Parent
/// provide<Ref<AppTheme>>(theme); // Custom type
///
/// // Child
/// final theme = inject<Ref<AppTheme>>(); // ✅ Matching type
/// ```
///
/// **Note:** This rule provides warnings about common types that might
/// conflict. Always use custom data classes for provide/inject to avoid type
/// collisions.
class ProvideInjectTypeMatch extends DartLintRule {
  /// Creates a new instance of [ProvideInjectTypeMatch].
  const ProvideInjectTypeMatch() : super(code: _code);

  static const _code = LintCode(
    name: 'flutter_compositions_provide_inject_type_match',
    problemMessage: 'Avoid using common types like Ref<String> or Ref<int> '
        'with provide/inject.',
    correctionMessage: 'Use custom data classes to avoid type conflicts. '
        'Example: class AppTheme { ... }, then '
        'provide<Ref<AppTheme>>(theme)',
  );

  // Common types that are likely to cause conflicts
  static const _commonTypes = {
    'String',
    'int',
    'double',
    'bool',
    'num',
    'List',
    'Map',
    'Set',
  };

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addMethodInvocation((node) {
      final methodName = node.methodName.name;

      // Check provide() calls
      if (methodName == 'provide') {
        _checkProvideCall(node, reporter);
      }

      // Check inject() calls
      if (methodName == 'inject') {
        _checkInjectCall(node, reporter);
      }
    });
  }

  void _checkProvideCall(MethodInvocation node, ErrorReporter reporter) {
    final typeArgs = node.typeArguments;
    if (typeArgs == null) return;

    for (final typeArg in typeArgs.arguments) {
      if (_isCommonType(typeArg.toString())) {
        reporter.atNode(node.methodName, _code);
        break;
      }
    }
  }

  void _checkInjectCall(MethodInvocation node, ErrorReporter reporter) {
    final typeArgs = node.typeArguments;
    if (typeArgs == null) return;

    for (final typeArg in typeArgs.arguments) {
      if (_isCommonType(typeArg.toString())) {
        reporter.atNode(node.methodName, _code);
        break;
      }
    }
  }

  bool _isCommonType(String typeString) {
    // Check if the type contains common types
    // e.g., "Ref<String>", "Ref<int>", "ComputedRef<bool>"
    for (final commonType in _commonTypes) {
      if (typeString.contains('<$commonType>') ||
          typeString.contains('<$commonType?>') ||
          typeString.endsWith(commonType)) {
        return true;
      }
    }
    return false;
  }
}
