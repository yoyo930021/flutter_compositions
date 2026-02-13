import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/src/dart/error/lint_codes.dart';

/// Suggests using `.raw` instead of `.value` for controller refs in builders.
///
/// When passing controllers to widgets inside the builder function,
/// using `.value` creates an unnecessary reactive dependency that causes
/// rebuilds. Using `.raw` reads the controller without tracking.
class PreferRawController extends AnalysisRule {
  PreferRawController()
    : super(
        name: 'flutter_compositions_prefer_raw_controller',
        description:
            "Use '.raw' instead of '.value' for controllers in builders.",
      );

  static const LintCode code = LintCode(
    'flutter_compositions_prefer_raw_controller',
    "Use '.raw' instead of '.value' for controllers in the builder function. "
        "'.value' creates an unnecessary reactive dependency.",
    correctionMessage: "Replace '.value' with '.raw' to avoid unnecessary "
        'rebuilds when passing controllers to widgets.',
  );

  @override
  LintCode get diagnosticCode => code;

  // Named parameters that typically accept controllers
  static const controllerParamNames = {
    'controller',
    'focusNode',
    'scrollController',
    'animationController',
  };

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

  final PreferRawController rule;

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

    // Find the returned builder function
    final body = node.body;
    if (body is! BlockFunctionBody) return;

    for (final statement in body.block.statements) {
      if (statement is ReturnStatement) {
        final expression = statement.expression;
        if (expression is FunctionExpression) {
          _checkBuilderFunction(expression);
        }
      }
    }
  }

  void _checkBuilderFunction(FunctionExpression builder) {
    final bodyVisitor = _BuilderVisitor(rule);
    builder.body.visitChildren(bodyVisitor);
  }
}

class _BuilderVisitor extends RecursiveAstVisitor<void> {
  _BuilderVisitor(this.rule);

  final PreferRawController rule;

  @override
  void visitNamedExpression(NamedExpression node) {
    final paramName = node.name.label.name;

    // Only check controller-related parameters
    if (PreferRawController.controllerParamNames.contains(paramName)) {
      final expression = node.expression;

      // Check if it's accessing .value on something
      if (expression is PropertyAccess &&
          expression.propertyName.name == 'value') {
        rule.reportAtNode(expression);
      } else if (expression is PrefixedIdentifier &&
          expression.identifier.name == 'value') {
        rule.reportAtNode(expression);
      }
    }

    super.visitNamedExpression(node);
  }
}
