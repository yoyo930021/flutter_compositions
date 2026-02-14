import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:flutter_compositions_lints/src/lints/no_logic_in_builder.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NoLogicInBuilderTest);
  });
}

@reflectiveTest
class NoLogicInBuilderTest extends AnalysisRuleTest {
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
  T get raw => throw '';
  set value(T v) {}
}
Ref<T> ref<T>(T v) => throw '';
''',
    );
    rule = NoLogicInBuilder();
    super.setUp();
  }

  Future<void> test_variableDeclarationInBuilder() async {
    await assertDiagnostics(
      '''
import 'package:flutter_compositions/flutter_compositions.dart';

class MyWidget extends CompositionWidget {
  @override
  Widget Function(BuildContext) setup() {
    final count = ref(0);
    return (context) {
      final x = count.value * 2;
      return Widget();
    };
  }
}
''',
      [lint(218, 26)],
    );
  }

  Future<void> test_ifStatementInBuilder() async {
    await assertDiagnostics(
      '''
import 'package:flutter_compositions/flutter_compositions.dart';

class MyWidget extends CompositionWidget {
  @override
  Widget Function(BuildContext) setup() {
    final count = ref(0);
    return (context) {
      if (count.value > 0) {
        return Widget();
      }
      return Widget();
    };
  }
}
''',
      [lint(218, 55)],
    );
  }

  Future<void> test_expressionStatementInBuilder() async {
    await assertDiagnostics(
      '''
import 'package:flutter_compositions/flutter_compositions.dart';

class MyWidget extends CompositionWidget {
  @override
  Widget Function(BuildContext) setup() {
    final count = ref(0);
    return (context) {
      print(count.value);
      return Widget();
    };
  }
}
''',
      [lint(218, 19)],
    );
  }

  Future<void> test_arrowFunctionBuilder_noDiagnostic() async {
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

  Future<void> test_propsDestructuringAndReturn_noDiagnostic() async {
    await assertNoDiagnostics('''
import 'package:flutter_compositions/flutter_compositions.dart';

class MyWidget extends CompositionWidget {
  final String title;
  MyWidget({required this.title});

  @override
  Widget Function(BuildContext) setup() {
    return (context) {
      final MyWidget(:title) = this;
      return Widget();
    };
  }
}
''');
  }

  Future<void> test_logicInSetupBody_noDiagnostic() async {
    await assertNoDiagnostics('''
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

  Future<void> test_nonCompositionWidget_noDiagnostic() async {
    await assertNoDiagnostics('''
class OtherWidget {
  void setup() {
    print('logic here is fine');
  }
}
''');
  }
}
