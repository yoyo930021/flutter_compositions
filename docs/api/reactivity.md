# Reactivity API

管理狀態的核心響應式原語。

## `ref<T>`

建立可寫入的響應式參照。

### 方法簽章

```dart
Ref<T> ref<T>(T initialValue)
```

### 參數

- `initialValue`：ref 的初始值

### 回傳值

回傳具有 `.value` 屬性的 `Ref<T>` 物件，讀寫時會觸發響應式更新。

### 範例

```dart
@override
Widget Function(BuildContext) setup() {
  final count = ref(0);

  // 讀取值
  print(count.value); // 0

  // 寫入值（會觸發響應式更新）
  count.value++;

  return (context) => Text('Count: ${count.value}');
}
```

### 響應式行為

- **讀取**：當 `.value` 在響應式脈絡中（如 `computed`、`watch`、`watchEffect` 或 builder 函式）被讀取時，該脈絡會追蹤此 ref 為依賴
- **寫入**：當 `.value` 被寫入時，所有相依脈絡都會收到通知並重新執行

---

## `computed<T>`

建立唯讀的衍生值，依賴變更時自動更新。

### 方法簽章

```dart
ComputedRef<T> computed<T>(T Function() getter)
```

### 參數

- `getter`：計算值的函式。依賴會自動被追蹤。

### 回傳值

回傳 `ComputedRef<T>`，可透過 `.value` 取得唯讀的衍生值。

### 範例

```dart
@override
Widget Function(BuildContext) setup() {
  final count = ref(0);
  final doubled = computed(() => count.value * 2);
  final quadrupled = computed(() => doubled.value * 2);

  count.value++; // doubled 與 quadrupled 會自動更新

  return (context) => Column(
    children: [
      Text('Count: ${count.value}'),
      Text('Doubled: ${doubled.value}'),
      Text('Quadrupled: ${quadrupled.value}'),
    ],
  );
}
```

### 延遲求值

衍生值採延遲求值；只有在 `.value` 被存取且依賴發生變化時，getter 才會執行。

### 快取

在依賴改變前會回傳快取結果，多次讀取 `.value` 不會重新執行 getter。

---

## `writableComputed<T>`

建立同時具備 getter 與 setter 的衍生值。

### 方法簽章

```dart
WritableComputedRef<T> writableComputed<T>({
  required T Function(T Function<V>(ReadonlyRef<V>) get) getter,
  required void Function(T value, void Function<V>(WritableRef<V>, V) set) setter,
})
```

### 參數

- `getter`：計算值的函式，透過提供的 `get` 函式讀取依賴。
- `setter`：當對 `.value` 指派時執行的函式，使用 `set` 更新來源 ref。

### 回傳值

回傳 `WritableComputedRef<T>`，其 `.value` 可讀可寫。

### 範例

```dart
@override
Widget Function(BuildContext) setup() {
  final firstName = ref('John');
  final lastName = ref('Doe');

  final fullName = writableComputed<String>(
    getter: (get) => '${get(firstName)} ${get(lastName)}',
    setter: (value, set) {
      final parts = value.split(' ');
      if (parts.length >= 2) {
        set(firstName, parts[0]);
        set(lastName, parts.sublist(1).join(' '));
      }
    },
  );

  // 讀取
  print(fullName.value); // "John Doe"

  // 寫入（會同步更新 firstName 與 lastName）
  fullName.value = 'Jane Smith';
  print(firstName.value); // "Jane"
  print(lastName.value); // "Smith"

  return (context) => TextField(
    controller: TextEditingController(text: fullName.value),
    onChanged: (value) => fullName.value = value,
  );
}
```

### 使用情境

- 雙向資料繫結
- 表單欄位同步
- 需要回寫來源的衍生狀態

---

## 型別別名

### `Ref<T>`

```dart
typedef Ref<T> = WritableRef<T>
```

可寫入的響應式參照，是 `WritableRef<T>` 的別名。

### `ComputedRef<T>`

```dart
typedef ComputedRef<T> = ReadonlyRef<T>
```

唯讀的衍生值，是 `ReadonlyRef<T>` 的別名。

---

## 介面型別

### `ReadonlyRef<T>`

唯讀響應式參照的介面。

```dart
abstract class ReadonlyRef<T> {
  T get value;
}
```

### `WritableRef<T>`

可寫入響應式參照的介面。

```dart
abstract class WritableRef<T> extends ReadonlyRef<T> {
  set value(T newValue);
}
```

### `WritableComputedRef<T>`

可寫入的衍生參照介面。

```dart
abstract class WritableComputedRef<T> extends WritableRef<T> {
  // 繼承 value getter/setter
}
```

---

## 最佳實務

### 1. 以 `ref` 管理可變狀態

```dart
// ✅ 較佳
final count = ref(0);
count.value++;

// ❌ 不佳：直接使用可變的 Widget 欄位
class MyWidget extends CompositionWidget {
  int count = 0; // 不會觸發響應式更新！
}
```

### 2. 用 `computed` 產生衍生狀態

```dart
// ✅ 較佳
final doubled = computed(() => count.value * 2);

// ❌ 不佳：手動更新
final doubled = ref(0);
watch(() => count.value, (value, _) {
  doubled.value = value * 2; // 多此一舉
});
```

### 3. 維持 computed 為純函式

```dart
// ✅ 較佳
final greeting = computed(() => 'Hello, ${name.value}!');

// ❌ 不佳：在 computed 中加入副作用
final greeting = computed(() {
  print('Computing...'); // 副作用！
  return 'Hello, ${name.value}!';
});
```

### 4. 使用 `writableComputed` 處理雙向資料流

```dart
// ✅ 較佳：雙向繫結
final fullName = writableComputed<String>(
  getter: (get) => '${get(firstName)} ${get(lastName)}',
  setter: (value, set) { /* split and update */ },
);

// ❌ 請避免：僅需讀取時就使用 writableComputed
final fullName = writableComputed<String>(
  getter: (get) => '${get(firstName)} ${get(lastName)}',
  setter: (value, set) {}, // 空的 setter 會浪費資源
);
```

---
## 效能考量

- **computed 採延遲求值**：只有被存取時才會計算
- **自動快取**：依賴未改變時回傳相同結果
- **細粒度更新**：只有讀取到變更 ref 的區塊會重建
- **自動追蹤依賴**：不需手動宣告依賴

---

## 延伸閱讀

- [watch, watchEffect](./watch.md) - 回應狀態變化
- [customRef](./custom-ref.md) - 自訂響應式邏輯
- [CompositionWidget](./composition-widget.md) - 在 Widget 中使用 ref
