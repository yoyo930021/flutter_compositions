import 'package:flutter/widgets.dart';
import 'package:flutter_compositions/flutter_compositions.dart';
import 'package:flutter_test/flutter_test.dart';

final _testKey1 = InjectionKey<Ref<String>>('test1');
final _testKey2 = InjectionKey<Ref<int>>('test2');

class _ParentWidget extends CompositionWidget {
  const _ParentWidget();

  @override
  Widget Function(BuildContext) setup() {
    final value = ref('from-widget');
    provide(_testKey1, value);

    return (context) => CompositionBuilder(
      setup: () {
        final injected = inject(_testKey1);
        return (context) => Text(injected.value);
      },
    );
  }
}

class _ChildWidget extends CompositionWidget {
  const _ChildWidget();

  @override
  Widget Function(BuildContext) setup() {
    final injected = inject(_testKey2);
    return (context) => Text('${injected.value}');
  }
}

void main() {
  group('CompositionBuilder Provide/Inject', () {
    testWidgets('CompositionBuilder can provide and inject values', (
      tester,
    ) async {
      final testKey = InjectionKey<Ref<String>>('test');

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: CompositionBuilder(
            setup: () {
              final value = ref('provided');
              provide(testKey, value);

              return (context) => CompositionBuilder(
                setup: () {
                  final injected = inject(testKey);
                  return (context) => Text(injected.value);
                },
              );
            },
          ),
        ),
      );

      expect(find.text('provided'), findsOneWidget);
    });

    testWidgets(
      'CompositionBuilder child can inject from CompositionWidget parent',
      (tester) async {
        await tester.pumpWidget(
          const Directionality(
            textDirection: TextDirection.ltr,
            child: _ParentWidget(),
          ),
        );

        expect(find.text('from-widget'), findsOneWidget);
      },
    );

    testWidgets(
      'CompositionWidget child can inject from CompositionBuilder parent',
      (tester) async {
        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: CompositionBuilder(
              setup: () {
                final value = ref(42);
                provide(_testKey2, value);

                return (context) => const _ChildWidget();
              },
            ),
          ),
        );

        expect(find.text('42'), findsOneWidget);
      },
    );

    testWidgets(
      'nested CompositionBuilders can inject from multiple ancestors',
      (tester) async {
        final key1 = InjectionKey<Ref<String>>('key1');
        final key2 = InjectionKey<Ref<String>>('key2');

        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: CompositionBuilder(
              setup: () {
                final value1 = ref('level1');
                provide(key1, value1);

                return (context) => CompositionBuilder(
                  setup: () {
                    final value2 = ref('level2');
                    provide(key2, value2);

                    return (context) => CompositionBuilder(
                      setup: () {
                        final injected1 = inject(key1);
                        final injected2 = inject(key2);
                        return (context) =>
                            Text('${injected1.value}-${injected2.value}');
                      },
                    );
                  },
                );
              },
            ),
          ),
        );

        expect(find.text('level1-level2'), findsOneWidget);
      },
    );

    testWidgets('CompositionBuilder child can override parent provided value', (
      tester,
    ) async {
      final testKey = InjectionKey<Ref<String>>('test');

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: CompositionBuilder(
            setup: () {
              final value = ref('parent');
              provide(testKey, value);

              return (context) => Column(
                children: [
                  CompositionBuilder(
                    setup: () {
                      final injected = inject(testKey);
                      return (context) => Text('child1: ${injected.value}');
                    },
                  ),
                  CompositionBuilder(
                    setup: () {
                      final overridden = ref('child');
                      provide(testKey, overridden);

                      return (context) => CompositionBuilder(
                        setup: () {
                          final injected = inject(testKey);
                          return (context) => Text('child2: ${injected.value}');
                        },
                      );
                    },
                  ),
                ],
              );
            },
          ),
        ),
      );

      expect(find.text('child1: parent'), findsOneWidget);
      expect(find.text('child2: child'), findsOneWidget);
    });

    testWidgets('inject with default value returns default when not found', (
      tester,
    ) async {
      final testKey = InjectionKey<String>('test');

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: CompositionBuilder(
            setup: () {
              final value = inject(testKey, defaultValue: 'default');
              return (context) => Text(value);
            },
          ),
        ),
      );

      expect(find.text('default'), findsOneWidget);
    });

    testWidgets('CompositionBuilder provide/inject works with multiple keys', (
      tester,
    ) async {
      final key1 = InjectionKey<Ref<String>>('key1');
      final key2 = InjectionKey<Ref<String>>('key2');

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: CompositionBuilder(
            setup: () {
              final value1 = ref('first');
              final value2 = ref('second');
              provide(key1, value1);
              provide(key2, value2);

              return (context) => CompositionBuilder(
                setup: () {
                  final injected1 = inject(key1);
                  final injected2 = inject(key2);
                  return (context) =>
                      Text('${injected1.value}-${injected2.value}');
                },
              );
            },
          ),
        ),
      );

      expect(find.text('first-second'), findsOneWidget);
    });
  });
}
