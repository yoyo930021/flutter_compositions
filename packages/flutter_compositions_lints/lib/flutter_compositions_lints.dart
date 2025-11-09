/// Custom lint rules for Flutter Compositions.
///
/// This package provides lint rules to enforce best practices when using
/// Flutter Compositions, including:
/// - Ensuring reactive props usage through `widget()`
/// - Preventing async setup functions
/// - Managing controller lifecycle properly
/// - Warning about shallow reactivity limitations
library;

import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:flutter_compositions_lints/src/lints/controller_lifecycle.dart';
import 'package:flutter_compositions_lints/src/lints/ensure_reactive_props.dart';
import 'package:flutter_compositions_lints/src/lints/no_async_setup.dart';
import 'package:flutter_compositions_lints/src/lints/no_conditional_composition.dart';
import 'package:flutter_compositions_lints/src/lints/shallow_reactivity_warning.dart';

/// Entry point for the custom lint plugin.
PluginBase createPlugin() => _FlutterCompositionsLints();

class _FlutterCompositionsLints extends PluginBase {
  @override
  List<LintRule> getLintRules(CustomLintConfigs configs) => [
    const EnsureReactiveProps(),
    const NoAsyncSetup(),
    const ControllerLifecycle(),
    const NoConditionalComposition(),
    const ShallowReactivityWarning(),
  ];
}
