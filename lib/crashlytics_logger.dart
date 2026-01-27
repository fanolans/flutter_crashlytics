import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

/// Utility class untuk logging ke Firebase Crashlytics dengan best practice
///
/// Cara pakai:
/// ```dart
/// await CrashlyticsLogger.logEvent(
///   eventId: 'add_counter',
///   eventName: 'Add Counter Button',
///   description: 'User menambah counter',
///   additionalData: {'counter_value': counter.toString()},
/// );
/// ```
class CrashlyticsLogger {
  static final FirebaseCrashlytics _crashlytics = FirebaseCrashlytics.instance;

  /// Log event dengan custom ID dan Name
  ///
  /// [eventId] - ID unik untuk event (gunakan snake_case, contoh: add_counter)
  /// [eventName] - Nama readable untuk event (contoh: Add Counter Button)
  /// [description] - Deskripsi detail tentang event
  /// [additionalData] - Data tambahan yang ingin di-log (opsional)
  static Future<void> logEvent({
    required String eventId,
    required String eventName,
    String? description,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      // Set custom keys untuk tracking yang lebih mudah
      await _crashlytics.setCustomKey('event_id', eventId);
      await _crashlytics.setCustomKey('event_name', eventName);

      if (description != null) {
        await _crashlytics.setCustomKey('event_description', description);
      }

      // Set additional data sebagai custom keys
      if (additionalData != null) {
        for (var entry in additionalData.entries) {
          await _crashlytics.setCustomKey(entry.key, entry.value.toString());
        }
      }

      // Log ke Crashlytics
      final logMessage =
          'Event: $eventId | $eventName${description != null ? ' - $description' : ''}';
      _crashlytics.log(logMessage);

      // Debug print untuk development
      if (kDebugMode) {
        print('📊 Crashlytics Log: $logMessage');
        if (additionalData != null) {
          print('   Additional Data: $additionalData');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error logging to Crashlytics: $e');
      }
    }
  }

  /// Log error dengan context
  ///
  /// [eventId] - ID event dimana error terjadi
  /// [eventName] - Nama event
  /// [error] - Error object
  /// [stackTrace] - Stack trace (opsional)
  /// [fatal] - Apakah error ini fatal atau tidak (default: false)
  /// [forceVisible] - Force non-fatal error untuk muncul di dashboard (default: true)
  static Future<void> logError({
    required String eventId,
    required String eventName,
    required dynamic error,
    StackTrace? stackTrace,
    bool fatal = false,
    bool forceVisible = true,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      // Set context sebelum record error
      await _crashlytics.setCustomKey('error_event_id', eventId);
      await _crashlytics.setCustomKey('error_event_name', eventName);
      await _crashlytics.setCustomKey('is_fatal', fatal);
      await _crashlytics.setCustomKey(
        'error_type',
        fatal ? 'FATAL' : 'NON_FATAL',
      );

      // Set additional data
      if (additionalData != null) {
        for (var entry in additionalData.entries) {
          await _crashlytics.setCustomKey(
            'error_${entry.key}',
            entry.value.toString(),
          );
        }
      }

      // Log error message
      _crashlytics.log('Error in $eventId ($eventName): $error');

      // PENTING: Untuk non-fatal errors yang ingin visible di dashboard
      // Ada 2 opsi:

      if (!fatal && forceVisible) {
        // OPSI 1: Gunakan recordError dengan information yang lebih detail
        // Non-fatal akan tetap tercatat tapi kadang tidak langsung muncul
        await _crashlytics.recordError(
          error,
          stackTrace,
          reason: '[NON-FATAL] $eventId - $eventName: ${error.toString()}',
          fatal: false,
          printDetails: true,
        );

        // OPSI 2: Kirim sebagai custom event untuk visibility lebih baik
        // Ini akan membuat non-fatal error lebih mudah terlihat
        await _crashlytics.setCustomKey('last_non_fatal_error', eventId);
        await _crashlytics.setCustomKey(
          'last_non_fatal_time',
          DateTime.now().toIso8601String(),
        );
        await _crashlytics.setCustomKey(
          'last_non_fatal_message',
          error.toString(),
        );
      } else {
        // Fatal error atau non-fatal yang tidak perlu force visible
        await _crashlytics.recordError(
          error,
          stackTrace,
          reason: fatal
              ? '[FATAL] $eventId - $eventName'
              : '[NON-FATAL] $eventId - $eventName',
          fatal: fatal,
          printDetails: true,
        );
      }

      if (kDebugMode) {
        print('❌ Crashlytics Error Log:');
        print('   Event: $eventId | $eventName');
        print('   Error: $error');
        print('   Fatal: $fatal');
        print('   Force Visible: $forceVisible');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error recording error to Crashlytics: $e');
      }
    }
  }

  /// Log non-fatal error dengan guarantee akan terlihat di dashboard
  /// Menggunakan teknik khusus untuk memastikan error terlihat
  ///
  /// RECOMMENDED untuk production error tracking!
  static Future<void> logNonFatalError({
    required String eventId,
    required String eventName,
    required dynamic error,
    StackTrace? stackTrace,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      // Set timestamp untuk tracking
      final timestamp = DateTime.now().toIso8601String();

      // Set semua context
      await _crashlytics.setCustomKey('non_fatal_event_id', eventId);
      await _crashlytics.setCustomKey('non_fatal_event_name', eventName);
      await _crashlytics.setCustomKey('non_fatal_timestamp', timestamp);
      await _crashlytics.setCustomKey(
        'non_fatal_error_type',
        error.runtimeType.toString(),
      );

      // Set additional data
      if (additionalData != null) {
        for (var entry in additionalData.entries) {
          await _crashlytics.setCustomKey(
            'non_fatal_${entry.key}',
            entry.value.toString(),
          );
        }
      }

      // Log dengan format yang jelas
      _crashlytics.log('🔶 NON-FATAL ERROR 🔶');
      _crashlytics.log('Event ID: $eventId');
      _crashlytics.log('Event Name: $eventName');
      _crashlytics.log('Error: $error');
      _crashlytics.log('Time: $timestamp');

      if (additionalData != null) {
        _crashlytics.log('Additional Data: $additionalData');
      }

      // Record error dengan reason yang sangat jelas
      await _crashlytics.recordError(
        error,
        stackTrace ?? StackTrace.current,
        reason: '🔶 NON-FATAL: [$eventId] $eventName - ${error.toString()}',
        fatal: false,
        printDetails: true,
      );

      if (kDebugMode) {
        print('🔶 Non-Fatal Error Logged to Crashlytics:');
        print('   Event: $eventId | $eventName');
        print('   Error: $error');
        print('   Timestamp: $timestamp');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error logging non-fatal error: $e');
      }
    }
  }

  /// Set user identifier untuk tracking
  static Future<void> setUserId(String userId) async {
    await _crashlytics.setUserIdentifier(userId);
    if (kDebugMode) {
      print('👤 User ID set: $userId');
    }
  }

  /// Set custom key yang akan persistent selama session
  static Future<void> setCustomKey(String key, dynamic value) async {
    await _crashlytics.setCustomKey(key, value);
  }

  /// Clear semua custom keys
  static Future<void> clearCustomKeys() async {
    // Firebase Crashlytics tidak punya method clear,
    // jadi kita set ke empty string untuk keys yang penting
    await _crashlytics.setCustomKey('event_id', '');
    await _crashlytics.setCustomKey('event_name', '');
    await _crashlytics.setCustomKey('event_description', '');
  }

  /// Force crash untuk testing (HANYA untuk testing!)
  static void forceCrash() {
    _crashlytics.crash();
  }

  /// Check if Crashlytics collection is enabled
  static Future<bool> isCrashlyticsCollectionEnabled() async {
    return _crashlytics.isCrashlyticsCollectionEnabled;
  }

  /// Enable/disable Crashlytics collection
  static Future<void> setCrashlyticsCollectionEnabled(bool enabled) async {
    await _crashlytics.setCrashlyticsCollectionEnabled(enabled);
  }
}
