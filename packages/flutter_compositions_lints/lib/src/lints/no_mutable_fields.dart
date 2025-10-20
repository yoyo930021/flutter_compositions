import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

/// Ensures CompositionWidget fields are final.
///
/// All mutable state should be managed through `ref()` or `computed()` in
/// setup(). Widget fields should be immutable props passed from the parent.
///
/// **Bad:**
/// ```dart
/// class MyWidget extends CompositionWidget {
///   MyWidget({required this.count}); // ❌ Missing 'const'
///   int count; // ❌ Mutable field
///
///   @override
///   Widget Function(BuildContext) setup() { ... }
/// }
/// ```
///
/// **Good:**
/// ```dart
/// class MyWidget extends CompositionWidget {
///   const MyWidget({super.key, required this.count}); // ✅ const constructor
///   final int count; // ✅ final field
///
///   @override
///   Widget Function(BuildContext) setup() {
///     // Mutable state in ref
///     final internalCount = ref(0); // ✅ Mutable via ref
///     ...
///   }
/// }
/// ```
class NoMutableFields extends DartLintRule {
  /// Creates a new instance of [NoMutableFields].
  const NoMutableFields() : super(code: _code);

  static const _code = LintCode(
    name: 'flutter_compositions_no_mutable_fields',
    problemMessage:
        'CompositionWidget fields must be final. Use ref() for '
        'mutable state.',
    correctionMessage:
        'Make the field final. Move mutable state into ref() '
        'or computed() in setup().',
    errorSeverity: ErrorSeverity.WARNING,
  );

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addClassDeclaration((node) {
      // Check if this extends CompositionWidget
      final extendsClause = node.extendsClause;
      if (extendsClause == null) return;

      final superclass = extendsClause.superclass.name2.lexeme;
      if (superclass != 'CompositionWidget') return;

      // Check all field declarations
      for (final member in node.members) {
        if (member is FieldDeclaration) {
          // Skip static fields
          if (member.isStatic) continue;

          // Check if fields are final
          if (!member.fields.isFinal && !member.fields.isConst) {
            for (final variable in member.fields.variables) {
              reporter.reportErrorForNode(
                _code,
                variable,
              );
            }
          }
        }
      }
    });
  }
}
