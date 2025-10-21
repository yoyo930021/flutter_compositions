import 'package:flutter/material.dart';
import 'package:flutter_compositions/flutter_compositions.dart';

import 'demos/animations_example.dart';
import 'demos/composition_builder_example.dart';
import 'demos/controllers_example.dart';
import 'demos/props_best_practices.dart';
import 'demos/props_class_pattern.dart';
import 'demos/use_text_field_example.dart';
import 'demos/value_notifier_example.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Compositions Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const ExamplesHomePage(),
    );
  }
}

class DemoDefinition {
  const DemoDefinition({
    required this.title,
    required this.description,
    required this.builder,
  });

  final String title;
  final String description;
  final WidgetBuilder builder;
}

class ExamplesHomePage extends StatelessWidget {
  const ExamplesHomePage({super.key});

  static final List<DemoDefinition> demos = [
    DemoDefinition(
      title: 'Counter & Core APIs',
      description: 'widget(), provide/inject, useTextEditingController, watch',
      builder: (context) => const CounterPage(),
    ),
    DemoDefinition(
      title: 'Animation Composables',
      description:
          'useAnimationController, manageAnimation, Tweens, and Curves',
      builder: (context) => const AnimationsExamplePage(),
    ),
    DemoDefinition(
      title: 'CompositionBuilder',
      description: 'Inline reactive widgets without defining classes',
      builder: (context) => const CompositionBuilderDemo(),
    ),
    DemoDefinition(
      title: 'Controller Integrations',
      description:
          'use* helpers with Text, Scroll, Page, and Focus controllers',
      builder: (context) => const ControllersExamplePage(),
    ),
    DemoDefinition(
      title: 'useTextEditingController showcase',
      description: 'Two-way binding and validation helpers',
      builder: (context) => const UseTextFieldExamplePage(),
    ),
    DemoDefinition(
      title: 'ValueNotifier integration',
      description: 'Bridge existing ValueNotifiers with manageValueListenable',
      builder: (context) => const ValueNotifierDemo(),
    ),
    DemoDefinition(
      title: 'Props best practices',
      description: 'Common pitfalls and recommended patterns',
      builder: (context) => const PropsBestPracticesPage(),
    ),
    DemoDefinition(
      title: 'Props class patterns',
      description: 'Reusable prop objects, validation, and sealed unions',
      builder: (context) => const PropsClassPatternsPage(),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Flutter Compositions Examples')),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: demos.length,
        separatorBuilder: (_, __) => const SizedBox(height: 16),
        itemBuilder: (context, index) {
          final demo = demos[index];
          return Card(
            child: ListTile(
              title: Text(demo.title),
              subtitle: Text(demo.description),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.of(
                  context,
                ).push(MaterialPageRoute<void>(builder: demo.builder));
              },
            ),
          );
        },
      ),
    );
  }
}

/// A component that demonstrates widget() with reactive props
class UserCard extends CompositionWidget {
  const UserCard({
    super.key,
    required this.userId,
    required this.name,
    this.role = 'User',
  });

  final String userId;
  final String name;
  final String role;

  @override
  Widget Function(BuildContext) setup() {
    // Get reactive widget reference (similar to State.widget in StatefulWidget)
    final w = widget();
    // Type is inferred as ComputedRef<UserCard>

    // Create computed values based on widget properties
    final displayName = computed(() => '${w.value.name} (#${w.value.userId})');
    final greeting = computed(() => 'Hello, ${w.value.name}!');
    final roleInfo = computed(() => 'Role: ${w.value.role}');

    // Watch for property changes
    watch(() => w.value.name, (newName, oldName) {
      debugPrint('Name changed: $oldName -> $newName');
    });

    watch(() => w.value.userId, (newId, oldId) {
      debugPrint('User ID changed: $oldId -> $newId');
    });

    return (context) => Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(greeting.value, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              displayName.value,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 4),
            Text(
              roleInfo.value,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }
}

/// Custom data class for theme configuration
class AppTheme {
  AppTheme(this.mode);
  String mode;
}

/// Define injection key for type-safe provide/inject
final themeKey = InjectionKey<Ref<AppTheme>>('app.theme');

/// A component that demonstrates provide/inject pattern with InjectionKey
class ThemeProvider extends CompositionWidget {
  const ThemeProvider({super.key});

  @override
  Widget Function(BuildContext) setup() {
    // Create a custom theme state
    final theme = ref(AppTheme('light'));

    // Provide using InjectionKey for type-safe dependency injection
    provide(themeKey, theme);

    return (context) => Column(
      children: [
        Card(
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Current Theme: ${theme.value.mode}'),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'light', label: Text('Light')),
                    ButtonSegment(value: 'dark', label: Text('Dark')),
                  ],
                  selected: {theme.value.mode},
                  onSelectionChanged: (Set<String> newSelection) {
                    // Replace the entire object to trigger reactivity
                    theme.value = AppTheme(newSelection.first);
                  },
                ),
              ],
            ),
          ),
        ),
        const ThemeConsumer(),
      ],
    );
  }
}

/// A component that injects the theme from parent
class ThemeConsumer extends CompositionWidget {
  const ThemeConsumer({super.key});

  @override
  Widget Function(BuildContext) setup() {
    // Inject by InjectionKey - type safe and no conflicts!
    final theme = inject(themeKey);

    final themeMessage = computed(
      () => 'Using ${theme.value.mode} theme from parent!',
    );

    return (context) => Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          themeMessage.value,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ),
    );
  }
}

/// A component that demonstrates useTextEditingController with reactive state
class UserGreeting extends CompositionWidget {
  const UserGreeting({super.key});

  @override
  Widget Function(BuildContext) setup() {
    // useTextEditingController returns (controller, text, value)
    // Note: controller is the raw TextEditingController (not a ref)
    final (usernameController, username, _) = useTextEditingController(
      text: 'User',
    );
    final (prefixController, prefix, _) = useTextEditingController(
      text: 'Hello',
    );

    // Use reactive features on the text refs
    final greeting = computed(() => '${prefix.value}, ${username.value}!');

    // Watch changes
    watch(() => username.value, (newValue, oldValue) {
      debugPrint('Username changed: $oldValue -> $newValue');
    });

    return (context) => Card(
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              greeting.value,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: usernameController,
              decoration: const InputDecoration(
                labelText: 'Username',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'Hello', label: Text('Hello')),
                ButtonSegment(value: 'Hi', label: Text('Hi')),
                ButtonSegment(value: 'Welcome', label: Text('Welcome')),
              ],
              selected: {prefix.value},
              onSelectionChanged: (Set<String> newSelection) {
                prefix.value = newSelection.first;
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// A counter page demonstrating Vue Composition API style in Flutter
class CounterPage extends CompositionWidget {
  const CounterPage({super.key});

  @override
  Widget Function(BuildContext) setup() {
    // Create reactive state (like Vue's ref())
    // This only runs once, not on every rebuild!
    final count = ref(0);
    final currentUserId = ref('user-1');
    final currentUserName = ref('Alice');

    // Create computed values (like Vue's computed())
    final doubled = computed(() => count.value * 2);
    final quadrupled = computed(() => (doubled.value / 3).round());
    final sum = computed(() => quadrupled.value * 2);

    // Watch for changes (like Vue's watch())
    watch(() => count.value, (newValue, oldValue) {
      debugPrint('Count changed from $oldValue to $newValue');
    });

    // Effect that runs on every reactive dependency change
    watchEffect(() {
      debugPrint('Effect: count is ${count.value}');
    });

    watchEffect(() {
      debugPrint('Effect: sum is ${sum.value}');
    });

    // Lifecycle hooks
    onMounted(() {
      debugPrint('CounterPage mounted!');
    });

    onUnmounted(() {
      debugPrint('CounterPage unmounted!');
    });

    // Return a builder function that will be called on reactive updates
    // Access InheritedWidgets (Theme, MediaQuery) here, not in setup!
    return (context) => Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Flutter Compositions Demo'),
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                // widget() demo section
                const Text(
                  'widget() Demo - Reactive Props',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                UserCard(
                  userId: currentUserId.value,
                  name: currentUserName.value,
                  role: 'Administrator',
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () {
                    // Toggle user to demonstrate reactive props
                    if (currentUserId.value == 'user-1') {
                      currentUserId.value = 'user-2';
                      currentUserName.value = 'Bob';
                    } else {
                      currentUserId.value = 'user-1';
                      currentUserName.value = 'Alice';
                    }
                  },
                  child: const Text('Toggle User'),
                ),
                const Divider(height: 40),
                // provide/inject demo section
                const Text(
                  'Provide/Inject Demo',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                const ThemeProvider(),
                const Divider(height: 40),
                // useTextEditingController demo section
                const Text(
                  'useTextEditingController Demo',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                const UserGreeting(),
                const Divider(height: 40),
                // Counter section
                const Text('You have pushed the button this many times:'),
                const SizedBox(height: 20),
                Text(
                  '${count.value}',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 10),
                Text(
                  'Doubled: ${doubled.value}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 10),
                Text(
                  'Quadrupled: ${quadrupled.value}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 40),
                Text(
                  'Sum (Quadrupled * 2): ${sum.value}',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {
                        count.value--;
                      },
                      icon: const Icon(Icons.remove),
                      label: const Text('Decrement'),
                    ),
                    const SizedBox(width: 20),
                    ElevatedButton.icon(
                      onPressed: () {
                        count.value = 0;
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('Reset'),
                    ),
                    const SizedBox(width: 20),
                    ElevatedButton.icon(
                      onPressed: () {
                        count.value++;
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Increment'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          count.value++;
        },
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}
