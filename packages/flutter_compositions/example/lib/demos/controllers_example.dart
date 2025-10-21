/// Example demonstrating integration with Flutter controllers
import 'package:flutter/material.dart';
import 'package:flutter_compositions/flutter_compositions.dart';

class ControllersExamplePage extends StatelessWidget {
  const ControllersExamplePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const ControllersDemo();
  }
}

class ControllersDemo extends CompositionWidget {
  const ControllersDemo({super.key});

  @override
  Widget Function(BuildContext) setup() {
    // Example 1: Basic TextEditingController
    final (basicController, _, __) = useTextEditingController();

    // Example 2: TextEditingController with reactive binding
    final (searchController, searchText, ___) = useTextEditingController();

    // Example 3: Multiple controllers with reactive state
    final (usernameControllerRef, usernameText, ____) =
        useTextEditingController();
    final (passwordControllerRef, passwordText, _____) =
        useTextEditingController();

    // Computed validation
    final isValid = computed(() {
      return usernameText.value.length >= 3 && passwordText.value.length >= 6;
    });

    final statusMessage = computed(() {
      if (usernameText.value.isEmpty) {
        return 'Please enter username';
      }
      if (usernameText.value.length < 3) {
        return 'Username must be at least 3 characters';
      }
      if (passwordText.value.isEmpty) {
        return 'Please enter password';
      }
      if (passwordText.value.length < 6) {
        return 'Password must be at least 6 characters';
      }
      return 'All fields valid!';
    });

    // Example 4: ScrollController with reactive position
    final scrollControllerRef = useScrollController();
    final scrollOffset = ref(0.0);

    scrollControllerRef.value.addListener(() {
      scrollOffset.value = scrollControllerRef.value.offset;
    });

    // Example 5: PageController
    final pageControllerRef = usePageController();
    final currentPage = ref(0);

    pageControllerRef.value.addListener(() {
      currentPage.value = pageControllerRef.value.page?.round() ?? 0;
    });

    // Example 6: FocusNode
    final usernameFocusRef = useFocusNode();
    final passwordFocusRef = useFocusNode();
    final searchFocusRef = useFocusNode();

    final focusedField = ref('none');

    usernameFocusRef.value.addListener(() {
      if (usernameFocusRef.value.hasFocus) focusedField.value = 'username';
    });

    passwordFocusRef.value.addListener(() {
      if (passwordFocusRef.value.hasFocus) focusedField.value = 'password';
    });

    searchFocusRef.value.addListener(() {
      if (searchFocusRef.value.hasFocus) focusedField.value = 'search';
    });

    // Watch for changes
    watch(() => searchText.value, (newValue, oldValue) {
      debugPrint('Search changed: "$oldValue" -> "$newValue"');
    });

    return (context) => Scaffold(
          appBar: AppBar(
            backgroundColor: Theme.of(context).colorScheme.inversePrimary,
            title: const Text('Controllers Integration'),
          ),
          body: PageView(
            controller: pageControllerRef.value,
            children: [
              // Page 1: Form Example
              _buildFormPage(
                context,
                searchController,
                searchText,
                searchFocusRef.value,
                usernameControllerRef,
                usernameText,
                usernameFocusRef.value,
                passwordControllerRef,
                passwordText,
                passwordFocusRef.value,
                isValid,
                statusMessage,
                focusedField,
              ),

              // Page 2: Scroll Example
              _buildScrollPage(
                  context, scrollControllerRef.value, scrollOffset),

              // Page 3: Basic Example
              _buildBasicPage(context, basicController),
            ],
          ),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: currentPage.value,
            onTap: (index) {
              pageControllerRef.value.animateToPage(
                index,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            },
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.edit), label: 'Form'),
              BottomNavigationBarItem(icon: Icon(Icons.list), label: 'Scroll'),
              BottomNavigationBarItem(
                icon: Icon(Icons.text_fields),
                label: 'Basic',
              ),
            ],
          ),
        );
  }

  Widget _buildFormPage(
    BuildContext context,
    TextEditingController searchController,
    WritableRef<String> searchText,
    FocusNode searchFocus,
    TextEditingController usernameController,
    WritableRef<String> usernameText,
    FocusNode usernameFocus,
    TextEditingController passwordController,
    WritableRef<String> passwordText,
    FocusNode passwordFocus,
    ReadonlyRef<bool> isValid,
    ReadonlyRef<String> statusMessage,
    Ref<String> focusedField,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Form with Reactive Validation',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),

          // Search field
          TextField(
            controller: searchController,
            focusNode: searchFocus,
            decoration: const InputDecoration(
              labelText: 'Search',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.search),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Search text: "${searchText.value}"',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 20),

          // Username field
          TextField(
            controller: usernameController,
            focusNode: usernameFocus,
            decoration: InputDecoration(
              labelText: 'Username',
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.person),
              errorText:
                  usernameText.value.isNotEmpty && usernameText.value.length < 3
                      ? 'Too short'
                      : null,
            ),
          ),
          const SizedBox(height: 16),

          // Password field
          TextField(
            controller: passwordController,
            focusNode: passwordFocus,
            obscureText: true,
            decoration: InputDecoration(
              labelText: 'Password',
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.lock),
              errorText:
                  passwordText.value.isNotEmpty && passwordText.value.length < 6
                      ? 'Too short'
                      : null,
            ),
          ),
          const SizedBox(height: 20),

          // Status message
          Card(
            color:
                isValid.value ? Colors.green.shade100 : Colors.orange.shade100,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    statusMessage.value,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isValid.value
                          ? Colors.green.shade900
                          : Colors.orange.shade900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Currently focused: ${focusedField.value}',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          ElevatedButton(
            onPressed: isValid.value
                ? () {
                    debugPrint('Login: ${usernameText.value}');
                  }
                : null,
            child: const Text('Login'),
          ),
        ],
      ),
    );
  }

  Widget _buildScrollPage(
    BuildContext context,
    ScrollController scrollController,
    Ref<double> scrollOffset,
  ) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: Theme.of(context).colorScheme.primaryContainer,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Scroll Position:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                scrollOffset.value.toStringAsFixed(1),
                style: const TextStyle(fontFamily: 'monospace'),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            controller: scrollController,
            itemCount: 100,
            itemBuilder: (context, index) {
              return ListTile(
                leading: CircleAvatar(child: Text('${index + 1}')),
                title: Text('Item ${index + 1}'),
                subtitle: Text(
                  'Scroll offset: ${scrollOffset.value.toStringAsFixed(1)}',
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBasicPage(
    BuildContext context,
    TextEditingController basicController,
  ) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Basic Controller (No Reactive Binding)',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: basicController,
            decoration: const InputDecoration(
              labelText: 'Type something',
              border: OutlineInputBorder(),
            ),
            maxLines: 5,
          ),
          const SizedBox(height: 20),
          const Text(
            'This controller has no reactive binding.\n'
            'Changes won\'t trigger computed properties automatically.',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
