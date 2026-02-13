import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/src/dart/error/lint_codes.dart';

/// Warns about shallow reactivity limitations.
///
/// Flutter Compositions uses shallow reactivity - only reassigning `.value`
/// triggers updates. Directly mutating properties or array elements will NOT
/// trigger reactive updates.
class ShallowReactivityWarning extends AnalysisRule {
  ShallowReactivityWarning()
    : super(
        name: 'flutter_compositions_shallow_reactivity',
        description:
            "Direct mutation won't trigger reactive updates. "
            'Reassign the entire value instead.',
      );

  static const LintCode code = LintCode(
    'flutter_compositions_shallow_reactivity',
    "Direct mutation won't trigger reactive updates. "
        'Reassign the entire value instead.',
    correctionMessage:
        'Reassign the entire value to trigger updates. '
        'Create a new object/array and assign it to .value. '
        'Example: ref.value = {...ref.value}; or ref.value = [...ref.value];',
  );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    var assignmentVisitor = _AssignmentVisitor(this);
    var methodVisitor = _MethodVisitor(this);
    registry.addAssignmentExpression(this, assignmentVisitor);
    registry.addMethodInvocation(this, methodVisitor);
  }
}

class _AssignmentVisitor extends SimpleAstVisitor<void> {
  _AssignmentVisitor(this.rule);

  final ShallowReactivityWarning rule;

  @override
  void visitAssignmentExpression(AssignmentExpression node) {
    final leftHandSide = node.leftHandSide;

    // Check for patterns like: ref.value['key'] = value
    // or ref.value[index] = value
    if (leftHandSide is IndexExpression) {
      final target = leftHandSide.target;
      if (_isRefValueAccess(target)) {
        rule.reportAtNode(node);
        return;
      }
    }

    // Check for patterns like: ref.value.property = value
    if (leftHandSide is PropertyAccess) {
      final target = leftHandSide.target;
      if (_isRefValueAccess(target)) {
        rule.reportAtNode(node);
        return;
      }
    }

    // Check for patterns like: ref.value.nested.property = value
    if (leftHandSide is PrefixedIdentifier) {
      if (_hasRefValueInChain(node)) {
        rule.reportAtNode(node);
        return;
      }
    }
  }
}

class _MethodVisitor extends SimpleAstVisitor<void> {
  _MethodVisitor(this.rule);

  final ShallowReactivityWarning rule;

  @override
  void visitMethodInvocation(MethodInvocation node) {
    // Check for mutating methods on ref.value (for Lists, Sets, Maps, etc.)
    final target = node.target;
    if (target == null) return;

    if (!_isRefValueAccess(target)) return;

    // List of common mutating methods
    const mutatingMethods = {
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
      // Map methods
      'putIfAbsent',
      'update',
      'updateAll',
      'addEntries',
    };

    final methodName = node.methodName.name;
    if (mutatingMethods.contains(methodName)) {
      rule.reportAtNode(node);
    }
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
