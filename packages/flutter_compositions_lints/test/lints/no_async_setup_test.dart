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
    newPackage('flutter_compositions').addFile(
      'lib/flutter_compositions.dart',
      '''
class CompositionWidget {
  dynamic setup() => throw '';
}
class Widget {}
class BuildContext {}
''',
    );
    rule = NoAsyncSetup();
    super.setUp();
  }

  Future<void> test_asyncSetup_blockBody() async {
    await assertDiagnostics(
      '''
import 'package:flutter_compositions/flutter_compositions.dart';

class MyWidget extends CompositionWidget {
  @override
  dynamic setup() async {
    return (context) => Widget();
  }
}
''',
      [lint(111, 73)],
    );
  }

  Future<void> test_syncSetup_noDiagnostic() async {
    await assertNoDiagnostics('''
import 'package:flutter_compositions/flutter_compositions.dart';

class MyWidget extends CompositionWidget {
  @override
  Widget Function(BuildContext) setup() {
    return (context) => Widget();
  }
}
''');
  }

  Future<void> test_nonCompositionWidget_noDiagnostic() async {
    await assertNoDiagnostics('''
class OtherWidget {
  Future<void> setup() async {}
}
''');
  }
}
