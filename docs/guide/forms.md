# Forms

Forms are at the core of most applications. This guide will explore how to build reactive forms using Flutter Compositions, including input handling, validation, submission, and error handling.

## Why Use Reactive Forms?

Traditional Flutter form handling requires a lot of boilerplate code:

```dart
// ❌ Traditional approach - lots of boilerplate
class _LoginFormState extends State<LoginForm> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose(); // Don't forget!
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      // Submit
    }
  }
}

// ✅ Compositions approach - clean and reactive
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

## useTextEditingController - Basic Input

`useTextEditingController` creates a `TextEditingController` with reactive text and selection tracking.

### Simple Text Input

```dart
class SimpleForm extends CompositionWidget {
  @override
  Widget Function(BuildContext) setup() {
    final (controller, text, selection) = useTextEditingController();

    // Reactive computation
    final charCount = computed(() => text.value.length);
    final wordCount = computed(() {
      if (text.value.isEmpty) return 0;
      return text.value.split(' ').where((w) => w.isNotEmpty).length;
    });

    return (context) => Column(
      children: [
        TextField(
          controller: controller.raw, // .raw avoids unnecessary rebuilds
          decoration: InputDecoration(
            labelText: 'Enter text',
            hintText: 'Start typing...',
          ),
        ),
        SizedBox(height: 8),
        Text('Characters: ${charCount.value}'),
        Text('Words: ${wordCount.value}'),
      ],
    );
  }
}
```

### Programmatic Control

```dart
class ControlledInput extends CompositionWidget {
  @override
  Widget Function(BuildContext) setup() {
    final (controller, text, selection) = useTextEditingController(
      text: 'Initial value',
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
        TextField(controller: controller.raw), // .raw avoids unnecessary rebuilds
        Row(
          children: [
            ElevatedButton(
              onPressed: clearText,
              child: Text('Clear'),
            ),
            ElevatedButton(
              onPressed: insertTemplate,
              child: Text('Template'),
            ),
            ElevatedButton(
              onPressed: selectAll,
              child: Text('Select All'),
            ),
            ElevatedButton(
              onPressed: toUpperCase,
              child: Text('Uppercase'),
            ),
          ],
        ),
      ],
    );
  }
}
```

## Form Validation

### Real-time Validation

```dart
class EmailForm extends CompositionWidget {
  @override
  Widget Function(BuildContext) setup() {
    final (controller, email, _) = useTextEditingController();

    // Validation rules
    final isEmailValid = computed(() {
      if (email.value.isEmpty) return null;
      final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
      return emailRegex.hasMatch(email.value);
    });

    final errorText = computed(() {
      final valid = isEmailValid.value;
      if (valid == null) return null;
      return valid ? null : 'Please enter a valid email address';
    });

    return (context) => TextField(
      controller: controller.raw, // .raw avoids unnecessary rebuilds
      decoration: InputDecoration(
        labelText: 'Email',
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

### Multi-field Validation

```dart
class RegistrationForm extends CompositionWidget {
  @override
  Widget Function(BuildContext) setup() {
    final (emailController, email, _) = useTextEditingController();
    final (passwordController, password, _) = useTextEditingController();
    final (confirmPasswordController, confirmPassword, _) =
        useTextEditingController();

    // Individual field validation
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

    // Overall form validation
    final isFormValid = computed(() {
      return isEmailValid.value == true &&
          isPasswordValid.value == true &&
          doPasswordsMatch.value == true;
    });

    // Error messages
    final emailError = computed(() {
      if (isEmailValid.value == null) return null;
      return isEmailValid.value! ? null : 'Invalid email address';
    });

    final passwordError = computed(() {
      if (isPasswordValid.value == null) return null;
      return isPasswordValid.value! ? null : 'Password must be at least 8 characters';
    });

    final confirmPasswordError = computed(() {
      if (doPasswordsMatch.value == null) return null;
      return doPasswordsMatch.value! ? null : 'Passwords do not match';
    });

    return (context) => Column(
      children: [
        TextField(
          controller: emailController.raw, // .raw avoids unnecessary rebuilds
          decoration: InputDecoration(
            labelText: 'Email',
            errorText: emailError.value,
          ),
          keyboardType: TextInputType.emailAddress,
        ),
        SizedBox(height: 16),
        TextField(
          controller: passwordController.raw, // .raw avoids unnecessary rebuilds
          decoration: InputDecoration(
            labelText: 'Password',
            errorText: passwordError.value,
            helperText: isPasswordStrong.value
                ? 'Strong password'
                : 'Include uppercase, lowercase letters and numbers',
          ),
          obscureText: true,
        ),
        SizedBox(height: 16),
        TextField(
          controller: confirmPasswordController.raw, // .raw avoids unnecessary rebuilds
          decoration: InputDecoration(
            labelText: 'Confirm Password',
            errorText: confirmPasswordError.value,
          ),
          obscureText: true,
        ),
        SizedBox(height: 24),
        ElevatedButton(
          onPressed: isFormValid.value ? () => submitForm() : null,
          child: Text('Register'),
        ),
      ],
    );
  }

  void submitForm() {
    // Submit form
  }
}
```

## Practical Examples

### Login Form

```dart
class LoginForm extends CompositionWidget {
  @override
  Widget Function(BuildContext) setup() {
    final (emailController, email, _) = useTextEditingController();
    final (passwordController, password, _) = useTextEditingController();

    final isLoading = ref(false);
    final error = ref<String?>(null);

    // Validation
    final isEmailValid = computed(() {
      final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
      return emailRegex.hasMatch(email.value);
    });

    final isFormValid = computed(() {
      return isEmailValid.value && password.value.isNotEmpty;
    });

    // Submit
    Future<void> submit() async {
      if (!isFormValid.value) return;

      isLoading.value = true;
      error.value = null;

      try {
        await authService.login(
          email: email.value,
          password: password.value,
        );
        // Navigate to home
      } catch (e) {
        error.value = e.toString();
      } finally {
        isLoading.value = false;
      }
    }

    return (context) => Scaffold(
      appBar: AppBar(title: Text('Login')),
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
              controller: emailController.raw, // .raw avoids unnecessary rebuilds
              decoration: InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.email),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
              enabled: !isLoading.value,
            ),
            SizedBox(height: 16),
            TextField(
              controller: passwordController.raw, // .raw avoids unnecessary rebuilds
              decoration: InputDecoration(
                labelText: 'Password',
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
                    : Text('Login'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

### Profile Form

```dart
const authServiceKey = InjectionKey<AuthService>('authService');
// Parent needs to provide the instance with provide(authServiceKey, AuthService())

class ProfileForm extends CompositionWidget {
  @override
  Widget Function(BuildContext) setup() {
    final authService = inject(authServiceKey);

    // Form fields
    final (nameController, name, _) = useTextEditingController();
    final (bioController, bio, _) = useTextEditingController();
    final (websiteController, website, _) = useTextEditingController();
    final avatar = ref<File?>(null);

    // Loading states
    final isLoading = ref(false);
    final isSaving = ref(false);

    // Validation
    final isNameValid = computed(() => name.value.trim().isNotEmpty);

    final isWebsiteValid = computed(() {
      if (website.value.isEmpty) return true;
      final urlRegex = RegExp(
        r'^https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b',
      );
      return urlRegex.hasMatch(website.value);
    });

    final hasChanges = ref(false);

    // Load existing profile
    onMounted(() async {
      isLoading.value = true;
      try {
        final profile = await authService.getCurrentUserProfile();
        name.value = profile.name;
        bio.value = profile.bio ?? '';
        website.value = profile.website ?? '';
      } catch (e) {
        // Handle error
      } finally {
        isLoading.value = false;
      }
    });

    // Track changes
    watchEffect(() {
      hasChanges.value = name.value.isNotEmpty ||
          bio.value.isNotEmpty ||
          website.value.isNotEmpty ||
          avatar.value != null;
    });

    // Pick avatar
    Future<void> pickAvatar() async {
      final picker = ImagePicker();
      final image = await picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        avatar.value = File(image.path);
      }
    }

    // Save
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

        // Show success message
        onBuild(() {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Profile updated')),
          );
        });

        hasChanges.value = false;
      } catch (e) {
        // Show error
        onBuild(() {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to update profile'),
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
          appBar: AppBar(title: Text('Edit Profile')),
          body: Center(child: CircularProgressIndicator()),
        );
      }

      return Scaffold(
        appBar: AppBar(
          title: Text('Edit Profile'),
          actions: [
            if (hasChanges.value)
              TextButton(
                onPressed: isSaving.value ? null : save,
                child: isSaving.value
                    ? CircularProgressIndicator(color: Colors.white)
                    : Text('Save', style: TextStyle(color: Colors.white)),
              ),
          ],
        ),
        body: SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              // Avatar
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

              // Name
              TextField(
                controller: nameController.raw, // .raw avoids unnecessary rebuilds
                decoration: InputDecoration(
                  labelText: 'Name',
                  border: OutlineInputBorder(),
                  errorText: !isNameValid.value ? 'Name is required' : null,
                ),
              ),
              SizedBox(height: 16),

              // Bio
              TextField(
                controller: bioController.raw, // .raw avoids unnecessary rebuilds
                decoration: InputDecoration(
                  labelText: 'Bio',
                  border: OutlineInputBorder(),
                  hintText: 'Tell us about yourself...',
                ),
                maxLines: 4,
                maxLength: 200,
              ),
              SizedBox(height: 16),

              // Website
              TextField(
                controller: websiteController.raw, // .raw avoids unnecessary rebuilds
                decoration: InputDecoration(
                  labelText: 'Website',
                  border: OutlineInputBorder(),
                  errorText: !isWebsiteValid.value ? 'Invalid URL' : null,
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

### Search Form with Filters

```dart
class ProductSearchForm extends CompositionWidget {
  @override
  Widget Function(BuildContext) setup() {
    final (searchController, query, _) = useTextEditingController();
    final category = ref<String>('all');
    final minPrice = ref(0.0);
    final maxPrice = ref(1000.0);
    final sortBy = ref<SortOption>(SortOption.relevance);

    // Debounced search
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

    // Search results
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

    // Reset filters
    void resetFilters() {
      searchController.value.clear();
      category.value = 'all';
      minPrice.value = 0.0;
      maxPrice.value = 1000.0;
      sortBy.value = SortOption.relevance;
    }

    return (context) => Column(
      children: [
        // Search bar
        Padding(
          padding: EdgeInsets.all(16),
          child: TextField(
            controller: searchController.raw, // .raw avoids unnecessary rebuilds
            decoration: InputDecoration(
              hintText: 'Search products...',
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

        // Filters
        ExpansionTile(
          title: Text('Filters'),
          children: [
            // Category
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: DropdownButtonFormField<String>(
                value: category.value,
                decoration: InputDecoration(labelText: 'Category'),
                items: [
                  DropdownMenuItem(value: 'all', child: Text('All')),
                  DropdownMenuItem(value: 'electronics', child: Text('Electronics')),
                  DropdownMenuItem(value: 'clothing', child: Text('Clothing')),
                  DropdownMenuItem(value: 'books', child: Text('Books')),
                ],
                onChanged: (value) => category.value = value!,
              ),
            ),

            // Price range
            Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Price Range: \$${minPrice.value.toInt()} - \$${maxPrice.value.toInt()}'),
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

            // Sort
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: DropdownButtonFormField<SortOption>(
                value: sortBy.value,
                decoration: InputDecoration(labelText: 'Sort By'),
                items: [
                  DropdownMenuItem(value: SortOption.relevance, child: Text('Relevance')),
                  DropdownMenuItem(value: SortOption.priceLow, child: Text('Price: Low to High')),
                  DropdownMenuItem(value: SortOption.priceHigh, child: Text('Price: High to Low')),
                  DropdownMenuItem(value: SortOption.newest, child: Text('Newest')),
                ],
                onChanged: (value) => sortBy.value = value!,
              ),
            ),

            // Reset button
            Padding(
              padding: EdgeInsets.all(16),
              child: TextButton(
                onPressed: resetFilters,
                child: Text('Reset Filters'),
              ),
            ),
          ],
        ),

        // Results
        Expanded(
          child: switch (results.value) {
            AsyncLoading() => Center(child: CircularProgressIndicator()),
            AsyncError(:final errorValue) => Center(
              child: Text('Error: $errorValue'),
            ),
            AsyncData(:final value) => value.isEmpty
                ? Center(child: Text('No products found'))
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

### Dynamic Forms

```dart
class DynamicSurveyForm extends CompositionWidget {
  @override
  Widget Function(BuildContext) setup() {
    final questions = ref<List<Question>>([
      Question(
        id: '1',
        text: 'What is your age range?',
        type: QuestionType.radio,
        options: ['18-25', '26-35', '36-45', '46+'],
      ),
      Question(
        id: '2',
        text: 'What topics interest you?',
        type: QuestionType.checkbox,
        options: ['Technology', 'Sports', 'Arts', 'Music'],
      ),
      Question(
        id: '3',
        text: 'Additional comments',
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
      // Submit survey
      print('Submitting answers: ${answers.value}');
    }

    return (context) => Scaffold(
      appBar: AppBar(title: Text('Survey')),
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
          child: Text('Submit'),
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
            hintText: 'Enter your answer...',
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

## Custom Validation

Create reusable validation composables:

```dart
// Email validation composable
ValidationResult useEmailValidation(Ref<String> email) {
  final isValid = computed(() {
    if (email.value.isEmpty) return null;
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(email.value);
  });

  final errorText = computed(() {
    if (isValid.value == null) return null;
    return isValid.value! ? null : 'Please enter a valid email address';
  });

  return ValidationResult(
    isValid: isValid,
    errorText: errorText,
  );
}

// Password validation composable
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
    return isValid.value! ? null : 'Password must be at least 8 characters';
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

## Best Practices

### 1. Use useTextEditingController

```dart
// ✅ Good - automatic disposal
final (controller, text, _) = useTextEditingController();

// ❌ Bad - manual disposal required
final controller = TextEditingController();
onUnmounted(() => controller.dispose());
```

### 2. Real-time Validation Instead of On-Submit

```dart
// ✅ Good - instant feedback
final isEmailValid = computed(() {
  final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
  return emailRegex.hasMatch(email.value);
});

// ❌ Bad - only validate on submit
void submit() {
  if (!isEmailValid(email.value)) {
    // Too late
  }
}
```

### 3. Debounce Search Input

```dart
// ✅ Good - debounce to reduce API calls
final debouncedQuery = ref('');
Timer? debounceTimer;

watch(() => query.value, (newQuery, _) {
  debounceTimer?.cancel();
  debounceTimer = Timer(Duration(milliseconds: 500), () {
    debouncedQuery.value = newQuery;
  });
});
```

### 4. Show Validation Feedback

```dart
// ✅ Good - visual feedback
TextField(
  decoration: InputDecoration(
    errorText: errorText.value,
    suffixIcon: isValid.value == true
        ? Icon(Icons.check_circle, color: Colors.green)
        : null,
  ),
);
```

### 5. Handle Loading States

```dart
// ✅ Good - disable during submission
ElevatedButton(
  onPressed: isLoading.value ? null : submit,
  child: isLoading.value
      ? CircularProgressIndicator()
      : Text('Submit'),
);
```

## Next Steps

- Explore [Async Operations](./async-operations.md) for handling form submission
- Learn [State Management](./state-management.md) for managing form state
- Read the [useTextEditingController API](./built-in-composables.md#usetexteditingcontroller) for full API reference
