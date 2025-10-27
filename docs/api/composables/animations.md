# 動畫組合式函式

用於建立 Flutter 動畫、具自動釋放與響應式值的組合式函式。

## useAnimationController

建立會自動釋放並提供響應式值的 `AnimationController`。

### 方法簽章

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

### 回傳值

回傳包含以下項目的 record：
- `controller`：實際的 AnimationController
- `value`：目前動畫值的響應式 ref

### 範例

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

### 旋轉範例

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

提供可給單一 `AnimationController` 使用的 `TickerProvider`。

### 方法簽章

```dart
TickerProvider useSingleTickerProvider()
```

### 範例

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

管理 `Tween` 動畫並自動釋放資源。

### 方法簽章

```dart
Animation<T> manageAnimation<T>({
  required Animation<double> parent,
  required Tween<T> tween,
})
```

### 範例

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

## 完整動畫範例

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

## 交錯動畫

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

## 曲線動畫

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

## 最佳實務

### 使用組合式函式取得自動釋放

```dart
// ❌ 不佳：需要手動釋放
@override
Widget Function(BuildContext) setup() {
  final vsync = useSingleTickerProvider();
  final controller = AnimationController(vsync: vsync, duration: Duration(seconds: 1));

  onUnmounted(() => controller.dispose()); // Don't forget!

  return (context) => Container();
}

// ✅ 較佳：自動釋放
@override
Widget Function(BuildContext) setup() {
  final (controller, animValue) = useAnimationController(
    duration: Duration(seconds: 1),
  );

  // 會自動釋放！

  return (context) => Container();
}
```

### 搭配響應式狀態控制動畫

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

## 延伸閱讀

- [useAnimationController](#useanimationcontroller) - 具自動釋放的動畫控制器
- [生命週期掛勾](../lifecycle.md) - onMounted、onUnmounted
- [watch](../watch.md) - 副作用
