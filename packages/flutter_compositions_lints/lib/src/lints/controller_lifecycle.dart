import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

/// Ensures Flutter controllers are managed with proper lifecycle hooks.
///
/// Controllers should use `useController` or explicitly call dispose in
/// `onUnmounted()` to avoid memory leaks.
///
/// **Bad:**
/// ```dart
/// @override
/// Widget Function(BuildContext) setup() {
///   final controller = ScrollController(); // ❌ No disposal
///   return (context) => ListView(controller: controller);
/// }
/// ```
///
/// **Good:**
/// ```dart
/// @override
/// Widget Function(BuildContext) setup() {
///   // Option 1: Use helper (recommended)
///   final controller = useScrollController();
///   return (context) => ListView(controller: controller.value);
///
///   // Option 2: Manual disposal
///   final controller = ScrollController();
///   onUnmounted(() => controller.dispose());
///   return (context) => ListView(controller: controller);
/// }
/// ```
class ControllerLifecycle extends DartLintRule {
  /// Creates a new instance of [ControllerLifecycle].
  const ControllerLifecycle() : super(code: _code);

  static const _code = LintCode(
    name: 'flutter_compositions_controller_lifecycle',
    problemMessage:
        'Flutter controllers must be disposed. Use '
        'use*Controller() helpers or call dispose() in onUnmounted().',
    correctionMessage:
        'Use useScrollController(), usePageController(), '
        'useFocusNode(), or useTextEditingController() helpers, or manually '
        'dispose the controller in onUnmounted().',
    errorSeverity: ErrorSeverity.WARNING,
  );

  // Common Flutter controller types
  static const _controllerTypes = {
    'ScrollController',
    'PageController',
    'TextEditingController',
    'TabController',
    'AnimationController',
    'VideoPlayerController',
    'WebViewController',
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

      // Check if this is inside a CompositionWidget
      final classNode = node.thisOrAncestorOfType<ClassDeclaration>();
      if (classNode == null) return;

      final extendsClause = classNode.extendsClause;
      if (extendsClause == null) return;

      final superclass = extendsClause.superclass.name2.lexeme;
      if (superclass != 'CompositionWidget') return;

      // Track controller creations and disposals
      final visitor = _ControllerVisitor(reporter);
      node.visitChildren(visitor);

      // Report controllers without disposal
      for (final controller in visitor.controllers) {
        final variableName = (controller as VariableDeclaration).name.lexeme;
        if (!visitor.disposedControllers.contains(variableName) &&
            !visitor.useHelperControllers.contains(variableName)) {
          reporter.reportErrorForNode(
            _code,
            controller,
          );
        }
      }
    });
  }
}

class _ControllerVisitor extends RecursiveAstVisitor<void> {
  /// Creates a new instance of [_ControllerVisitor].
  _ControllerVisitor(this.reporter);

  final ErrorReporter reporter;
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
          ControllerLifecycle._controllerTypes.any(
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
  /// Creates a new instance of [_DisposeCallVisitor].
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
