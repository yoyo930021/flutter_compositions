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
    newPackage('flutter_compositions').addFile(
      'lib/flutter_compositions.dart',
      '''
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
''',
    );
    rule = EnsureReactiveProps();
    super.setUp();
  }

  Future<void> test_directThisAccess() async {
    await assertDiagnostics(
      '''
import 'package:flutter_compositions/flutter_compositions.dart';

class MyWidget extends CompositionWidget {
  final String title = 'hello';

  @override
  Widget Function(BuildContext) setup() {
    final name = this.title;
    return (context) => Widget();
  }
}
''',
      [lint(213, 10)],
    );
  }

  Future<void> test_widgetCall_noDiagnostic() async {
    await assertNoDiagnostics('''
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

  Future<void> test_nonCompositionWidget_noDiagnostic() async {
    await assertNoDiagnostics('''
class OtherWidget {
  final String title = 'hello';
  void setup() {
    final name = this.title;
  }
}
''');
  }
}
