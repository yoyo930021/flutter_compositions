# Performance Considerations

## Provide/Inject Performance

### Current Implementation

The `provide/inject` mechanism uses a parent chain approach, similar to Vue's provide/inject:

```dart
// Each widget stores a reference to its parent context
_setupContext._parent = _findParentSetupContext(context);

// Lookup walks up the parent chain
dynamic getProvided(Object key) {
  if (_provided.containsKey(key)) return _provided[key];
  return _parent?.getProvided(key);  // Recursive lookup
}
```

### Performance Characteristics

#### Time Complexity
- **Lookup**: O(n) where n = number of ancestor CompositionWidgets
- **First lookup during setup()**: One-time cost
- **Subsequent access**: O(1) via cached reference

#### Space Complexity
- **Per widget**: One `_parent` reference + `_provided` Map for local values
- **Total overhead**: O(w) where w = total number of widgets with provided values

### Comparison with InheritedWidget

| Aspect | Current (Parent Chain) | InheritedWidget |
|--------|----------------------|-----------------|
| Lookup time | O(n) | O(1) |
| Memory per element | 1 reference | Full Map |
| Update propagation | Manual (via Ref) | Automatic rebuild |
| Rebuild overhead | None | All dependents rebuild |
| Setup cost | One-time in initState | Per build |

### When to Use Which?

#### Use `provide/inject` (Current) when:
✅ You want **fine-grained reactivity** via `Ref<T>`
✅ You want to **avoid unnecessary rebuilds**
✅ Ancestor chain depth is shallow (< 10 levels)
✅ You need **type-safe dependency injection**

#### Use InheritedWidget when:
✅ You need **O(1) lookup** for deeply nested trees
✅ You want **automatic rebuilds** when values change
✅ You're working with **Flutter's built-in widgets** (Theme, MediaQuery)

### Optimization Tips

1. **Keep provide/inject chains shallow**
   ```dart
   // Good: Direct parent-child
   ParentWidget -> ChildWidget

   // Acceptable: 2-3 levels
   GrandparentWidget -> ParentWidget -> ChildWidget

   // Consider alternatives for very deep trees
   ```

2. **Use Ref for reactive updates**
   ```dart
   // Efficient: Only reactive consumers update
   final theme = ref(AppTheme('dark'));
   provide(theme);

   // In child: Only rebuilds when theme.value changes
   final localTheme = inject<Ref<AppTheme>>();
   return (context) => Text(localTheme.value.mode);
   ```

3. **Benchmark your specific use case**
   ```dart
   import 'package:flutter_test/flutter_test.dart';

   void main() {
     testWidgets('benchmark provide/inject', (tester) async {
       final stopwatch = Stopwatch()..start();

       await tester.pumpWidget(/* your widget tree */);

       stopwatch.stop();
       print('Time: ${stopwatch.elapsedMicroseconds}μs');
     });
   }
   ```

## Future Optimizations

Potential improvements being considered:

1. **Cache lookup results** in `inject()` for repeated calls
2. **Hybrid approach**: Use InheritedWidget for common values, parent chain for custom types
3. **Lazy parent chain**: Only build chain when first `inject()` is called

## Benchmarks

_(TODO: Add benchmark results for common scenarios)_

- 10 nested widgets with 1 provide/inject: ~Xμs
- 100 nested widgets with 10 provide/inject: ~Xμs
- Comparison with equivalent InheritedWidget setup: ~Xμs
