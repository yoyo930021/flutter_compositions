# Animation Composables

Composables for Flutter animations with automatic disposal and reactive values.

## useAnimationController

Create an `AnimationController` with automatic disposal and reactive value.

### Signature

```dart
(
  AnimationController,
  Ref<double>,
) useAnimationController({
  required Duration duration,
  Duration? reverseDuration,
  String? debugLabel,
  double initialValue = 0.0,
  double lowerBound = 0.0,
  double upperBound = 1.0,
  AnimationBehavior animationBehavior = AnimationBehavior.normal,
})
```

### Returns

A record with:
- `controller` - The AnimationController
- `value` - Reactive ref for current animation value

### Example

```dart
@override
Widget Function(BuildContext) setup() {
  final (controller, animValue) = useAnimationController(
    duration: Duration(seconds: 2),
  );

  onMounted(() {
    controller.repeat(reverse: true);
  });

  return (context) => Opacity(
    opacity: animValue.value,
    child: Text('Fading'),
  );
}
```

### With Rotation

```dart
@override
Widget Function(BuildContext) setup() {
  final (controller, animValue) = useAnimationController(
    duration: Duration(seconds: 2),
  );

  onMounted(() => controller.repeat());

  return (context) => Transform.rotate(
    angle: animValue.value * 2 * pi,
    child: Icon(Icons.refresh),
  );
}
```

## useSingleTickerProvider

Provides a `TickerProvider` for a single `AnimationController`.

### Signature

```dart
TickerProvider useSingleTickerProvider()
```

### Example

```dart
@override
Widget Function(BuildContext) setup() {
  final vsync = useSingleTickerProvider();

  final controller = AnimationController(
    vsync: vsync,
    duration: Duration(seconds: 1),
  );

  onUnmounted(() => controller.dispose());

  onMounted(() => controller.forward());

  return (context) => AnimatedBuilder(
    animation: controller,
    builder: (context, child) => Opacity(
      opacity: controller.value,
      child: Text('Fading in'),
    ),
  );
}
```

## manageAnimation

Manage a `Tween` animation with automatic disposal.

### Signature

```dart
Animation<T> manageAnimation<T>({
  required Animation<double> parent,
  required Tween<T> tween,
})
```

### Example

```dart
@override
Widget Function(BuildContext) setup() {
  final (controller, _) = useAnimationController(
    duration: Duration(milliseconds: 500),
  );

  final colorAnimation = manageAnimation(
    parent: controller,
    tween: ColorTween(
      begin: Colors.red,
      end: Colors.blue,
    ),
  );

  return (context) => AnimatedBuilder(
    animation: colorAnimation,
    builder: (context, child) => Container(
      color: colorAnimation.value,
    ),
  );
}
```

## Complete Animation Example

```dart
class AnimatedBox extends CompositionWidget {
  @override
  Widget Function(BuildContext) setup() {
    final (controller, animValue) = useAnimationController(
      duration: Duration(milliseconds: 800),
    );

    final sizeAnimation = manageAnimation(
      parent: controller,
      tween: Tween<double>(begin: 100, end: 200),
    );

    final colorAnimation = manageAnimation(
      parent: controller,
      tween: ColorTween(begin: Colors.blue, end: Colors.purple),
    );

    final borderRadiusAnimation = manageAnimation(
      parent: controller,
      tween: Tween<double>(begin: 0, end: 50),
    );

    void toggle() {
      if (controller.status == AnimationStatus.completed) {
        controller.reverse();
      } else {
        controller.forward();
      }
    }

    return (context) => GestureDetector(
      onTap: toggle,
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, child) => Container(
          width: sizeAnimation.value,
          height: sizeAnimation.value,
          decoration: BoxDecoration(
            color: colorAnimation.value,
            borderRadius: BorderRadius.circular(borderRadiusAnimation.value),
          ),
        ),
      ),
    );
  }
}
```

## Staggered Animations

```dart
@override
Widget Function(BuildContext) setup() {
  final (controller, _) = useAnimationController(
    duration: Duration(seconds: 2),
  );

  final fadeAnimation = manageAnimation(
    parent: controller,
    tween: Tween<double>(begin: 0, end: 1),
  );

  final slideAnimation = manageAnimation(
    parent: controller,
    tween: Tween<Offset>(
      begin: Offset(0, 0.5),
      end: Offset.zero,
    ),
  );

  onMounted(() => controller.forward());

  return (context) => AnimatedBuilder(
    animation: controller,
    builder: (context, child) => SlideTransition(
      position: slideAnimation,
      child: FadeTransition(
        opacity: fadeAnimation,
        child: Text('Animated text'),
      ),
    ),
  );
}
```

## Curved Animations

```dart
@override
Widget Function(BuildContext) setup() {
  final (controller, _) = useAnimationController(
    duration: Duration(milliseconds: 500),
  );

  final curvedAnimation = CurvedAnimation(
    parent: controller,
    curve: Curves.easeInOut,
  );

  final scaleAnimation = manageAnimation(
    parent: curvedAnimation,
    tween: Tween<double>(begin: 0.5, end: 1.0),
  );

  onMounted(() => controller.repeat(reverse: true));

  return (context) => AnimatedBuilder(
    animation: scaleAnimation,
    builder: (context, child) => Transform.scale(
      scale: scaleAnimation.value,
      child: Icon(Icons.favorite, size: 100),
    ),
  );
}
```

## Best Practices

### Use Composables for Auto-Disposal

```dart
// ❌ Bad: Manual disposal
@override
Widget Function(BuildContext) setup() {
  final vsync = useSingleTickerProvider();
  final controller = AnimationController(vsync: vsync, duration: Duration(seconds: 1));

  onUnmounted(() => controller.dispose()); // Don't forget!

  return (context) => Container();
}

// ✅ Good: Auto-disposal
@override
Widget Function(BuildContext) setup() {
  final (controller, animValue) = useAnimationController(
    duration: Duration(seconds: 1),
  );

  // Automatically disposed!

  return (context) => Container();
}
```

### Control Animations with Reactive State

```dart
@override
Widget Function(BuildContext) setup() {
  final (controller, animValue) = useAnimationController(
    duration: Duration(milliseconds: 300),
  );

  final isExpanded = ref(false);

  watch(() => isExpanded.value, (expanded, _) {
    if (expanded) {
      controller.forward();
    } else {
      controller.reverse();
    }
  });

  return (context) => Column(
    children: [
      ElevatedButton(
        onPressed: () => isExpanded.value = !isExpanded.value,
        child: Text('Toggle'),
      ),
      SizeTransition(
        sizeFactor: controller,
        child: Container(height: 200, color: Colors.blue),
      ),
    ],
  );
}
```

## See Also

- [useAnimationController](#useanimationcontroller) - Animation controller with auto-disposal
- [Lifecycle hooks](../lifecycle.md) - onMounted, onUnmounted
- [watch](../watch.md) - Side effects
