import 'package:analysis_server_plugin/plugin.dart';
import 'package:analysis_server_plugin/registry.dart';
import 'package:flutter_compositions_lints/src/lints/controller_lifecycle.dart';
import 'package:flutter_compositions_lints/src/lints/ensure_reactive_props.dart';
import 'package:flutter_compositions_lints/src/lints/no_async_setup.dart';
import 'package:flutter_compositions_lints/src/lints/no_conditional_composition.dart';
import 'package:flutter_compositions_lints/src/lints/no_logic_in_builder.dart';
import 'package:flutter_compositions_lints/src/lints/prefer_raw_controller.dart';
import 'package:flutter_compositions_lints/src/lints/shallow_reactivity_warning.dart';

final plugin = FlutterCompositionsPlugin();

class FlutterCompositionsPlugin extends Plugin {
  @override
  String get name => 'flutter_compositions_lints';

  @override
  void register(PluginRegistry registry) {
    registry.registerWarningRule(EnsureReactiveProps());
    registry.registerWarningRule(NoAsyncSetup());
    registry.registerWarningRule(ControllerLifecycle());
    registry.registerWarningRule(NoConditionalComposition());
    registry.registerWarningRule(ShallowReactivityWarning());
    registry.registerWarningRule(NoLogicInBuilder());
    registry.registerWarningRule(PreferRawController());
  }
}
