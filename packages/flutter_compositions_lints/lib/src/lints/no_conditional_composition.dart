import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/src/dart/error/lint_codes.dart';

/// Ensures composition APIs are not called conditionally in setup().
///
/// Composition APIs like `ref()`, `computed()`, `watch()`, `useController()`,
/// etc. should be called unconditionally at the top level of setup(), similar
/// to React Hooks rules.
class NoConditionalComposition extends AnalysisRule {
  NoConditionalComposition()
    : super(
        name: 'flutter_compositions_no_conditional_composition',
        description:
            'Composition API calls must not be inside conditionals or loops.',
      );

  static const LintCode code = LintCode(
    'flutter_compositions_no_conditional_composition',
    'Composition API calls must not be inside conditionals or loops. '
        'Call composition APIs unconditionally at the top level of setup().',
    correctionMessage:
        'Move the composition API call to the top level of '
        'setup(). You can still use conditional logic to set values.',
  );

  @override
  LintCode get diagnosticCode => code;

  // Composition API function names to check
  static const compositionApis = {
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
    'useController',
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
    'useContextRef',
    'useSearchController',
    'useAppLifecycleState',
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

  final NoConditionalComposition rule;

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    // Only check setup() methods
    if (node.name.lexeme != 'setup') return;

    // Check if this is inside a CompositionWidget
    final classNode = node.thisOrAncestorOfType<ClassDeclaration>();
    if (classNode != null) {
      final extendsClause = classNode.extendsClause;
      if (extendsClause != null) {
        final superclass = extendsClause.superclass.name.lexeme;
        if (superclass != 'CompositionWidget') return;
      } else {
        return;
      }
    }

    // Visit the setup method body to find composition API calls
    final bodyVisitor = _ConditionalCompositionVisitor(rule);
    node.body.visitChildren(bodyVisitor);
  }
}

class _ConditionalCompositionVisitor extends RecursiveAstVisitor<void> {
  _ConditionalCompositionVisitor(this.rule);

  final NoConditionalComposition rule;

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
      if (NoConditionalComposition.compositionApis.contains(methodName)) {
        rule.reportAtNode(node);
      }
    }

    super.visitMethodInvocation(node);
  }

  @override
  void visitFunctionExpression(FunctionExpression node) {
    // Don't traverse into nested functions (like the returned builder)
    final parent = node.parent;
    if (parent is ReturnStatement || parent is ExpressionStatement) {
      return;
    }

    super.visitFunctionExpression(node);
  }
}
