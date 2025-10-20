import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

/// Ensures composition APIs are not called conditionally in setup().
///
/// Composition APIs like `ref()`, `computed()`, `watch()`, `useController()`,
/// etc. should be called unconditionally at the top level of setup(), similar
/// to React Hooks rules.
///
/// This ensures:
/// - Consistent ordering of composition calls across renders
/// - Predictable reactivity behavior
/// - Easier to reason about component lifecycle
///
/// **Bad:**
/// ```dart
/// @override
/// Widget Function(BuildContext) setup() {
///   if (someCondition) {
///     final count = ref(0); // ❌ Conditional composition API call
///   }
///
///   for (var i = 0; i < 10; i++) {
///     final item = ref(i); // ❌ Inside loop
///   }
///
///   return (context) => Text('Hello');
/// }
/// ```
///
/// **Good:**
/// ```dart
/// @override
/// Widget Function(BuildContext) setup() {
///   // ✅ Composition APIs at top level
///   final count = ref(0);
///   final items = ref(<int>[]);
///
///   // Conditional logic is fine for non-composition code
///   if (someCondition) {
///     count.value = 10; // ✅ OK to modify values conditionally
///   }
///
///   return (context) => Text('Count: ${count.value}');
/// }
/// ```
class NoConditionalComposition extends DartLintRule {
  /// Creates a new instance of [NoConditionalComposition].
  const NoConditionalComposition() : super(code: _code);

  static const _code = LintCode(
    name: 'flutter_compositions_no_conditional_composition',
    problemMessage:
        'Composition API calls must not be inside conditionals or loops. '
        'Call composition APIs unconditionally at the top level of setup().',
    correctionMessage:
        'Move the composition API call to the top level of '
        'setup(). You can still use conditional logic to set values.',
    errorSeverity: ErrorSeverity.ERROR,
  );

  // Composition API function names to check
  static const _compositionApis = {
    // Core reactivity
    'ref',
    'computed',
    'writableComputed',
    'customRef',
    'watch',
    'watchEffect',

    // Lifecycle
    'onMounted',
    'onUnmounted',

    // Dependency injection
    'provide',
    'inject',

    // Listenable helpers
    'manageListenable',
    'manageChangeNotifier',
    'manageValueListenable',

    // Controller helpers
    'useScrollController',
    'usePageController',
    'useFocusNode',
    'useTextEditingController',

    // Async helpers
    'useStream',
    'useStreamController',
    'useFuture',

    // Animation helpers
    'useSingleTickerProvider',
    'useAnimationController',
    'manageAnimation',

    // Framework helpers
    'useContext',
    'useSearchController',
    'useAppLifecycleState',
  };

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addMethodDeclaration((node) {
      // Only check setup() methods
      if (node.name.lexeme != 'setup') return;

      // Check if this is inside a CompositionWidget or CompositionBuilder
      final classNode = node.thisOrAncestorOfType<ClassDeclaration>();
      if (classNode != null) {
        final extendsClause = classNode.extendsClause;
        if (extendsClause != null) {
          final superclass = extendsClause.superclass.name2.lexeme;
          if (superclass != 'CompositionWidget') return;
        } else {
          return;
        }
      }

      // Visit the setup method body to find composition API calls
      final visitor = _ConditionalCompositionVisitor(reporter);
      node.body.visitChildren(visitor);
    });
  }
}

class _ConditionalCompositionVisitor extends RecursiveAstVisitor<void> {
  /// Creates a new instance of [_ConditionalCompositionVisitor].
  _ConditionalCompositionVisitor(this.reporter);

  final ErrorReporter reporter;

  // Track nesting depth of conditional/loop structures
  int _conditionalDepth = 0;
  int _loopDepth = 0;

  bool get _isInsideConditionalOrLoop =>
      _conditionalDepth > 0 || _loopDepth > 0;

  @override
  void visitIfStatement(IfStatement node) {
    _conditionalDepth++;
    super.visitIfStatement(node);
    _conditionalDepth--;
  }

  @override
  void visitConditionalExpression(ConditionalExpression node) {
    _conditionalDepth++;
    super.visitConditionalExpression(node);
    _conditionalDepth--;
  }

  @override
  void visitForStatement(ForStatement node) {
    _loopDepth++;
    super.visitForStatement(node);
    _loopDepth--;
  }

  @override
  void visitWhileStatement(WhileStatement node) {
    _loopDepth++;
    super.visitWhileStatement(node);
    _loopDepth--;
  }

  @override
  void visitDoStatement(DoStatement node) {
    _loopDepth++;
    super.visitDoStatement(node);
    _loopDepth--;
  }

  @override
  void visitSwitchStatement(SwitchStatement node) {
    _conditionalDepth++;
    super.visitSwitchStatement(node);
    _conditionalDepth--;
  }

  @override
  void visitSwitchExpression(SwitchExpression node) {
    _conditionalDepth++;
    super.visitSwitchExpression(node);
    _conditionalDepth--;
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (_isInsideConditionalOrLoop) {
      final methodName = node.methodName.name;

      // Check if this is a composition API call
      if (NoConditionalComposition._compositionApis.contains(methodName)) {
        reporter.reportErrorForNode(
          NoConditionalComposition._code,
          node,
        );
      }
    }

    super.visitMethodInvocation(node);
  }

  @override
  void visitFunctionExpression(FunctionExpression node) {
    // Don't traverse into nested functions (like the returned builder)
    // Composition APIs are allowed inside the returned builder function
    // We only check the direct body of setup()

    // Check if this is the returned builder function
    final parent = node.parent;
    if (parent is ReturnStatement || parent is ExpressionStatement) {
      // This is likely the returned builder - don't check inside it
      return;
    }

    super.visitFunctionExpression(node);
  }
}
