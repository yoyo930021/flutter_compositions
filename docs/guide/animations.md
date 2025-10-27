# 動畫

動畫讓您的應用程式栩栩如生。本指南將探討如何使用 Flutter Compositions 建立流暢的動畫，包括基本動畫、交錯動畫、響應式動畫控制和動畫模式。

## 為什麼使用 Composables 處理動畫？

在傳統的 Flutter 中，動畫控制器需要手動管理生命週期：

```dart
// ❌ 傳統方式 - 樣板程式碼多
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
    _controller.dispose(); // 別忘了！
    super.dispose();
  }
}

// ✅ Compositions 方式 - 簡潔且安全
@override
Widget Function(BuildContext) setup() {
  final (controller, animValue) = useAnimationController(
    duration: Duration(seconds: 1),
  );
  // 自動釋放！

  return (context) => /* ... */;
}
```

## useAnimationController - 基本動畫

`useAnimationController` 建立一個帶有自動釋放和響應式值追蹤的 `AnimationController`。

### 簡單淡入淡出

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

### 使用響應式值

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
      scale: 1.0 + (animValue.value * 0.2), // 1.0 到 1.2
      child: Icon(Icons.favorite, size: 100, color: Colors.red),
    );
  }
}
```

### 旋轉動畫

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

## 補間動畫

使用 `Tween` 在值之間進行插值。

### 尺寸動畫

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

### 顏色動畫

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

### 多重動畫

同時動畫多個屬性：

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

## 曲線動畫

使用緩動曲線讓動畫更自然。

### 使用內建曲線

```dart
class BouncingBox extends CompositionWidget {
  @override
  Widget Function(BuildContext) setup() {
    final (controller, _) = useAnimationController(
      duration: Duration(milliseconds: 1000),
    );

    final curvedAnimation = CurvedAnimation(
      parent: controller,
      curve: Curves.elasticOut, // 彈性緩動
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

### 不同階段的不同曲線

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
      reverseCurve: Curves.bounceOut, // 反向時使用不同曲線
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

## 交錯動畫

建立複雜的序列動畫。

### 序列轉換

```dart
class StaggeredAnimation extends CompositionWidget {
  @override
  Widget Function(BuildContext) setup() {
    final (controller, _) = useAnimationController(
      duration: Duration(milliseconds: 2000),
    );

    // 0.0 - 0.3: 淡入
    final fadeAnimation = manageAnimation(
      parent: controller,
      tween: Tween<double>(begin: 0, end: 1),
    );

    // 0.2 - 0.6: 滑動
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

    // 0.5 - 1.0: 縮放
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

### 列表項目交錯

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
        // 每個項目有輕微延遲
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

## 響應式動畫控制

使用響應式狀態控制動畫。

### 切換動畫

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

    // 監聽狀態變更並控制動畫
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
          child: Text(isExpanded.value ? '收起' : '展開'),
        ),
        AnimatedBuilder(
          animation: heightAnimation,
          builder: (context, child) => Container(
            width: 300,
            height: heightAnimation.value,
            color: Colors.blue,
            child: Center(
              child: Text(
                '可展開內容',
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

### 基於條件的動畫

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

### 資料驅動的動畫

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

    // 監聽目標值變更
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

    // 更新當前值
    watchEffect(() {
      value.value = valueAnimation.value;
    });

    return (context) => Column(
      children: [
        // 進度條
        AnimatedBuilder(
          animation: valueAnimation,
          builder: (context, child) => LinearProgressIndicator(
            value: valueAnimation.value / 100,
          ),
        ),

        // 當前值
        Text('${value.value.toStringAsFixed(1)}%'),

        // 控制項
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

## 實戰範例

### 載入指示器

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
        // 每個點有不同的延遲
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

### 滑動刪除

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
        // 滑動距離足夠，刪除
        controller.forward().then((_) => onDismissed());
      } else {
        // 回彈
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

### 下拉刷新

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
            controller: scrollController.value,
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

### 視差滾動

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
      controller: scrollController.value,
      slivers: [
        SliverAppBar(
          expandedHeight: 300,
          flexibleSpace: FlexibleSpaceBar(
            background: Transform.translate(
              offset: Offset(0, scrollOffset.value * 0.5), // 視差效果
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

## 動畫組合

建立可重用的動畫 composables。

```dart
// 可重用的淡入動畫 composable
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

// 使用
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

## 效能考量

### 1. 使用 const Widget

```dart
// ✅ 良好 - const widget 不會重建
return AnimatedBuilder(
  animation: animation,
  builder: (context, child) => Transform.scale(
    scale: animation.value,
    child: child,
  ),
  child: const ExpensiveWidget(), // const!
);
```

### 2. 限制 AnimatedBuilder 範圍

```dart
// ❌ 不良 - 整個樹重建
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

// ✅ 良好 - 只有動畫部分重建
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

### 3. 重用動畫

```dart
// ✅ 良好 - 單一控制器，多個動畫
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

## 最佳實踐

### 1. 始終使用 useAnimationController

```dart
// ✅ 良好 - 自動釋放
final (controller, animValue) = useAnimationController(
  duration: Duration(seconds: 1),
);

// ❌ 不良 - 手動釋放
final vsync = useSingleTickerProvider();
final controller = AnimationController(vsync: vsync, duration: Duration(seconds: 1));
onUnmounted(() => controller.dispose());
```

### 2. 使用響應式狀態控制動畫

```dart
// ✅ 良好 - 宣告式
final isPlaying = ref(false);

watch(() => isPlaying.value, (playing, _) {
  if (playing) {
    controller.repeat();
  } else {
    controller.stop();
  }
});

// ❌ 不良 - 命令式
void toggleAnimation() {
  if (controller.isAnimating) {
    controller.stop();
  } else {
    controller.repeat();
  }
}
```

### 3. 對複雜動畫使用曲線

```dart
// ✅ 良好 - 更自然的動畫
final curvedAnimation = CurvedAnimation(
  parent: controller,
  curve: Curves.easeInOut,
);

// ❌ 不良 - 線性動畫感覺機械
// 直接使用 controller
```

### 4. 適當地清理

```dart
// ✅ 良好 - composables 自動處理
final (controller, _) = useAnimationController(/* ... */);

// ❌ 不良 - 手動管理
final controller = AnimationController(/* ... */);
onUnmounted(() {
  controller.dispose();
  // 容易忘記！
});
```

## 下一步

- 探索[表單處理](./forms.md)以構建響應式表單
- 學習[非同步操作](./async-operations.md)以處理非同步動畫
- 閱讀 [Animation API](../api/composables/animations.md) 以了解完整 API 參考
