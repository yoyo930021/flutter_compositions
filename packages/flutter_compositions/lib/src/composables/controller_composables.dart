import 'package:flutter/widgets.dart';
import 'package:flutter_compositions/src/composables/listenable_composables.dart';
import 'package:flutter_compositions/src/framework.dart';

/// Creates a [ScrollController] with automatic lifecycle management and
/// reactive tracking.
///
/// Same parameters as Flutter's ScrollController constructor.
///
/// Returns a `ReadonlyRef<ScrollController>` that tracks scroll changes.
/// The controller is automatically disposed when the component unmounts.
///
/// Example:
/// ```dart
/// @override
/// Widget Function(BuildContext) setup() {
///   final scrollController = useScrollController();
///
///   // React to scroll position
///   final scrollOffset = computed(() {
///     scrollController.value; // Track changes
///     return scrollController.value.offset;
///   });
///
///   return (context) => ListView(
///     controller: scrollController.raw, // Use .raw to avoid unnecessary rebuilds
///     children: [...],
///   );
/// }
/// ```
ReadonlyRef<ScrollController> useScrollController({
  double initialScrollOffset = 0.0,
  bool keepScrollOffset = true,
  String? debugLabel,
}) {
  return useController(
    () => ScrollController(
      initialScrollOffset: initialScrollOffset,
      keepScrollOffset: keepScrollOffset,
      debugLabel: debugLabel,
    ),
  );
}

/// Creates a [PageController] with automatic lifecycle management and
/// reactive tracking.
///
/// Same parameters as Flutter's PageController constructor.
///
/// Returns a `ReadonlyRef<PageController>` that tracks page changes.
/// The controller is automatically disposed when the component unmounts.
///
/// Example:
/// ```dart
/// @override
/// Widget Function(BuildContext) setup() {
///   final pageController = usePageController();
///
///   final currentPage = computed(() {
///     pageController.value; // Track changes
///     return pageController.value.page?.round() ?? 0;
///   });
///
///   return (context) => PageView(
///     controller: pageController.raw, // Use .raw to avoid unnecessary rebuilds
///     children: [...],
///   );
/// }
/// ```
ReadonlyRef<PageController> usePageController({
  int initialPage = 0,
  bool keepPage = true,
  double viewportFraction = 1.0,
}) {
  return useController(
    () => PageController(
      initialPage: initialPage,
      keepPage: keepPage,
      viewportFraction: viewportFraction,
    ),
  );
}

/// Creates a [FocusNode] with automatic lifecycle management and reactive
/// tracking.
///
/// Same parameters as Flutter's FocusNode constructor.
///
/// Returns a `ReadonlyRef<FocusNode>` that tracks focus changes.
/// The focus node is automatically disposed when the component unmounts.
///
/// Example:
/// ```dart
/// @override
/// Widget Function(BuildContext) setup() {
///   final focusNode = useFocusNode(debugLabel: 'MyField');
///
///   final isFocused = computed(() {
///     focusNode.value; // Track changes
///     return focusNode.value.hasFocus;
///   });
///
///   return (context) => TextField(
///     focusNode: focusNode.raw, // Use .raw to avoid unnecessary rebuilds
///     decoration: InputDecoration(
///       border: OutlineInputBorder(
///         borderSide: BorderSide(
///           color: isFocused.value ? Colors.blue : Colors.grey,
///         ),
///       ),
///     ),
///   );
/// }
/// ```
ReadonlyRef<FocusNode> useFocusNode({
  String? debugLabel,
  FocusOnKeyEventCallback? onKeyEvent,
  bool skipTraversal = false,
  bool canRequestFocus = true,
  bool descendantsAreFocusable = true,
  bool descendantsAreTraversable = true,
}) {
  return useController(
    () => FocusNode(
      debugLabel: debugLabel,
      onKeyEvent: onKeyEvent,
      skipTraversal: skipTraversal,
      canRequestFocus: canRequestFocus,
      descendantsAreFocusable: descendantsAreFocusable,
      descendantsAreTraversable: descendantsAreTraversable,
    ),
  );
}

/// Creates a TextEditingController with automatic lifecycle management.
///
/// Same parameters as Flutter's TextEditingController constructor.
///
/// Returns a record of `(controller, text, value)` where:
/// - controller: `TextEditingController` - Direct controller instance
///   (NOT a ref)
/// - text: `WritableRef<String>` that syncs with controller.text (writable)
/// - value: `WritableRef<TextEditingValue>` that syncs with
///   `controller.value` (writable)
///
/// **Important API difference**: Unlike other `use*` functions that return
/// `ReadonlyRef<Controller>`, this returns the raw controller directly for
/// better ergonomics. The `text` and `value` refs are reactive, so you get
/// the best of both worlds - direct controller access for widgets, and
/// reactive refs for computed values.
///
/// All refs stay synced with the controller and react to updates.
/// The controller is automatically disposed when the component unmounts.
///
/// Example:
/// ```dart
/// @override
/// Widget Function(BuildContext) setup() {
///   final (controller, text, value) =
///       useTextEditingController(text: 'initial');
///
///   // Use reactive features on text
///   final charCount = computed(() => text.value.length);
///   final isEmpty = computed(() => text.value.isEmpty);
///
///   // Access advanced features via value
///   final selection = computed(() => value.value.selection);
///   final cursorPosition = computed(() => selection.value.baseOffset);
///
///   watch(() => text.value, (newValue, oldValue) {
///     print('Text changed: $oldValue -> $newValue');
///   });
///
///   return (context) => Column(
///     children: [
///       // Use controller directly (no .value needed)
///       TextField(controller: controller),
///       Text('Characters: ${charCount.value}'),
///       Text('Cursor at: ${cursorPosition.value}'),
///       if (isEmpty.value) Text('Please enter something'),
///     ],
///   );
/// }
/// ```
(TextEditingController, WritableRef<String>, WritableRef<TextEditingValue>)
useTextEditingController({String? text}) {
  // TextEditingController implements ValueListenable<TextEditingValue>,
  // but it's also a ChangeNotifier, so we need to manage it properly.
  final controller = hotReloadableContainer(
    () => TextEditingController(text: text),
  );

  // Use manageChangeNotifier to handle both listener and disposal
  final reactiveController = manageChangeNotifier(controller);

  // Extract the value reactively
  final editingValueRef = computed(() => reactiveController.value.value);

  // Create writable refs that sync with the controller
  final editingValue = writableComputed<TextEditingValue>(
    get: () => editingValueRef.value,
    set: (newValue) {
      controller.value = newValue;
    },
  );

  final textRef = writableComputed<String>(
    get: () => editingValueRef.value.text,
    set: (newText) {
      controller.text = newText;
    },
  );

  return (controller, textRef, editingValue);
}
