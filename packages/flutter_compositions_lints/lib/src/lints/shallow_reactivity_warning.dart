import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

/// Warns about shallow reactivity limitations.
///
/// Flutter Compositions uses shallow reactivity - only reassigning `.value`
/// triggers updates. Directly mutating properties or array elements will NOT
/// trigger reactive updates.
///
/// **Bad:**
/// ```dart
/// final user = ref({'name': 'John', 'age': 30});
/// user.value['name'] = 'Jane'; // ❌ Won't trigger update
///
/// final items = ref([1, 2, 3]);
/// items.value[0] = 10; // ❌ Won't trigger update
/// items.value.add(4); // ❌ Won't trigger update
/// ```
///
/// **Good:**
/// ```dart
/// final user = ref({'name': 'John', 'age': 30});
/// user.value = {...user.value, 'name': 'Jane'}; // ✅ Triggers update
///
/// final items = ref([1, 2, 3]);
/// items.value = [...items.value.sublist(0, 0), 10, ...items.value.sublist(1)]; // ✅ Triggers update
/// items.value = [...items.value, 4]; // ✅ Triggers update
/// ```
class ShallowReactivityWarning extends DartLintRule {
  /// Creates a new instance of [ShallowReactivityWarning].
  const ShallowReactivityWarning() : super(code: _code);

  static const _code = LintCode(
    name: 'flutter_compositions_shallow_reactivity',
    problemMessage:
        'Direct mutation won\'t trigger reactive updates. '
        'Reassign the entire value instead.',
    correctionMessage:
        'Create a new object/array and assign it to .value to trigger updates. '
        'Example: ref.value = {...ref.value}; or ref.value = [...ref.value];',
  );

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addAssignmentExpression((node) {
      _checkAssignment(node, reporter);
    });

    context.registry.addMethodInvocation((node) {
      _checkMethodInvocation(node, reporter);
    });
  }

  void _checkAssignment(AssignmentExpression node, ErrorReporter reporter) {
    final leftHandSide = node.leftHandSide;

    // Check for patterns like: ref.value['key'] = value
    // or ref.value[index] = value
    if (leftHandSide is IndexExpression) {
      final target = leftHandSide.target;
      if (_isRefValueAccess(target)) {
        reporter.atNode(node, _code);
        return;
      }
    }

    // Check for patterns like: ref.value.property = value
    if (leftHandSide is PropertyAccess) {
      final target = leftHandSide.target;
      if (_isRefValueAccess(target)) {
        reporter.atNode(node, _code);
        return;
      }
    }

    // Check for patterns like: ref.value.nested.property = value
    if (leftHandSide is PrefixedIdentifier) {
      final prefix = leftHandSide.prefix;
      if (prefix is SimpleIdentifier) {
        // This might be part of a chain, check the context
        final parent = node.parent;
        if (parent != null && _hasRefValueInChain(node)) {
          reporter.atNode(node, _code);
          return;
        }
      }
    }
  }

  void _checkMethodInvocation(
    MethodInvocation node,
    ErrorReporter reporter,
  ) {
    // Check for mutating methods on ref.value (for Lists, Sets, Maps, etc.)
    final target = node.target;
    if (target == null) return;

    if (!_isRefValueAccess(target)) return;

    // List of common mutating methods
    final mutatingMethods = {
      // List methods
      'add',
      'addAll',
      'insert',
      'insertAll',
      'remove',
      'removeAt',
      'removeLast',
      'removeRange',
      'removeWhere',
      'retainWhere',
      'clear',
      'sort',
      'shuffle',
      'fillRange',
      'setRange',
      'setAll',
      // Set methods
      // Map methods
      'putIfAbsent',
      'update',
      'updateAll',
      'addEntries',
      'removeWhere',
    };

    final methodName = node.methodName.name;
    if (mutatingMethods.contains(methodName)) {
      reporter.atNode(node, _code);
    }
  }

  /// Checks if the expression is accessing .value on a ref-like object
  bool _isRefValueAccess(Expression? expr) {
    if (expr == null) return false;

    // Check for direct .value access
    if (expr is PropertyAccess) {
      return expr.propertyName.name == 'value';
    }

    // Check for identifier.value pattern
    if (expr is PrefixedIdentifier) {
      return expr.identifier.name == 'value';
    }

    return false;
  }

  /// Checks if there's a ref.value access somewhere in the assignment chain
  bool _hasRefValueInChain(AstNode node) {
    AstNode? current = node;
    while (current != null) {
      if (current is PropertyAccess && current.propertyName.name == 'value') {
        return true;
      }
      if (current is PrefixedIdentifier && current.identifier.name == 'value') {
        return true;
      }
      current = current.parent;
    }
    return false;
  }
}
