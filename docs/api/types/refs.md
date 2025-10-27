# Ref 型別

Flutter Compositions 中用於描述響應式參照的介面與類別。

## 概觀

Flutter Compositions 參考 Vue 3 的 ref 系統，提供一套具階層性的響應式參照型別，並透過底層的 `alien_signals` 實現細粒度的響應式更新。

## 型別階層

```
ReadonlyRef<T>
├── WritableRef<T>
│   ├── Ref<T>
│   └── WritableComputedRef<T>
└── ComputedRef<T>
```

---

## ReadonlyRef

所有可讀取之響應式參照的基底介面。

### 介面定義

```dart
abstract class ReadonlyRef<T> {
  T get value;
  T get raw;
}
```

### 屬性

- `value`：取得目前數值並建立響應式依賴
- `raw`：在不建立依賴的情況下取得原始值

### 說明

`ReadonlyRef` 是所有響應式參照的基礎。當在響應式脈絡（例如 `computed()` 或 `watchEffect()`）中讀取 `.value` 時，系統會自動追蹤其為依賴。

### 範例：基本使用

```dart
final count = ref(0);
ReadonlyRef<int> readonlyCount = count; // 可以指派

print(readonlyCount.value); // 可以讀取
// readonlyCount.value = 1; // 錯誤：無法寫入唯讀參照
```

### 範例：使用 .raw

`.raw` 可在不建立依賴的情況下讀取值：

```dart
final scrollController = useScrollController();

return (context) => ListView(
  // 使用 .raw 讀取，不會在控制器變更時重建
  controller: scrollController.raw,
  children: [...],
);
```

---

## WritableRef

可讀可寫的響應式參照介面。

### 介面定義

```dart
abstract class WritableRef<T> implements ReadonlyRef<T> {
  T get value;
  set value(T newValue);
}
```

### 屬性

- `value`：可讀取或設定數值；讀取時會建立依賴。

### 說明

`WritableRef` 繼承自 `ReadonlyRef`，並新增 setter。`Ref` 與 `WritableComputedRef` 都實作此介面。

### 範例

```dart
WritableRef<int> count = ref(0);

count.value = 10; // 可以寫入
print(count.value); // 可以讀取

// 可以套用在任何需要 WritableRef 的地方
void increment(WritableRef<int> counter) {
  counter.value++;
}

increment(count);
```

---

## Ref

通用的響應式參照實作。

### 類別定義

```dart
class Ref<T> implements WritableRef<T> {
  Ref(T initialValue);

  T get value;
  set value(T newValue);
  T get raw;
}
```

### 建立方式

使用 `ref()` 函式建立：

```dart
Ref<T> ref<T>(T initialValue, {String? debugLabel})
```

### 範例：基本使用

```dart
final count = ref(0);  // Ref<int>
final name = ref('Alice');  // Ref<String>
final user = ref<User?>(null);  // Ref<User?>

count.value++;  // 觸發響應式更新
print(count.value);  // 1
```

### 範例：搭配物件

```dart
class User {
  final String name;
  final int age;

  User(this.name, this.age);
}

final user = ref(User('Alice', 30));

// 更新整個物件
user.value = User('Bob', 25);

// 讀取屬性（不會追蹤個別屬性）
print(user.value.name);  // 'Bob'
```

### 範例：熱重載狀態保留

```dart
@override
Widget Function(BuildContext) setup() {
  final count = ref(0, debugLabel: 'count');  // 位置 0
  final name = ref('Alice', debugLabel: 'name');  // 位置 1

  // 熱重載期間會自動保留這些值
  // 前提是它們的宣告順序維持不變

  return (context) => Column(
    children: [
      Text('Count: ${count.value}'),
      Text('Name: ${name.value}'),
    ],
  );
}
```

### 最佳實務

```dart
// ✅ 較佳：交由型別推斷
final count = ref(0);  // Ref<int>

// ✅ 較佳：對可為 null 的值明確標註
final user = ref<User?>(null);

// ⚠️ 請避免：不必要的型別註記
final count = ref<int>(0);

// ✅ 較佳：提供有意義的 debug 標籤
final userCount = ref(0, debugLabel: 'userCount');
```

---

## ComputedRef

唯讀的衍生響應式參照。

### 類別定義

```dart
class ComputedRef<T> implements ReadonlyRef<T> {
  ComputedRef(T Function() getter);

  T get value;
  T get raw;
}
```

### 建立方式

使用 `computed()` 函式建立：

```dart
ReadonlyRef<T> computed<T>(T Function() getter)
```

### 範例：基本使用

```dart
final count = ref(0);
final doubled = computed(() => count.value * 2);

print(doubled.value);  // 0
count.value = 5;
print(doubled.value);  // 10

// doubled.value = 20;  // 錯誤：無法寫入 computed 參照
```

### 範例：多個依賴

```dart
final firstName = ref('John');
final lastName = ref('Doe');

final fullName = computed(() => '${firstName.value} ${lastName.value}');

print(fullName.value);  // 'John Doe'
firstName.value = 'Jane';
print(fullName.value);  // 'Jane Doe'
```

### 範例：鏈式衍生

```dart
final count = ref(0);
final doubled = computed(() => count.value * 2);
final quadrupled = computed(() => doubled.value * 2);

print(quadrupled.value);  // 0
count.value = 5;
print(quadrupled.value);  // 20
```

### 範例：複雜運算

```dart
final items = ref<List<Item>>([
  Item('Apple', price: 1.0),
  Item('Banana', price: 0.5),
  Item('Orange', price: 1.5),
]);

final totalPrice = computed(() {
  return items.value.fold<double>(
    0.0,
    (sum, item) => sum + item.price,
  );
});

final averagePrice = computed(() {
  final total = totalPrice.value;
  final count = items.value.length;
  return count > 0 ? total / count : 0.0;
});

print(averagePrice.value);  // 1.0
```

### 最佳實務

```dart
// ✅ 較佳：維持純計算
final doubled = computed(() => count.value * 2);

// ⚠️ 請避免：在 computed 中埋副作用
final doubled = computed(() {
  print('Computing...'); // 不要這樣做！
  return count.value * 2;
});

// ✅ 較佳：以 watch 處理副作用
watch(() => count.value, (value, _) {
  print('Count changed to $value');
});
```

---

## WritableComputedRef

具自訂 getter 與 setter 的可寫入衍生參照。

### 類別定義

```dart
class WritableComputedRef<T> implements WritableRef<T> {
  WritableComputedRef(T Function() getter, void Function(T) setter);

  T get value;
  set value(T newValue);
  T get raw;
}
```

### 建立方式

使用 `writableComputed()` 建立：

```dart
WritableRef<T> writableComputed<T>({
  required T Function() get,
  required void Function(T value) set,
})
```

### 範例：基本使用

```dart
final count = ref(0);

final doubled = writableComputed<int>(
  get: () => count.value * 2,
  set: (value) => count.value = value ~/ 2,
);

print(doubled.value);  // 0
doubled.value = 10;  // 會將 count 設為 5
print(count.value);  // 5
print(doubled.value);  // 10
```

### 範例：雙向綁定

```dart
final celsius = ref(0.0);

final fahrenheit = writableComputed<double>(
  get: () => celsius.value * 9 / 5 + 32,
  set: (f) => celsius.value = (f - 32) * 5 / 9,
);

celsius.value = 100;
print(fahrenheit.value);  // 212.0

fahrenheit.value = 32;
print(celsius.value);  // 0.0
```

### 範例：表單欄位綁定

```dart
final user = ref(User(name: 'Alice', age: 30));

final userName = writableComputed<String>(
  get: () => user.value.name,
  set: (name) => user.value = User(name: name, age: user.value.age),
);

final userAge = writableComputed<int>(
  get: () => user.value.age,
  set: (age) => user.value = User(name: user.value.name, age: age),
);

return (context) => Column(
  children: [
    TextField(
      onChanged: (value) => userName.value = value,
      controller: TextEditingController(text: userName.value),
    ),
    TextField(
      onChanged: (value) => userAge.value = int.tryParse(value) ?? 0,
      controller: TextEditingController(text: userAge.value.toString()),
    ),
  ],
);
```

### 範例：資料驗證

```dart
final rawInput = ref('');

final validatedInput = writableComputed<String>(
  get: () => rawInput.value,
  set: (value) {
// 驗證並整理輸入內容
    final sanitized = value.trim().toLowerCase();
    if (sanitized.length <= 50) {
      rawInput.value = sanitized;
    }
  },
);

validatedInput.value = '  HELLO  ';
print(rawInput.value);  // 'hello'

validatedInput.value = 'a' * 100;
print(rawInput.value);  // 'hello'（未變更，因長度過長）
```

### 最佳實務

```dart
// ✅ 較佳：雙向同步
final doubled = writableComputed(
  get: () => count.value * 2,
  set: (value) => count.value = value ~/ 2,
);

// ✅ 較佳：在 setter 中處理驗證
final email = writableComputed(
  get: () => rawEmail.value,
  set: (value) {
    if (isValidEmail(value)) {
      rawEmail.value = value;
    }
  },
);

// ⚠️ 請避免：在 setter 中加入副作用
final computed = writableComputed(
  get: () => value.value,
  set: (v) {
    value.value = v;
    print('Changed!'); // 避免在此執行副作用
    api.sync(v); // 不要在這裡進行非同步作業
  },
);

// ✅ 較佳：透過 watch 處理副作用
watch(() => value.value, (newValue, _) {
  print('Changed!');
  api.sync(newValue);
});
```

---

## 型別轉換

### 將 Writable 轉為 Readonly

```dart
final count = ref(0);  // Ref<int>
ReadonlyRef<int> readonly = count;  // 可轉為唯讀參照

print(readonly.value);  // 可以讀取
// readonly.value = 1;  // 錯誤：無法寫入
```

### 將 Computed 當成 Readonly 使用

```dart
final doubled = computed(() => count.value * 2);  // ComputedRef<int>
ReadonlyRef<int> readonly = doubled;  // 天生即為唯讀

print(readonly.value);
```

---

## 常見模式

### 可選值

```dart
final user = ref<User?>(null);

final userName = computed(() {
  final u = user.value;
  return u?.name ?? 'Guest';
});

if (user.value != null) {
  print('User: ${user.value!.name}');
}
```

### 集合

```dart
final items = ref<List<String>>([]);

final itemCount = computed(() => items.value.length);
final isEmpty = computed(() => items.value.isEmpty);

items.value = [...items.value, 'new item'];  // 觸發更新
```

### 更新物件

```dart
class Settings {
  final bool darkMode;
  final String language;

  Settings({required this.darkMode, required this.language});

  Settings copyWith({bool? darkMode, String? language}) {
    return Settings(
      darkMode: darkMode ?? this.darkMode,
      language: language ?? this.language,
    );
  }
}

final settings = ref(Settings(darkMode: false, language: 'en'));

// 以不可變的方式更新
settings.value = settings.value.copyWith(darkMode: true);
```

### 衍生狀態

```dart
final items = ref<List<Item>>([]);
final filter = ref('');

final filteredItems = computed(() {
  final query = filter.value.toLowerCase();
  if (query.isEmpty) return items.value;

  return items.value.where((item) {
    return item.name.toLowerCase().contains(query);
  }).toList();
});

final filteredCount = computed(() => filteredItems.value.length);
```

---

## 效能小技巧

### 使用 .raw 進行非響應式存取

```dart
// ⚠️ 請避免：造成不必要的依賴
final controller = useScrollController();
return ListView(
  controller: controller.value,  // 滾動時會導致重建
  children: [...],
);

// ✅ 較佳：不建立響應式追蹤
return ListView(
  controller: controller.raw,  // 不會因此重建
  children: [...],
);
```

### 在複雜情境中使用 untracked()

```dart
final result = computed(() {
  final a = valueA.value;  // 會被追蹤
  final b = untracked(() => valueB.value);  // 不會被追蹤
  return a + b;
});
// 只有在 valueA 改變時才會重新計算
```

## 延伸閱讀

- [ref](../reactivity.md#ref) - 建立響應式參照
- [computed](../reactivity.md#computed) - 建立衍生值
- [untracked](../reactivity.md#untracked) - 取消依賴追蹤的讀取方式
- [customRef](../custom-ref.md) - 自訂響應式參照
- [watch](../watch.md) - 副作用與監看器
