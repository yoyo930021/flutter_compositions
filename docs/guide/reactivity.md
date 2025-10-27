# 響應式系統

響應式是 Flutter Compositions 的核心。本指南將深入探討響應式狀態管理、細粒度更新的工作原理，以及如何高效使用響應式系統。

## 什麼是響應式？

在傳統的 Flutter `StatefulWidget` 中，當您呼叫 `setState()` 時，整個 widget 子樹會重建。這可能導致不必要的計算和 widget 重建。

Flutter Compositions 使用**細粒度響應式系統**（由 [`alien_signals`](https://pub.dev/packages/alien_signals) 提供支援），只更新依賴於已更改資料的特定部分。

### 傳統方式 vs 響應式方式

```dart
// ❌ 傳統方式 - 使用 setState
class CounterWidget extends StatefulWidget {
  @override
  State<CounterWidget> createState() => _CounterWidgetState();
}

class _CounterWidgetState extends State<CounterWidget> {
  int count = 0;

  @override
  Widget build(BuildContext context) {
    // 整個 build 方法在每次 setState 時重新執行
    print('Building entire widget tree');

    return Column(
      children: [
        Text('Count: $count'),
        ExpensiveWidget(), // 即使不依賴 count 也會重建
        ElevatedButton(
          onPressed: () => setState(() => count++),
          child: Text('Increment'),
        ),
      ],
    );
  }
}

// ✅ 響應式方式 - 使用 ref
class CounterWidget extends CompositionWidget {
  @override
  Widget Function(BuildContext) setup() {
    final count = ref(0);

    return (context) {
      // 只有這個 builder 在 count 改變時重新執行
      print('Building with reactive system');

      return Column(
        children: [
          Text('Count: ${count.value}'), // 只有這部分響應變化
          const ExpensiveWidget(), // 從不重建
          ElevatedButton(
            onPressed: () => count.value++,
            child: Text('Increment'),
          ),
        ],
      );
    };
  }
}
```

## 響應式的三大核心概念

### 1. Ref - 響應式狀態

`ref()` 建立可以讀寫的響應式狀態。當您修改 ref 的值時，所有依賴它的計算和 UI 元件都會自動更新。

```dart
// 建立 ref
final count = ref(0);
final name = ref('John');
final items = ref(<String>[]);

// 讀取值
print(count.value); // 0
print(name.value); // 'John'

// 寫入值（觸發響應式更新）
count.value++;
name.value = 'Jane';
items.value = [...items.value, 'new item'];
```

**重點**：
- 始終透過 `.value` 存取和修改狀態
- 寫入操作會觸發自動更新
- Ref 可以儲存任何類型：基本類型、物件、集合等
- 對於集合（List、Map、Set），必須建立新實例才能觸發更新

### 2. Computed - 衍生狀態

`computed()` 建立從其他響應式狀態衍生的值。它們會在依賴項變更時自動更新，並且會快取結果直到依賴項變更。

```dart
final firstName = ref('John');
final lastName = ref('Doe');

// 自動從 firstName 和 lastName 衍生
final fullName = computed(() => '${firstName.value} ${lastName.value}');

print(fullName.value); // 'John Doe'

firstName.value = 'Jane';
print(fullName.value); // 'Jane Doe' - 自動更新！
```

**重點**：
- **惰性求值** - 只在存取時計算
- **自動依賴追蹤** - 無需手動指定依賴項
- **快取結果** - 只在依賴項變更時重新計算
- **唯讀** - computed 值不能被直接修改（使用 `writableComputed` 實現雙向綁定）

### 3. Watch - 副作用

`watch()` 和 `watchEffect()` 在響應式依賴項變更時執行副作用（如日誌記錄、API 呼叫、本地儲存等）。

#### watch() - 明確指定監聽的內容

```dart
final count = ref(0);

watch(
  () => count.value,  // Getter: 要監聽什麼
  (newValue, oldValue) {  // Callback: 要做什麼
    print('Count changed from $oldValue to $newValue');
    // 執行副作用：儲存到本地儲存、發送分析事件等
  },
);

count.value = 5;  // 輸出: "Count changed from 0 to 5"
```

#### watchEffect() - 自動追蹤所有依賴項

```dart
final firstName = ref('John');
final lastName = ref('Doe');

watchEffect(() {
  // 自動追蹤 firstName 和 lastName
  print('Full name: ${firstName.value} ${lastName.value}');
  // 任何一個值變更時都會執行
});

firstName.value = 'Jane';  // 輸出: "Full name: Jane Doe"
lastName.value = 'Smith';  // 輸出: "Full name: Jane Smith"
```

**何時使用哪個**：
- 當您需要存取新舊值時使用 `watch()`
- 對於更簡單的副作用使用 `watchEffect()`
- 當您想要明確控制依賴項時使用 `watch()`

## 響應式系統的運作原理

### 依賴追蹤

當您在 `computed()` 或 `watchEffect()` 中讀取 `.value` 時，系統會自動追蹤該依賴項：

```dart
final count = ref(0);
final doubled = computed(() => count.value * 2);
//                              ^^^^^^^^^^^
//                              自動追蹤這個依賴項

// 內部流程：
// 1. computed 開始執行
// 2. 讀取 count.value
// 3. count 將 computed 註冊為訂閱者
// 4. computed 返回結果並快取

count.value = 5;
// 5. count 通知所有訂閱者
// 6. computed 標記為過時
// 7. 下次讀取 doubled.value 時重新計算
```

### 批次更新

響應式系統使用 **microtask** 批次處理更新，以避免冗餘的重新計算：

```dart
final count = ref(0);

watchEffect(() {
  print('Count: ${count.value}');
});

count.value = 1;
count.value = 2;
count.value = 3;

// 只輸出一次: "Count: 3"
// 而不是三次！
```

### 在 CompositionWidget 中的響應式

在 `CompositionWidget` 中，從 `setup()` 返回的 builder 函數被包裝在響應式 effect 中：

```dart
@override
Widget Function(BuildContext) setup() {
  final count = ref(0);

  // 這個 builder 是一個響應式 effect
  return (context) {
    print('Building with count: ${count.value}');
    return Text('${count.value}');
  };
}

// 當 count.value 改變時：
// 1. Builder effect 被標記為過時
// 2. 在 microtask 中重新執行 builder
// 3. 如果 widget tree 改變，呼叫 setState()
// 4. Flutter 重建 widget
```

## 實戰範例

### 範例 1：計數器應用

```dart
class CounterApp extends CompositionWidget {
  @override
  Widget Function(BuildContext) setup() {
    // 狀態
    final count = ref(0);

    // 衍生狀態
    final isEven = computed(() => count.value % 2 == 0);
    final squared = computed(() => count.value * count.value);

    // 副作用：記錄變更
    watch(
      () => count.value,
      (newValue, oldValue) {
        print('Count: $oldValue → $newValue');
      },
    );

    // 方法
    void increment() => count.value++;
    void decrement() => count.value--;
    void reset() => count.value = 0;

    return (context) => Scaffold(
      appBar: AppBar(title: Text('計數器')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${count.value}',
              style: Theme.of(context).textTheme.displayLarge,
            ),
            Text(
              isEven.value ? '偶數' : '奇數',
              style: TextStyle(
                color: isEven.value ? Colors.blue : Colors.red,
              ),
            ),
            Text('平方: ${squared.value}'),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: decrement,
                  child: Icon(Icons.remove),
                ),
                SizedBox(width: 10),
                ElevatedButton(
                  onPressed: reset,
                  child: Text('重設'),
                ),
                SizedBox(width: 10),
                ElevatedButton(
                  onPressed: increment,
                  child: Icon(Icons.add),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
```

### 範例 2：購物車

```dart
class Product {
  const Product({required this.id, required this.name, required this.price});
  final int id;
  final String name;
  final double price;
}

class ShoppingCart extends CompositionWidget {
  @override
  Widget Function(BuildContext) setup() {
    // 狀態
    final items = ref(<Product>[]);
    final quantities = ref(<int, int>{}); // productId -> quantity

    // 衍生狀態
    final itemCount = computed(() {
      return quantities.value.values.fold<int>(0, (sum, qty) => sum + qty);
    });

    final totalPrice = computed(() {
      double total = 0;
      for (final item in items.value) {
        final qty = quantities.value[item.id] ?? 0;
        total += item.price * qty;
      }
      return total;
    });

    final isEmpty = computed(() => items.value.isEmpty);

    // 方法
    void addItem(Product product) {
      if (!items.value.contains(product)) {
        items.value = [...items.value, product];
      }
      final newQuantities = Map<int, int>.from(quantities.value);
      newQuantities[product.id] = (newQuantities[product.id] ?? 0) + 1;
      quantities.value = newQuantities;
    }

    void removeItem(int productId) {
      items.value = items.value.where((p) => p.id != productId).toList();
      final newQuantities = Map<int, int>.from(quantities.value);
      newQuantities.remove(productId);
      quantities.value = newQuantities;
    }

    void updateQuantity(int productId, int quantity) {
      if (quantity <= 0) {
        removeItem(productId);
      } else {
        final newQuantities = Map<int, int>.from(quantities.value);
        newQuantities[productId] = quantity;
        quantities.value = newQuantities;
      }
    }

    // 副作用：儲存到本地儲存
    watch(
      () => [items.value, quantities.value],
      (_, __) {
        // 儲存購物車狀態到本地儲存
        print('Saving cart state...');
      },
    );

    return (context) => Scaffold(
      appBar: AppBar(
        title: Text('購物車 (${itemCount.value})'),
      ),
      body: isEmpty.value
          ? Center(child: Text('購物車是空的'))
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: items.value.length,
                    itemBuilder: (context, index) {
                      final item = items.value[index];
                      final quantity = quantities.value[item.id] ?? 0;
                      return ListTile(
                        title: Text(item.name),
                        subtitle: Text('\$${item.price.toStringAsFixed(2)}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(Icons.remove),
                              onPressed: () => updateQuantity(item.id, quantity - 1),
                            ),
                            Text('$quantity'),
                            IconButton(
                              icon: Icon(Icons.add),
                              onPressed: () => updateQuantity(item.id, quantity + 1),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                Divider(),
                Padding(
                  padding: EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '總計:',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      Text(
                        '\$${totalPrice.value.toStringAsFixed(2)}',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
```

## 處理集合的響應式

在處理集合（List、Map、Set）時，您必須建立新實例才能觸發響應式更新：

```dart
final items = ref(<String>[]);

// ❌ 這不會觸發更新
items.value.add('new item');
items.value[0] = 'updated';
items.value.sort();

// ✅ 建立新集合
items.value = [...items.value, 'new item'];
items.value = [...items.value]..[0] = 'updated';
items.value = [...items.value]..sort();

// 對於 Map
final map = ref(<String, int>{});

// ❌ 不會觸發更新
map.value['key'] = 42;

// ✅ 建立新 Map
map.value = {...map.value, 'key': 42};

// 對於 Set
final set = ref(<int>{});

// ❌ 不會觸發更新
set.value.add(1);

// ✅ 建立新 Set
set.value = {...set.value, 1};
```

## 效能最佳化

### 1. 保持 Computed 函數純粹

Computed 函數應該是純函數 - 相同的輸入總是產生相同的輸出，沒有副作用。

```dart
// ✅ 良好 - 純函數
final greeting = computed(() => 'Hello, ${name.value}');
final doubled = computed(() => count.value * 2);

// ❌ 不良 - 有副作用
final greeting = computed(() {
  print('Computing greeting...'); // 副作用！
  return 'Hello, ${name.value}';
});

// ❌ 不良 - 修改外部狀態
final result = computed(() {
  someOtherRef.value = count.value * 2; // 副作用！
  return count.value;
});
```

### 2. 最小化 Builder 中的依賴項

```dart
// ❌ 在任何 count 變更時重建
return (context) => Column(
  children: [
    Text('Count: ${count.value}'),
    ExpensiveWidget(data: someData), // 不必要地重建
  ],
);

// ✅ 提取到獨立 widget
return (context) => Column(
  children: [
    Text('Count: ${count.value}'),
    const ExpensiveWidget(data: someData), // 從不重建
  ],
);

// ✅ 或使用 computed 隔離依賴項
final countText = computed(() => 'Count: ${count.value}');
return (context) => Column(
  children: [
    Text(countText.value),
    const ExpensiveWidget(data: someData),
  ],
);
```

### 3. 對昂貴的計算使用 Computed

```dart
final items = ref(List.generate(1000, (i) => i));

// ❌ 每次存取時計算
int getSum() {
  return items.value.fold(0, (sum, item) => sum + item);
}

// ✅ 快取直到 items 變更
final sum = computed(() {
  return items.value.fold(0, (sum, item) => sum + item);
});

// 多次存取 sum.value 只計算一次
print(sum.value); // 計算
print(sum.value); // 使用快取
print(sum.value); // 使用快取
```

### 4. 使用 Watch 清理

Watch effects 會自動在元件卸載時清理，但您也可以手動停止它們：

```dart
@override
Widget Function(BuildContext) setup() {
  final count = ref(0);

  // Watch 返回一個 stop 函數
  final stop = watch(
    () => count.value,
    (newValue, _) {
      print('Count: $newValue');
    },
  );

  // 條件式停止
  if (someCondition) {
    stop(); // 手動停止監聽
  }

  return (context) => Text('${count.value}');
}
```

## 常見模式

### 模式 1：切換狀態

```dart
final isOpen = ref(false);

void toggle() => isOpen.value = !isOpen.value;
```

### 模式 2：載入狀態

```dart
final isLoading = ref(false);
final data = ref<String?>(null);

Future<void> loadData() async {
  isLoading.value = true;
  try {
    data.value = await fetchData();
  } finally {
    isLoading.value = false;
  }
}
```

### 模式 3：表單驗證

```dart
final email = ref('');
final password = ref('');

final isEmailValid = computed(() {
  final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
  return emailRegex.hasMatch(email.value);
});

final isPasswordValid = computed(() => password.value.length >= 8);

final isFormValid = computed(() {
  return isEmailValid.value && isPasswordValid.value;
});
```

### 模式 4：搜尋和過濾

```dart
final items = ref(['Apple', 'Banana', 'Cherry', 'Date', 'Elderberry']);
final searchQuery = ref('');

final filteredItems = computed(() {
  final query = searchQuery.value.toLowerCase();
  if (query.isEmpty) return items.value;
  return items.value.where((item) {
    return item.toLowerCase().contains(query);
  }).toList();
});
```

## 常見陷阱

### 陷阱 1：忘記 .value

```dart
final count = ref(5);

// ❌ 比較 Ref 物件，而不是值
if (count == 5) { /* 永遠不會是 true */ }

// ✅ 比較值
if (count.value == 5) { /* 正確 */ }
```

### 陷阱 2：直接讀取 Props

在 `CompositionWidget` 中，始終使用 `widget()` 來響應 prop 變更：

```dart
class UserCard extends CompositionWidget {
  final String name;

  @override
  Widget Function(BuildContext) setup() {
    // ❌ 只捕獲初始值
    final greeting = computed(() => 'Hello, $name');

    // ✅ 響應 prop 變更
    final props = widget();
    final greeting = computed(() => 'Hello, ${props.value.name}');

    return (context) => Text(greeting.value);
  }
}
```

### 陷阱 3：變更集合

```dart
final items = ref(<String>[]);

// ❌ 變更不會觸發更新
items.value.add('new');

// ✅ 建立新集合
items.value = [...items.value, 'new'];
```

### 陷阱 4：在 Computed 中使用副作用

```dart
final count = ref(0);

// ❌ 副作用在 computed 中
final doubled = computed(() {
  print('Computing...'); // 不要這樣做！
  return count.value * 2;
});

// ✅ 使用 watch 處理副作用
watch(() => count.value, (value, _) {
  print('Count changed to $value');
});

final doubled = computed(() => count.value * 2);
```

## 除錯響應式

### 檢查依賴項

```dart
// 添加日誌以查看 computed 何時執行
final fullName = computed(() {
  print('Computing fullName');
  return '${firstName.value} ${lastName.value}';
});
```

### 監聽所有變更

```dart
watchEffect(() {
  print('State snapshot:');
  print('  count: ${count.value}');
  print('  name: ${name.value}');
  print('  isActive: ${isActive.value}');
});
```

### 使用 Flutter DevTools

Flutter DevTools 可以幫助您查看 widget 重建。在 builder 中添加日誌以追蹤重建：

```dart
return (context) {
  print('Building with count: ${count.value}');
  return Text('${count.value}');
};
```

## 最佳實踐

### 1. 狀態放在正確的位置

- **本地狀態**：僅在單個 widget 中使用的狀態應該放在該 widget 中
- **共享狀態**：多個 widget 需要的狀態應該使用 `provide`/`inject` 或提升到共同的父 widget

### 2. 保持狀態扁平

```dart
// ❌ 深層巢狀
final state = ref({
  'user': {
    'profile': {
      'name': 'John',
    },
  },
});

// ✅ 扁平結構
final userName = ref('John');
```

### 3. 為複雜邏輯使用 Composables

```dart
// 提取可重用的邏輯
(Ref<int>, void Function()) useCounter({int initial = 0}) {
  final count = ref(initial);
  void increment() => count.value++;
  return (count, increment);
}
```

### 4. 避免過度響應式

不是所有東西都需要是響應式的。對於靜態數據或配置，使用普通變數：

```dart
// ❌ 不必要的響應式
final apiEndpoint = ref('https://api.example.com');

// ✅ 靜態配置
const apiEndpoint = 'https://api.example.com';
```

## 下一步

- 探索[狀態管理](./state-management.md)以了解應用程式級狀態
- 學習[非同步操作](./async-operations.md)以處理 futures 和 streams
- 閱讀[深入響應式](../internals/reactivity-in-depth.md)以了解進階概念
