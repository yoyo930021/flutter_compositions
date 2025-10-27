# 表單處理

表單是大多數應用程式的核心。本指南將探討如何使用 Flutter Compositions 建立響應式表單，包括輸入處理、驗證、提交和錯誤處理。

## 為什麼使用響應式表單？

傳統的 Flutter 表單處理需要大量樣板程式碼：

```dart
// ❌ 傳統方式 - 樣板程式碼多
class _LoginFormState extends State<LoginForm> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose(); // 別忘了！
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      // 提交
    }
  }
}

// ✅ Compositions 方式 - 簡潔且響應式
@override
Widget Function(BuildContext) setup() {
  final (emailController, email, _) = useTextEditingController();
  final (passwordController, password, _) = useTextEditingController();

  final isValid = computed(() {
    return email.value.isNotEmpty && password.value.length >= 8;
  });

  return (context) => /* ... */;
}
```

## useTextEditingController - 基本輸入

`useTextEditingController` 建立一個帶有響應式文字和選擇追蹤的 `TextEditingController`。

### 簡單文字輸入

```dart
class SimpleForm extends CompositionWidget {
  @override
  Widget Function(BuildContext) setup() {
    final (controller, text, selection) = useTextEditingController();

    // 響應式計算
    final charCount = computed(() => text.value.length);
    final wordCount = computed(() {
      if (text.value.isEmpty) return 0;
      return text.value.split(' ').where((w) => w.isNotEmpty).length;
    });

    return (context) => Column(
      children: [
        TextField(
          controller: controller.value,
          decoration: InputDecoration(
            labelText: '輸入文字',
            hintText: '開始輸入...',
          ),
        ),
        SizedBox(height: 8),
        Text('字元: ${charCount.value}'),
        Text('單字: ${wordCount.value}'),
      ],
    );
  }
}
```

### 程式化控制

```dart
class ControlledInput extends CompositionWidget {
  @override
  Widget Function(BuildContext) setup() {
    final (controller, text, selection) = useTextEditingController(
      text: '初始值',
    );

    void clearText() {
      text.value = '';
    }

    void insertTemplate() {
      text.value = 'Dear [Name],\n\n[Content]\n\nBest regards,\n[Your Name]';
    }

    void selectAll() {
      selection.value = TextSelection(
        baseOffset: 0,
        extentOffset: text.value.length,
      );
    }

    void toUpperCase() {
      text.value = text.value.toUpperCase();
    }

    return (context) => Column(
      children: [
        TextField(controller: controller.value),
        Row(
          children: [
            ElevatedButton(
              onPressed: clearText,
              child: Text('清除'),
            ),
            ElevatedButton(
              onPressed: insertTemplate,
              child: Text('範本'),
            ),
            ElevatedButton(
              onPressed: selectAll,
              child: Text('全選'),
            ),
            ElevatedButton(
              onPressed: toUpperCase,
              child: Text('大寫'),
            ),
          ],
        ),
      ],
    );
  }
}
```

## 表單驗證

### 即時驗證

```dart
class EmailForm extends CompositionWidget {
  @override
  Widget Function(BuildContext) setup() {
    final (controller, email, _) = useTextEditingController();

    // 驗證規則
    final isEmailValid = computed(() {
      if (email.value.isEmpty) return null;
      final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
      return emailRegex.hasMatch(email.value);
    });

    final errorText = computed(() {
      final valid = isEmailValid.value;
      if (valid == null) return null;
      return valid ? null : '請輸入有效的電子郵件地址';
    });

    return (context) => TextField(
      controller: controller.value,
      decoration: InputDecoration(
        labelText: '電子郵件',
        errorText: errorText.value,
        suffixIcon: email.value.isNotEmpty
            ? Icon(
                isEmailValid.value == true
                    ? Icons.check_circle
                    : Icons.error,
                color: isEmailValid.value == true
                    ? Colors.green
                    : Colors.red,
              )
            : null,
      ),
      keyboardType: TextInputType.emailAddress,
    );
  }
}
```

### 多欄位驗證

```dart
class RegistrationForm extends CompositionWidget {
  @override
  Widget Function(BuildContext) setup() {
    final (emailController, email, _) = useTextEditingController();
    final (passwordController, password, _) = useTextEditingController();
    final (confirmPasswordController, confirmPassword, _) =
        useTextEditingController();

    // 個別欄位驗證
    final isEmailValid = computed(() {
      if (email.value.isEmpty) return null;
      final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
      return emailRegex.hasMatch(email.value);
    });

    final isPasswordValid = computed(() {
      if (password.value.isEmpty) return null;
      return password.value.length >= 8;
    });

    final isPasswordStrong = computed(() {
      if (password.value.isEmpty) return false;
      final hasUppercase = password.value.contains(RegExp(r'[A-Z]'));
      final hasLowercase = password.value.contains(RegExp(r'[a-z]'));
      final hasDigits = password.value.contains(RegExp(r'[0-9]'));
      return hasUppercase && hasLowercase && hasDigits;
    });

    final doPasswordsMatch = computed(() {
      if (confirmPassword.value.isEmpty) return null;
      return password.value == confirmPassword.value;
    });

    // 整體表單驗證
    final isFormValid = computed(() {
      return isEmailValid.value == true &&
          isPasswordValid.value == true &&
          doPasswordsMatch.value == true;
    });

    // 錯誤訊息
    final emailError = computed(() {
      if (isEmailValid.value == null) return null;
      return isEmailValid.value! ? null : '無效的電子郵件地址';
    });

    final passwordError = computed(() {
      if (isPasswordValid.value == null) return null;
      return isPasswordValid.value! ? null : '密碼必須至少 8 個字元';
    });

    final confirmPasswordError = computed(() {
      if (doPasswordsMatch.value == null) return null;
      return doPasswordsMatch.value! ? null : '密碼不匹配';
    });

    return (context) => Column(
      children: [
        TextField(
          controller: emailController.value,
          decoration: InputDecoration(
            labelText: '電子郵件',
            errorText: emailError.value,
          ),
          keyboardType: TextInputType.emailAddress,
        ),
        SizedBox(height: 16),
        TextField(
          controller: passwordController.value,
          decoration: InputDecoration(
            labelText: '密碼',
            errorText: passwordError.value,
            helperText: isPasswordStrong.value
                ? '強密碼'
                : '包含大小寫字母和數字',
          ),
          obscureText: true,
        ),
        SizedBox(height: 16),
        TextField(
          controller: confirmPasswordController.value,
          decoration: InputDecoration(
            labelText: '確認密碼',
            errorText: confirmPasswordError.value,
          ),
          obscureText: true,
        ),
        SizedBox(height: 24),
        ElevatedButton(
          onPressed: isFormValid.value ? () => submitForm() : null,
          child: Text('註冊'),
        ),
      ],
    );
  }

  void submitForm() {
    // 提交表單
  }
}
```

## 實戰範例

### 登入表單

```dart
class LoginForm extends CompositionWidget {
  @override
  Widget Function(BuildContext) setup() {
    final (emailController, email, _) = useTextEditingController();
    final (passwordController, password, _) = useTextEditingController();

    final isLoading = ref(false);
    final error = ref<String?>(null);

    // 驗證
    final isEmailValid = computed(() {
      final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
      return emailRegex.hasMatch(email.value);
    });

    final isFormValid = computed(() {
      return isEmailValid.value && password.value.isNotEmpty;
    });

    // 提交
    Future<void> submit() async {
      if (!isFormValid.value) return;

      isLoading.value = true;
      error.value = null;

      try {
        await authService.login(
          email: email.value,
          password: password.value,
        );
        // 導航到主頁
      } catch (e) {
        error.value = e.toString();
      } finally {
        isLoading.value = false;
      }
    }

    return (context) => Scaffold(
      appBar: AppBar(title: Text('登入')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (error.value != null)
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red),
                    SizedBox(width: 8),
                    Expanded(child: Text(error.value!)),
                  ],
                ),
              ),
            SizedBox(height: 16),
            TextField(
              controller: emailController.value,
              decoration: InputDecoration(
                labelText: '電子郵件',
                prefixIcon: Icon(Icons.email),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
              enabled: !isLoading.value,
            ),
            SizedBox(height: 16),
            TextField(
              controller: passwordController.value,
              decoration: InputDecoration(
                labelText: '密碼',
                prefixIcon: Icon(Icons.lock),
                border: OutlineInputBorder(),
              ),
              obscureText: true,
              enabled: !isLoading.value,
              onSubmitted: (_) => submit(),
            ),
            SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: isLoading.value || !isFormValid.value
                    ? null
                    : submit,
                child: isLoading.value
                    ? CircularProgressIndicator(color: Colors.white)
                    : Text('登入'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

### 個人資料表單

```dart
const authServiceKey = InjectionKey<AuthService>('authService');
// 父層需要以 provide(authServiceKey, AuthService()) 提供實例

class ProfileForm extends CompositionWidget {
  @override
  Widget Function(BuildContext) setup() {
    final authService = inject(authServiceKey);

    // 表單欄位
    final (nameController, name, _) = useTextEditingController();
    final (bioController, bio, _) = useTextEditingController();
    final (websiteController, website, _) = useTextEditingController();
    final avatar = ref<File?>(null);

    // 載入狀態
    final isLoading = ref(false);
    final isSaving = ref(false);

    // 驗證
    final isNameValid = computed(() => name.value.trim().isNotEmpty);

    final isWebsiteValid = computed(() {
      if (website.value.isEmpty) return true;
      final urlRegex = RegExp(
        r'^https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b',
      );
      return urlRegex.hasMatch(website.value);
    });

    final hasChanges = ref(false);

    // 載入現有個人資料
    onMounted(() async {
      isLoading.value = true;
      try {
        final profile = await authService.getCurrentUserProfile();
        name.value = profile.name;
        bio.value = profile.bio ?? '';
        website.value = profile.website ?? '';
      } catch (e) {
        // 處理錯誤
      } finally {
        isLoading.value = false;
      }
    });

    // 追蹤變更
    watchEffect(() {
      hasChanges.value = name.value.isNotEmpty ||
          bio.value.isNotEmpty ||
          website.value.isNotEmpty ||
          avatar.value != null;
    });

    // 選擇頭像
    Future<void> pickAvatar() async {
      final picker = ImagePicker();
      final image = await picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        avatar.value = File(image.path);
      }
    }

    // 儲存
    Future<void> save() async {
      if (!isNameValid.value || !isWebsiteValid.value) return;

      isSaving.value = true;
      try {
        await authService.updateProfile(
          name: name.value,
          bio: bio.value.isEmpty ? null : bio.value,
          website: website.value.isEmpty ? null : website.value,
          avatar: avatar.value,
        );

        // 顯示成功訊息
        onBuild(() {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('個人資料已更新')),
          );
        });

        hasChanges.value = false;
      } catch (e) {
        // 顯示錯誤
        onBuild(() {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('無法更新個人資料'),
              backgroundColor: Colors.red,
            ),
          );
        });
      } finally {
        isSaving.value = false;
      }
    }

    return (context) {
      if (isLoading.value) {
        return Scaffold(
          appBar: AppBar(title: Text('編輯個人資料')),
          body: Center(child: CircularProgressIndicator()),
        );
      }

      return Scaffold(
        appBar: AppBar(
          title: Text('編輯個人資料'),
          actions: [
            if (hasChanges.value)
              TextButton(
                onPressed: isSaving.value ? null : save,
                child: isSaving.value
                    ? CircularProgressIndicator(color: Colors.white)
                    : Text('儲存', style: TextStyle(color: Colors.white)),
              ),
          ],
        ),
        body: SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              // 頭像
              GestureDetector(
                onTap: pickAvatar,
                child: CircleAvatar(
                  radius: 50,
                  backgroundImage: avatar.value != null
                      ? FileImage(avatar.value!)
                      : null,
                  child: avatar.value == null
                      ? Icon(Icons.add_a_photo, size: 40)
                      : null,
                ),
              ),
              SizedBox(height: 24),

              // 姓名
              TextField(
                controller: nameController.value,
                decoration: InputDecoration(
                  labelText: '姓名',
                  border: OutlineInputBorder(),
                  errorText: !isNameValid.value ? '姓名為必填' : null,
                ),
              ),
              SizedBox(height: 16),

              // 簡介
              TextField(
                controller: bioController.value,
                decoration: InputDecoration(
                  labelText: '簡介',
                  border: OutlineInputBorder(),
                  hintText: '介紹一下你自己...',
                ),
                maxLines: 4,
                maxLength: 200,
              ),
              SizedBox(height: 16),

              // 網站
              TextField(
                controller: websiteController.value,
                decoration: InputDecoration(
                  labelText: '網站',
                  border: OutlineInputBorder(),
                  errorText: !isWebsiteValid.value ? '無效的網址' : null,
                  hintText: 'https://example.com',
                ),
                keyboardType: TextInputType.url,
              ),
            ],
          ),
        ),
      );
    };
  }
}
```

### 搜尋表單與過濾

```dart
class ProductSearchForm extends CompositionWidget {
  @override
  Widget Function(BuildContext) setup() {
    final (searchController, query, _) = useTextEditingController();
    final category = ref<String>('all');
    final minPrice = ref(0.0);
    final maxPrice = ref(1000.0);
    final sortBy = ref<SortOption>(SortOption.relevance);

    // 防抖搜尋
    final debouncedQuery = ref('');
    Timer? debounceTimer;

    watch(
      () => query.value,
      (newQuery, _) {
        debounceTimer?.cancel();
        debounceTimer = Timer(Duration(milliseconds: 500), () {
          debouncedQuery.value = newQuery;
        });
      },
    );

    onUnmounted(() => debounceTimer?.cancel());

    // 搜尋結果
    final (results, refresh) = useAsyncData<List<Product>, SearchParams>(
      (params) => productService.search(params),
      watch: () => SearchParams(
        query: debouncedQuery.value,
        category: category.value,
        minPrice: minPrice.value,
        maxPrice: maxPrice.value,
        sortBy: sortBy.value,
      ),
    );

    // 重設過濾器
    void resetFilters() {
      searchController.value.clear();
      category.value = 'all';
      minPrice.value = 0.0;
      maxPrice.value = 1000.0;
      sortBy.value = SortOption.relevance;
    }

    return (context) => Column(
      children: [
        // 搜尋列
        Padding(
          padding: EdgeInsets.all(16),
          child: TextField(
            controller: searchController.value,
            decoration: InputDecoration(
              hintText: '搜尋產品...',
              prefixIcon: Icon(Icons.search),
              suffixIcon: query.value.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.clear),
                      onPressed: () => searchController.value.clear(),
                    )
                  : null,
              border: OutlineInputBorder(),
            ),
          ),
        ),

        // 過濾器
        ExpansionTile(
          title: Text('過濾器'),
          children: [
            // 類別
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: DropdownButtonFormField<String>(
                value: category.value,
                decoration: InputDecoration(labelText: '類別'),
                items: [
                  DropdownMenuItem(value: 'all', child: Text('全部')),
                  DropdownMenuItem(value: 'electronics', child: Text('電子產品')),
                  DropdownMenuItem(value: 'clothing', child: Text('服裝')),
                  DropdownMenuItem(value: 'books', child: Text('書籍')),
                ],
                onChanged: (value) => category.value = value!,
              ),
            ),

            // 價格範圍
            Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('價格範圍: \$${minPrice.value.toInt()} - \$${maxPrice.value.toInt()}'),
                  RangeSlider(
                    values: RangeValues(minPrice.value, maxPrice.value),
                    min: 0,
                    max: 1000,
                    divisions: 20,
                    onChanged: (values) {
                      minPrice.value = values.start;
                      maxPrice.value = values.end;
                    },
                  ),
                ],
              ),
            ),

            // 排序
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: DropdownButtonFormField<SortOption>(
                value: sortBy.value,
                decoration: InputDecoration(labelText: '排序'),
                items: [
                  DropdownMenuItem(value: SortOption.relevance, child: Text('相關性')),
                  DropdownMenuItem(value: SortOption.priceLow, child: Text('價格: 低到高')),
                  DropdownMenuItem(value: SortOption.priceHigh, child: Text('價格: 高到低')),
                  DropdownMenuItem(value: SortOption.newest, child: Text('最新')),
                ],
                onChanged: (value) => sortBy.value = value!,
              ),
            ),

            // 重設按鈕
            Padding(
              padding: EdgeInsets.all(16),
              child: TextButton(
                onPressed: resetFilters,
                child: Text('重設過濾器'),
              ),
            ),
          ],
        ),

        // 結果
        Expanded(
          child: switch (results.value) {
            AsyncLoading() => Center(child: CircularProgressIndicator()),
            AsyncError(:final errorValue) => Center(
              child: Text('錯誤: $errorValue'),
            ),
            AsyncData(:final value) => value.isEmpty
                ? Center(child: Text('找不到產品'))
                : ListView.builder(
                    itemCount: value.length,
                    itemBuilder: (context, index) {
                      return ProductCard(product: value[index]);
                    },
                  ),
            AsyncIdle() => SizedBox.shrink(),
          },
        ),
      ],
    );
  }
}

class SearchParams {
  const SearchParams({
    required this.query,
    required this.category,
    required this.minPrice,
    required this.maxPrice,
    required this.sortBy,
  });

  final String query;
  final String category;
  final double minPrice;
  final double maxPrice;
  final SortOption sortBy;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SearchParams &&
          query == other.query &&
          category == other.category &&
          minPrice == other.minPrice &&
          maxPrice == other.maxPrice &&
          sortBy == other.sortBy;

  @override
  int get hashCode => Object.hash(query, category, minPrice, maxPrice, sortBy);
}

enum SortOption { relevance, priceLow, priceHigh, newest }
```

### 動態表單

```dart
class DynamicSurveyForm extends CompositionWidget {
  @override
  Widget Function(BuildContext) setup() {
    final questions = ref<List<Question>>([
      Question(
        id: '1',
        text: '您的年齡範圍？',
        type: QuestionType.radio,
        options: ['18-25', '26-35', '36-45', '46+'],
      ),
      Question(
        id: '2',
        text: '您感興趣的主題？',
        type: QuestionType.checkbox,
        options: ['科技', '運動', '藝術', '音樂'],
      ),
      Question(
        id: '3',
        text: '額外意見',
        type: QuestionType.text,
      ),
    ]);

    final answers = ref<Map<String, dynamic>>({});

    void updateAnswer(String questionId, dynamic answer) {
      final newAnswers = Map<String, dynamic>.from(answers.value);
      newAnswers[questionId] = answer;
      answers.value = newAnswers;
    }

    final isComplete = computed(() {
      return questions.value.every((q) => answers.value.containsKey(q.id));
    });

    Future<void> submit() async {
      // 提交問卷
      print('提交答案: ${answers.value}');
    }

    return (context) => Scaffold(
      appBar: AppBar(title: Text('問卷調查')),
      body: ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: questions.value.length,
        itemBuilder: (context, index) {
          final question = questions.value[index];

          return Card(
            margin: EdgeInsets.only(bottom: 16),
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    question.text,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  SizedBox(height: 12),
                  _buildQuestionInput(question, answers, updateAnswer),
                ],
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: Padding(
        padding: EdgeInsets.all(16),
        child: ElevatedButton(
          onPressed: isComplete.value ? submit : null,
          child: Text('提交'),
        ),
      ),
    );
  }

  Widget _buildQuestionInput(
    Question question,
    Ref<Map<String, dynamic>> answers,
    void Function(String, dynamic) updateAnswer,
  ) {
    switch (question.type) {
      case QuestionType.radio:
        return Column(
          children: question.options!.map((option) {
            return RadioListTile<String>(
              title: Text(option),
              value: option,
              groupValue: answers.value[question.id],
              onChanged: (value) => updateAnswer(question.id, value),
            );
          }).toList(),
        );

      case QuestionType.checkbox:
        return Column(
          children: question.options!.map((option) {
            final selected = (answers.value[question.id] as List?)?.contains(option) ?? false;
            return CheckboxListTile(
              title: Text(option),
              value: selected,
              onChanged: (checked) {
                final current = List<String>.from(
                  (answers.value[question.id] as List?) ?? [],
                );
                if (checked!) {
                  current.add(option);
                } else {
                  current.remove(option);
                }
                updateAnswer(question.id, current);
              },
            );
          }).toList(),
        );

      case QuestionType.text:
        return TextField(
          decoration: InputDecoration(
            border: OutlineInputBorder(),
            hintText: '輸入您的答案...',
          ),
          maxLines: 3,
          onChanged: (value) => updateAnswer(question.id, value),
        );
    }
  }
}

class Question {
  const Question({
    required this.id,
    required this.text,
    required this.type,
    this.options,
  });

  final String id;
  final String text;
  final QuestionType type;
  final List<String>? options;
}

enum QuestionType { radio, checkbox, text }
```

## 自訂驗證

建立可重用的驗證 composables：

```dart
// 電子郵件驗證 composable
ValidationResult useEmailValidation(Ref<String> email) {
  final isValid = computed(() {
    if (email.value.isEmpty) return null;
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(email.value);
  });

  final errorText = computed(() {
    if (isValid.value == null) return null;
    return isValid.value! ? null : '請輸入有效的電子郵件地址';
  });

  return ValidationResult(
    isValid: isValid,
    errorText: errorText,
  );
}

// 密碼驗證 composable
ValidationResult usePasswordValidation(Ref<String> password) {
  final isValid = computed(() {
    if (password.value.isEmpty) return null;
    return password.value.length >= 8;
  });

  final strength = computed(() {
    if (password.value.isEmpty) return PasswordStrength.none;

    var score = 0;
    if (password.value.length >= 8) score++;
    if (password.value.contains(RegExp(r'[A-Z]'))) score++;
    if (password.value.contains(RegExp(r'[a-z]'))) score++;
    if (password.value.contains(RegExp(r'[0-9]'))) score++;
    if (password.value.contains(RegExp(r'[!@#$%^&*()]'))) score++;

    if (score <= 2) return PasswordStrength.weak;
    if (score <= 3) return PasswordStrength.medium;
    return PasswordStrength.strong;
  });

  final errorText = computed(() {
    if (isValid.value == null) return null;
    return isValid.value! ? null : '密碼必須至少 8 個字元';
  });

  return ValidationResult(
    isValid: isValid,
    errorText: errorText,
    strength: strength,
  );
}

class ValidationResult {
  const ValidationResult({
    required this.isValid,
    required this.errorText,
    this.strength,
  });

  final ComputedRef<bool?> isValid;
  final ComputedRef<String?> errorText;
  final ComputedRef<PasswordStrength>? strength;
}

enum PasswordStrength { none, weak, medium, strong }
```

## 最佳實踐

### 1. 使用 useTextEditingController

```dart
// ✅ 良好 - 自動釋放
final (controller, text, _) = useTextEditingController();

// ❌ 不良 - 手動釋放
final controller = TextEditingController();
onUnmounted(() => controller.dispose());
```

### 2. 即時驗證而不是在提交時

```dart
// ✅ 良好 - 即時反饋
final isEmailValid = computed(() {
  final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
  return emailRegex.hasMatch(email.value);
});

// ❌ 不良 - 提交時才驗證
void submit() {
  if (!isEmailValid(email.value)) {
    // 為時已晚
  }
}
```

### 3. 防抖搜尋輸入

```dart
// ✅ 良好 - 防抖以減少 API 呼叫
final debouncedQuery = ref('');
Timer? debounceTimer;

watch(() => query.value, (newQuery, _) {
  debounceTimer?.cancel();
  debounceTimer = Timer(Duration(milliseconds: 500), () {
    debouncedQuery.value = newQuery;
  });
});
```

### 4. 顯示驗證反饋

```dart
// ✅ 良好 - 視覺反饋
TextField(
  decoration: InputDecoration(
    errorText: errorText.value,
    suffixIcon: isValid.value == true
        ? Icon(Icons.check_circle, color: Colors.green)
        : null,
  ),
);
```

### 5. 處理載入狀態

```dart
// ✅ 良好 - 提交期間停用
ElevatedButton(
  onPressed: isLoading.value ? null : submit,
  child: isLoading.value
      ? CircularProgressIndicator()
      : Text('提交'),
);
```

## 下一步

- 探索[非同步操作](./async-operations.md)以處理表單提交
- 學習[狀態管理](./state-management.md)以管理表單狀態
- 閱讀 [useTextEditingController API](./built-in-composables.md#usetexteditingcontroller) 以了解完整 API 參考
