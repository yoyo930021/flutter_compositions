/// Example demonstrating the improved useTextEditingController API
import 'package:flutter/material.dart';
import 'package:flutter_compositions/flutter_compositions.dart';

class UseTextFieldExamplePage extends StatelessWidget {
  const UseTextFieldExamplePage({super.key});

  @override
  Widget build(BuildContext context) => const UseTextFieldDemo();
}

class UseTextFieldDemo extends CompositionWidget {
  const UseTextFieldDemo({super.key});

  @override
  Widget Function(BuildContext) setup() {
    // ✅ API: useTextEditingController returns (controller, text, value)
    final (usernameController, username, _) = useTextEditingController(
      text: '',
    );
    final (passwordController, password, __) = useTextEditingController(
      text: '',
    );
    final (emailController, email, ___) = useTextEditingController(text: '');

    // ✨ Use reactive features on the text refs
    final usernameLength = computed(() => username.value.length);
    final passwordLength = computed(() => password.value.length);

    final isUsernameValid = computed(() => usernameLength.value >= 3);
    final isPasswordValid = computed(() => passwordLength.value >= 8);
    final isEmailValid = computed(() => email.value.contains('@'));

    final isFormValid = computed(() {
      return isUsernameValid.value &&
          isPasswordValid.value &&
          isEmailValid.value;
    });

    final statusMessage = computed(() {
      if (!isUsernameValid.value && username.value.isNotEmpty) {
        return 'Username must be at least 3 characters';
      }
      if (!isPasswordValid.value && password.value.isNotEmpty) {
        return 'Password must be at least 8 characters';
      }
      if (!isEmailValid.value && email.value.isNotEmpty) {
        return 'Email must contain @';
      }
      if (isFormValid.value) {
        return '✅ All fields are valid!';
      }
      return 'Please fill in all fields';
    });

    // 🔍 Watch for changes
    watch(() => username.value, (newValue, oldValue) {
      debugPrint('Username: "$oldValue" → "$newValue"');
    });

    void handleSubmit() {
      if (isFormValid.value) {
        debugPrint('Form submitted:');
        debugPrint('  Username: ${username.value}');
        debugPrint('  Email: ${email.value}');
        debugPrint('  Password length: ${passwordLength.value}');
      }
    }

    return (context) => Scaffold(
          appBar: AppBar(
            backgroundColor: Theme.of(context).colorScheme.inversePrimary,
            title: const Text('useTextEditingController Demo'),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Text(
                  'Registration Form',
                  style: Theme.of(context).textTheme.headlineMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Demonstrating useTextEditingController with reactive validation',
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                // Username field
                TextField(
                  controller: usernameController,
                  decoration: InputDecoration(
                    labelText: 'Username',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.person),
                    helperText: '${usernameLength.value} characters',
                    errorText:
                        username.value.isNotEmpty && !isUsernameValid.value
                            ? 'Too short (min 3)'
                            : null,
                    suffixIcon: isUsernameValid.value
                        ? const Icon(Icons.check_circle, color: Colors.green)
                        : null,
                  ),
                ),
                const SizedBox(height: 16),

                // Email field
                TextField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.email),
                    errorText: email.value.isNotEmpty && !isEmailValid.value
                        ? 'Invalid email format'
                        : null,
                    suffixIcon: isEmailValid.value
                        ? const Icon(Icons.check_circle, color: Colors.green)
                        : null,
                  ),
                ),
                const SizedBox(height: 16),

                // Password field
                TextField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.lock),
                    helperText: '${passwordLength.value}/8 characters',
                    errorText:
                        password.value.isNotEmpty && !isPasswordValid.value
                            ? 'Too short (min 8)'
                            : null,
                    suffixIcon: isPasswordValid.value
                        ? const Icon(Icons.check_circle, color: Colors.green)
                        : null,
                  ),
                ),
                const SizedBox(height: 24),

                // Status message
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isFormValid.value
                        ? Colors.green.shade50
                        : Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isFormValid.value ? Colors.green : Colors.orange,
                      width: 2,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isFormValid.value ? Icons.check_circle : Icons.info,
                        color: isFormValid.value ? Colors.green : Colors.orange,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          statusMessage.value,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isFormValid.value
                                ? Colors.green.shade900
                                : Colors.orange.shade900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Submit button
                FilledButton.icon(
                  onPressed: isFormValid.value ? handleSubmit : null,
                  icon: const Icon(Icons.send),
                  label: const Text('Submit'),
                  style:
                      FilledButton.styleFrom(padding: const EdgeInsets.all(16)),
                ),
                const SizedBox(height: 32),

                // Info card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '💡 Benefits of useTextEditingController',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                            '✅ Returns both controller and reactive ref'),
                        const Text('✅ Automatic bidirectional sync'),
                        const Text('✅ Use computed for validation logic'),
                        const Text('✅ Use watch for side effects'),
                        const Text('✅ Automatic lifecycle management'),
                        const SizedBox(height: 12),
                        const Divider(),
                        const SizedBox(height: 12),
                        const Text(
                          'Code comparison:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '// Old way:',
                                style: TextStyle(
                                  fontFamily: 'monospace',
                                  color: Colors.grey,
                                ),
                              ),
                              Text(
                                'final text = ref(\'\');',
                                style: TextStyle(fontFamily: 'monospace'),
                              ),
                              Text(
                                'final controller = useTextEditingController(text);',
                                style: TextStyle(fontFamily: 'monospace'),
                              ),
                              SizedBox(height: 8),
                              Text(
                                '// New way:',
                                style: TextStyle(
                                  fontFamily: 'monospace',
                                  color: Colors.green,
                                ),
                              ),
                              Text(
                                'final (ctrl, text, _) = useTextEditingController();',
                                style: TextStyle(
                                  fontFamily: 'monospace',
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Debug info
                Card(
                  color: Colors.blue.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '🔍 Live State',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text('Username length: ${usernameLength.value}'),
                        Text('Password length: ${passwordLength.value}'),
                        Text('Email valid: ${isEmailValid.value}'),
                        Text('Form valid: ${isFormValid.value}'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
  }
}
