import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/src/dart/error/lint_codes.dart';

/// Prevents logic inside the builder function returned by setup().
///
/// The builder function should only build the widget tree. All logic
/// (conditionals, computations, side effects) should be in setup() using
/// `computed`, `watch`, or composables. The only exception is props
/// destructuring via pattern variable declarations.
class NoLogicInBuilder extends AnalysisRule {
  NoLogicInBuilder()
    : super(
        name: 'flutter_compositions_no_logic_in_builder',
        description:
            'Do not place logic inside the builder function. '
            'Move computations and conditionals to setup().',
      );

  static const LintCode code = LintCode(
    'flutter_compositions_no_logic_in_builder',
    'Do not place logic inside the builder function. '
        'Move computations and conditionals to setup().',
    correctionMessage:
        'Move this logic into setup() using computed(), watch(), '
        'or composables. The builder should only build the widget tree. '
        'Props destructuring (e.g., final MyWidget(:prop) = props.value;) '
        'is the only exception.',
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

  final NoLogicInBuilder rule;

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
    final body = builder.body;

    // Arrow function builders are always OK
    if (body is ExpressionFunctionBody) return;

    // Block function body - check each statement
    if (body is BlockFunctionBody) {
      for (final statement in body.block.statements) {
        if (!_isAllowedInBuilder(statement)) {
          rule.reportAtNode(statement);
        }
      }
    }
  }

  /// Checks if a statement is allowed inside the builder function.
  ///
  /// Allowed:
  /// - ReturnStatement (returning the widget tree)
  /// - PatternVariableDeclarationStatement (props destructuring)
  /// - VariableDeclarationStatement with a pattern destructure on .value
  bool _isAllowedInBuilder(Statement statement) {
    // Return statements are always OK
    if (statement is ReturnStatement) return true;

    // Pattern variable declaration (e.g., final MyWidget(:prop) = props.value;)
    if (statement is PatternVariableDeclarationStatement) return true;

    return false;
  }
}
