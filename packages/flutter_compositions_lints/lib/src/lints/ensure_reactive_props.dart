import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/src/dart/error/lint_codes.dart';

/// Ensures that widget properties are accessed through `widget()` in setup()
/// to maintain reactivity.
class EnsureReactiveProps extends AnalysisRule {
  EnsureReactiveProps()
    : super(
        name: 'flutter_compositions_ensure_reactive_props',
        description:
            'Widget properties should be accessed through widget() for reactivity.',
      );

  static const LintCode code = LintCode(
    'flutter_compositions_ensure_reactive_props',
    'Widget properties should be accessed through widget() '
        'for reactivity.',
    correctionMessage:
        'Use widget() to get a reactive reference, then access '
        'properties through .value',
  );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    var visitor = _Visitor(this);
    registry.addMethodDeclaration(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  _Visitor(this.rule);

  final EnsureReactiveProps rule;

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    // Only check setup() methods
    if (node.name.lexeme != 'setup') return;

    // Check if this is inside a CompositionWidget
    final classNode = node.thisOrAncestorOfType<ClassDeclaration>();
    if (classNode == null) return;

    final extendsClause = classNode.extendsClause;
    if (extendsClause == null) return;

    final superclass = extendsClause.superclass.name.lexeme;
    if (superclass != 'CompositionWidget') return;

    // Visit all property accesses in setup()
    node.visitChildren(_PropertyAccessVisitor(rule, node));
  }
}

class _PropertyAccessVisitor extends RecursiveAstVisitor<void> {
  _PropertyAccessVisitor(this.rule, this.setupMethod);

  final EnsureReactiveProps rule;
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
      rule.reportAtNode(node);
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
      final enclosingClass = element.enclosingElement;
      final currentClass =
          setupMethod.thisOrAncestorOfType<ClassDeclaration>();

      final declaredElement = currentClass?.declaredFragment?.element;
      if (enclosingClass != null &&
          declaredElement != null &&
          enclosingClass == declaredElement) {
        rule.reportAtNode(node);
      }
    }

    super.visitSimpleIdentifier(node);
  }
}
