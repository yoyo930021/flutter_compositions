import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:flutter_compositions_lints/src/lints/prefer_raw_controller.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(PreferRawControllerTest);
  });
}

@reflectiveTest
class PreferRawControllerTest extends AnalysisRuleTest {
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
Ref<T> ref<T>(T v) => throw '';
''');
    rule = PreferRawController();
    super.setUp();
  }

  void test_controllerWithDotValue() async {
    await assertDiagnostics(r'''
import 'package:flutter_compositions/flutter_compositions.dart';

class MyListView extends Widget {
  MyListView({Object? controller});
}

class MyWidget extends CompositionWidget {
  @override
  Widget Function(BuildContext) setup() {
    final sc = ref<Object?>(null);
    return (context) {
      return MyListView(controller: sc.value);
    };
  }
}
''', [lint(330, 8)]);
  }

  void test_controllerWithDotRaw_noDiagnostic() async {
    await assertNoDiagnostics(r'''
import 'package:flutter_compositions/flutter_compositions.dart';

class MyListView extends Widget {
  MyListView({Object? controller});
}

class MyWidget extends CompositionWidget {
  @override
  Widget Function(BuildContext) setup() {
    final sc = ref<Object?>(null);
    return (context) {
      return MyListView(controller: sc.raw);
    };
  }
}
''');
  }

  void test_focusNodeWithDotValue() async {
    await assertDiagnostics(r'''
import 'package:flutter_compositions/flutter_compositions.dart';

class MyTextField extends Widget {
  MyTextField({Object? focusNode});
}

class MyWidget extends CompositionWidget {
  @override
  Widget Function(BuildContext) setup() {
    final fn = ref<Object?>(null);
    return (context) {
      return MyTextField(focusNode: fn.value);
    };
  }
}
''', [lint(331, 8)]);
  }

  void test_nonControllerDotValue_noDiagnostic() async {
    await assertNoDiagnostics(r'''
import 'package:flutter_compositions/flutter_compositions.dart';

class MyText extends Widget {
  MyText(String text);
}

class MyWidget extends CompositionWidget {
  @override
  Widget Function(BuildContext) setup() {
    final name = ref('hello');
    return (context) {
      return MyText(name.value);
    };
  }
}
''');
  }

  void test_arrowBuilder_controllerWithDotRaw_noDiagnostic() async {
    await assertNoDiagnostics(r'''
import 'package:flutter_compositions/flutter_compositions.dart';

class MyListView extends Widget {
  MyListView({Object? controller});
}

class MyWidget extends CompositionWidget {
  @override
  Widget Function(BuildContext) setup() {
    final sc = ref<Object?>(null);
    return (context) => MyListView(controller: sc.raw);
  }
}
''');
  }

  void test_nonCompositionWidget_noDiagnostic() async {
    await assertNoDiagnostics(r'''
class OtherWidget {
  void setup() {}
}
''');
  }
}
