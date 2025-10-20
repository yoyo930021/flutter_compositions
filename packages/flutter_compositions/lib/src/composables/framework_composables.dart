import 'package:flutter/material.dart';
import 'package:flutter_compositions/src/custom_ref.dart';
import 'package:flutter_compositions/src/framework.dart';

/// Creates a reactive reference to the BuildContext.
///
/// **Important**: The context is only available in the returned builder
/// function, not in setup(). This returns a [Ref] that will be populated
/// when the builder runs.
///
/// This is useful when you need to access InheritedWidgets or the context
/// in reactive computations.
///
/// Example:
/// ```dart
/// @override
/// Widget Function(BuildContext) setup() {
///   final context = useContext();
///
///   // ❌ This won't work - context is null in setup()
///   // final theme = Theme.of(context.value);
///
///   return (buildContext) {
///     // ✅ Set the context value
///     context.value = buildContext;
///
///     // Now you can use it
///     final theme = Theme.of(context.value);
///     return Text('Primary color: ${theme.primaryColor}');
///   };
/// }
/// ```
///
/// Better approach - access context directly in builder:
/// ```dart
/// @override
/// Widget Function(BuildContext) setup() {
///   return (context) {
///     // ✅ Direct access is simpler
///     final theme = Theme.of(context);
///     return Text('Primary color: ${theme.primaryColor}');
///   };
/// }
/// ```
Ref<BuildContext?> useContext() {
  return ref<BuildContext?>(null);
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
  final controller = SearchController();

  final reactiveController = ReadonlyCustomRef<SearchController>(
    getter: (track) {
      track();
      return controller;
    },
  );

  void listener() {
    reactiveController.trigger();
  }

  controller.addListener(listener);

  onUnmounted(() {
    controller
      ..removeListener(listener)
      ..dispose();
  });

  return reactiveController;
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
