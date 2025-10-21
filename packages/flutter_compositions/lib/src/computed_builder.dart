import 'dart:async';

import 'package:alien_signals/alien_signals.dart' as signals;
import 'package:flutter/widgets.dart';

/// A widget that creates a fine-grained reactive scope for its child.
///
/// Unlike the standard CompositionWidget builder which rebuilds the entire
/// widget tree when any reactive dependency changes, [ComputedBuilder]
/// creates an isolated reactive scope that only rebuilds itself.
///
/// This is useful for optimizing performance by preventing unnecessary
/// rebuilds of large widget subtrees when only a small part needs to update.
///
/// ## Basic Example
///
/// ```dart
/// class Counter extends CompositionWidget {
///   @override
///   Widget Function(BuildContext) setup() {
///     final count1 = ref(0);
///     final count2 = ref(0);
///
///     return (context) => Column(
///       children: [
///         // Only this text rebuilds when count1 changes
///         ComputedBuilder(
///           builder: () => Text('Count1: ${count1.value}'),
///         ),
///
///         // Only this text rebuilds when count2 changes
///         ComputedBuilder(
///           builder: () => Text('Count2: ${count2.value}'),
///         ),
///
///         // Static widgets never rebuild
///         const Text('This is static'),
///
///         ElevatedButton(
///           onPressed: () => count1.value++,
///           child: const Text('Increment Count1'),
///         ),
///       ],
///     );
///   }
/// }
/// ```
///
/// ## Performance Benefits
///
/// Without ComputedBuilder:
/// ```dart
/// return (context) => Column(
///   children: [
///     Text('Count: ${count.value}'),
///     const ExpensiveStaticWidget(),  // Rebuilds unnecessarily!
///   ],
/// );
/// ```
///
/// With ComputedBuilder:
/// ```dart
/// return (context) => Column(
///   children: [
///     ComputedBuilder(
///       builder: () => Text('Count: ${count.value}'),
///     ),
///     const ExpensiveStaticWidget(),  // Never rebuilds!
///   ],
/// );
/// ```
///
/// ## Use Cases
///
/// ### 1. High-frequency updates
/// ```dart
/// final progress = ref(0.0);
///
/// // Updates 60 times per second
/// Timer.periodic(Duration(milliseconds: 16), (_) {
///   progress.value = (progress.value + 0.01) % 1.0;
/// });
///
/// return Column(
///   children: [
///     // Only this rebuilds 60fps
///     ComputedBuilder(
///       builder: () => LinearProgressIndicator(value: progress.value),
///     ),
///     // Static content never rebuilds
///     const Text('Loading...'),
///   ],
/// );
/// ```
///
/// ### 2. List items with independent state
/// ```dart
/// return ListView.builder(
///   itemCount: items.length,
///   itemBuilder: (context, index) {
///     final item = items[index];
///     return ListTile(
///       title: ComputedBuilder(
///         builder: () => Text('${item.name}: ${item.count.value}'),
///       ),
///       trailing: IconButton(
///         onPressed: () => item.count.value++,
///         child: const Icon(Icons.add),
///       ),
///     );
///   },
/// );
/// ```
///
/// ### 3. Complex computed values
/// ```dart
/// final items = ref<List<Item>>([...]);
/// final filter = ref('');
///
/// final filteredItems = computed(() {
///   final query = filter.value.toLowerCase();
///   return items.value.where((item) =>
///     item.name.toLowerCase().contains(query)
///   ).toList();
/// });
///
/// return Column(
///   children: [
///     TextField(
///       onChanged: (value) => filter.value = value,
///     ),
///     // Only this rebuilds when filter or items change
///     ComputedBuilder(
///       builder: () => Text('Found: ${filteredItems.value.length} items'),
///     ),
///     // Expensive widget tree never rebuilds
///     const ExpensiveFilterPanel(),
///   ],
/// );
/// ```
///
/// ## How It Works
///
/// [ComputedBuilder] creates its own reactive effect that only tracks
/// the signals used within its [builder] function. When those signals
/// change, only the [ComputedBuilder] widget rebuilds, not its parent
/// or siblings.
///
/// This is similar to Vue's fine-grained reactivity or Solid.js's
/// reactive primitives, where each reactive scope can update independently.
class ComputedBuilder extends StatefulWidget {
  /// Creates a [ComputedBuilder].
  ///
  /// The [builder] callback is called within a reactive effect and should
  /// return a widget. When any reactive dependencies accessed in [builder]
  /// change, only this widget rebuilds.
  const ComputedBuilder({
    required this.builder,
    super.key,
  });

  /// The builder function that creates the widget.
  ///
  /// This function runs inside a reactive effect, so any signals (ref,
  /// computed, etc.) accessed within will be tracked as dependencies.
  ///
  /// When any tracked dependency changes, only this builder re-runs and
  /// only this widget rebuilds.
  final Widget Function() builder;

  @override
  State<ComputedBuilder> createState() => _ComputedBuilderState();
}

class _ComputedBuilderState extends State<ComputedBuilder> {
  signals.Effect? _effect;
  Widget? _cachedWidget;
  bool _pendingRebuild = false;
  bool _isInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!_isInitialized) {
      _isInitialized = true;

      _effect = signals.effect(() {
        final newWidget = widget.builder();

        // First build: set cache directly without setState
        if (_cachedWidget == null) {
          _cachedWidget = newWidget;
          return;
        }

        // Subsequent updates: use batched setState
        _cachedWidget = newWidget;

        if (!_pendingRebuild) {
          _pendingRebuild = true;

          // Use scheduleMicrotask for batching
          scheduleMicrotask(() {
            if (mounted && _pendingRebuild) {
              _pendingRebuild = false;
              setState(() {
                // Widget is already updated in _cachedWidget
              });
            }
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return _cachedWidget ?? const SizedBox.shrink();
  }

  @override
  void dispose() {
    _pendingRebuild = false;
    _effect?.dispose();
    super.dispose();
  }
}
