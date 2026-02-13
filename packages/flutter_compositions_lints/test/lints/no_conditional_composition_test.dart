import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:flutter_compositions_lints/src/lints/no_conditional_composition.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NoConditionalCompositionTest);
  });
}

@reflectiveTest
class NoConditionalCompositionTest extends AnalysisRuleTest {
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
void onMounted(void Function() cb) {}
void onUnmounted(void Function() cb) {}
''');
    rule = NoConditionalComposition();
    super.setUp();
  }

  void test_refInsideIf() async {
    await assertDiagnostics(r'''
import 'package:flutter_compositions/flutter_compositions.dart';

class MyWidget extends CompositionWidget {
  @override
  Widget Function(BuildContext) setup() {
    if (true) {
      final count = ref(0);
    }
    return (context) => Widget();
  }
}
''', [lint(199, 6)]);
  }

  void test_refInsideForLoop() async {
    await assertDiagnostics(r'''
import 'package:flutter_compositions/flutter_compositions.dart';

class MyWidget extends CompositionWidget {
  @override
  Widget Function(BuildContext) setup() {
    for (var i = 0; i < 3; i++) {
      final item = ref(i);
    }
    return (context) => Widget();
  }
}
''', [lint(216, 6)]);
  }

  void test_topLevelRef_noDiagnostic() async {
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

  void test_conditionalValueAssignment_noDiagnostic() async {
    await assertNoDiagnostics(r'''
import 'package:flutter_compositions/flutter_compositions.dart';

class MyWidget extends CompositionWidget {
  @override
  Widget Function(BuildContext) setup() {
    final count = ref(0);
    if (true) {
      count.value = 10;
    }
    return (context) => Widget();
  }
}
''');
  }

  void test_nonCompositionWidget_noDiagnostic() async {
    await assertNoDiagnostics(r'''
class OtherWidget {
  void setup() {
    if (true) {
      print('ok');
    }
  }
}
''');
  }
}
