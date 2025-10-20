# Animation Composables Demo

這個示例展示了 `flutter_compositions` 中所有動畫相關的 composables。

## 包含的示例

### 1. Basic Animation (基本動畫)
- 使用 `useAnimationController` 創建動畫控制器
- 自動管理 vsync 和生命週期
- 使用 `computed()` 基於動畫值計算衍生值
- 展示旋轉和透明度動畫

**核心概念:**
```dart
final (controller, animValue) = useAnimationController(
  duration: const Duration(seconds: 2),
);

// 響應式計算動畫值
final rotation = computed(() => animValue.value * 2 * math.pi);
```

### 2. Curved Animation (曲線動畫)
- 使用 `manageAnimation` 管理 CurvedAnimation
- 展示彈性曲線效果 (Curves.elasticOut)
- 自動清理動畫監聽器

**核心概念:**
```dart
final (curvedAnimation, curvedValue) = manageAnimation(
  CurvedAnimation(
    parent: controller,
    curve: Curves.elasticOut,
  ),
);
```

### 3. Tween Animation (補間動畫)
- 顏色補間動畫 (ColorTween)
- 位置補間動畫 (Offset Tween)
- 結合 SlideTransition 實現滑動效果

**核心概念:**
```dart
final (colorAnimation, colorValue) = manageAnimation(
  ColorTween(begin: Colors.blue, end: Colors.purple).animate(controller),
);
```

### 4. Staggered Animation (交錯動畫)
- 使用 Interval 創建延遲動畫
- 多個元素按順序動畫
- 展示如何協調多個動畫

**核心概念:**
```dart
final (anim, value) = manageAnimation(
  CurvedAnimation(
    parent: controller,
    curve: Interval(0.0, 0.3, curve: Curves.easeOut),
  ),
);
```

### 5. Interactive Animation (互動動畫)
- 結合 `ref()` 和 `watch()` 實現響應式動畫控制
- 根據用戶輸入觸發動畫
- 展示狀態和動畫的完美結合

**核心概念:**
```dart
final isExpanded = ref(false);

watch(() => isExpanded.value, (expanded, _) {
  if (expanded) {
    controller.forward();
  } else {
    controller.reverse();
  }
});
```

### 6. Spring Animation (彈簧動畫)
- 使用 `controller.fling()` 實現物理動畫
- 手勢互動觸發動畫
- 展示基於物理的動畫效果

**核心概念:**
```dart
onTapDown: (details) {
  position.value = localPosition;
  controller.reset();
  controller.fling(velocity: 2.0);
}
```

## 關鍵 API

### useAnimationController
自動創建和管理 AnimationController，包括：
- 自動創建 SingleTickerProvider (vsync)
- 自動處理 TickerMode 變化
- 組件卸載時自動 dispose
- 返回響應式動畫值 (ReadonlyRef<double>)

### manageAnimation
管理任何 Animation<T> 並創建響應式引用：
- 適用於 CurvedAnimation、Tween 等
- 自動添加/移除監聽器
- 不會 dispose 動畫（適合衍生動畫）
- 返回原始動畫和響應式值

### useSingleTickerProvider
低階 API，手動創建 ticker provider：
- 大多數情況下不需要直接使用
- useAnimationController 內部已經處理

## 最佳實踐

1. **使用 useAnimationController** 而不是手動管理 AnimationController
2. **使用 computed()** 基於動畫值計算衍生值
3. **使用 watch()** 響應狀態變化並控制動畫
4. **使用 manageAnimation** 處理衍生動畫（Tween、CurvedAnimation）
5. **在 onMounted** 中啟動自動動畫

## 注意事項

- 動畫控制器會在組件卸載時自動清理
- 不要在 setup() 中直接啟動動畫，使用 onMounted()
- 響應式動畫值會自動觸發重建
- 所有動畫監聽器都會自動清理
