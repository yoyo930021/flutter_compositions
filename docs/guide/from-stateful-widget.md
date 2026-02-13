# Migrating from StatefulWidget

This guide helps you transition from `StatefulWidget` to `CompositionWidget` by showing equivalent patterns side-by-side.

## Table of Contents

1. [Basic Counter](#basic-counter)
2. [Controllers](#controllers)
3. [Lifecycle Methods](#lifecycle-methods)
4. [State Dependencies](#state-dependencies)
5. [Forms](#forms)
6. [Async Operations](#async-operations)
7. [Animations](#animations)
8. [Navigation](#navigation)

## Basic Counter

### StatefulWidget

```dart
class Counter extends StatefulWidget {
  const Counter({super.key});

  @override
  State<Counter> createState() => _CounterState();
}

class _CounterState extends State<Counter> {
  int _count = 0;

  void _increment() {
    setState(() {
      _count++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text('Count: $_count'),
        ElevatedButton(
          onPressed: _increment,
          child: const Text('Increment'),
        ),
      ],
    );
  }
}
```

### CompositionWidget

```dart
class Counter extends CompositionWidget {
  const Counter({super.key});

  @override
  Widget Function(BuildContext) setup() {
    // Reactive state - no setState needed
    final count = ref(0);

    void increment() => count.value++;

    return (context) => Column(
      children: [
        Text('Count: ${count.value}'),
        ElevatedButton(
          onPressed: increment,
          child: const Text('Increment'),
        ),
      ],
    );
  }
}
```

**Key Differences**:
- ✅ No separate State class
- ✅ No `setState()` calls
- ✅ Direct value updates trigger automatic rebuilds
- ✅ Cleaner, more concise code

## Controllers

### StatefulWidget

```dart
class ScrollExample extends StatefulWidget {
  @override
  State<ScrollExample> createState() => _ScrollExampleState();
}

class _ScrollExampleState extends State<ScrollExample> {
  late ScrollController _scrollController;
  double _scrollOffset = 0;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    setState(() {
      _scrollOffset = _scrollController.offset;
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text('Offset: $_scrollOffset'),
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            itemCount: 100,
            itemBuilder: (context, index) => ListTile(
              title: Text('Item $index'),
            ),
          ),
        ),
      ],
    );
  }
}
```

### CompositionWidget

```dart
class ScrollExample extends CompositionWidget {
  @override
  Widget Function(BuildContext) setup() {
    // Auto-disposed controller with reactive offset
    final scrollController = useScrollController();

    final scrollOffset = computed(() {
      // Automatically tracks controller changes
      return scrollController.value.offset;
    });

    return (context) => Column(
      children: [
        Text('Offset: ${scrollOffset.value.toStringAsFixed(1)}'),
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
  }
}
```

**Key Differences**:
- ✅ Automatic disposal (no manual cleanup)
- ✅ No listener management
- ✅ Reactive offset tracking with `computed`
- ✅ Less boilerplate

## Lifecycle Methods

### StatefulWidget

```dart
class LifecycleExample extends StatefulWidget {
  @override
  State<LifecycleExample> createState() => _LifecycleExampleState();
}

class _LifecycleExampleState extends State<LifecycleExample> {
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    print('Widget created');

    WidgetsBinding.instance.addPostFrameCallback((_) {
      print('Widget mounted (first frame)');
    });

    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      print('Timer tick');
    });
  }

  @override
  void dispose() {
    print('Widget disposing');
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    print('Building widget');
    return Container();
  }
}
```

### CompositionWidget

```dart
class LifecycleExample extends CompositionWidget {
  @override
  Widget Function(BuildContext) setup() {
    print('Setup (runs once)');

    onMounted(() {
      print('Widget mounted (first frame)');

      // Timer automatically managed
      final timer = Timer.periodic(Duration(seconds: 1), (timer) {
        print('Timer tick');
      });

      onUnmounted(() {
        print('Cleaning up timer');
        timer.cancel();
      });
    });

    onUnmounted(() {
      print('Widget unmounted');
    });

    onBuild((context) {
      print('Building widget');
    });

    return (context) => Container();
  }
}
```

**Key Differences**:
- ✅ Clear lifecycle hook names
- ✅ Multiple onMounted/onUnmounted supported
- ✅ onBuild hook for build-time logic
- ✅ Cleanup callbacks colocated with initialization

## State Dependencies

### StatefulWidget

```dart
class DependentState extends StatefulWidget {
  @override
  State<DependentState> createState() => _DependentStateState();
}

class _DependentStateState extends State<DependentState> {
  int _count = 0;
  late String _message;

  @override
  void initState() {
    super.initState();
    _updateMessage();
  }

  void _updateMessage() {
    setState(() {
      _message = _count == 0 ? 'Start' : 'Count: $_count';
    });
  }

  void _increment() {
    setState(() {
      _count++;
      _updateMessage();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(_message),
        ElevatedButton(
          onPressed: _increment,
          child: const Text('Increment'),
        ),
      ],
    );
  }
}
```

### CompositionWidget

```dart
class DependentState extends CompositionWidget {
  @override
  Widget Function(BuildContext) setup() {
    final count = ref(0);

    // Automatically updates when count changes
    final message = computed(() =>
      count.value == 0 ? 'Start' : 'Count: ${count.value}'
    );

    void increment() => count.value++;

    return (context) => Column(
      children: [
        Text(message.value),
        ElevatedButton(
          onPressed: increment,
          child: const Text('Increment'),
        ),
      ],
    );
  }
}
```

**Key Differences**:
- ✅ Automatic dependency tracking
- ✅ No manual updates needed
- ✅ Cleaner derived state with `computed`

## Forms

### StatefulWidget

```dart
class LoginForm extends StatefulWidget {
  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  late TextEditingController _emailController;
  late TextEditingController _passwordController;
  bool _isValid = false;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();

    _emailController.addListener(_validate);
    _passwordController.addListener(_validate);
  }

  void _validate() {
    setState(() {
      _isValid = _emailController.text.isNotEmpty &&
                 _passwordController.text.length >= 6;
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_isValid) {
      print('Email: ${_emailController.text}');
      print('Password: ${_passwordController.text}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: _emailController,
          decoration: InputDecoration(labelText: 'Email'),
        ),
        TextField(
          controller: _passwordController,
          decoration: InputDecoration(labelText: 'Password'),
          obscureText: true,
        ),
        ElevatedButton(
          onPressed: _isValid ? _submit : null,
          child: Text('Submit'),
        ),
      ],
    );
  }
}
```

### CompositionWidget

```dart
class LoginForm extends CompositionWidget {
  @override
  Widget Function(BuildContext) setup() {
    final (emailController, email, _) = useTextEditingController();
    final (passwordController, password, _) = useTextEditingController();

    // Reactive validation
    final isValid = computed(() =>
      email.value.isNotEmpty && password.value.length >= 6
    );

    void submit() {
      if (isValid.value) {
        print('Email: ${email.value}');
        print('Password: ${password.value}');
      }
    }

    return (context) => Column(
      children: [
        TextField(
          controller: emailController,
          decoration: InputDecoration(labelText: 'Email'),
        ),
        TextField(
          controller: passwordController,
          decoration: InputDecoration(labelText: 'Password'),
          obscureText: true,
        ),
        ElevatedButton(
          onPressed: isValid.value ? submit : null,
          child: Text('Submit'),
        ),
      ],
    );
  }
}
```

**Key Differences**:
- ✅ Automatic controller disposal
- ✅ Reactive text binding
- ✅ Computed validation
- ✅ No manual listener management

## Async Operations

### StatefulWidget

```dart
class UserProfile extends StatefulWidget {
  final int userId;
  const UserProfile({required this.userId});

  @override
  State<UserProfile> createState() => _UserProfileState();
}

class _UserProfileState extends State<UserProfile> {
  User? _user;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  @override
  void didUpdateWidget(UserProfile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.userId != oldWidget.userId) {
      _loadUser();
    }
  }

  Future<void> _loadUser() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final user = await api.fetchUser(widget.userId);
      if (mounted) {
        setState(() {
          _user = user;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return CircularProgressIndicator();
    if (_error != null) return Text('Error: $_error');
    if (_user == null) return Text('No user');
    return Text('User: ${_user!.name}');
  }
}
```

### CompositionWidget

```dart
class UserProfile extends CompositionWidget {
  final int userId;
  const UserProfile({required this.userId});

  @override
  Widget Function(BuildContext) setup() {
    final props = widget();

    // Auto-refetch when userId changes
    final (userData, _) = useAsyncData<User, int>(
      (userId) => api.fetchUser(userId),
      watch: () => props.value.userId,
    );

    return (context) => switch (userData.value) {
      AsyncLoading() => CircularProgressIndicator(),
      AsyncError(:final errorValue) => Text('Error: $errorValue'),
      AsyncData(:final value) => Text('User: ${value.name}'),
      AsyncIdle() => Text('No user'),
    };
  }
}
```

**Key Differences**:
- ✅ Automatic refetch on prop changes
- ✅ Built-in loading/error/data states
- ✅ No mounted checks needed
- ✅ Pattern matching for clean state handling

## Animations

### StatefulWidget

```dart
class FadeInWidget extends StatefulWidget {
  @override
  State<FadeInWidget> createState() => _FadeInWidgetState();
}

class _FadeInWidgetState extends State<FadeInWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(seconds: 1),
      vsync: this,
    );

    _opacity = Tween<double>(begin: 0.0, end: 1.0).animate(_controller);

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _opacity,
      builder: (context, child) => Opacity(
        opacity: _opacity.value,
        child: child,
      ),
      child: Container(child: Text('Hello')),
    );
  }
}
```

### CompositionWidget

```dart
class FadeInWidget extends CompositionWidget {
  @override
  Widget Function(BuildContext) setup() {
    final (controller, animValue) = useAnimationController(
      duration: Duration(seconds: 1),
    );

    final opacity = computed(() => animValue.value);

    onMounted(() => controller.forward());

    return (context) => Opacity(
      opacity: opacity.value,
      child: Container(child: Text('Hello')),
    );
  }
}
```

**Key Differences**:
- ✅ No mixin required
- ✅ Automatic disposal
- ✅ Reactive animation value
- ✅ Cleaner API

## Prop Reactivity

### StatefulWidget

```dart
class UserGreeting extends StatefulWidget {
  final String username;
  const UserGreeting({required this.username});

  @override
  State<UserGreeting> createState() => _UserGreetingState();
}

class _UserGreetingState extends State<UserGreeting> {
  late String _greeting;

  @override
  void initState() {
    super.initState();
    _updateGreeting();
  }

  @override
  void didUpdateWidget(UserGreeting oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.username != oldWidget.username) {
      _updateGreeting();
    }
  }

  void _updateGreeting() {
    setState(() {
      _greeting = 'Hello, ${widget.username}!';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Text(_greeting);
  }
}
```

### CompositionWidget

```dart
class UserGreeting extends CompositionWidget {
  final String username;
  const UserGreeting({required this.username});

  @override
  Widget Function(BuildContext) setup() {
    final props = widget();

    // Automatically updates when username changes
    final greeting = computed(() => 'Hello, ${props.value.username}!');

    return (context) => Text(greeting.value);
  }
}
```

**Key Differences**:
- ✅ No `didUpdateWidget` needed
- ✅ Automatic prop change detection
- ✅ Cleaner reactive code

## Migration Checklist

When migrating from StatefulWidget:

- [ ] Replace State class with `setup()` method
- [ ] Convert `setState(() => field = value)` to `ref.value = value`
- [ ] Replace `initState` logic with `setup()` body
- [ ] Replace `dispose` with `onUnmounted`
- [ ] Use `onMounted` for post-first-frame logic
- [ ] Replace controllers with `use*` helpers
- [ ] Use `widget()` for reactive prop access
- [ ] Convert derived state to `computed`
- [ ] Replace listeners with `watch` or `watchEffect`
- [ ] Test that hot reload works correctly

## Best Practices

### ✅ Do

```dart
// Use refs for mutable state
final count = ref(0);

// Use computed for derived state
final doubled = computed(() => count.value * 2);

// Use composables for reusable logic
final (controller, text) = useTextEditingController();

// Use widget() for props
final props = widget();
final name = computed(() => props.value.username);
```

### ❌ Don't

```dart
// Don't use mutable fields
int count = 0; // ❌ Not reactive

// Don't access props directly in setup
final name = this.username; // ❌ Not reactive

// Don't forget .value
if (count == 5) { /* ❌ compares Ref objects */ }

// Don't manually dispose when using use* helpers
final controller = useScrollController();
controller.value.dispose(); // ❌ Already handled
```

## Conclusion

CompositionWidget offers a more modern, reactive approach to Flutter state management while maintaining full compatibility with Flutter's widget system. The migration path is straightforward, and the benefits in code clarity and maintainability are significant.

For more information:
- [Introduction](./introduction.md) — what Flutter Compositions offers vs. alternatives
- [Reactivity Fundamentals](./reactivity-fundamentals.md)
- [Built-in Composables](./built-in-composables.md)
- [Creating Composables](./creating-composables.md)
