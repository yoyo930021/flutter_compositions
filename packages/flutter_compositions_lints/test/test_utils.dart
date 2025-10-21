import 'dart:io';

/// Gets the absolute path to a fixture file.
///
/// This works regardless of where the test is run from (root, package dir, etc.)
String getFixturePath(String fileName) {
  // Start from the test file's directory and go up to find the package root
  var dir = Directory.current;

  // Try to find the fixtures directory
  while (true) {
    final fixturesDir = Directory('${dir.path}/test/fixtures');
    if (fixturesDir.existsSync()) {
      final fixturePath = '${fixturesDir.path}/$fileName';
      if (File(fixturePath).existsSync()) {
        return fixturePath;
      }
    }

    // Also check in packages/flutter_compositions_lints/test/fixtures
    final lintsFixturesDir = Directory(
      '${dir.path}/packages/flutter_compositions_lints/test/fixtures',
    );
    if (lintsFixturesDir.existsSync()) {
      final fixturePath = '${lintsFixturesDir.path}/$fileName';
      if (File(fixturePath).existsSync()) {
        return fixturePath;
      }
    }

    // Go up one directory
    final parent = dir.parent;
    if (parent.path == dir.path) {
      throw Exception('Could not find fixture file: $fileName');
    }
    dir = parent;
  }
}
