# 深入理解組合式 API

在「快速上手」中，您看到了 `CompositionWidget` 的基本用法。現在，讓我們深入探討其背後的強大功能：屬性 (Props)、生命週期和依賴注入。

## `setup()` 的黃金法則

`setup()` 方法是 `CompositionWidget` 的心臟，但請務必記住這條黃金法則：

> `setup()` 只會在 Widget 的生命週期中執行一次（相當於 `StatefulWidget` 的 `initState`）。

這意味著您可以在此處安全地初始化狀態、建立控制器、註冊監聽器，而無需擔心它們會在每次 Widget 重建時被重新建立。

相對地，從 `setup()` 返回的 `builder` 函式則會在它所依賴的任何響應式數據發生變化時被重新執行。

## 響應式屬性 (Reactive Props)

如果 `setup` 只執行一次，我們要如何響應來自父 Widget 的屬性變化呢？直接在 `setup` 中存取 `widget.myProp` 是**無效的**，因為它只會讀取到初始值。

正確的答案是使用 `widget()` API。

`widget()` 函式會返回一個響應式的 `ComputedRef`，它總是代表著**最新**的 Widget 實例。當父 Widget 重建並傳入新的屬性時，這個 `ComputedRef` 會觸發更新。

讓我們來看一個 `UserCard` 範例：

```dart
class UserCard extends CompositionWidget {
  const UserCard({super.key, required this.name});

  final String name;

  @override
  Widget Function(BuildContext) setup() {
    // ✅ 正確：使用 widget() 獲取響應式的屬性參考
    final props = widget();

    // ❌ 錯誤：直接存取 this.name 或 name，這不是響應式的！
    // final greeting = computed(() => 'Hello, $name');

    // `greeting` 會在 `props.value.name` 變化時自動更新
    final greeting = computed(() => 'Hello, ${props.value.name}!');

    // 監聽 name 屬性的變化
    watch(() => props.value.name, (newName, oldName) {
      print('Name changed from $oldName to $newName');
    });

    return (context) => Text(greeting.value);
  }
}
```

**重點**: 始終透過 `widget().value.yourProp` 來存取屬性，以確保您的 `computed` 和 `watch` 能夠正確地響應變化。

## 生命週期鉤子 (Lifecycle Hooks)

`flutter_compositions` 提供了類似 Vue 的生命週期鉤子，讓您可以在 `setup` 內部掛載和卸載邏輯。

- `onMounted(callback)`: 在 Widget 被掛載到畫面上後（`initState` 之後的第一幀）執行。適合用來發送網路請求、初始化需要 `BuildContext` 的控制器等。
- `onUnmounted(callback)`: 在 Widget 被銷毀前（`dispose` 期間）執行。這是清理控制器、取消訂閱、釋放資源的最佳位置。

```dart
@override
Widget Function(BuildContext) setup() {
  final myController = useController(AnimationController());

  onMounted(() {
    print('Widget is mounted!');
    myController.value.forward();
  });

  onUnmounted(() {
    print('Widget is unmounted, cleaning up.');
    // `useController` 會自動 dispose，但這裡是手動清理的示範
    // myController.value.dispose();
  });

  return (context) => /* ... */;
}
```

## 依賴注入 (Provide / Inject)

當您需要在組件樹中向下傳遞數據時，除了透過一層層的建構子傳遞，您還可以使用 `provide` 和 `inject` 來實現類似 `Provider` 套件的依賴注入功能，但它更輕量且型別安全。

- `provide(value)`: 將一個值提供給所有後代 `CompositionWidget`。
- `inject<T>()`: 從祖先 `CompositionWidget` 中獲取對應型別 `T` 的值。

這個機制是基於**型別**來查找的，所以建議使用自訂的類別作為 Key，以避免衝突。

**範例：提供一個主題狀態**

```dart
// 1. 定義一個自訂的資料類別
class AppTheme {
  AppTheme(this.mode);
  String mode;
}

// 2. 在父 Widget 中 provide 一個響應式狀態
class ThemeProvider extends CompositionWidget {
  @override
  Widget Function(BuildContext) setup() {
    final theme = ref(AppTheme('light'));
    provide(theme); // 型別被自動推斷為 Ref<AppTheme>

    return (context) => Column(
      children: [
        // ... 用於切換主題的按鈕 ...
        const ThemeDisplay(),
      ],
    );
  }
}

// 3. 在子 Widget 中 inject
class ThemeDisplay extends CompositionWidget {
  @override
  Widget Function(BuildContext) setup() {
    // 透過型別注入，完全型別安全！
    final theme = inject<Ref<AppTheme>>();

    return (context) => Text('Current mode: ${theme.value.mode}');
  }
}
```

`provide`/`inject` 的一大優勢是它不會引起不必要的 Widget 重建。只有真正 `inject` 並使用了該響應式值的 `builder` 才會在值變化時更新。
