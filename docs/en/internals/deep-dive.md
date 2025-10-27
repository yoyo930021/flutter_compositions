# Deep Dive into Flutter Compositions

This article consolidates the core architecture, reactive system principles, design trade-offs, and performance considerations of Flutter Compositions to help you deeply understand how the framework works.

## Architecture Overview

Flutter Compositions builds an extremely thin runtime layer on top of native `StatefulWidget`, providing a development experience similar to Vue Composition API.

### Lifecycle Flow

1. **Initialization Phase** (`initState`)
   - Create `_SetupContext`
   - Call `setup()` once
   - Register lifecycle hooks, create reactive state
   - Obtain the builder function responsible for rendering UI

2. **Reactive Execution**
   - Builder is wrapped in an `effect` from `alien_signals`
   - Automatically re-executes when dependent `Ref` or `Computed` changes

3. **Props Updates**
   - When parent passes new props, internal `_widgetSignal` emits new widget instance
   - Props accessed via `widget()` remain reactive

4. **Cleanup Phase** (`dispose`)
   - Automatically cleanup effects, controllers, and hooks registered in `setup()`
   - Prevents resource leaks

### Reactive Data Flow

```
Parent passes props
    ↓
_widgetSignal updates (WritableSignal)
    ↓
Related computed and watchers re-execute
    ↓
Builder re-executes inside effect
    ↓
Produces new Widget tree
    ↓
Flutter Element diff (only repaints changed parts)
```

## Reactive System Principles

The core driving force of Flutter Compositions is the `alien_signals` package. Understanding its principles helps you fully grasp how the framework operates.

### Three Pillars of the Signal System

1. **Signal (Ref)**: Reactive data source
   - Created by `ref()`
   - Establishes dependency tracking when reading `.value`
   - Triggers updates when writing `.value`

2. **Computed**: Derived data
   - Created by `computed()`
   - Automatically tracks dependencies used during calculation
   - Uses lazy evaluation

3. **Effect**: Terminal of the reactive system
   - Created implicitly by `watchEffect()`, `watch()`, or builder
   - Automatically tracks dependencies used during execution
   - Re-executes automatically when dependencies change

### Automatic Dependency Tracking

When you read `ref.value` inside a `computed` or `effect` function:

1. Before execution, set the global "current listener"
2. When accessing `ref.value`, `ref` checks the current listener
3. If it exists, add the listener to the subscribers list
4. After function execution completes, clear the current listener

This is why you don't need to manually declare dependencies.

### Update Flow

When modifying `ref.value`:

1. `ref`'s setter is called
2. Iterate through subscribers list, notify all dependents
3. `computed` is marked as "stale", will recalculate on next read
4. `effect` is queued, executes in batches in microtask

### Integration with Flutter

`CompositionWidget` wraps the builder function in an effect:

```dart
_renderEffect = effect(() {
  // Execute builder function
  final newWidget = builder(context);

  // Call setState when produced Widget differs
  if (_cachedWidget != newWidget) {
    setState(() {
      _cachedWidget = newWidget;
    });
  }
});
```

This achieves:
- Only re-executes when reactive data used inside builder changes
- Calls `setState` to trigger Flutter update when re-executing
- Flutter's Element diff ensures only changed parts are updated

## Core Design Trade-offs

### `setup()` Executes Only Once

**Advantages**:
- Avoids repeated initialization
- Clear lifecycle
- Better performance

**Challenges**:
- Requires `widget()` API to react to props changes
- Slightly higher learning curve

**Solution**:
- `_widgetSignal` updates in `didUpdateWidget`
- `widget()` returns subscription to signal
- Trades for complete reactive capability and clear data flow

### `provide/inject` vs `InheritedWidget`

| Feature | provide/inject | InheritedWidget |
|---------|---------------|-----------------|
| Lookup Time | O(n) | O(1) |
| Update Mechanism | Manual (via Ref) | Auto-triggers rebuild |
| Rebuild Scope | None, only dependent builder updates | All dependent descendants |
| Setup Cost | One-time in initState | Every build |

**Why Choose O(n) Lookup?**

1. **Avoid Unnecessary Rebuilds**
   - `InheritedWidget` changes rebuild all dependents
   - `provide/inject` passes `Ref`, only builders that read it update

2. **Performance Sufficient in Shallow Trees**
   - Most applications have component tree depth < 10 layers
   - O(n) lookup overhead is negligible

**Usage Recommendations**:
- Reactive state: Use `provide/inject`
- Global configuration (like Theme): Can still use `InheritedWidget`

### Dependency on `alien_signals`

**Advantages**:
- One of the fastest reactive libraries in Dart ecosystem
- Focus on high-level API design
- Lightweight and focused

**Disadvantages**:
- Performance and behavior constrained by it

**Conclusion**:
Strategic choice. Leveraging a focused lower-level library is wiser than building from scratch.

## Performance Considerations

### provide/inject Performance Characteristics

**Time Complexity**:
- Lookup: O(n), where n = number of ancestor CompositionWidgets
- First lookup requires walking the parent chain
- Reads/writes after obtaining Ref are O(1)

**Space Complexity**:
- Each SetupContext stores `_parent` reference and `_provided` Map
- Total consumption O(w), where w = number of widgets registering provide

### Performance Comparison

| Metric | provide/inject | InheritedWidget |
|--------|---------------|-----------------|
| Lookup Time | O(n) | O(1) |
| Memory | Parent reference + Map | Entire InheritedElement |
| Update Behavior | Manual control via Ref | Change triggers all dependent rebuilds |
| Rebuild Overhead | None (reactive control) | All dependent widgets rebuild |
| Setup Cost | One-time in initState | Every build |

### Optimization Recommendations

1. **Keep provide/inject chain shallow**
   ```dart
   // ✅ Reasonable: parent-child connected
   Parent -> Child

   // ✅ Acceptable: 2-3 layers
   Grandparent -> Parent -> Child
   ```

2. **Pass reactive state via Ref**
   ```dart
   // Only places using theme.value update
   final theme = ref(AppTheme('dark'));
   provide(themeKey, theme);

   final localTheme = inject(themeKey);
   return Text(localTheme.value.mode);
   ```

3. **Benchmark for your specific project context**
   ```dart
   testWidgets('benchmark provide/inject', (tester) async {
     final stopwatch = Stopwatch()..start();
     await tester.pumpWidget(/* your widget tree */);
     stopwatch.stop();
     print('Time: ${stopwatch.elapsedMicroseconds}μs');
   });
   ```

### When to Use Which?

**Suitable for provide/inject**:
- ✅ Need fine-grained reactive updates via Ref
- ✅ Want to avoid unnecessary widget rebuilds
- ✅ Component tree depth is shallow (< 10 layers)
- ✅ Need type-safe dependency injection

**Suitable for InheritedWidget**:
- ✅ Lookup cost must be O(1), tree depth is very deep
- ✅ Want value changes to automatically rebuild entire subtree
- ✅ Using Flutter's built-in global resources like Theme, MediaQuery

## Error Prevention Mechanisms

1. **Assertion Checks**
   - Ensure lifecycle-related tools can only be called inside `setup()`

2. **inject Error Handling**
   - Immediately throws error when dependency not found (non-nullable type)
   - Avoids silent failures

3. **Automatic Cleanup**
   - All effects registered via `watch`, `use*` are bound to `_SetupContext`
   - Automatically cleaned up in `dispose`

## Summary

Flutter Compositions achieves high-performance reactive UI through the following design:

1. **Fine-grained Reactivity**: Only updates truly changed parts
2. **Clear Lifecycle**: `setup()` executes only once
3. **Automatic Dependency Tracking**: No need to manually declare dependencies
4. **Type-safe DI**: InjectionKey prevents injection errors
5. **Automatic Resource Management**: Prevents memory leaks

Understanding these principles helps you better use the framework and make correct architectural decisions at the right time.
