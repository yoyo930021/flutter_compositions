# Async Operations

Flutter apps regularly talk to the network, disk, and other asynchronous sources. This guide shows how to keep those flows reactive when you build with Flutter Compositions.

## Goals

- Keep loading/error/data state co-located with the widget that needs it.
- Share asynchronous state with descendants without prop drilling.
- Make retries and refresh flows explicit.

> Need the full deep-dive in Traditional Chinese? See the original version in `/guide/async-operations.md`.

## Choosing the Right Composable

| Use case | Recommended tool | Notes |
|----------|-----------------|-------|
| One-off future with simple UI | `useFuture` | Returns a `Ref<AsyncValue<T>>` that you can `switch` on. |
| Future that depends on other reactive values | `useAsyncData` | Automatically re-runs when the `watch` input changes. |
| Stream subscriptions | `useStream` | Keeps the latest event in a `Ref<T?>`. |
| Exposing loading/error/data separately | `useAsyncValue` | Splits an `AsyncValue<T>` into individual refs. |
| Imperative refresh button | `useAsyncData` | The returned `refresh()` callback can be exposed to the UI. |

## Example: Loading a Profile

```dart
class ProfilePage extends CompositionWidget {
  const ProfilePage({super.key, required this.userId});

  final String userId;

  @override
  Widget Function(BuildContext) setup() {
    final props = widget<ProfilePage>();

    final (status, refresh) = useAsyncData<User, String>(
      (id) => api.fetchUser(id),
      watch: () => props.value.userId,
    );

    return (context) => switch (status.value) {
          AsyncLoading() => const Center(child: CircularProgressIndicator()),
          AsyncError(:final errorValue) => ErrorView(
              message: '$errorValue',
              onRetry: refresh,
            ),
          AsyncData(:final value) => ProfileView(user: value),
          AsyncIdle() => const SizedBox.shrink(),
        };
  }
}
```

Key points:

- `useAsyncData` recalculates when `props.value.userId` changes.
- The `refresh` callback can be wired to pull-to-refresh or a retry button.
- Returning early for `AsyncIdle` covers the first frame before the request starts.

## Example: Streaming Updates

```dart
class NotificationsPanel extends CompositionWidget {
  @override
  Widget Function(BuildContext) setup() {
    final notifications = useStream<NotificationEvent>(
      notificationBus.events,
      initialData: null,
    );

    final recent = computed(() {
      final event = notifications.value;
      if (event == null) return <NotificationEvent>[];
      return [...previousEvents.value, event]
          .take(10)
          .toList(growable: false);
    });

    return (context) => NotificationList(events: recent.value);
  }
}
```

- `useStream` disposes the subscription automatically.
- Combine the latest emission with other refs (`previousEvents` here) to build derived state.

## Sharing Async State with Descendants

```dart
const todosKey = InjectionKey<ReadonlyRef<AsyncValue<List<Todo>>>>('todos');

class TodosProvider extends CompositionWidget {
  @override
  Widget Function(BuildContext) setup() {
    final (todos, refresh) = useAsyncData<List<Todo>, void>(
      (_) => api.fetchTodos(),
    );

    provide(todosKey, todos);

    return (context) => Column(
          children: [
            ElevatedButton(onPressed: refresh, child: const Text('Refresh')),
            const TodosList(),
          ],
        );
  }
}

class TodosList extends CompositionWidget {
  const TodosList({super.key});

  @override
  Widget Function(BuildContext) setup() {
    final todos = inject(todosKey);

    return (context) => switch (todos.value) {
          AsyncLoading() => const CircularProgressIndicator(),
          AsyncError(:final errorValue) => Text('Error: $errorValue'),
          AsyncData(:final value) => ListView(
              children: [for (final todo in value) TodoTile(todo: todo)],
            ),
          _ => const SizedBox.shrink(),
        };
  }
}
```

- Provide the entire `Ref<AsyncValue<T>>` to descendants to keep reactivity.
- Consumers stay lightweight—they just switch on the async state.

## Handling Parallel Requests

When you need to run multiple futures simultaneously, use `Future.wait` inside `useAsyncData`:

```dart
final (status, _) = useAsyncData<_DashboardPayload, void>(
  (_) async {
    final [user, stats, notifications] = await Future.wait([
      api.fetchUser(),
      api.fetchStats(),
      api.fetchNotifications(),
    ]);
    return _DashboardPayload(user, stats, notifications);
  },
);
```

Wrap heavy requests with caching (e.g., keep the last result in a `Ref` and early-return) to avoid unnecessary network calls during rebuilds.

## Testing Tips

- Pass in fake services through `InjectionKey`s so that composables stay deterministic.
- Pump frames with `tester.pump()` until the async request completes.
- For `useStream`, emit test events through a `StreamController` that you control inside the test.

## Next Steps

- Learn how dependency injection keeps async code modular in [Dependency Injection](./dependency-injection.md).
- Explore a larger end-to-end example in [Best Practices](./best-practices.md).
