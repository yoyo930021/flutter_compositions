import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_compositions/flutter_compositions.dart';

/// Demonstrates animation composables:
/// - useAnimationController
/// - manageAnimation
/// - useSingleTickerProvider
/// - Reactive animation value tracking
class AnimationsExamplePage extends CompositionWidget {
  const AnimationsExamplePage({super.key});

  @override
  Widget Function(BuildContext) setup() {
    return (context) => Scaffold(
          appBar: AppBar(
            title: const Text('Animation Composables'),
            backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          ),
          body: const SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _SectionHeader(
                  title: 'Basic Animation',
                  subtitle: 'useAnimationController with reactive tracking',
                ),
                SizedBox(height: 16),
                BasicAnimationDemo(),
                SizedBox(height: 32),
                _SectionHeader(
                  title: 'Curved Animation',
                  subtitle: 'manageAnimation with CurvedAnimation',
                ),
                SizedBox(height: 16),
                CurvedAnimationDemo(),
                SizedBox(height: 32),
                _SectionHeader(
                  title: 'Tween Animation',
                  subtitle: 'Color and Offset tweens',
                ),
                SizedBox(height: 16),
                TweenAnimationDemo(),
                SizedBox(height: 32),
                _SectionHeader(
                  title: 'Staggered Animation',
                  subtitle: 'Multiple animations with delays',
                ),
                SizedBox(height: 16),
                StaggeredAnimationDemo(),
                SizedBox(height: 32),
                _SectionHeader(
                  title: 'Interactive Animation',
                  subtitle: 'User-controlled animation with reactive state',
                ),
                SizedBox(height: 16),
                InteractiveAnimationDemo(),
                SizedBox(height: 32),
                _SectionHeader(
                  title: 'Physics-Based Animation',
                  subtitle: 'Spring animation with AnimationController',
                ),
                SizedBox(height: 16),
                SpringAnimationDemo(),
              ],
            ),
          ),
        );
  }
}

/// Section header widget
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
        ),
      ],
    );
  }
}

/// Basic rotating animation using useAnimationController
class BasicAnimationDemo extends CompositionWidget {
  const BasicAnimationDemo({super.key});

  @override
  Widget Function(BuildContext) setup() {
    // useAnimationController automatically creates vsync and manages disposal
    final (controller, animValue) = useAnimationController(
      duration: const Duration(seconds: 2),
    );

    // Computed values based on animation
    final rotation = computed(() => animValue.value * 2 * math.pi);
    final opacity = computed(() => animValue.value);

    // Start animation on mount
    onMounted(() {
      controller.repeat();
    });

    return (context) => Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Transform.rotate(
                  angle: rotation.value,
                  child: Opacity(
                    opacity: opacity.value,
                    child: const Icon(
                      Icons.refresh,
                      size: 64,
                      color: Colors.blue,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Value: ${animValue.value.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: () => controller.forward(),
                      child: const Text('Forward'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () => controller.reverse(),
                      child: const Text('Reverse'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () => controller.reset(),
                      child: const Text('Reset'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
  }
}

/// Animation with curves using manageAnimation
class CurvedAnimationDemo extends CompositionWidget {
  const CurvedAnimationDemo({super.key});

  @override
  Widget Function(BuildContext) setup() {
    final (controller, _) = useAnimationController(
      duration: const Duration(milliseconds: 800),
    );

    // Create curved animation and manage it
    final (curvedAnimation, curvedValue) = manageAnimation(
      CurvedAnimation(
        parent: controller,
        curve: Curves.elasticOut,
        reverseCurve: Curves.easeIn,
      ),
    );

    // Compute scale from curved value
    final scale = computed(() => 0.5 + (curvedValue.value * 0.5));

    return (context) => Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Transform.scale(
                  scale: scale.value,
                  child: const Icon(
                    Icons.favorite,
                    size: 80,
                    color: Colors.red,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Scale: ${scale.value.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () async {
                    await controller.forward();
                    await controller.reverse();
                  },
                  child: const Text('Animate'),
                ),
              ],
            ),
          ),
        );
  }
}

/// Tween animations for colors and offsets
class TweenAnimationDemo extends CompositionWidget {
  const TweenAnimationDemo({super.key});

  @override
  Widget Function(BuildContext) setup() {
    final (controller, _) = useAnimationController(
      duration: const Duration(milliseconds: 600),
    );

    // Color tween animation
    final (colorAnimation, colorValue) = manageAnimation(
      ColorTween(
        begin: Colors.blue,
        end: Colors.purple,
      ).animate(controller),
    );

    // Offset tween for slide effect
    final (offsetAnimation, offsetValue) = manageAnimation(
      Tween<Offset>(
        begin: const Offset(-1, 0),
        end: Offset.zero,
      ).animate(
        CurvedAnimation(
          parent: controller,
          curve: Curves.easeOutCubic,
        ),
      ),
    );

    return (context) => Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                SlideTransition(
                  position: offsetAnimation,
                  child: Container(
                    width: 200,
                    height: 100,
                    decoration: BoxDecoration(
                      color: colorValue.value ?? Colors.blue,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: Text(
                        'Slide & Color',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: () => controller.forward(),
                      child: const Text('Show'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () => controller.reverse(),
                      child: const Text('Hide'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
  }
}

/// Staggered animation with multiple elements
class StaggeredAnimationDemo extends CompositionWidget {
  const StaggeredAnimationDemo({super.key});

  @override
  Widget Function(BuildContext) setup() {
    final (controller, _) = useAnimationController(
      duration: const Duration(milliseconds: 1200),
    );

    // Create staggered animations for 3 items
    final animations = [
      (0.0, 0.3),
      (0.2, 0.5),
      (0.4, 0.7),
    ].map((interval) {
      final (anim, value) = manageAnimation(
        CurvedAnimation(
          parent: controller,
          curve: Interval(
            interval.$1,
            interval.$2,
            curve: Curves.easeOut,
          ),
        ),
      );
      return (anim, value);
    }).toList();

    return (context) => Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: animations.asMap().entries.map((entry) {
                    final index = entry.key;
                    final (_, value) = entry.value;
                    final scale = computed(() => value.value);
                    final opacity = computed(() => value.value);

                    return Transform.scale(
                      scale: scale.value,
                      child: Opacity(
                        opacity: opacity.value,
                        child: Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: [
                              Colors.red,
                              Colors.green,
                              Colors.blue
                            ][index],
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              '${index + 1}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () async {
                    controller.reset();
                    await controller.forward();
                  },
                  child: const Text('Animate Stagger'),
                ),
              ],
            ),
          ),
        );
  }
}

/// Interactive animation controlled by user input
class InteractiveAnimationDemo extends CompositionWidget {
  const InteractiveAnimationDemo({super.key});

  @override
  Widget Function(BuildContext) setup() {
    final (controller, animValue) = useAnimationController(
      duration: const Duration(milliseconds: 500),
    );

    final isExpanded = ref(false);

    // Watch isExpanded and animate accordingly
    watch(() => isExpanded.value, (expanded, _) {
      if (expanded) {
        controller.forward();
      } else {
        controller.reverse();
      }
    });

    // Compute values based on animation
    final height = computed(() => 100 + (animValue.value * 100));
    final borderRadius = computed(() => 12 - (animValue.value * 8));

    return (context) => Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                GestureDetector(
                  onTap: () {
                    isExpanded.value = !isExpanded.value;
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeInOut,
                    width: double.infinity,
                    height: height.value,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.purple,
                          Colors.purple.withValues(alpha: 0.7),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(borderRadius.value),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            isExpanded.value
                                ? Icons.expand_less
                                : Icons.expand_more,
                            color: Colors.white,
                            size: 32,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            isExpanded.value
                                ? 'Tap to collapse'
                                : 'Tap to expand',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Height: ${height.value.toStringAsFixed(0)}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        );
  }
}

/// Spring (physics-based) animation
class SpringAnimationDemo extends CompositionWidget {
  const SpringAnimationDemo({super.key});

  @override
  Widget Function(BuildContext) setup() {
    final (controller, animValue) = useAnimationController(
      duration: const Duration(milliseconds: 1000),
    );

    final position = ref(Offset.zero);

    // Compute animated position
    final animatedX = computed(() => position.value.dx * animValue.value);
    final animatedY = computed(() => position.value.dy * animValue.value);

    return (context) => Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                GestureDetector(
                  onTapDown: (details) {
                    final box = context.findRenderObject() as RenderBox;
                    final localPosition =
                        box.globalToLocal(details.globalPosition);
                    position.value = Offset(
                      localPosition.dx - 150,
                      localPosition.dy - 150,
                    );
                    controller.reset();
                    controller.fling(velocity: 2.0);
                  },
                  child: Container(
                    width: 300,
                    height: 300,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Stack(
                      children: [
                        Positioned(
                          left: 150 + animatedX.value,
                          top: 150 + animatedY.value,
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: const BoxDecoration(
                              color: Colors.orange,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Tap anywhere to animate',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Progress: ${animValue.value.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        );
  }
}
