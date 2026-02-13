# Animations

Animations bring your application to life. This guide explores how to create smooth animations using Flutter Compositions, including basic animations, staggered animations, reactive animation control, and animation patterns.

## Why Use Composables for Animations?

In traditional Flutter, animation controllers require manual lifecycle management:

```dart
// ❌ Traditional approach - lots of boilerplate
class _MyWidgetState extends State<MyWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: 1),
    );
  }

  @override
  void dispose() {
    _controller.dispose(); // Don't forget!
    super.dispose();
  }
}

// ✅ Compositions approach - concise and safe
@override
Widget Function(BuildContext) setup() {
  final (controller, animValue) = useAnimationController(
    duration: Duration(seconds: 1),
  );
  // Automatically disposed!

  return (context) => /* ... */;
}
```

## useAnimationController - Basic Animations

`useAnimationController` creates an `AnimationController` with automatic disposal and reactive value tracking.

### Simple Fade In

```dart
class FadeInWidget extends CompositionWidget {
  @override
  Widget Function(BuildContext) setup() {
    final (controller, animValue) = useAnimationController(
      duration: Duration(milliseconds: 500),
    );

    onMounted(() {
      controller.forward();
    });

    return (context) => FadeTransition(
      opacity: controller,
      child: Text('Hello, World!'),
    );
  }
}
```

### Using Reactive Values

```dart
class PulsingHeart extends CompositionWidget {
  @override
  Widget Function(BuildContext) setup() {
    final (controller, animValue) = useAnimationController(
      duration: Duration(milliseconds: 800),
    );

    onMounted(() {
      controller.repeat(reverse: true);
    });

    return (context) => Transform.scale(
      scale: 1.0 + (animValue.value * 0.2), // 1.0 to 1.2
      child: Icon(Icons.favorite, size: 100, color: Colors.red),
    );
  }
}
```

### Rotation Animation

```dart
class SpinningIcon extends CompositionWidget {
  @override
  Widget Function(BuildContext) setup() {
    final (controller, animValue) = useAnimationController(
      duration: Duration(seconds: 2),
    );

    onMounted(() {
      controller.repeat();
    });

    return (context) => Transform.rotate(
      angle: animValue.value * 2 * pi,
      child: Icon(Icons.refresh, size: 48),
    );
  }
}
```

## Interpolated Animations

Use `Tween` to interpolate between values.

### Size Animation

```dart
class GrowingBox extends CompositionWidget {
  @override
  Widget Function(BuildContext) setup() {
    final (controller, _) = useAnimationController(
      duration: Duration(milliseconds: 600),
    );

    final sizeAnimation = manageAnimation(
      parent: controller,
      tween: Tween<double>(begin: 50, end: 200),
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
        animation: sizeAnimation,
        builder: (context, child) => Container(
          width: sizeAnimation.value,
          height: sizeAnimation.value,
          color: Colors.blue,
        ),
      ),
    );
  }
}
```

### Color Animation

```dart
class ColorChangingBox extends CompositionWidget {
  @override
  Widget Function(BuildContext) setup() {
    final (controller, _) = useAnimationController(
      duration: Duration(seconds: 2),
    );

    final colorAnimation = manageAnimation(
      parent: controller,
      tween: ColorTween(
        begin: Colors.blue,
        end: Colors.purple,
      ),
    );

    onMounted(() => controller.repeat(reverse: true));

    return (context) => AnimatedBuilder(
      animation: colorAnimation,
      builder: (context, child) => Container(
        width: 200,
        height: 200,
        color: colorAnimation.value,
      ),
    );
  }
}
```

### Multiple Animations

Animate multiple properties simultaneously:

```dart
class AnimatedCard extends CompositionWidget {
  @override
  Widget Function(BuildContext) setup() {
    final (controller, _) = useAnimationController(
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

    final rotationAnimation = manageAnimation(
      parent: controller,
      tween: Tween<double>(begin: 0, end: 0.1),
    );

    void toggle() {
      if (controller.isCompleted) {
        controller.reverse();
      } else {
        controller.forward();
      }
    }

    return (context) => GestureDetector(
      onTap: toggle,
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, child) => Transform.rotate(
          angle: rotationAnimation.value,
          child: Container(
            width: sizeAnimation.value,
            height: sizeAnimation.value,
            decoration: BoxDecoration(
              color: colorAnimation.value,
              borderRadius: BorderRadius.circular(
                borderRadiusAnimation.value,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
```

## Curved Animations

Use easing curves to make animations more natural.

### Using Built-in Curves

```dart
class BouncingBox extends CompositionWidget {
  @override
  Widget Function(BuildContext) setup() {
    final (controller, _) = useAnimationController(
      duration: Duration(milliseconds: 1000),
    );

    final curvedAnimation = CurvedAnimation(
      parent: controller,
      curve: Curves.elasticOut, // Elastic easing
    );

    final scaleAnimation = manageAnimation(
      parent: curvedAnimation,
      tween: Tween<double>(begin: 0, end: 1),
    );

    onMounted(() => controller.forward());

    return (context) => AnimatedBuilder(
      animation: scaleAnimation,
      builder: (context, child) => Transform.scale(
        scale: scaleAnimation.value,
        child: Container(
          width: 100,
          height: 100,
          color: Colors.blue,
        ),
      ),
    );
  }
}
```

### Different Curves for Different Phases

```dart
class ComplexCurveBox extends CompositionWidget {
  @override
  Widget Function(BuildContext) setup() {
    final (controller, _) = useAnimationController(
      duration: Duration(seconds: 2),
    );

    final curvedAnimation = CurvedAnimation(
      parent: controller,
      curve: Curves.easeInOut,
      reverseCurve: Curves.bounceOut, // Use different curve when reversing
    );

    final positionAnimation = manageAnimation(
      parent: curvedAnimation,
      tween: Tween<Offset>(
        begin: Offset.zero,
        end: Offset(1, 0),
      ),
    );

    onMounted(() => controller.repeat(reverse: true));

    return (context) => SlideTransition(
      position: positionAnimation,
      child: Container(
        width: 100,
        height: 100,
        color: Colors.blue,
      ),
    );
  }
}
```

## Staggered Animations

Create complex sequenced animations.

### Sequential Transitions

```dart
class StaggeredAnimation extends CompositionWidget {
  @override
  Widget Function(BuildContext) setup() {
    final (controller, _) = useAnimationController(
      duration: Duration(milliseconds: 2000),
    );

    // 0.0 - 0.3: Fade in
    final fadeAnimation = manageAnimation(
      parent: controller,
      tween: Tween<double>(begin: 0, end: 1),
    );

    // 0.2 - 0.6: Slide
    final slideAnimation = manageAnimation(
      parent: CurvedAnimation(
        parent: controller,
        curve: Interval(0.2, 0.6, curve: Curves.easeOut),
      ),
      tween: Tween<Offset>(
        begin: Offset(0, 0.5),
        end: Offset.zero,
      ),
    );

    // 0.5 - 1.0: Scale
    final scaleAnimation = manageAnimation(
      parent: CurvedAnimation(
        parent: controller,
        curve: Interval(0.5, 1.0, curve: Curves.elasticOut),
      ),
      tween: Tween<double>(begin: 0.5, end: 1.0),
    );

    onMounted(() => controller.forward());

    return (context) => AnimatedBuilder(
      animation: controller,
      builder: (context, child) => FadeTransition(
        opacity: fadeAnimation,
        child: SlideTransition(
          position: slideAnimation,
          child: Transform.scale(
            scale: scaleAnimation.value,
            child: Container(
              width: 200,
              height: 200,
              color: Colors.blue,
              child: Center(
                child: Text(
                  'Hello!',
                  style: TextStyle(color: Colors.white, fontSize: 24),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
```

### Staggered List Items

```dart
class StaggeredListAnimation extends CompositionWidget {
  @override
  Widget Function(BuildContext) setup() {
    final items = ['Apple', 'Banana', 'Cherry', 'Date', 'Elderberry'];

    final (controller, _) = useAnimationController(
      duration: Duration(milliseconds: 1200),
    );

    onMounted(() => controller.forward());

    return (context) => ListView.builder(
      itemCount: items.length,
      itemBuilder: (context, index) {
        // Each item has a slight delay
        final start = index * 0.1;
        final end = start + 0.4;

        final animation = CurvedAnimation(
          parent: controller,
          curve: Interval(start, end, curve: Curves.easeOut),
        );

        return SlideTransition(
          position: Tween<Offset>(
            begin: Offset(1, 0),
            end: Offset.zero,
          ).animate(animation),
          child: FadeTransition(
            opacity: animation,
            child: ListTile(title: Text(items[index])),
          ),
        );
      },
    );
  }
}
```

## Reactive Animation Control

Control animations using reactive state.

### Toggle Animation

```dart
class ExpandableCard extends CompositionWidget {
  @override
  Widget Function(BuildContext) setup() {
    final isExpanded = ref(false);

    final (controller, _) = useAnimationController(
      duration: Duration(milliseconds: 300),
    );

    final heightAnimation = manageAnimation(
      parent: controller,
      tween: Tween<double>(begin: 100, end: 300),
    );

    // Watch state changes and control animation
    watch(
      () => isExpanded.value,
      (expanded, _) {
        if (expanded) {
          controller.forward();
        } else {
          controller.reverse();
        }
      },
    );

    return (context) => Column(
      children: [
        ElevatedButton(
          onPressed: () => isExpanded.value = !isExpanded.value,
          child: Text(isExpanded.value ? 'Collapse' : 'Expand'),
        ),
        AnimatedBuilder(
          animation: heightAnimation,
          builder: (context, child) => Container(
            width: 300,
            height: heightAnimation.value,
            color: Colors.blue,
            child: Center(
              child: Text(
                'Expandable Content',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
```

### Condition-Based Animation

```dart
class ConditionalAnimation extends CompositionWidget {
  @override
  Widget Function(BuildContext) setup() {
    final status = ref<Status>(Status.idle);

    final (controller, _) = useAnimationController(
      duration: Duration(milliseconds: 500),
    );

    final colorAnimation = manageAnimation(
      parent: controller,
      tween: ColorTween(begin: Colors.grey, end: Colors.green),
    );

    watch(
      () => status.value,
      (newStatus, _) {
        switch (newStatus) {
          case Status.loading:
            controller.repeat();
          case Status.success:
            controller.forward();
          case Status.error:
            controller.reverse();
          case Status.idle:
            controller.reset();
        }
      },
    );

    return (context) => AnimatedBuilder(
      animation: colorAnimation,
      builder: (context, child) => Container(
        width: 100,
        height: 100,
        color: colorAnimation.value,
      ),
    );
  }
}

enum Status { idle, loading, success, error }
```

### Data-Driven Animation

```dart
class DataDrivenChart extends CompositionWidget {
  @override
  Widget Function(BuildContext) setup() {
    final value = ref(0.0);
    final targetValue = ref(75.0);

    final (controller, _) = useAnimationController(
      duration: Duration(milliseconds: 800),
    );

    final valueAnimation = manageAnimation(
      parent: CurvedAnimation(
        parent: controller,
        curve: Curves.easeInOut,
      ),
      tween: Tween<double>(begin: 0, end: 100),
    );

    // Watch target value changes
    watch(
      () => targetValue.value,
      (target, _) {
        valueAnimation.tween = Tween<double>(
          begin: value.value,
          end: target,
        );
        controller.forward(from: 0);
      },
    );

    // Update current value
    watchEffect(() {
      value.value = valueAnimation.value;
    });

    return (context) => Column(
      children: [
        // Progress bar
        AnimatedBuilder(
          animation: valueAnimation,
          builder: (context, child) => LinearProgressIndicator(
            value: valueAnimation.value / 100,
          ),
        ),

        // Current value
        Text('${value.value.toStringAsFixed(1)}%'),

        // Controls
        Slider(
          value: targetValue.value,
          min: 0,
          max: 100,
          onChanged: (v) => targetValue.value = v,
        ),
      ],
    );
  }
}
```

## Real-World Examples

### Loading Indicator

```dart
class CustomLoader extends CompositionWidget {
  @override
  Widget Function(BuildContext) setup() {
    final (controller, animValue) = useAnimationController(
      duration: Duration(milliseconds: 1500),
    );

    onMounted(() => controller.repeat());

    final dots = [0, 1, 2];

    return (context) => Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: dots.map((index) {
        // Each dot has a different delay
        final delay = index * 0.2;
        final scale = sin((animValue.value + delay) * 2 * pi) * 0.5 + 1;

        return Transform.scale(
          scale: scale,
          child: Container(
            width: 10,
            height: 10,
            margin: EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: Colors.blue,
              shape: BoxShape.circle,
            ),
          ),
        );
      }).toList(),
    );
  }
}
```

### Swipe to Dismiss

```dart
class SwipeToDismiss extends CompositionWidget {
  const SwipeToDismiss({required this.child, required this.onDismissed});
  final Widget child;
  final VoidCallback onDismissed;

  @override
  Widget Function(BuildContext) setup() {
    final offset = ref(Offset.zero);
    final isDragging = ref(false);

    final (controller, _) = useAnimationController(
      duration: Duration(milliseconds: 200),
    );

    final slideAnimation = manageAnimation(
      parent: controller,
      tween: Tween<Offset>(begin: Offset.zero, end: Offset(-1, 0)),
    );

    void onPanStart(DragStartDetails details) {
      isDragging.value = true;
      controller.stop();
    }

    void onPanUpdate(DragUpdateDetails details) {
      offset.value = Offset(
        (offset.value.dx + details.delta.dx).clamp(-300, 0),
        0,
      );
    }

    void onPanEnd(DragEndDetails details) {
      isDragging.value = false;

      if (offset.value.dx < -100) {
        // Swipe distance is sufficient, dismiss
        controller.forward().then((_) => onDismissed());
      } else {
        // Snap back
        offset.value = Offset.zero;
      }
    }

    final props = widget();

    return (context) => GestureDetector(
      onPanStart: onPanStart,
      onPanUpdate: onPanUpdate,
      onPanEnd: onPanEnd,
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, child) {
          final currentOffset = isDragging.value
              ? offset.value
              : slideAnimation.value;

          return Transform.translate(
            offset: currentOffset,
            child: props.value.child,
          );
        },
      ),
    );
  }
}
```

### Pull to Refresh

```dart
class PullToRefresh extends CompositionWidget {
  const PullToRefresh({required this.onRefresh, required this.child});
  final Future<void> Function() onRefresh;
  final Widget child;

  @override
  Widget Function(BuildContext) setup() {
    final scrollController = useScrollController();
    final pullDistance = ref(0.0);
    final isRefreshing = ref(false);

    final (controller, animValue) = useAnimationController(
      duration: Duration(milliseconds: 500),
    );

    final rotationAnimation = manageAnimation(
      parent: controller,
      tween: Tween<double>(begin: 0, end: 2 * pi),
    );

    void checkRefresh() {
      if (pullDistance.value > 80 && !isRefreshing.value) {
        isRefreshing.value = true;
        controller.repeat();

        onRefresh().then((_) {
          isRefreshing.value = false;
          controller.stop();
          pullDistance.value = 0;
        });
      }
    }

    final props = widget();

    return (context) => NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification is ScrollUpdateNotification) {
          if (scrollController.value.position.pixels < 0) {
            pullDistance.value = -scrollController.value.position.pixels;
          }
        } else if (notification is ScrollEndNotification) {
          checkRefresh();
        }
        return false;
      },
      child: Stack(
        children: [
          ListView(
            controller: scrollController.raw, // .raw avoids unnecessary rebuilds
            children: [props.value.child],
          ),
          if (pullDistance.value > 0)
            Positioned(
              top: pullDistance.value - 40,
              left: 0,
              right: 0,
              child: Center(
                child: AnimatedBuilder(
                  animation: rotationAnimation,
                  builder: (context, child) => Transform.rotate(
                    angle: isRefreshing.value
                        ? rotationAnimation.value
                        : pullDistance.value / 80 * pi,
                    child: Icon(Icons.refresh, size: 32),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
```

### Parallax Scrolling

```dart
class ParallaxScroll extends CompositionWidget {
  @override
  Widget Function(BuildContext) setup() {
    final scrollController = useScrollController();
    final scrollOffset = ref(0.0);

    watchEffect(() {
      scrollOffset.value = scrollController.value.offset;
    });

    return (context) => CustomScrollView(
      controller: scrollController.raw, // .raw avoids unnecessary rebuilds
      slivers: [
        SliverAppBar(
          expandedHeight: 300,
          flexibleSpace: FlexibleSpaceBar(
            background: Transform.translate(
              offset: Offset(0, scrollOffset.value * 0.5), // Parallax effect
              child: Image.network(
                'https://example.com/image.jpg',
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) => ListTile(title: Text('Item $index')),
            childCount: 50,
          ),
        ),
      ],
    );
  }
}
```

## Animation Composition

Create reusable animation composables.

```dart
// Reusable fade-in animation composable
(AnimationController, Animation<double>) useFadeIn({
  Duration duration = const Duration(milliseconds: 300),
  bool autoStart = true,
}) {
  final (controller, _) = useAnimationController(duration: duration);

  final fadeAnimation = manageAnimation(
    parent: controller,
    tween: Tween<double>(begin: 0, end: 1),
  );

  if (autoStart) {
    onMounted(() => controller.forward());
  }

  return (controller, fadeAnimation);
}

// Usage
class MyWidget extends CompositionWidget {
  @override
  Widget Function(BuildContext) setup() {
    final (controller, fadeAnimation) = useFadeIn();

    return (context) => FadeTransition(
      opacity: fadeAnimation,
      child: Text('Fading in!'),
    );
  }
}
```

## Performance Considerations

### 1. Use const Widgets

```dart
// ✅ Good - const widget won't rebuild
return AnimatedBuilder(
  animation: animation,
  builder: (context, child) => Transform.scale(
    scale: animation.value,
    child: child,
  ),
  child: const ExpensiveWidget(), // const!
);
```

### 2. Limit AnimatedBuilder Scope

```dart
// ❌ Bad - entire tree rebuilds
return AnimatedBuilder(
  animation: controller,
  builder: (context, child) => Column(
    children: [
      Transform.scale(scale: controller.value, child: Icon(Icons.star)),
      ExpensiveWidget(),
      AnotherExpensiveWidget(),
    ],
  ),
);

// ✅ Good - only animated part rebuilds
return Column(
  children: [
    AnimatedBuilder(
      animation: controller,
      builder: (context, child) => Transform.scale(
        scale: controller.value,
        child: Icon(Icons.star),
      ),
    ),
    const ExpensiveWidget(),
    const AnotherExpensiveWidget(),
  ],
);
```

### 3. Reuse Animations

```dart
// ✅ Good - single controller, multiple animations
final (controller, _) = useAnimationController(
  duration: Duration(seconds: 1),
);

final scaleAnimation = manageAnimation(
  parent: controller,
  tween: Tween<double>(begin: 0.5, end: 1.0),
);

final rotationAnimation = manageAnimation(
  parent: controller,
  tween: Tween<double>(begin: 0, end: 2 * pi),
);
```

## Best Practices

### 1. Always Use useAnimationController

```dart
// ✅ Good - automatic disposal
final (controller, animValue) = useAnimationController(
  duration: Duration(seconds: 1),
);

// ❌ Bad - manual disposal
final vsync = useSingleTickerProvider();
final controller = AnimationController(vsync: vsync, duration: Duration(seconds: 1));
onUnmounted(() => controller.dispose());
```

### 2. Use Reactive State to Control Animations

```dart
// ✅ Good - declarative
final isPlaying = ref(false);

watch(() => isPlaying.value, (playing, _) {
  if (playing) {
    controller.repeat();
  } else {
    controller.stop();
  }
});

// ❌ Bad - imperative
void toggleAnimation() {
  if (controller.isAnimating) {
    controller.stop();
  } else {
    controller.repeat();
  }
}
```

### 3. Use Curves for Complex Animations

```dart
// ✅ Good - more natural animation
final curvedAnimation = CurvedAnimation(
  parent: controller,
  curve: Curves.easeInOut,
);

// ❌ Bad - linear animation feels mechanical
// Using controller directly
```

### 4. Clean Up Properly

```dart
// ✅ Good - composables handle automatically
final (controller, _) = useAnimationController(/* ... */);

// ❌ Bad - manual management
final controller = AnimationController(/* ... */);
onUnmounted(() {
  controller.dispose();
  // Easy to forget!
});
```

## Next Steps

- Explore [Form Handling](./forms.md) to build reactive forms
- Learn [Async Operations](./async-operations.md) to handle asynchronous animations
- Read the [useAnimationController API](https://pub.dev/documentation/flutter_compositions/latest/flutter_compositions/useAnimationController.html) for the complete API reference
