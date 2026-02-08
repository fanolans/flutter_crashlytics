import 'package:flutter_crashlytics/analytics_logger.dart';
import 'package:flutter_crashlytics/crashlytics_logger.dart';

class AppLogger {
  static Future<void> logAction({
    required String analyticsEvent,
    Map<String, Object>? analyticsParams,
    String? crashEventId,
    String? crashEventName,
  }) async {
    await AnalyticsLogger.logEvent(
      name: analyticsEvent,
      parameters: analyticsParams,
    );

    if (crashEventId != null && crashEventName != null) {
      await CrashlyticsLogger.logEvent(
        eventId: crashEventId,
        eventName: crashEventName,
        additionalData: analyticsParams?.map(
          (k, v) => MapEntry(k, v.toString()),
        ),
      );
    }
  }
}
