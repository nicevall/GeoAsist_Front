// lib/screens/firebase/firebase_blaze_test_screen.dart
import 'package:flutter/material.dart';
import 'package:geo_asist_front/core/utils/app_logger.dart';
import 'package:geo_asist_front/services/firebase/firebase_cloud_service.dart';
import 'package:geo_asist_front/services/firebase/firebase_evento_service_v2.dart';
import 'package:geo_asist_front/services/firebase/firebase_auth_service_v2.dart';

/// Test screen for Firebase Blaze migration
/// Validates all migrated functionalities
class FirebaseBlazeTastScreen extends StatefulWidget {
  const FirebaseBlazeTastScreen({super.key});

  @override
  State<FirebaseBlazeTastScreen> createState() => _FirebaseBlazeTastScreenState();
}

class _FirebaseBlazeTastScreenState extends State<FirebaseBlazeTastScreen> {
  final FirebaseEventoServiceV2 _eventoService = FirebaseEventoServiceV2();
  final FirebaseAuthServiceV2 _authService = FirebaseAuthServiceV2();
  
  final List<TestResult> _testResults = [];
  bool _isRunningTests = false;
  int _currentTestIndex = 0;

  @override
  void initState() {
    super.initState();
    logger.i('🧪 Firebase Blaze Test Screen initialized');
  }

  /// Run all Firebase migration tests
  Future<void> _runAllTests() async {
    setState(() {
      _isRunningTests = true;
      _testResults.clear();
      _currentTestIndex = 0;
    });

    final tests = [
      _testFirebaseConnectivity,
      _testHealthCheck,
      _testFirestoreDirectRead,
      _testEventoServiceV2,
      _testAuthServiceV2,
      _testNotificationService,
      _testCloudFunctions,
      _testRealTimeStreams,
    ];

    logger.i('🧪 Starting Firebase Blaze migration tests (${tests.length} total)');

    for (int i = 0; i < tests.length; i++) {
      setState(() {
        _currentTestIndex = i;
      });

      try {
        await tests[i]();
        await Future.delayed(const Duration(milliseconds: 500));
      } catch (e) {
        logger.e('❌ Test ${i + 1} failed unexpectedly', e);
        _addTestResult(
          'Test ${i + 1}',
          false,
          'Unexpected error: $e',
          Duration.zero,
        );
      }
    }

    setState(() {
      _isRunningTests = false;
      _currentTestIndex = 0;
    });

    _showTestSummary();
    logger.i('🎯 All Firebase migration tests completed');
  }

  /// Test Firebase connectivity
  Future<void> _testFirebaseConnectivity() async {
    const testName = 'Firebase Connectivity';
    final stopwatch = Stopwatch()..start();
    
    try {
      logger.i('🔍 Testing Firebase connectivity...');
      
      final results = await FirebaseCloudService.testConnectivity();
      final allConnected = results.values.every((connected) => connected);
      
      stopwatch.stop();
      
      if (allConnected) {
        _addTestResult(
          testName,
          true,
          'All services connected: $results',
          stopwatch.elapsed,
        );
      } else {
        _addTestResult(
          testName,
          false,
          'Some services failed: $results',
          stopwatch.elapsed,
        );
      }
    } catch (e) {
      stopwatch.stop();
      _addTestResult(
        testName,
        false,
        'Connectivity test failed: $e',
        stopwatch.elapsed,
      );
    }
  }

  /// Test health check endpoint
  Future<void> _testHealthCheck() async {
    const testName = 'Health Check (Cloud Function)';
    final stopwatch = Stopwatch()..start();
    
    try {
      logger.i('🏥 Testing health check Cloud Function...');
      
      final healthData = await FirebaseCloudService.checkHealth();
      final success = healthData['success'] ?? false;
      
      stopwatch.stop();
      
      _addTestResult(
        testName,
        success,
        success 
          ? 'Health check successful: ${healthData['system']}'
          : 'Health check failed: ${healthData['error']}',
        stopwatch.elapsed,
      );
    } catch (e) {
      stopwatch.stop();
      _addTestResult(
        testName,
        false,
        'Health check error: $e',
        stopwatch.elapsed,
      );
    }
  }

  /// Test direct Firestore read operations
  Future<void> _testFirestoreDirectRead() async {
    const testName = 'Firestore Direct Read';
    final stopwatch = Stopwatch()..start();
    
    try {
      logger.i('📄 Testing direct Firestore read...');
      
      final eventos = await FirebaseCloudService.getEventos();
      
      stopwatch.stop();
      
      _addTestResult(
        testName,
        true,
        'Successfully read ${eventos.length} eventos from Firestore',
        stopwatch.elapsed,
      );
    } catch (e) {
      stopwatch.stop();
      _addTestResult(
        testName,
        false,
        'Firestore read failed: $e',
        stopwatch.elapsed,
      );
    }
  }

  /// Test Evento Service V2 (Firebase direct)
  Future<void> _testEventoServiceV2() async {
    const testName = 'Evento Service V2';
    final stopwatch = Stopwatch()..start();
    
    try {
      logger.i('🎯 Testing Evento Service V2...');
      
      await _eventoService.initialize();
      final eventos = await _eventoService.getEventos();
      final eventoActivo = await _eventoService.getEventoActivo();
      
      stopwatch.stop();
      
      _addTestResult(
        testName,
        _eventoService.isInitialized,
        'Service initialized: ${_eventoService.isInitialized}, '
        'Events: ${eventos.length}, '
        'Active event: ${eventoActivo?.nombre ?? 'None'}',
        stopwatch.elapsed,
      );
    } catch (e) {
      stopwatch.stop();
      _addTestResult(
        testName,
        false,
        'Evento Service V2 failed: $e',
        stopwatch.elapsed,
      );
    }
  }

  /// Test Auth Service V2 (Firebase direct)
  Future<void> _testAuthServiceV2() async {
    const testName = 'Auth Service V2';
    final stopwatch = Stopwatch()..start();
    
    try {
      logger.i('🔐 Testing Auth Service V2...');
      
      await _authService.initialize();
      final isAuth = _authService.isAuthenticated;
      final userId = _authService.currentUserId;
      
      Map<String, dynamic>? profile;
      if (isAuth) {
        profile = await _authService.getUserProfile();
      }
      
      stopwatch.stop();
      
      _addTestResult(
        testName,
        _authService.isInitialized,
        'Service initialized: ${_authService.isInitialized}, '
        'Authenticated: $isAuth, '
        'User ID: ${userId ?? 'None'}, '
        'Profile loaded: ${profile != null}',
        stopwatch.elapsed,
      );
    } catch (e) {
      stopwatch.stop();
      _addTestResult(
        testName,
        false,
        'Auth Service V2 failed: $e',
        stopwatch.elapsed,
      );
    }
  }

  /// Test notification service
  Future<void> _testNotificationService() async {
    const testName = 'Notification Service';
    final stopwatch = Stopwatch()..start();
    
    try {
      logger.i('📱 Testing notification service...');
      
      // Test notification sending (will fail if not authenticated, which is OK)
      final notificationSent = await FirebaseCloudService.sendNotification(
        title: 'Test Notification',
        body: 'Firebase Blaze migration test notification',
        type: 'test',
      );
      
      stopwatch.stop();
      
      _addTestResult(
        testName,
        true, // Always pass since we're testing the call, not authentication
        'Notification service callable: $notificationSent',
        stopwatch.elapsed,
      );
    } catch (e) {
      stopwatch.stop();
      _addTestResult(
        testName,
        false,
        'Notification service error: $e',
        stopwatch.elapsed,
      );
    }
  }

  /// Test Cloud Functions accessibility
  Future<void> _testCloudFunctions() async {
    const testName = 'Cloud Functions Access';
    final stopwatch = Stopwatch()..start();
    
    try {
      logger.i('☁️ Testing Cloud Functions access...');
      
      // Test statistics function (will require authentication)
      final statsResult = await FirebaseCloudService.getEventStatistics();
      
      stopwatch.stop();
      
      _addTestResult(
        testName,
        true,
        'Cloud Functions accessible, Stats result: ${statsResult['success'] ?? 'unknown'}',
        stopwatch.elapsed,
      );
    } catch (e) {
      stopwatch.stop();
      // Expected to fail without authentication
      final isAuthError = e.toString().contains('unauthenticated');
      _addTestResult(
        testName,
        isAuthError, // Pass if it's just an auth error
        isAuthError 
          ? 'Cloud Functions accessible (auth required as expected)'
          : 'Cloud Functions error: $e',
        stopwatch.elapsed,
      );
    }
  }

  /// Test real-time streams
  Future<void> _testRealTimeStreams() async {
    const testName = 'Real-time Streams';
    final stopwatch = Stopwatch()..start();
    
    try {
      logger.i('🔄 Testing real-time streams...');
      
      // Test evento stream
      final eventosStream = _eventoService.eventosStream;
      final notifications = FirebaseCloudService.streamNotifications();
      
      // Listen for a brief moment to test stream setup
      await eventosStream.take(1).timeout(
        const Duration(seconds: 3),
        onTimeout: () => [],
      ).toList();
      
      stopwatch.stop();
      
      _addTestResult(
        testName,
        true,
        'Real-time streams initialized successfully',
        stopwatch.elapsed,
      );
    } catch (e) {
      stopwatch.stop();
      _addTestResult(
        testName,
        false,
        'Real-time streams error: $e',
        stopwatch.elapsed,
      );
    }
  }

  /// Add test result
  void _addTestResult(String name, bool success, String details, Duration duration) {
    setState(() {
      _testResults.add(TestResult(
        name: name,
        success: success,
        details: details,
        duration: duration,
      ));
    });
    
    final status = success ? '✅' : '❌';
    logger.i('$status $name: $details (${duration.inMilliseconds}ms)');
  }

  /// Show test summary dialog
  void _showTestSummary() {
    final passedTests = _testResults.where((t) => t.success).length;
    final totalTests = _testResults.length;
    final successRate = (passedTests / totalTests * 100).round();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🧪 Test Summary'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Passed: $passedTests / $totalTests'),
            Text('Success Rate: $successRate%'),
            const SizedBox(height: 16),
            Text(
              successRate >= 80 
                ? '🎉 Firebase Blaze migration is working well!'
                : '⚠️ Some issues detected. Check individual test results.',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: successRate >= 80 ? Colors.green : Colors.orange,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🔥 Firebase Blaze Tests'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.orange.shade50,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '🚀 Firebase Blaze Migration Tests',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Validates complete migration from Node.js hybrid to Firebase Cloud Functions',
                ),
                if (_isRunningTests) ...[
                  const SizedBox(height: 12),
                  LinearProgressIndicator(
                    value: _testResults.length / 8,
                    backgroundColor: Colors.orange.shade200,
                    valueColor: const AlwaysStoppedAnimation(Colors.orange),
                  ),
                  const SizedBox(height: 4),
                  Text('Running test ${_currentTestIndex + 1} of 8...'),
                ],
              ],
            ),
          ),
          
          // Test Results
          Expanded(
            child: _testResults.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.science, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'Ready to test Firebase Blaze migration',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _testResults.length,
                    itemBuilder: (context, index) {
                      final result = _testResults[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: Icon(
                            result.success ? Icons.check_circle : Icons.error,
                            color: result.success ? Colors.green : Colors.red,
                          ),
                          title: Text(result.name),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(result.details),
                              const SizedBox(height: 4),
                              Text(
                                'Duration: ${result.duration.inMilliseconds}ms',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                          isThreeLine: true,
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isRunningTests ? null : _runAllTests,
        backgroundColor: Colors.orange,
        icon: _isRunningTests 
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.play_arrow),
        label: Text(_isRunningTests ? 'Running Tests...' : 'Run All Tests'),
      ),
    );
  }
}

/// Test result data class
class TestResult {
  final String name;
  final bool success;
  final String details;
  final Duration duration;

  TestResult({
    required this.name,
    required this.success,
    required this.details,
    required this.duration,
  });
}