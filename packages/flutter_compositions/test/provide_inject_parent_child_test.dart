import 'package:flutter/material.dart';
import 'package:flutter_compositions/flutter_compositions.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Provide/Inject Parent-Child', () {
    testWidgets('child widget can inject value from parent widget', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ParentWidget(),
        ),
      );

      // If provide/inject works correctly, child should display the theme
      expect(find.text('Theme: dark'), findsOneWidget);
    });

    testWidgets('nested children can inject from multiple ancestors', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: GrandparentWidget(),
        ),
      );

      // Grandchild should access both theme from parent and
      // config from grandparent
      expect(find.text('Config: prod, Theme: light'), findsOneWidget);
    });

    testWidgets('child can override parent provided value', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: OverrideParentWidget(),
        ),
      );

      // First child should see parent's value
      expect(find.text('Value: parent'), findsOneWidget);
      // Second child should see overridden value
      expect(find.text('Value: child'), findsOneWidget);
    });

    testWidgets('inject with default value returns default when not found', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: DefaultValueWidget(),
        ),
      );

      // Should use default value
      expect(find.text('Value: default'), findsOneWidget);
    });

    testWidgets('multiple keys with same type do not conflict', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: MultipleKeysWidget(),
        ),
      );

      // Should correctly distinguish between two String values
      expect(find.text('Theme: dark, User: Alice'), findsOneWidget);
    });
  });
}

// Define injection keys
const themeKey = InjectionKey<Ref<AppTheme>>('theme');
const configKey = InjectionKey<Ref<AppConfig>>('config');
const simpleValueKey = InjectionKey<Ref<SimpleValue>>('simpleValue');
const optionalKey = InjectionKey<String>('optional');
const themeStringKey = InjectionKey<Ref<String>>('themeString');
const userNameKey = InjectionKey<Ref<String>>('userName');

class AppTheme {
  const AppTheme(this.mode);
  final String mode;
}

class AppConfig {
  const AppConfig(this.env);
  final String env;
}

class SimpleValue {
  const SimpleValue(this.text);
  final String text;
}

// Test 1: Basic parent-child
class ParentWidget extends CompositionWidget {
  const ParentWidget({super.key});

  @override
  Widget Function(BuildContext) setup() {
    final theme = ref(const AppTheme('dark'));

    // Provide theme to children with key
    provide(themeKey, theme);

    return (context) => const ChildWidget();
  }
}

class ChildWidget extends CompositionWidget {
  const ChildWidget({super.key});

  @override
  Widget Function(BuildContext) setup() {
    // Try to inject theme from parent using key
    final theme = inject(themeKey);

    return (context) => Text('Theme: ${theme.value.mode}');
  }
}

// Test 2: Nested with multiple providers
class GrandparentWidget extends CompositionWidget {
  const GrandparentWidget({super.key});

  @override
  Widget Function(BuildContext) setup() {
    final config = ref(const AppConfig('prod'));
    provide(configKey, config);

    return (context) => const MiddleWidget();
  }
}

class MiddleWidget extends CompositionWidget {
  const MiddleWidget({super.key});

  @override
  Widget Function(BuildContext) setup() {
    final theme = ref(const AppTheme('light'));
    provide(themeKey, theme);

    return (context) => const GrandchildWidget();
  }
}

class GrandchildWidget extends CompositionWidget {
  const GrandchildWidget({super.key});

  @override
  Widget Function(BuildContext) setup() {
    // Should be able to inject from both parent and grandparent using keys
    final config = inject(configKey);
    final theme = inject(themeKey);

    return (context) =>
        Text('Config: ${config.value.env}, Theme: ${theme.value.mode}');
  }
}

// Test 3: Override behavior
class OverrideParentWidget extends CompositionWidget {
  const OverrideParentWidget({super.key});

  @override
  Widget Function(BuildContext) setup() {
    final value = ref(const SimpleValue('parent'));
    provide(simpleValueKey, value);

    return (context) => const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DirectChildWidget(),
            OverrideChildWidget(),
          ],
        );
  }
}

class DirectChildWidget extends CompositionWidget {
  const DirectChildWidget({super.key});

  @override
  Widget Function(BuildContext) setup() {
    final value = inject(simpleValueKey);
    return (context) => Text('Value: ${value.value.text}');
  }
}

class OverrideChildWidget extends CompositionWidget {
  const OverrideChildWidget({super.key});

  @override
  Widget Function(BuildContext) setup() {
    // Override parent's value
    final value = ref(const SimpleValue('child'));
    provide(simpleValueKey, value);

    return (context) => const OverrideGrandchildWidget();
  }
}

class OverrideGrandchildWidget extends CompositionWidget {
  const OverrideGrandchildWidget({super.key});

  @override
  Widget Function(BuildContext) setup() {
    // Should get the overridden value from OverrideChildWidget
    final value = inject(simpleValueKey);
    return (context) => Text('Value: ${value.value.text}');
  }
}

// Test 4: Default value
class DefaultValueWidget extends CompositionWidget {
  const DefaultValueWidget({super.key});

  @override
  Widget Function(BuildContext) setup() {
    // Inject with default value when key not provided
    final value = inject(optionalKey, defaultValue: 'default');
    return (context) => Text('Value: $value');
  }
}

// Test 5: Multiple keys with same type
class MultipleKeysWidget extends CompositionWidget {
  const MultipleKeysWidget({super.key});

  @override
  Widget Function(BuildContext) setup() {
    final theme = ref('dark');
    final userName = ref('Alice');

    // Provide two String values with different keys
    provide(themeStringKey, theme);
    provide(userNameKey, userName);

    return (context) => const MultipleKeysChildWidget();
  }
}

class MultipleKeysChildWidget extends CompositionWidget {
  const MultipleKeysChildWidget({super.key});

  @override
  Widget Function(BuildContext) setup() {
    // Inject both String values without conflict
    final theme = inject(themeStringKey);
    final userName = inject(userNameKey);

    return (context) => Text('Theme: ${theme.value}, User: ${userName.value}');
  }
}
