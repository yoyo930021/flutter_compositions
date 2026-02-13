import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:flutter_compositions_lints/src/lints/controller_lifecycle.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ControllerLifecycleTest);
  });
}

@reflectiveTest
class ControllerLifecycleTest extends AnalysisRuleTest {
  @override
  void setUp() {
    newPackage('flutter_compositions')
      ..addFile('lib/flutter_compositions.dart', r'''
class CompositionWidget {
  Widget Function(BuildContext) setup() => throw '';
}
class Widget {}
class BuildContext {}
class Ref<T> {
  T get value => throw '';
  T get raw => throw '';
  set value(T v) {}
}
Ref<T> useScrollController() => throw '';
void onUnmounted(void Function() cb) {}
''');
    newPackage('flutter')
      ..addFile('lib/widgets.dart', r'''
class ScrollController {
  void dispose() {}
}
''');
    rule = ControllerLifecycle();
    super.setUp();
  }

  void test_controllerWithoutDisposal() async {
    await assertDiagnostics(r'''
import 'package:flutter_compositions/flutter_compositions.dart';
import 'package:flutter/widgets.dart';

class MyWidget extends CompositionWidget {
  @override
  Widget Function(BuildContext) setup() {
    final controller = ScrollController();
    return (context) => Widget();
  }
}
''', [lint(212, 31)]);
  }

  void test_controllerWithOnUnmounted_noDiagnostic() async {
    await assertNoDiagnostics(r'''
import 'package:flutter_compositions/flutter_compositions.dart';
import 'package:flutter/widgets.dart';

class MyWidget extends CompositionWidget {
  @override
  Widget Function(BuildContext) setup() {
    final controller = ScrollController();
    onUnmounted(() => controller.dispose());
    return (context) => Widget();
  }
}
''');
  }

  void test_useHelper_noDiagnostic() async {
    await assertNoDiagnostics(r'''
import 'package:flutter_compositions/flutter_compositions.dart';

class MyWidget extends CompositionWidget {
  @override
  Widget Function(BuildContext) setup() {
    final controller = useScrollController();
    return (context) => Widget();
  }
}
''');
  }
}
