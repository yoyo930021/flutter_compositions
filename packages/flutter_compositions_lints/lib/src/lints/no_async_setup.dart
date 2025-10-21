import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

/// Ensures that setup() methods are not async.
///
/// The setup() method must synchronously return a builder function.
/// Async operations should be performed inside lifecycle hooks like
/// onMounted().
///
/// **Bad:**
/// ```dart
/// @override
/// Future<Widget Function(BuildContext)> setup() async { // ❌ Async setup
///   await loadData();
///   return (context) => Text('Data loaded');
/// }
/// ```
///
/// **Good:**
/// ```dart
/// @override
/// Widget Function(BuildContext) setup() {
///   final data = ref<String?>(null);
///
///   onMounted(() async {
///     data.value = await loadData(); // ✅ Async in lifecycle hook
///   });
///
///   return (context) => Text(data.value ?? 'Loading...');
/// }
/// ```
class NoAsyncSetup extends DartLintRule {
  /// Creates a new instance of [NoAsyncSetup].
  const NoAsyncSetup() : super(code: _code);

  static const _code = LintCode(
    name: 'flutter_compositions_no_async_setup',
    problemMessage: 'The setup() method must not be async.',
    correctionMessage: 'Remove async keyword. Use onMounted() or '
        'onUnmounted() for async operations.',
  );

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addMethodDeclaration((node) {
      // Only check setup() methods
      if (node.name.lexeme != 'setup') return;

      // Check if this is inside a CompositionWidget
      final classNode = node.thisOrAncestorOfType<ClassDeclaration>();
      if (classNode == null) return;

      final extendsClause = classNode.extendsClause;
      if (extendsClause == null) return;

      final superclass = extendsClause.superclass.name2.lexeme;
      if (superclass != 'CompositionWidget') return;

      // Check if the method body is async
      final body = node.body;
      if (body is BlockFunctionBody && body.isAsynchronous) {
        reporter.atNode(node, _code);
        return;
      }

      if (body is ExpressionFunctionBody && body.isAsynchronous) {
        reporter.atNode(node, _code);
      }
    });
  }
}
