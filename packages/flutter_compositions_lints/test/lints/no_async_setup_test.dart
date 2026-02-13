import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:flutter_compositions_lints/src/lints/no_async_setup.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NoAsyncSetupTest);
  });
}

@reflectiveTest
class NoAsyncSetupTest extends AnalysisRuleTest {
  @override
  void setUp() {
    newPackage('flutter_compositions')
      ..addFile('lib/flutter_compositions.dart', r'''
class CompositionWidget {
  dynamic setup() => throw '';
}
class Widget {}
class BuildContext {}
''');
    rule = NoAsyncSetup();
    super.setUp();
  }

  void test_asyncSetup_blockBody() async {
    await assertDiagnostics(r'''
import 'package:flutter_compositions/flutter_compositions.dart';

class MyWidget extends CompositionWidget {
  @override
  dynamic setup() async {
    return (context) => Widget();
  }
}
''', [lint(111, 73)]);
  }

  void test_syncSetup_noDiagnostic() async {
    await assertNoDiagnostics(r'''
import 'package:flutter_compositions/flutter_compositions.dart';

class MyWidget extends CompositionWidget {
  @override
  Widget Function(BuildContext) setup() {
    return (context) => Widget();
  }
}
''');
  }

  void test_nonCompositionWidget_noDiagnostic() async {
    await assertNoDiagnostics(r'''
class OtherWidget {
  Future<void> setup() async {}
}
''');
  }
}
