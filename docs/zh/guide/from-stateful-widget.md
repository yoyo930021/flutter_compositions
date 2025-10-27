# 從 StatefulWidget 遷移

本指南透過並列比較的方式，幫助你從 `StatefulWidget` 轉換到 `CompositionWidget`。

## 目錄

1. [基本計數器](#基本計數器)
2. [控制器](#控制器)
3. [生命週期方法](#生命週期方法)
4. [狀態依賴](#狀態依賴)
5. [表單](#表單)
6. [非同步操作](#非同步操作)
7. [動畫](#動畫)
8. [屬性響應式](#屬性響應式)

## 基本計數器

### StatefulWidget

```dart
class Counter extends StatefulWidget {
  const Counter({super.key});

  @override
  State<Counter> createState() => _CounterState();
}

class _CounterState extends State<Counter> {
  int _count = 0;

  void _increment() {
    setState(() {
      _count++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text('Count: $_count'),
        ElevatedButton(
          onPressed: _increment,
          child: const Text('Increment'),
        ),
      ],
    );
  }
}
```

### CompositionWidget

```dart
class Counter extends CompositionWidget {
  const Counter({super.key});

  @override
  Widget Function(BuildContext) setup() {
    // Reactive state - no setState needed
    final count = ref(0);

    void increment() => count.value++;

    return (context) => Column(
      children: [
        Text('Count: ${count.value}'),
        ElevatedButton(
          onPressed: increment,
          child: const Text('Increment'),
        ),
      ],
    );
  }
}
```

**主要差異**：
- ✅ 無需獨立的 State 類別
- ✅ 無需呼叫 `setState()`
- ✅ 直接更新值即可自動觸發重建
- ✅ 程式碼更簡潔清晰

## 控制器

### StatefulWidget

```dart
class ScrollExample extends StatefulWidget {
  @override
  State<ScrollExample> createState() => _ScrollExampleState();
}

class _ScrollExampleState extends State<ScrollExample> {
  late ScrollController _scrollController;
  double _scrollOffset = 0;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    setState(() {
      _scrollOffset = _scrollController.offset;
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text('Offset: $_scrollOffset'),
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            itemCount: 100,
            itemBuilder: (context, index) => ListTile(
              title: Text('Item $index'),
            ),
          ),
        ),
      ],
    );
  }
}
```

### CompositionWidget

```dart
class ScrollExample extends CompositionWidget {
  @override
  Widget Function(BuildContext) setup() {
    // Auto-disposed controller with reactive offset
    final scrollController = useScrollController();

    final scrollOffset = computed(() {
      // Automatically tracks controller changes
      return scrollController.value.offset;
    });

    return (context) => Column(
      children: [
        Text('Offset: ${scrollOffset.value.toStringAsFixed(1)}'),
        Expanded(
          child: ListView.builder(
            controller: scrollController.value,
            itemCount: 100,
            itemBuilder: (context, index) => ListTile(
              title: Text('Item $index'),
            ),
          ),
        ),
      ],
    );
  }
}
```

**主要差異**：
- ✅ 自動釋放資源（無需手動清理）
- ✅ 無需管理監聽器
- ✅ 使用 `computed` 實現響應式偏移量追蹤
- ✅ 減少樣板程式碼

## 生命週期方法

### StatefulWidget

```dart
class LifecycleExample extends StatefulWidget {
  @override
  State<LifecycleExample> createState() => _LifecycleExampleState();
}

class _LifecycleExampleState extends State<LifecycleExample> {
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    print('Widget created');

    WidgetsBinding.instance.addPostFrameCallback((_) {
      print('Widget mounted (first frame)');
    });

    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      print('Timer tick');
    });
  }

  @override
  void dispose() {
    print('Widget disposing');
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    print('Building widget');
    return Container();
  }
}
```

### CompositionWidget

```dart
class LifecycleExample extends CompositionWidget {
  @override
  Widget Function(BuildContext) setup() {
    print('Setup (runs once)');

    onMounted(() {
      print('Widget mounted (first frame)');

      // Timer automatically managed
      final timer = Timer.periodic(Duration(seconds: 1), (timer) {
        print('Timer tick');
      });

      onUnmounted(() {
        print('Cleaning up timer');
        timer.cancel();
      });
    });

    onUnmounted(() {
      print('Widget unmounted');
    });

    onBuild((context) {
      print('Building widget');
    });

    return (context) => Container();
  }
}
```

**主要差異**：
- ✅ 清晰的生命週期鉤子名稱
- ✅ 支援多個 onMounted/onUnmounted
- ✅ 提供 onBuild 鉤子用於建構時邏輯
- ✅ 清理回呼與初始化位置相近

## 狀態依賴

### StatefulWidget

```dart
class DependentState extends StatefulWidget {
  @override
  State<DependentState> createState() => _DependentStateState();
}

class _DependentStateState extends State<DependentState> {
  int _count = 0;
  late String _message;

  @override
  void initState() {
    super.initState();
    _updateMessage();
  }

  void _updateMessage() {
    setState(() {
      _message = _count == 0 ? 'Start' : 'Count: $_count';
    });
  }

  void _increment() {
    setState(() {
      _count++;
      _updateMessage();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(_message),
        ElevatedButton(
          onPressed: _increment,
          child: const Text('Increment'),
        ),
      ],
    );
  }
}
```

### CompositionWidget

```dart
class DependentState extends CompositionWidget {
  @override
  Widget Function(BuildContext) setup() {
    final count = ref(0);

    // Automatically updates when count changes
    final message = computed(() =>
      count.value == 0 ? 'Start' : 'Count: ${count.value}'
    );

    void increment() => count.value++;

    return (context) => Column(
      children: [
        Text(message.value),
        ElevatedButton(
          onPressed: increment,
          child: const Text('Increment'),
        ),
      ],
    );
  }
}
```

**主要差異**：
- ✅ 自動追蹤依賴關係
- ✅ 無需手動更新
- ✅ 使用 `computed` 清晰地定義衍生狀態

## 表單

### StatefulWidget

```dart
class LoginForm extends StatefulWidget {
  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  late TextEditingController _emailController;
  late TextEditingController _passwordController;
  bool _isValid = false;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();

    _emailController.addListener(_validate);
    _passwordController.addListener(_validate);
  }

  void _validate() {
    setState(() {
      _isValid = _emailController.text.isNotEmpty &&
                 _passwordController.text.length >= 6;
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_isValid) {
      print('Email: ${_emailController.text}');
      print('Password: ${_passwordController.text}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: _emailController,
          decoration: InputDecoration(labelText: 'Email'),
        ),
        TextField(
          controller: _passwordController,
          decoration: InputDecoration(labelText: 'Password'),
          obscureText: true,
        ),
        ElevatedButton(
          onPressed: _isValid ? _submit : null,
          child: Text('Submit'),
        ),
      ],
    );
  }
}
```

### CompositionWidget

```dart
class LoginForm extends CompositionWidget {
  @override
  Widget Function(BuildContext) setup() {
    final (emailController, email, _) = useTextEditingController();
    final (passwordController, password, _) = useTextEditingController();

    // Reactive validation
    final isValid = computed(() =>
      email.value.isNotEmpty && password.value.length >= 6
    );

    void submit() {
      if (isValid.value) {
        print('Email: ${email.value}');
        print('Password: ${password.value}');
      }
    }

    return (context) => Column(
      children: [
        TextField(
          controller: emailController,
          decoration: InputDecoration(labelText: 'Email'),
        ),
        TextField(
          controller: passwordController,
          decoration: InputDecoration(labelText: 'Password'),
          obscureText: true,
        ),
        ElevatedButton(
          onPressed: isValid.value ? submit : null,
          child: Text('Submit'),
        ),
      ],
    );
  }
}
```

**主要差異**：
- ✅ 自動釋放控制器
- ✅ 響應式文字綁定
- ✅ 計算式驗證
- ✅ 無需手動管理監聽器

## 非同步操作

### StatefulWidget

```dart
class UserProfile extends StatefulWidget {
  final int userId;
  const UserProfile({required this.userId});

  @override
  State<UserProfile> createState() => _UserProfileState();
}

class _UserProfileState extends State<UserProfile> {
  User? _user;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  @override
  void didUpdateWidget(UserProfile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.userId != oldWidget.userId) {
      _loadUser();
    }
  }

  Future<void> _loadUser() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final user = await api.fetchUser(widget.userId);
      if (mounted) {
        setState(() {
          _user = user;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return CircularProgressIndicator();
    if (_error != null) return Text('Error: $_error');
    if (_user == null) return Text('No user');
    return Text('User: ${_user!.name}');
  }
}
```

### CompositionWidget

```dart
class UserProfile extends CompositionWidget {
  final int userId;
  const UserProfile({required this.userId});

  @override
  Widget Function(BuildContext) setup() {
    final props = widget();

    // Auto-refetch when userId changes
    final (userData, _) = useAsyncData<User, int>(
      (userId) => api.fetchUser(userId),
      watch: () => props.value.userId,
    );

    return (context) => switch (userData.value) {
      AsyncLoading() => CircularProgressIndicator(),
      AsyncError(:final errorValue) => Text('Error: $errorValue'),
      AsyncData(:final value) => Text('User: ${value.name}'),
      AsyncIdle() => Text('No user'),
    };
  }
}
```

**主要差異**：
- ✅ 屬性變更時自動重新擷取
- ✅ 內建載入/錯誤/資料狀態
- ✅ 無需檢查 mounted
- ✅ 使用模式匹配清晰處理狀態

## 動畫

### StatefulWidget

```dart
class FadeInWidget extends StatefulWidget {
  @override
  State<FadeInWidget> createState() => _FadeInWidgetState();
}

class _FadeInWidgetState extends State<FadeInWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(seconds: 1),
      vsync: this,
    );

    _opacity = Tween<double>(begin: 0.0, end: 1.0).animate(_controller);

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _opacity,
      builder: (context, child) => Opacity(
        opacity: _opacity.value,
        child: child,
      ),
      child: Container(child: Text('Hello')),
    );
  }
}
```

### CompositionWidget

```dart
class FadeInWidget extends CompositionWidget {
  @override
  Widget Function(BuildContext) setup() {
    final (controller, animValue) = useAnimationController(
      duration: Duration(seconds: 1),
    );

    final opacity = computed(() => animValue.value);

    onMounted(() => controller.forward());

    return (context) => Opacity(
      opacity: opacity.value,
      child: Container(child: Text('Hello')),
    );
  }
}
```

**主要差異**：
- ✅ 無需混入（mixin）
- ✅ 自動釋放資源
- ✅ 響應式動畫值
- ✅ 更簡潔的 API

## 屬性響應式

### StatefulWidget

```dart
class UserGreeting extends StatefulWidget {
  final String username;
  const UserGreeting({required this.username});

  @override
  State<UserGreeting> createState() => _UserGreetingState();
}

class _UserGreetingState extends State<UserGreeting> {
  late String _greeting;

  @override
  void initState() {
    super.initState();
    _updateGreeting();
  }

  @override
  void didUpdateWidget(UserGreeting oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.username != oldWidget.username) {
      _updateGreeting();
    }
  }

  void _updateGreeting() {
    setState(() {
      _greeting = 'Hello, ${widget.username}!';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Text(_greeting);
  }
}
```

### CompositionWidget

```dart
class UserGreeting extends CompositionWidget {
  final String username;
  const UserGreeting({required this.username});

  @override
  Widget Function(BuildContext) setup() {
    final props = widget();

    // Automatically updates when username changes
    final greeting = computed(() => 'Hello, ${props.value.username}!');

    return (context) => Text(greeting.value);
  }
}
```

**主要差異**：
- ✅ 無需 `didUpdateWidget`
- ✅ 自動偵測屬性變更
- ✅ 更簡潔的響應式程式碼

## 遷移檢查清單

從 StatefulWidget 遷移時：

- [ ] 將 State 類別替換為 `setup()` 方法
- [ ] 將 `setState(() => field = value)` 轉換為 `ref.value = value`
- [ ] 將 `initState` 邏輯移至 `setup()` 主體
- [ ] 將 `dispose` 替換為 `onUnmounted`
- [ ] 使用 `onMounted` 處理首次畫面後的邏輯
- [ ] 將控制器替換為 `use*` 輔助函式
- [ ] 使用 `widget()` 進行響應式屬性存取
- [ ] 將衍生狀態轉換為 `computed`
- [ ] 將監聽器替換為 `watch` 或 `watchEffect`
- [ ] 測試熱重載是否正常運作

## 最佳實踐

### ✅ 建議做法

```dart
// 使用 refs 處理可變狀態
final count = ref(0);

// 使用 computed 處理衍生狀態
final doubled = computed(() => count.value * 2);

// 使用 composables 實現可重用邏輯
final (controller, text) = useTextEditingController();

// 使用 widget() 存取屬性
final props = widget();
final name = computed(() => props.value.username);
```

### ❌ 不建議做法

```dart
// 不要使用可變欄位
int count = 0; // ❌ 非響應式

// 不要在 setup 中直接存取屬性
final name = this.username; // ❌ 非響應式

// 不要忘記 .value
if (count == 5) { /* ❌ 比較的是 Ref 物件 */ }

// 使用 use* 輔助函式時不要手動釋放
final controller = useScrollController();
controller.value.dispose(); // ❌ 已自動處理
```

## 結論

CompositionWidget 為 Flutter 狀態管理提供了更現代、更響應式的方法，同時保持與 Flutter widget 系統的完全相容性。遷移路徑直截了當，在程式碼清晰度和可維護性方面帶來顯著的效益。

更多資訊請參閱：
- [響應式基礎](/guide/reactivity-fundamentals.md)
- [內建 Composables](/guide/built-in-composables.md)
- [建立 Composables](./creating-composables.md)
