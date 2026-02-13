import 'package:flutter/material.dart';
import 'package:flutter_compositions/src/composables/listenable_composables.dart';
import 'package:flutter_compositions/src/framework.dart';

/// Creates a reactive reference to the [BuildContext].
///
/// **Important**: The context is only available after the first build,
/// not during setup(). Use this when you need to access context in
/// lifecycle hooks or pass it to async operations.
///
/// **Prefer [useContextRef] for reactive InheritedWidget access.**
/// `useContextRef` provides fine-grained reactivity with equality checks,
/// so it only triggers updates when values actually change. Use `useContext`
/// only when you need the raw `BuildContext` for imperative operations
/// (e.g., `showDialog`, `Navigator.of`, `ScaffoldMessenger.of`).
///
/// Example - Perform side effect with context in onMounted:
/// ```dart
/// @override
/// Widget Function(BuildContext) setup() {
///   final context = useContext();
///
///   onMounted(() {
///     // ✅ Use context for imperative operations
///     showDialog(
///       context: context.value!,
///       builder: (context) => const AlertDialog(
///         content: Text('Widget mounted!'),
///       ),
///     );
///   });
///
///   return (buildContext) => const SizedBox();
/// }
/// ```
///
/// Example - Store context for async operations:
/// ```dart
/// @override
/// Widget Function(BuildContext) setup() {
///   final context = useContext();
///
///   void handleAsyncAction() async {
///     final result = await fetchData();
///
///     // ✅ Use stored context in async callback
///     if (context.value != null && context.value!.mounted) {
///       ScaffoldMessenger.of(context.value!).showSnackBar(
///         SnackBar(content: Text('Result: $result')),
///       );
///     }
///   }
///
///   return (buildContext) => ElevatedButton(
///     onPressed: handleAsyncAction,
///     child: const Text('Fetch Data'),
///   );
/// }
/// ```
///
/// **❌ Anti-pattern - Don't use for InheritedWidgets**:
/// ```dart
/// // ❌ WRONG: Accessing InheritedWidgets through useContext()
/// final context = useContext();
/// final theme = computed(() => Theme.of(context.value!));
///
/// // ✅ CORRECT: Use useContextRef for reactive InheritedWidget access
/// final theme = useContextRef(Theme.of);
/// ```
Ref<BuildContext?> useContext() {
  final contextRef = ref<BuildContext?>(null);

  var isFirstBuild = true;
  onBuild((context) {
    if (isFirstBuild) {
      contextRef.value = context;
      isFirstBuild = false;
    }
  });

  return contextRef;
}

/// Creates a SearchController with automatic lifecycle management and
/// reactive tracking.
///
/// The controller is automatically disposed when the component unmounts.
/// Returns a [ReadonlyRef] that tracks search text changes.
///
/// Example:
/// ```dart
/// @override
/// Widget Function(BuildContext) setup() {
///   final searchController = useSearchController();
///
///   // React to search text changes
///   final searchText = computed(() {
///     searchController.value; // Track changes
///     return searchController.value.text;
///   });
///
///   watch(
///     () => searchText.value,
///     (newValue, oldValue) {
///       print('Search text changed: $oldValue -> $newValue');
///       // Perform search
///     },
///   );
///
///   return (context) => SearchAnchor(
///     searchController: searchController.value,
///     builder: (context, controller) {
///       return SearchBar(
///         controller: controller,
///         hintText: 'Search...',
///       );
///     },
///     suggestionsBuilder: (context, controller) {
///       return [
///         ListTile(title: Text('Result for: ${searchText.value}')),
///       ];
///     },
///   );
/// }
/// ```
ReadonlyRef<SearchController> useSearchController() {
  return useController(SearchController.new);
}

/// Creates a reactive reference that tracks the app lifecycle state.
///
/// Returns a [Ref] that updates whenever the app lifecycle state changes
/// (resumed, inactive, paused, detached, hidden).
///
/// The lifecycle observer is automatically removed when the component unmounts.
///
/// Example:
/// ```dart
/// @override
/// Widget Function(BuildContext) setup() {
///   final lifecycleState = useAppLifecycleState();
///
///   // React to lifecycle changes
///   watch(
///     () => lifecycleState.value,
///     (newState, oldState) {
///       print('App lifecycle changed: $oldState -> $newState');
///
///       if (newState == AppLifecycleState.resumed) {
///         print('App resumed - refresh data');
///       } else if (newState == AppLifecycleState.paused) {
///         print('App paused - save state');
///       }
///     },
///   );
///
///   return (context) => Column(
///     children: [
///       Text('Current state: ${lifecycleState.value}'),
///       if (lifecycleState.value == AppLifecycleState.resumed)
///         const Text('App is active')
///       else
///         const Text('App is not active'),
///     ],
///   );
/// }
/// ```
///
/// Example - Pause video when app goes to background:
/// ```dart
/// @override
/// Widget Function(BuildContext) setup() {
///   final lifecycleState = useAppLifecycleState();
///   final videoController = useVideoController();
///
///   watch(
///     () => lifecycleState.value,
///     (newState, oldState) {
///       if (newState == AppLifecycleState.paused) {
///         videoController.value.pause();
///       } else if (newState == AppLifecycleState.resumed) {
///         videoController.value.play();
///       }
///     },
///   );
///
///   return (context) => VideoPlayer(videoController.value);
/// }
/// ```
Ref<AppLifecycleState> useAppLifecycleState() {
  final lifecycleState = ref<AppLifecycleState>(
    WidgetsBinding.instance.lifecycleState ?? AppLifecycleState.resumed,
  );

  final observer = _LifecycleObserver((state) {
    lifecycleState.value = state;
  });

  onMounted(() {
    WidgetsBinding.instance.addObserver(observer);
  });

  onUnmounted(() {
    WidgetsBinding.instance.removeObserver(observer);
  });

  return lifecycleState;
}

class _LifecycleObserver extends WidgetsBindingObserver {
  _LifecycleObserver(this.onStateChange);

  final void Function(AppLifecycleState) onStateChange;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    onStateChange(state);
  }
}
