# Creating Your Own Composables

The built-in `use` functions are convenient, but the real power of `flutter_compositions` comes from the ability to easily create your own composable functions (Composables).

## What is a Composable?

A Composable is a regular Dart function whose name starts with `use`. It allows you to encapsulate reactive logic and lifecycle management related to a specific feature so that it can be reused across different `CompositionWidget`s.

The main benefits of creating your own Composables are:

- **Logic Reusability**: Extract stateful logic from your widgets to avoid writing the same code over and over.
- **Separation of Concerns**: Keep your `setup` methods clean and focused on composing different Composables, rather than implementing all the details.
- **Testability**: Independent Composable functions are easier to unit test than large widgets.

## Example: Creating `useOrientation`

Let's create a `useOrientation` Composable that returns a reactive `Ref` indicating the current device orientation (portrait or landscape).

**1. Create a `use_orientation.dart` file**

```dart
import 'package:flutter/widgets.dart';
import 'package:flutter_compositions/flutter_compositions.dart';

// A Composable is just a function that starts with `use`
Ref<Orientation> useOrientation() {
  // 1. Create a ref to store the current orientation
  final orientation = ref(Orientation.portrait);

  // 2. Use onMounted because we need a BuildContext to get MediaQuery
  onMounted(() {
    // Get the current BuildContext
    final context = inject<BuildContext>();

    // Set the initial value
    orientation.value = MediaQuery.of(context).orientation;

    // Note: In a real-world app, you would need a more robust way
    // to listen for orientation changes, e.g., using `WidgetsBindingObserver`.
    // For simplicity, we only set it once on mount.
  });

  // 3. Return the reactive reference
  return orientation;
}
```

**Important Tip**: In the example above, we used `inject<BuildContext>()` to get the `BuildContext` inside `onMounted`. This is a little trick, as the `CompositionWidget` framework automatically provides the current `BuildContext` before executing the `builder` function.

**2. Use It in Your Widget**

Now, you can use `useOrientation` in your `setup` method just like any built-in Composable.

```dart
import './use_orientation.dart'; // Import the Composable you created

class OrientationAwareWidget extends CompositionWidget {
  const OrientationAwareWidget({super.key});

  @override
  Widget Function(BuildContext) setup() {
    // Call it just like a built-in function
    final orientation = useOrientation();

    // Create a computed property to display different text
    final message = computed(() {
      return orientation.value == Orientation.portrait
          ? 'Currently in Portrait Mode'
          : 'Currently in Landscape Mode';
    });

    return (context) => Scaffold(
      appBar: AppBar(title: const Text('Orientation')),
      body: Center(
        child: Text(message.value), // The UI will react to changes automatically
      ),
    );
  }
}
```

Using this pattern, you can create all sorts of reusable logic, such as:

- `useConnectivity()`: To monitor network connection status.
- `useGeolocation()`: To track the user's geographical location.
- `useForm()`: To encapsulate the state and validation logic of a complex form.

Decomposing your application logic into small, manageable, and reusable Composables is the best practice when working with `flutter_compositions`.
