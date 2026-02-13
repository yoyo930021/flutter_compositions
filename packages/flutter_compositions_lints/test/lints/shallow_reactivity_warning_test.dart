import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:flutter_compositions_lints/src/lints/shallow_reactivity_warning.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ShallowReactivityWarningTest);
  });
}

@reflectiveTest
class ShallowReactivityWarningTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = ShallowReactivityWarning();
    super.setUp();
  }

  void test_indexAssignmentOnValue() async {
    await assertDiagnostics(r'''
class Ref<T> {
  Ref(this._v);
  T _v;
  T get value => _v;
  set value(T v) { _v = v; }
}

void f() {
  final items = Ref<List<int>>([1, 2, 3]);
  items.value[0] = 10;
}
''', [lint(148, 19)]);
  }

  void test_propertyAssignmentOnValue() async {
    await assertDiagnostics(r'''
class Ref<T> {
  Ref(this._v);
  T _v;
  T get value => _v;
  set value(T v) { _v = v; }
}

class User {
  String name = '';
}

void f() {
  final user = Ref<User>(User());
  user.value.name = 'Jane';
}
''', [lint(175, 24)]);
  }

  void test_mutatingMethodOnValue() async {
    await assertDiagnostics(r'''
class Ref<T> {
  Ref(this._v);
  T _v;
  T get value => _v;
  set value(T v) { _v = v; }
}

void f() {
  final items = Ref<List<int>>([1, 2, 3]);
  items.value.add(4);
}
''', [lint(148, 18)]);
  }

  void test_reassigningValue_noDiagnostic() async {
    await assertNoDiagnostics(r'''
class Ref<T> {
  Ref(this._v);
  T _v;
  T get value => _v;
  set value(T v) { _v = v; }
}

void f() {
  final items = Ref<List<int>>([1, 2, 3]);
  items.value = [...items.value, 4];
}
''');
  }
}
