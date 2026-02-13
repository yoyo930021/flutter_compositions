import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/src/dart/error/lint_codes.dart';

/// Ensures Flutter controllers are managed with proper lifecycle hooks.
///
/// Controllers should use `useController` or explicitly call dispose in
/// `onUnmounted()` to avoid memory leaks.
class ControllerLifecycle extends AnalysisRule {
  ControllerLifecycle()
    : super(
        name: 'flutter_compositions_controller_lifecycle',
        description:
            'Flutter controllers must be disposed. Use '
            'use*Controller() helpers or call dispose() in onUnmounted().',
      );

  static const LintCode code = LintCode(
    'flutter_compositions_controller_lifecycle',
    'Flutter controllers must be disposed. Use '
        'use*Controller() helpers or call dispose() in onUnmounted().',
    correctionMessage:
        'Use useScrollController(), usePageController(), '
        'useFocusNode(), or useTextEditingController() helpers, or manually '
        'dispose the controller in onUnmounted().',
  );

  @override
  LintCode get diagnosticCode => code;

  // Common Flutter controller types
  static const controllerTypes = {
    'ScrollController',
    'PageController',
    'TextEditingController',
    'TabController',
    'AnimationController',
    'VideoPlayerController',
    'WebViewController',
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

  final ControllerLifecycle rule;

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

    // Track controller creations and disposals
    final bodyVisitor = _ControllerVisitor(rule);
    node.visitChildren(bodyVisitor);

    // Report controllers without disposal
    for (final controller in bodyVisitor.controllers) {
      final variableName = (controller as VariableDeclaration).name.lexeme;
      if (!bodyVisitor.disposedControllers.contains(variableName) &&
          !bodyVisitor.useHelperControllers.contains(variableName)) {
        rule.reportAtNode(controller);
      }
    }
  }
}

class _ControllerVisitor extends RecursiveAstVisitor<void> {
  _ControllerVisitor(this.rule);

  final ControllerLifecycle rule;
  final List<AstNode> controllers = [];
  final Set<String> disposedControllers = {};
  final Set<String> useHelperControllers = {};

  @override
  void visitVariableDeclaration(VariableDeclaration node) {
    final initializer = node.initializer;

    // Check for controller instantiation
    if (initializer is InstanceCreationExpression) {
      final type = initializer.staticType;
      if (type != null &&
          ControllerLifecycle.controllerTypes.any(
            (ct) => type.toString().startsWith(ct),
          )) {
        controllers.add(node);
      }
    }

    // Check for use* helper calls
    if (initializer is MethodInvocation) {
      final methodName = initializer.methodName.name;
      if (methodName.startsWith('use') &&
          (methodName.contains('Controller') ||
              methodName == 'useFocusNode' ||
              methodName == 'useTextEditingController')) {
        // Track that this variable is managed by a helper
        useHelperControllers.add(node.name.lexeme);
      }
    }

    super.visitVariableDeclaration(node);
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    // Check for onUnmounted disposal
    if (node.methodName.name == 'onUnmounted') {
      final args = node.argumentList.arguments;
      if (args.isNotEmpty) {
        final callback = args.first;
        if (callback is FunctionExpression) {
          // Look for dispose() calls in the callback
          _findDisposeCallsIn(callback.body, disposedControllers);
        }
      }
    }

    super.visitMethodInvocation(node);
  }

  void _findDisposeCallsIn(FunctionBody body, Set<String> disposed) {
    body.visitChildren(_DisposeCallVisitor(disposed));
  }
}

class _DisposeCallVisitor extends RecursiveAstVisitor<void> {
  _DisposeCallVisitor(this.disposed);

  final Set<String> disposed;

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (node.methodName.name == 'dispose') {
      final target = node.target;
      if (target is SimpleIdentifier) {
        disposed.add(target.name);
      }
    }
    super.visitMethodInvocation(node);
  }
}
