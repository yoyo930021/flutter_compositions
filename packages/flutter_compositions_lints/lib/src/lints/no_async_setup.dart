import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/src/dart/error/lint_codes.dart';

/// Ensures that setup() methods are not async.
///
/// The setup() method must synchronously return a builder
/// function. Async operations should be performed inside
/// lifecycle hooks like onMounted().
class NoAsyncSetup extends AnalysisRule {
  /// Creates a new [NoAsyncSetup] rule instance.
  NoAsyncSetup()
    : super(
        name: 'flutter_compositions_no_async_setup',
        description: 'The setup() method must not be async.',
      );

  /// The lint code reported by this rule.
  static const LintCode code = LintCode(
    'flutter_compositions_no_async_setup',
    'The setup() method must not be async.',
    correctionMessage:
        'Remove async keyword. Use onMounted() or '
        'onUnmounted() for async operations.',
  );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final visitor = _Visitor(this);
    registry.addMethodDeclaration(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  _Visitor(this.rule);

  final NoAsyncSetup rule;

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

    // Check if the method body is async
    final body = node.body;
    if (body is BlockFunctionBody && body.isAsynchronous) {
      rule.reportAtNode(node);
      return;
    }

    if (body is ExpressionFunctionBody && body.isAsynchronous) {
      rule.reportAtNode(node);
    }
  }
}
