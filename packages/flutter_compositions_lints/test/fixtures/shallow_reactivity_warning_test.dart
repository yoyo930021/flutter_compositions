// ignore_for_file: unused_local_variable, prefer_const_constructors
import 'package:flutter/material.dart';

// Mock types for testing
class Ref<T> {
  T get value => throw UnimplementedError();
  set value(T val) => throw UnimplementedError();
}

Ref<T> ref<T>(T value) => throw UnimplementedError();

// ============================================================================
// TEST CASES
// ============================================================================

/// Should trigger lint: direct property mutation via index
void testIndexAssignment() {
  final user = ref({'name': 'John', 'age': 30});

  // expect_lint: flutter_compositions_shallow_reactivity
  user.value['name'] = 'Jane';
}

/// Should trigger lint: direct array element mutation
void testArrayElementAssignment() {
  final items = ref([1, 2, 3]);

  // expect_lint: flutter_compositions_shallow_reactivity
  items.value[0] = 10;
}

/// Should trigger lint: nested property assignment
void testNestedPropertyAssignment() {
  final config = ref({
    'settings': {'theme': 'light', 'locale': 'en'},
  });

  // expect_lint: flutter_compositions_shallow_reactivity
  config.value['settings']['theme'] = 'dark';
}

/// Should trigger lint: mutating List methods
void testListMutatingMethods() {
  final items = ref([1, 2, 3]);

  // expect_lint: flutter_compositions_shallow_reactivity
  items.value.add(4);

  // expect_lint: flutter_compositions_shallow_reactivity
  items.value.remove(1);

  // expect_lint: flutter_compositions_shallow_reactivity
  items.value.removeAt(0);

  // expect_lint: flutter_compositions_shallow_reactivity
  items.value.clear();

  // expect_lint: flutter_compositions_shallow_reactivity
  items.value.insert(0, 100);

  // expect_lint: flutter_compositions_shallow_reactivity
  items.value.sort();
}

/// Should trigger lint: mutating Map methods
void testMapMutatingMethods() {
  final user = ref({'name': 'John', 'age': 30});

  // expect_lint: flutter_compositions_shallow_reactivity
  user.value.putIfAbsent('email', () => 'john@example.com');

  // expect_lint: flutter_compositions_shallow_reactivity
  user.value.update('name', (value) => 'Jane');

  // expect_lint: flutter_compositions_shallow_reactivity
  user.value.remove('age');
}

/// Should NOT trigger lint: correct reassignment pattern
void testCorrectReassignment() {
  final user = ref({'name': 'John', 'age': 30});
  final items = ref([1, 2, 3]);

  // ✅ Correct: reassign entire value
  user.value = {...user.value, 'name': 'Jane'};

  // ✅ Correct: create new array
  items.value = [...items.value, 4];

  // ✅ Correct: create new array with modification
  items.value = [...items.value.sublist(0, 0), 10, ...items.value.sublist(1)];
}

/// Should NOT trigger lint: reading values (non-mutating)
void testNonMutatingAccess() {
  final user = ref({'name': 'John', 'age': 30});
  final items = ref([1, 2, 3]);

  // ✅ Reading is fine
  final name = user.value['name'];
  final firstItem = items.value[0];
  final length = items.value.length;

  // ✅ Non-mutating methods are fine
  final mapped = items.value.map((x) => x * 2).toList();
  final filtered = items.value.where((x) => x > 1).toList();
}

/// Should NOT trigger lint: local variables (not refs)
void testLocalVariables() {
  final localMap = {'name': 'John', 'age': 30};
  final localList = [1, 2, 3];

  // ✅ These are not refs, so mutation is allowed
  localMap['name'] = 'Jane';
  localList[0] = 10;
  localList.add(4);
}

/// Real-world example: managing a todo list incorrectly
void testTodoListBadExample() {
  final todos = ref([
    {'id': 1, 'text': 'Learn Flutter', 'done': false},
    {'id': 2, 'text': 'Build app', 'done': false},
  ]);

  // ❌ Bad: directly mutating
  // expect_lint: flutter_compositions_shallow_reactivity
  todos.value[0]['done'] = true;

  // expect_lint: flutter_compositions_shallow_reactivity
  todos.value.add({'id': 3, 'text': 'Deploy', 'done': false});
}

/// Real-world example: managing a todo list correctly
void testTodoListGoodExample() {
  final todos = ref([
    {'id': 1, 'text': 'Learn Flutter', 'done': false},
    {'id': 2, 'text': 'Build app', 'done': false},
  ]);

  // ✅ Good: create new array with updated item
  todos.value = todos.value.asMap().entries.map((entry) {
    if (entry.key == 0) {
      return {...entry.value, 'done': true};
    }
    return entry.value;
  }).toList();

  // ✅ Good: create new array with added item
  todos.value = [
    ...todos.value,
    {'id': 3, 'text': 'Deploy', 'done': false},
  ];
}
