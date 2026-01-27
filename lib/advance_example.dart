import 'package:flutter/material.dart';
import 'package:flutter_crashlytics/crashlytics_logger.dart';

/// Contoh penggunaan CrashlyticsLogger di berbagai scenario
class AdvancedExamples {
  /// Example 1: API Call dengan logging
  static Future<void> fetchUserData(String userId) async {
    try {
      // Log sebelum API call
      await CrashlyticsLogger.logEvent(
        eventId: 'api_fetch_user',
        eventName: 'Fetch User Data API',
        description: 'Fetching user data from server',
        additionalData: {'user_id': userId, 'endpoint': '/api/users/$userId'},
      );

      // Simulate API call
      await Future.delayed(const Duration(seconds: 2));

      // Simulate random error (30% chance)
      if (DateTime.now().millisecond % 3 == 0) {
        throw Exception('Network timeout');
      }

      // Log success
      await CrashlyticsLogger.logEvent(
        eventId: 'api_fetch_user_success',
        eventName: 'Fetch User Data Success',
        description: 'Successfully fetched user data',
        additionalData: {'user_id': userId, 'response_time': '2s'},
      );
    } catch (e, stackTrace) {
      // Log error dengan context lengkap
      await CrashlyticsLogger.logError(
        eventId: 'api_fetch_user',
        eventName: 'Fetch User Data API',
        error: e,
        stackTrace: stackTrace,
        fatal: false,
        additionalData: {
          'user_id': userId,
          'error_type': 'network_error',
          'retry_count': 0,
        },
      );
      rethrow;
    }
  }

  /// Example 2: Form Submission dengan validation
  static Future<void> submitForm({
    required String name,
    required String email,
    required String phone,
  }) async {
    try {
      // Log form submission attempt
      await CrashlyticsLogger.logEvent(
        eventId: 'form_submit',
        eventName: 'Form Submission',
        description: 'User submitting registration form',
        additionalData: {
          'has_name': name.isNotEmpty,
          'has_email': email.isNotEmpty,
          'has_phone': phone.isNotEmpty,
        },
      );

      // Validation
      if (name.isEmpty) {
        throw Exception('Name is required');
      }
      if (email.isEmpty || !email.contains('@')) {
        throw Exception('Valid email is required');
      }

      // Simulate submission
      await Future.delayed(const Duration(seconds: 1));

      // Log success
      await CrashlyticsLogger.logEvent(
        eventId: 'form_submit_success',
        eventName: 'Form Submission Success',
        description: 'Form submitted successfully',
        additionalData: {'email_domain': email.split('@').last},
      );
    } catch (e, stackTrace) {
      await CrashlyticsLogger.logError(
        eventId: 'form_submit',
        eventName: 'Form Submission',
        error: e,
        stackTrace: stackTrace,
        fatal: false,
        additionalData: {
          'validation_failed': true,
          'error_message': e.toString(),
        },
      );
      rethrow;
    }
  }

  /// Example 3: Navigation tracking
  static Future<void> navigateToScreen(String screenName) async {
    await CrashlyticsLogger.logEvent(
      eventId: 'screen_navigation',
      eventName: 'Screen Navigation',
      description: 'User navigating to $screenName',
      additionalData: {
        'screen_name': screenName,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );

    // Set custom key untuk current screen
    await CrashlyticsLogger.setCustomKey('current_screen', screenName);
  }

  /// Example 4: Purchase flow
  static Future<void> processPurchase({
    required String productId,
    required double amount,
    required String currency,
  }) async {
    try {
      // Log purchase attempt
      await CrashlyticsLogger.logEvent(
        eventId: 'purchase_attempt',
        eventName: 'Purchase Attempt',
        description: 'User attempting to purchase product',
        additionalData: {
          'product_id': productId,
          'amount': amount,
          'currency': currency,
          'payment_method': 'credit_card',
        },
      );

      // Set custom keys untuk purchase context
      await CrashlyticsLogger.setCustomKey('last_product_id', productId);
      await CrashlyticsLogger.setCustomKey('last_amount', amount);

      // Simulate payment processing
      await Future.delayed(const Duration(seconds: 3));

      // Log success
      await CrashlyticsLogger.logEvent(
        eventId: 'purchase_success',
        eventName: 'Purchase Success',
        description: 'Purchase completed successfully',
        additionalData: {
          'product_id': productId,
          'amount': amount,
          'currency': currency,
          'transaction_id': 'TXN${DateTime.now().millisecondsSinceEpoch}',
        },
      );
    } catch (e, stackTrace) {
      await CrashlyticsLogger.logError(
        eventId: 'purchase_attempt',
        eventName: 'Purchase Attempt',
        error: e,
        stackTrace: stackTrace,
        fatal: false,
        additionalData: {
          'product_id': productId,
          'amount': amount,
          'currency': currency,
          'payment_failed': true,
        },
      );
      rethrow;
    }
  }

  /// Example 5: File upload dengan progress tracking
  static Future<void> uploadFile(String filePath) async {
    try {
      // Log upload start
      await CrashlyticsLogger.logEvent(
        eventId: 'file_upload_start',
        eventName: 'File Upload Started',
        description: 'User started uploading file',
        additionalData: {
          'file_path': filePath,
          'file_name': filePath.split('/').last,
        },
      );

      // Simulate upload with progress
      for (int i = 0; i <= 100; i += 25) {
        await Future.delayed(const Duration(milliseconds: 500));

        await CrashlyticsLogger.logEvent(
          eventId: 'file_upload_progress',
          eventName: 'File Upload Progress',
          description: 'Upload progress: $i%',
          additionalData: {
            'progress': i,
            'file_name': filePath.split('/').last,
          },
        );
      }

      // Log completion
      await CrashlyticsLogger.logEvent(
        eventId: 'file_upload_complete',
        eventName: 'File Upload Complete',
        description: 'File uploaded successfully',
        additionalData: {
          'file_name': filePath.split('/').last,
          'upload_duration': '2s',
        },
      );
    } catch (e, stackTrace) {
      await CrashlyticsLogger.logError(
        eventId: 'file_upload_start',
        eventName: 'File Upload Started',
        error: e,
        stackTrace: stackTrace,
        fatal: false,
        additionalData: {'file_path': filePath, 'upload_failed': true},
      );
      rethrow;
    }
  }

  /// Example 6: Authentication flow
  static Future<void> loginUser(String email, String password) async {
    try {
      await CrashlyticsLogger.logEvent(
        eventId: 'user_login_attempt',
        eventName: 'User Login Attempt',
        description: 'User attempting to login',
        additionalData: {
          'email_domain': email.split('@').last,
          'method': 'email_password',
        },
      );

      // Simulate login
      await Future.delayed(const Duration(seconds: 2));

      // Set user after successful login
      await CrashlyticsLogger.setUserId(email);
      await CrashlyticsLogger.setCustomKey(
        'user_email_domain',
        email.split('@').last,
      );

      await CrashlyticsLogger.logEvent(
        eventId: 'user_login_success',
        eventName: 'User Login Success',
        description: 'User logged in successfully',
        additionalData: {'email_domain': email.split('@').last},
      );
    } catch (e, stackTrace) {
      await CrashlyticsLogger.logError(
        eventId: 'user_login_attempt',
        eventName: 'User Login Attempt',
        error: e,
        stackTrace: stackTrace,
        fatal: false,
        additionalData: {
          'email_domain': email.split('@').last,
          'login_failed': true,
        },
      );
      rethrow;
    }
  }

  /// Example 7: Database operation
  static Future<void> saveToDatabase(Map<String, dynamic> data) async {
    try {
      await CrashlyticsLogger.logEvent(
        eventId: 'db_save',
        eventName: 'Database Save',
        description: 'Saving data to local database',
        additionalData: {'record_count': 1, 'table_name': 'users'},
      );

      // Simulate database save
      await Future.delayed(const Duration(milliseconds: 500));

      await CrashlyticsLogger.logEvent(
        eventId: 'db_save_success',
        eventName: 'Database Save Success',
        description: 'Data saved successfully',
      );
    } catch (e, stackTrace) {
      await CrashlyticsLogger.logError(
        eventId: 'db_save',
        eventName: 'Database Save',
        error: e,
        stackTrace: stackTrace,
        fatal: false,
        additionalData: {'table_name': 'users', 'operation': 'insert'},
      );
      rethrow;
    }
  }
}

/// Widget untuk menampilkan advanced examples
class AdvancedExamplesScreen extends StatefulWidget {
  const AdvancedExamplesScreen({super.key});

  @override
  State<AdvancedExamplesScreen> createState() => _AdvancedExamplesScreenState();
}

class _AdvancedExamplesScreenState extends State<AdvancedExamplesScreen> {
  String _status = 'Ready';

  void _updateStatus(String status) {
    setState(() {
      _status = status;
    });
  }

  Future<void> _runExample(String name, Future<void> Function() example) async {
    try {
      _updateStatus('Running $name...');
      await example();
      _updateStatus('✅ $name completed');
    } catch (e) {
      _updateStatus('❌ $name failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Advanced Examples')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Status: $_status',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),

          _buildExampleButton(
            'API Call',
            () => _runExample(
              'API Call',
              () => AdvancedExamples.fetchUserData('user123'),
            ),
          ),

          _buildExampleButton(
            'Form Submission',
            () => _runExample(
              'Form Submission',
              () => AdvancedExamples.submitForm(
                name: 'John Doe',
                email: 'john@example.com',
                phone: '1234567890',
              ),
            ),
          ),

          _buildExampleButton(
            'Navigation',
            () => _runExample(
              'Navigation',
              () => AdvancedExamples.navigateToScreen('ProfileScreen'),
            ),
          ),

          _buildExampleButton(
            'Purchase',
            () => _runExample(
              'Purchase',
              () => AdvancedExamples.processPurchase(
                productId: 'prod_001',
                amount: 99.99,
                currency: 'USD',
              ),
            ),
          ),

          _buildExampleButton(
            'File Upload',
            () => _runExample(
              'File Upload',
              () => AdvancedExamples.uploadFile('/path/to/file.jpg'),
            ),
          ),

          _buildExampleButton(
            'Login',
            () => _runExample(
              'Login',
              () =>
                  AdvancedExamples.loginUser('user@example.com', 'password123'),
            ),
          ),

          _buildExampleButton(
            'Database Save',
            () => _runExample(
              'Database Save',
              () => AdvancedExamples.saveToDatabase({'name': 'John'}),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExampleButton(String title, VoidCallback onPressed) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(16)),
        child: Text(title),
      ),
    );
  }
}
