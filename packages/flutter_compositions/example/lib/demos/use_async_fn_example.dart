import 'package:flutter/material.dart';
import 'package:flutter_compositions/flutter_compositions.dart';

/// Example demonstrating useAsyncData for async operations.
///
/// This composable is useful when you want to control when an async operation
/// executes, such as in response to a button press.
class UseAsyncDataExample extends CompositionWidget {
  const UseAsyncDataExample({super.key});

  @override
  Widget Function(BuildContext) setup() {
    // Simulate an API call
    Future<String> fetchUserData() async {
      await Future<void>.delayed(const Duration(seconds: 2));
      return 'John Doe';
    }

    // Create an async function with manual execution control
    final (status, refresh) = useAsyncData<String, void>(
      (_) => fetchUserData(),
    );
    final (data, error, loading, hasData) = useAsyncValue(status);

    return (context) => Scaffold(
      appBar: AppBar(title: const Text('useAsyncData Example')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (loading.value)
              const CircularProgressIndicator()
            else if (data.value != null)
              Text(
                'User: ${data.value}',
                style: Theme.of(context).textTheme.headlineMedium,
              )
            else
              Text(
                'No data loaded yet',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: loading.value ? null : refresh,
              child: Text(loading.value ? 'Loading...' : 'Load User Data'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Example with automatic execution on mount
class UseAsyncDataAutoExecuteExample extends CompositionWidget {
  const UseAsyncDataAutoExecuteExample({super.key});

  @override
  Widget Function(BuildContext) setup() {
    Future<List<String>> fetchItems() async {
      await Future<void>.delayed(const Duration(seconds: 1));
      return ['Item 1', 'Item 2', 'Item 3'];
    }

    final (status, refresh) = useAsyncData<List<String>, void>(
      (_) => fetchItems(),
    );
    final (data, error, loading, hasData) = useAsyncValue(status);

    return (context) => Scaffold(
      appBar: AppBar(title: const Text('Auto Execute Example')),
      body: Column(
        children: [
          if (loading.value)
            const LinearProgressIndicator()
          else
            const SizedBox(height: 4),
          Expanded(
            child: data.value != null
                ? ListView.builder(
                    itemCount: data.value!.length,
                    itemBuilder: (context, index) {
                      return ListTile(title: Text(data.value![index]));
                    },
                  )
                : const Center(child: Text('No items')),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: loading.value ? null : refresh,
        child: const Icon(Icons.refresh),
      ),
    );
  }
}

/// Example with reactive watch parameter
class UseAsyncDataWithWatchExample extends CompositionWidget {
  const UseAsyncDataWithWatchExample({super.key});

  @override
  Widget Function(BuildContext) setup() {
    final searchQuery = ref('');

    Future<List<String>> searchUsers(String query) async {
      await Future<void>.delayed(const Duration(milliseconds: 500));
      return ['User 1 - $query', 'User 2 - $query', 'User 3 - $query'];
    }

    final (status, refresh) = useAsyncData<List<String>, String>(
      (query) => searchUsers(query),
      watch: () => searchQuery.value, // Auto-executes when query changes
    );
    final (data, error, loading, hasData) = useAsyncValue(status);

    return (context) => Scaffold(
      appBar: AppBar(title: const Text('Search Example')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              onChanged: (value) {
                searchQuery.value = value;
              },
              decoration: InputDecoration(
                hintText: 'Search users...',
                suffixIcon: IconButton(
                  onPressed: loading.value ? null : refresh,
                  icon: loading.value
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.search),
                ),
              ),
            ),
          ),
          Expanded(
            child: data.value != null
                ? ListView.builder(
                    itemCount: data.value!.length,
                    itemBuilder: (context, index) {
                      return ListTile(title: Text(data.value![index]));
                    },
                  )
                : const Center(child: Text('Enter a search query')),
          ),
        ],
      ),
    );
  }
}
