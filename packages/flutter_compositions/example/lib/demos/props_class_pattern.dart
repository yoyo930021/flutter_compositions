/// Demonstrates advanced patterns when using dedicated prop classes.
import 'package:flutter/material.dart';
import 'package:flutter_compositions/flutter_compositions.dart';

class PropsClassPatternsPage extends StatelessWidget {
  const PropsClassPatternsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Props Class Patterns')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const UserCard(
            props: UserCardProps(
              userId: '001',
              name: 'Alice',
              avatarUrl: 'https://example.com/avatar.jpg',
            ),
          ),
          const SizedBox(height: 16),
          const UserProfileCard(
            userInfo: UserInfoProps(userId: '002', name: 'Bob'),
          ),
          const SizedBox(height: 16),
          const UserBadge(
            userInfo: UserInfoProps(userId: '003', name: 'Charlie'),
          ),
          const SizedBox(height: 16),
          const ExtendedUserCard(
            props: ExtendedUserProps(
              id: '004',
              name: 'Dana',
              email: 'dana@example.com',
            ),
          ),
          const SizedBox(height: 16),
          DataWidget(state: Loading()),
          const SizedBox(height: 16),
          DataWidget(state: Success('Loaded data')),
          const SizedBox(height: 16),
          DataWidget(state: Error('Network error')),
          const SizedBox(height: 16),
          ValidatedForm(
            props: ValidatedFormProps(
              email: 'user@example.com',
              password: 'password123',
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// Pattern 1: simple props container
// ============================================================
class UserCardProps {
  const UserCardProps({
    required this.userId,
    required this.name,
    this.avatarUrl,
  });

  final String userId;
  final String name;
  final String? avatarUrl;
}

class UserCard extends CompositionWidget {
  const UserCard({super.key, required this.props});

  final UserCardProps props;

  @override
  Widget Function(BuildContext) setup() {
    final widgetProps = widget();
    final props = computed(() => widgetProps.value.props);

    final userId = computed(() => props.value.userId);
    final name = computed(() => props.value.name);
    final avatarUrl = computed(() => props.value.avatarUrl);

    final displayText = computed(() {
      final badge = avatarUrl.value != null ? '🖼️' : '👤';
      return '$badge ${name.value} (${userId.value})';
    });

    return (context) => Card(
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Text(displayText.value),
          ),
        );
  }
}

// ============================================================
// Pattern 2: reusable prop classes
// ============================================================
class UserInfoProps {
  const UserInfoProps({required this.userId, required this.name});

  final String userId;
  final String name;
}

class UserProfileCard extends CompositionWidget {
  const UserProfileCard({super.key, required this.userInfo});

  final UserInfoProps userInfo;

  @override
  Widget Function(BuildContext) setup() {
    final props = widget();
    final info = computed(() => props.value.userInfo);
    final name = computed(() => info.value.name);

    return (context) => Text('Profile: ${name.value}');
  }
}

class UserBadge extends CompositionWidget {
  const UserBadge({super.key, required this.userInfo});

  final UserInfoProps userInfo;

  @override
  Widget Function(BuildContext) setup() {
    final props = widget();
    final info = computed(() => props.value.userInfo);
    final userId = computed(() => info.value.userId);

    return (context) => Chip(label: Text('ID: ${userId.value}'));
  }
}

// ============================================================
// Pattern 3: inheritance-friendly props (still prefer composition)
// ============================================================
class BaseEntityProps {
  const BaseEntityProps({required this.id});
  final String id;
}

class ExtendedUserProps extends BaseEntityProps {
  const ExtendedUserProps({
    required super.id,
    required this.name,
    required this.email,
  });

  final String name;
  final String email;
}

class ExtendedUserCard extends CompositionWidget {
  const ExtendedUserCard({super.key, required this.props});

  final ExtendedUserProps props;

  @override
  Widget Function(BuildContext) setup() {
    final widgetProps = widget();
    final props = computed(() => widgetProps.value.props);

    final id = computed(() => props.value.id);
    final name = computed(() => props.value.name);
    final email = computed(() => props.value.email);

    final displayText = computed(
      () => '${name.value} (${id.value})\n${email.value}',
    );

    return (context) => Text(displayText.value);
  }
}

// ============================================================
// Pattern 4: sealed classes as props (Dart 3+)
// ============================================================
sealed class LoadingState {}

class Loading extends LoadingState {
  Loading();
}

class Success extends LoadingState {
  Success(this.data);
  final String data;
}

class Error extends LoadingState {
  Error(this.message);
  final String message;
}

class DataWidget extends CompositionWidget {
  const DataWidget({super.key, required this.state});

  final LoadingState state;

  @override
  Widget Function(BuildContext) setup() {
    final props = widget();
    final state = computed(() => props.value.state);

    final displayWidget = computed(() {
      return switch (state.value) {
        Loading() => const CircularProgressIndicator(),
        Success(data: final data) => Text('Success: $data'),
        Error(message: final msg) => Text(
            'Error: $msg',
            style: const TextStyle(color: Colors.red),
          ),
      };
    });

    return (context) => Center(child: displayWidget.value);
  }
}

// ============================================================
// Pattern 5: validation inside props
// ============================================================
class ValidatedFormProps {
  ValidatedFormProps({required String email, required String password})
      : _email = email,
        _password = password {
    if (!_email.contains('@')) {
      throw ArgumentError('Invalid email format');
    }
    if (_password.length < 6) {
      throw ArgumentError('Password must be at least 6 characters');
    }
  }

  final String _email;
  final String _password;

  String get email => _email;
  String get password => _password;
}

class ValidatedForm extends CompositionWidget {
  const ValidatedForm({super.key, required this.props});

  final ValidatedFormProps props;

  @override
  Widget Function(BuildContext) setup() {
    final widgetProps = widget();
    final props = computed(() => widgetProps.value.props);
    final email = computed(() => props.value.email);

    return (context) => Text('Email: ${email.value}');
  }
}
