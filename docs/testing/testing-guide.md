# Testing Guide

This comprehensive guide covers testing strategies for Flutter Compositions applications, including unit testing composables, widget testing, integration testing, and mocking dependencies.

## Table of Contents

1. [Testing Composables](#testing-composables)
2. [Widget Testing](#widget-testing)
3. [Mocking Dependencies](#mocking-dependencies)
4. [Testing Async Operations](#testing-async-operations)
5. [Testing Patterns](#testing-patterns)
6. [Best Practices](#best-practices)

## Testing Composables

Composables can be tested independently from widgets, making them easy to test in isolation.

### Basic Composable Tests

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_compositions/flutter_compositions.dart';

void main() {
  group('useCounter', () {
    test('should start with initial value', () {
      final (count, increment) = useCounter(initialValue: 5);

      expect(count.value, 5);
    });

    test('should increment count', () {
      final (count, increment) = useCounter(initialValue: 0);

      increment();
      expect(count.value, 1);

      increment();
      expect(count.value, 2);
    });

    test('should decrement count', () {
      final (count, increment, decrement) = useCounter(initialValue: 10);

      decrement();
      expect(count.value, 9);
    });
  });
}

// Example composable
(Ref<int>, void Function(), void Function()) useCounter({int initialValue = 0}) {
  final count = ref(initialValue);

  void increment() => count.value++;
  void decrement() => count.value--;

  return (count, increment, decrement);
}
```

### Testing Composables with Watch

Test that watchers trigger correctly:

```dart
test('should call watch callback when value changes', () {
  final values = <int>[];
  final count = ref(0);

  watch(() => count.value, (newValue, oldValue) {
    values.add(newValue);
  });

  count.value = 1;
  count.value = 2;
  count.value = 3;

  // Wait for microtasks to complete
  await Future.delayed(Duration.zero);

  expect(values, [1, 2, 3]);
});
```

### Testing Computed Values

```dart
test('should recompute when dependencies change', () {
  final firstName = ref('John');
  final lastName = ref('Doe');

  final fullName = computed(() => '${firstName.value} ${lastName.value}');

  expect(fullName.value, 'John Doe');

  firstName.value = 'Jane';
  expect(fullName.value, 'Jane Doe');

  lastName.value = 'Smith';
  expect(fullName.value, 'Jane Smith');
});
```

## Widget Testing

### Testing CompositionWidgets

Use Flutter's standard widget testing tools:

```dart
testWidgets('Counter increments when button pressed', (tester) async {
  await tester.pumpWidget(
    MaterialApp(home: CounterPage()),
  );

  // Verify initial state
  expect(find.text('0'), findsOneWidget);
  expect(find.text('1'), findsNothing);

  // Tap increment button
  await tester.tap(find.byIcon(Icons.add));
  await tester.pump();

  // Verify updated state
  expect(find.text('0'), findsNothing);
  expect(find.text('1'), findsOneWidget);
});
```

### Testing Reactive Props

Test that widgets respond to prop changes:

```dart
testWidgets('Widget updates when props change', (tester) async {
  Future<void> buildWidget(String name) async {
    await tester.pumpWidget(
      MaterialApp(
        home: UserGreeting(username: name),
      ),
    );
  }

  await buildWidget('Alice');
  expect(find.text('Hello, Alice!'), findsOneWidget);

  await buildWidget('Bob');
  await tester.pump();
  expect(find.text('Hello, Bob!'), findsOneWidget);
});

class UserGreeting extends CompositionWidget {
  final String username;
  const UserGreeting({required this.username});

  @override
  Widget Function(BuildContext) setup() {
    final props = widget();
    final greeting = computed(() => 'Hello, ${props.value.username}!');

    return (context) => Text(greeting.value);
  }
}
```

### Testing with CompositionBuilder

Use `CompositionBuilder` for testing without creating widget classes:

```dart
testWidgets('CompositionBuilder test', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: CompositionBuilder(
        setup: () {
          final count = ref(0);

          return (context) => Scaffold(
            body: Center(child: Text('${count.value}')),
            floatingActionButton: FloatingActionButton(
              onPressed: () => count.value++,
              child: Icon(Icons.add),
            ),
          );
        },
      ),
    ),
  );

  expect(find.text('0'), findsOneWidget);

  await tester.tap(find.byType(FloatingActionButton));
  await tester.pump();

  expect(find.text('1'), findsOneWidget);
});
```

## Mocking Dependencies

### Creating Mock Services

Use packages like `mockito` or `mocktail` to create mocks:

```dart
import 'package:mocktail/mocktail.dart';

class MockAuthService extends Mock implements AuthService {}
class MockApiService extends Mock implements ApiService {}

testWidgets('LoginPage with mocked auth service', (tester) async {
  final mockAuth = MockAuthService();

  when(() => mockAuth.login(any(), any())).thenAnswer(
    (_) async => User(id: '1', name: 'Test User'),
  );

  await tester.pumpWidget(
    CompositionBuilder(
      setup: () {
        provide(mockAuth);

        return (context) => MaterialApp(home: LoginPage());
      },
    ),
  );

  // Enter credentials
  await tester.enterText(find.byType(TextField).first, 'test@example.com');
  await tester.enterText(find.byType(TextField).last, 'password');

  // Tap login
  await tester.tap(find.text('Login'));
  await tester.pumpAndSettle();

  // Verify login was called
  verify(() => mockAuth.login('test@example.com', 'password')).called(1);
});
```

### Providing Mock Dependencies

Inject mocks using `provide`:

```dart
testWidgets('Widget uses injected service', (tester) async {
  final mockUserRepo = MockUserRepository();

  when(() => mockUserRepo.getUser('1')).thenAnswer(
    (_) async => User(id: '1', name: 'Alice'),
  );

  await tester.pumpWidget(
    CompositionBuilder(
      setup: () {
        provide<UserRepository>(mockUserRepo);

        return (context) => MaterialApp(
          home: UserProfile(userId: '1'),
        );
      },
    ),
  );

  await tester.pumpAndSettle();

  expect(find.text('Alice'), findsOneWidget);
  verify(() => mockUserRepo.getUser('1')).called(1);
});
```

### Testing with InjectionKeys

Use InjectionKeys for type-safe mocking:

```dart
class UserRepositoryKey extends InjectionKey<UserRepository> {
  const UserRepositoryKey();
}

const userRepositoryKey = UserRepositoryKey();

testWidgets('Widget uses keyed dependency', (tester) async {
  final mockRepo = MockUserRepository();

  await tester.pumpWidget(
    CompositionBuilder(
      setup: () {
        provide<UserRepository>(mockRepo, key: userRepositoryKey);

        return (context) => MaterialApp(home: MyWidget());
      },
    ),
  );

  // Test continues...
});
```

## Testing Async Operations

### Testing useFuture

```dart
testWidgets('useFuture handles loading and success', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: CompositionBuilder(
        setup: () {
          final userData = useFuture(() async {
            await Future.delayed(Duration(milliseconds: 100));
            return User(name: 'Alice');
          });

          return (context) => switch (userData.value) {
            AsyncLoading() => CircularProgressIndicator(),
            AsyncData(:final value) => Text(value.name),
            AsyncError(:final errorValue) => Text('Error: $errorValue'),
            AsyncIdle() => SizedBox.shrink(),
          };
        },
      ),
    ),
  );

  // Initially loading
  expect(find.byType(CircularProgressIndicator), findsOneWidget);

  // Wait for future to complete
  await tester.pumpAndSettle();

  // Shows data
  expect(find.text('Alice'), findsOneWidget);
  expect(find.byType(CircularProgressIndicator), findsNothing);
});
```

### Testing useAsyncData

```dart
testWidgets('useAsyncData with watch refetches', (tester) async {
  final mockApi = MockApiService();
  const apiKey = InjectionKey<MockApiService>('mockApi');

  when(() => mockApi.fetchUser(1)).thenAnswer(
    (_) async => User(id: '1', name: 'Alice'),
  );
  when(() => mockApi.fetchUser(2)).thenAnswer(
    (_) async => User(id: '2', name: 'Bob'),
  );

  await tester.pumpWidget(
    CompositionBuilder(
      setup: () {
        provide(apiKey, mockApi);

        final userId = ref(1);
        final api = inject(apiKey);

        final (status, refresh) = useAsyncData<User, int>(
          (id) => api.fetchUser(id),
          watch: () => userId.value,
        );

        return (context) => Scaffold(
          body: switch (status.value) {
            AsyncData(:final value) => Text(value.name),
            _ => CircularProgressIndicator(),
          },
          floatingActionButton: FloatingActionButton(
            onPressed: () => userId.value = 2,
            child: Icon(Icons.next_plan),
          ),
        );
      },
    ),
  );

  await tester.pumpAndSettle();
  expect(find.text('Alice'), findsOneWidget);

  // Change userId - should refetch
  await tester.tap(find.byType(FloatingActionButton));
  await tester.pump();

  // Loading state
  expect(find.byType(CircularProgressIndicator), findsOneWidget);

  await tester.pumpAndSettle();

  // New data
  expect(find.text('Bob'), findsOneWidget);
  verify(() => mockApi.fetchUser(1)).called(1);
  verify(() => mockApi.fetchUser(2)).called(1);
});
```

### Testing Error States

```dart
testWidgets('Shows error state on failure', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: CompositionBuilder(
        setup: () {
          final userData = useFuture(() async {
            await Future.delayed(Duration(milliseconds: 100));
            throw Exception('Network error');
          });

          return (context) => switch (userData.value) {
            AsyncError(:final errorValue) => Text('Error: $errorValue'),
            AsyncLoading() => CircularProgressIndicator(),
            _ => SizedBox.shrink(),
          };
        },
      ),
    ),
  );

  await tester.pumpAndSettle();

  expect(find.textContaining('Network error'), findsOneWidget);
});
```

## Testing Patterns

### Testing Form Validation

```dart
testWidgets('Form validates input', (tester) async {
  await tester.pumpWidget(
    MaterialApp(home: LoginForm()),
  );

  // Submit with empty fields
  await tester.tap(find.text('Submit'));
  await tester.pump();

  expect(find.text('Email is required'), findsOneWidget);
  expect(find.text('Password is required'), findsOneWidget);

  // Enter invalid email
  await tester.enterText(find.byKey(Key('email')), 'invalid');
  await tester.tap(find.text('Submit'));
  await tester.pump();

  expect(find.text('Invalid email'), findsOneWidget);

  // Enter valid data
  await tester.enterText(find.byKey(Key('email')), 'test@example.com');
  await tester.enterText(find.byKey(Key('password')), 'password123');
  await tester.tap(find.text('Submit'));
  await tester.pump();

  // No errors
  expect(find.text('Email is required'), findsNothing);
  expect(find.text('Invalid email'), findsNothing);
});
```

### Testing Lifecycle Hooks

```dart
testWidgets('onMounted callback executes', (tester) async {
  var mountedCalled = false;

  await tester.pumpWidget(
    MaterialApp(
      home: CompositionBuilder(
        setup: () {
          onMounted(() {
            mountedCalled = true;
          });

          return (context) => Container();
        },
      ),
    ),
  );

  await tester.pumpAndSettle();

  expect(mountedCalled, true);
});

testWidgets('onUnmounted callback executes', (tester) async {
  var unmountedCalled = false;

  await tester.pumpWidget(
    MaterialApp(
      home: CompositionBuilder(
        setup: () {
          onUnmounted(() {
            unmountedCalled = true;
          });

          return (context) => Container();
        },
      ),
    ),
  );

  // Remove widget
  await tester.pumpWidget(SizedBox.shrink());
  await tester.pump();

  expect(unmountedCalled, true);
});
```

### Testing Controllers

```dart
testWidgets('ScrollController tracks position', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: CompositionBuilder(
        setup: () {
          final scrollController = useScrollController();
          final offset = ref(0.0);

          watchEffect(() {
            offset.value = scrollController.value.offset;
          });

          return (context) => Column(
            children: [
              Text('Offset: ${offset.value.toInt()}'),
              Expanded(
                child: ListView.builder(
                  controller: scrollController.raw, // .raw avoids unnecessary rebuilds
                  itemCount: 100,
                  itemBuilder: (context, index) => ListTile(
                    title: Text('Item $index'),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    ),
  );

  expect(find.text('Offset: 0'), findsOneWidget);

  // Scroll down
  await tester.drag(find.byType(ListView), Offset(0, -500));
  await tester.pumpAndSettle();

  // Offset should have changed
  expect(find.textContaining('Offset: 0'), findsNothing);
});
```

## Best Practices

### 1. Test Behavior, Not Implementation

```dart
// ✅ Good - Tests observable behavior
testWidgets('Shows user name after loading', (tester) async {
  // Setup and assertions
});

// ❌ Bad - Tests internal implementation
testWidgets('Creates ref with null initial value', (tester) async {
  // Don't test internal details
});
```

### 2. Use Descriptive Test Names

```dart
// ✅ Good - Clear what is being tested
test('should increment counter when increment is called')
test('should show error message when login fails')
test('should disable submit button when form is invalid')

// ❌ Bad - Unclear purpose
test('test1')
test('button test')
test('works correctly')
```

### 3. Arrange-Act-Assert Pattern

```dart
test('should add item to cart', () {
  // Arrange
  final cart = CartStore();
  final product = Product(id: '1', name: 'Test', price: 10.0);

  // Act
  cart.addItem(product);

  // Assert
  expect(cart.items.value.length, 1);
  expect(cart.total.value, 10.0);
});
```

### 4. Mock External Dependencies

```dart
// ✅ Good - Mocks API calls
testWidgets('Shows loading then data', (tester) async {
  final mockApi = MockApiService();
  when(() => mockApi.fetchData()).thenAnswer(
    (_) async => Data(value: 'test'),
  );

  // Test with mock
});

// ❌ Bad - Makes real API calls
testWidgets('Fetches real data', (tester) async {
  // Don't make real network calls in tests
});
```

### 5. Test Edge Cases

```dart
group('useValidation', () {
  test('should handle empty input', () { /* ... */ });
  test('should handle whitespace', () { /* ... */ });
  test('should handle very long input', () { /* ... */ });
  test('should handle special characters', () { /* ... */ });
  test('should handle null values', () { /* ... */ });
});
```

### 6. Clean Up After Tests

```dart
testWidgets('Cleans up resources', (tester) async {
  final subscription = stream.listen((_) {});

  addTearDown(() {
    subscription.cancel();
  });

  // Test code
});
```

### 7. Use Test Groups

```dart
void main() {
  group('AuthService', () {
    late AuthService authService;

    setUp(() {
      authService = AuthService();
    });

    group('login', () {
      test('should succeed with valid credentials', () { /* ... */ });
      test('should fail with invalid credentials', () { /* ... */ });
      test('should update authentication state', () { /* ... */ });
    });

    group('logout', () {
      test('should clear user data', () { /* ... */ });
      test('should update authentication state', () { /* ... */ });
    });
  });
}
```

## Testing Checklist

Use this checklist for comprehensive testing:

### Unit Tests (Composables)
- [ ] Test initial state
- [ ] Test state updates
- [ ] Test computed values
- [ ] Test watch callbacks
- [ ] Test cleanup (onUnmounted)
- [ ] Test edge cases

### Widget Tests
- [ ] Test initial render
- [ ] Test user interactions
- [ ] Test prop changes
- [ ] Test reactive updates
- [ ] Test error states
- [ ] Test loading states

### Integration Tests
- [ ] Test complete user flows
- [ ] Test navigation
- [ ] Test data persistence
- [ ] Test dependency injection
- [ ] Test async operations

### Mocking
- [ ] Mock external services
- [ ] Mock API calls
- [ ] Mock storage
- [ ] Verify method calls
- [ ] Test error scenarios

## See Also

- [Best Practices](../guide/best-practices.md) — general best practices
- [Built-in Composables](../guide/built-in-composables.md) — catalog of built-in helpers
- [Dependency Injection](../guide/dependency-injection.md) — DI patterns
- [Creating Composables](../guide/creating-composables.md) — creating testable composables
