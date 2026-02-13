import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:flutter_compositions_lints/src/lints/ensure_reactive_props.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(EnsureReactivePropsTest);
  });
}

@reflectiveTest
class EnsureReactivePropsTest extends AnalysisRuleTest {
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
  set value(T v) {}
}
Ref<T> ref<T>(T v) => throw '';
''');
    rule = EnsureReactiveProps();
    super.setUp();
  }

  void test_directThisAccess() async {
    await assertDiagnostics(r'''
import 'package:flutter_compositions/flutter_compositions.dart';

class MyWidget extends CompositionWidget {
  final String title = 'hello';

  @override
  Widget Function(BuildContext) setup() {
    final name = this.title;
    return (context) => Widget();
  }
}
''', [lint(213, 10)]);
  }

  void test_widgetCall_noDiagnostic() async {
    await assertNoDiagnostics(r'''
import 'package:flutter_compositions/flutter_compositions.dart';

class MyWidget extends CompositionWidget {
  @override
  Widget Function(BuildContext) setup() {
    final count = ref(0);
    return (context) => Widget();
  }
}
''');
  }

  void test_nonCompositionWidget_noDiagnostic() async {
    await assertNoDiagnostics(r'''
class OtherWidget {
  final String title = 'hello';
  void setup() {
    final name = this.title;
  }
}
''');
  }
}
