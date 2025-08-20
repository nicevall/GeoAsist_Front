// flutter_test_config.dart
// Global test configuration file that runs before all tests

import 'dart:async';
import 'package:flutter_test/flutter_test.dart';

import 'test/utils/test_config.dart';

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  // Setup global test environment
  await TestConfig.setupCompleteTestEnvironment();
  
  // Setup golden file comparator for consistent golden tests
  if (goldenFileComparator is LocalFileComparator) {
    final testUrl = (goldenFileComparator as LocalFileComparator).basedir;
    goldenFileComparator = LocalFileComparator(
      testUrl.resolve('test/golden_files/'),
    );
  }
  
  // Note: Global timeout cannot be set on testWidgets function
  // Individual tests should use timeout parameter if needed
  
  try {
    // Run the actual tests
    await testMain();
  } finally {
    // Cleanup after all tests
    TestConfig.cleanup();
  }
}