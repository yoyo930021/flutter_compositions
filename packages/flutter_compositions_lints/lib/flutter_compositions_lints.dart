/// Custom lint rules for Flutter Compositions.
///
/// This package provides lint rules to enforce best practices when using
/// Flutter Compositions, including:
/// - Ensuring reactive props usage through `widget()`
/// - Preventing async setup functions
/// - Managing controller lifecycle properly
/// - Avoiding mutable fields on widget classes
/// - Validating provide/inject type matching
library;

import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:flutter_compositions_lints/src/lints/controller_lifecycle.dart';
import 'package:flutter_compositions_lints/src/lints/ensure_reactive_props.dart';
import 'package:flutter_compositions_lints/src/lints/no_async_setup.dart';
import 'package:flutter_compositions_lints/src/lints/no_conditional_composition.dart';
import 'package:flutter_compositions_lints/src/lints/no_mutable_fields.dart';
import 'package:flutter_compositions_lints/src/lints/provide_inject_type_match.dart';

/// Entry point for the custom lint plugin.
PluginBase createPlugin() => _FlutterCompositionsLints();

class _FlutterCompositionsLints extends PluginBase {
  @override
  List<LintRule> getLintRules(CustomLintConfigs configs) => [
    const EnsureReactiveProps(),
    const NoAsyncSetup(),
    const NoMutableFields(),
    const ControllerLifecycle(),
    const ProvideInjectTypeMatch(),
    const NoConditionalComposition(),
  ];
}
