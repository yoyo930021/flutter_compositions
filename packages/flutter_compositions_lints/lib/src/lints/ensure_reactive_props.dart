import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

/// Ensures that widget properties are accessed through `widget()` in setup()
/// to maintain reactivity.
///
/// **Bad:**
/// ```dart
/// @override
/// Widget Function(BuildContext) setup() {
///   final name = this.displayName; // ❌ Not reactive
///   return (context) => Text(name);
/// }
/// ```
///
/// **Good:**
/// ```dart
/// @override
/// Widget Function(BuildContext) setup() {
///   final props = widget();
///   final name = computed(() => props.value.displayName); // ✅ Reactive
///   return (context) => Text(name.value);
/// }
/// ```
class EnsureReactiveProps extends DartLintRule {
  /// Creates a new instance of [EnsureReactiveProps].
  const EnsureReactiveProps() : super(code: _code);

  static const _code = LintCode(
    name: 'flutter_compositions_ensure_reactive_props',
    problemMessage:
        'Widget properties should be accessed through widget() '
        'for reactivity.',
    correctionMessage:
        'Use widget() to get a reactive reference, then access '
        'properties through .value',
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

      // Visit all property accesses in setup()
      node.visitChildren(_PropertyAccessVisitor(reporter, node));
    });
  }
}

class _PropertyAccessVisitor extends RecursiveAstVisitor<void> {
  _PropertyAccessVisitor(this.reporter, this.setupMethod);

  final ErrorReporter reporter;
  final MethodDeclaration setupMethod;
  bool _insideReturnedBuilder = false;

  @override
  void visitFunctionExpression(FunctionExpression node) {
    // Check if this is the returned builder function (context) => ...
    final parent = node.parent;
    if (parent is ReturnStatement) {
      _insideReturnedBuilder = true;
      super.visitFunctionExpression(node);
      _insideReturnedBuilder = false;
      return;
    }
    super.visitFunctionExpression(node);
  }

  @override
  void visitPropertyAccess(PropertyAccess node) {
    // Skip if we're inside the returned builder function
    if (_insideReturnedBuilder) {
      super.visitPropertyAccess(node);
      return;
    }

    // Check for direct property access on 'this'
    final target = node.target;
    if (target is ThisExpression) {
      // Allow 'this.widget()' calls
      if (node.propertyName.name == 'widget') {
        super.visitPropertyAccess(node);
        return;
      }

      // Report direct property access
      reporter.atNode(node, EnsureReactiveProps._code);
    }

    super.visitPropertyAccess(node);
  }

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    // Skip if we're inside the returned builder
    if (_insideReturnedBuilder) {
      super.visitSimpleIdentifier(node);
      return;
    }

    // Check if this identifier refers to a field of the widget
    final parent = node.parent;

    // Skip if it's part of a property access we already checked
    if (parent is PropertyAccess && parent.propertyName == node) {
      super.visitSimpleIdentifier(node);
      return;
    }

    // Skip if it's a method call
    if (parent is MethodInvocation && parent.methodName == node) {
      super.visitSimpleIdentifier(node);
      return;
    }

    // Check if this is a field reference
    final element = node.element;
    if (element != null && element.kind.toString() == 'FIELD') {
      // Check if it's a field of the current widget class
      final enclosingClass = element.enclosingElement2;
      final currentClass = setupMethod.thisOrAncestorOfType<ClassDeclaration>();

      final declaredElement = currentClass?.declaredFragment?.element;
      if (enclosingClass != null &&
          declaredElement != null &&
          enclosingClass == declaredElement) {
        reporter.atNode(node, EnsureReactiveProps._code);
      }
    }

    super.visitSimpleIdentifier(node);
  }
}
