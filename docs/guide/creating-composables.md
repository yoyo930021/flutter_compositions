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

**1. Create a `use_media_query.dart` file**

```dart
import 'package:flutter/widgets.dart';
import 'package:flutter_compositions/flutter_compositions.dart';

// A Composable is just a function that starts with `use`
(Ref<Size>, Ref<Orientation>) useMediaQuery() {
  // 1. Create refs to store reactive values
  final size = ref(Size.zero);
  final orientation = ref(Orientation.portrait);

  // 2. Use onBuild to access BuildContext on each build
  // This allows us to react to MediaQuery changes
  onBuild((context) {
    final mediaQuery = MediaQuery.of(context);
    size.value = mediaQuery.size;
    orientation.value = mediaQuery.orientation;
  });

  // 3. Return the reactive references
  return (size, orientation);
}
```

**Important Tip**: The example above uses `onBuild()` to access `BuildContext` on each build. This is the recommended way to integrate with Flutter's `InheritedWidget` system (like `MediaQuery`, `Theme`, etc.).

**Alternative - Using useContextRef()**: If you need to access context-dependent values reactively, use `useContextRef()`:

```dart
ReadonlyRef<OverlayState> useOverlayState() {
  return useContextRef((context) => Overlay.of(context));
}
```

**2. Use It in Your Widget**

Now, you can use `useMediaQuery` in your `setup` method just like any built-in Composable.

```dart
import '../en/guide/use_media_query.dart'; // Import the Composable you created

class ResponsiveWidget extends CompositionWidget {
  const ResponsiveWidget({super.key});

  @override
  Widget Function(BuildContext) setup() {
    // Call it just like a built-in function
    final (screenSize, orientation) = useMediaQuery();

    // Create computed properties based on screen info
    final isPortrait = computed(() => orientation.value == Orientation.portrait);
    final isSmallScreen = computed(() => screenSize.value.width < 600);

    final message = computed(() {
      final orientationText = isPortrait.value ? 'Portrait' : 'Landscape';
      final sizeText = isSmallScreen.value ? 'Small' : 'Large';
      return 'Screen: $sizeText, $orientationText (${screenSize.value.width.toInt()}x${screenSize.value.height.toInt()})';
    });

    return (context) => Scaffold(
      appBar: AppBar(title: const Text('Responsive')),
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
