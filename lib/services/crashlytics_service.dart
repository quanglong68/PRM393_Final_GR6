import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

/// Firebase Crashlytics service for monitoring errors and unhandled exceptions.
class CrashlyticsService {
  CrashlyticsService({FirebaseCrashlytics? crashlytics})
    : _crashlytics =
          crashlytics ??
          (Firebase.apps.isNotEmpty ? FirebaseCrashlytics.instance : null);

  final FirebaseCrashlytics? _crashlytics;

  Future<void> enableCollection() async {
    final client = _crashlytics;
    if (client == null) throw StateError('Crashlytics chưa được kết nối.');
    await client.setCrashlyticsCollectionEnabled(true);
  }

  Future<void> testCrash() async {
    await enableCollection();
    _crashlytics!.crash();
  }

  /// Sets up global error handlers for both Flutter framework errors and
  /// asynchronous platform dispatcher errors.
  Future<void> initialize() async {
    final client = _crashlytics;
    if (client == null) {
      debugPrint(
        '[Crashlytics] No Firebase App initialized, skipping Crashlytics setup.',
      );
      return;
    }

    try {
      // Keep explicit debug-test opt-in across the crash/relaunch boundary,
      // when the native SDK sends the previous process's report.
      // Android defaults to disabled via manifest; the native SDK persists
      // enableCollection(), so debug initialization must not undo that opt-in.
      if (!kDebugMode) {
        await client.setCrashlyticsCollectionEnabled(true);
      }

      // Pass all uncaught "fatal" errors from the framework to Crashlytics
      FlutterError.onError = client.recordFlutterFatalError;

      // Pass all uncaught asynchronous errors to Crashlytics
      PlatformDispatcher.instance.onError = (error, stack) {
        client.recordError(error, stack, fatal: true);
        return true;
      };

      debugPrint('[Crashlytics] Initialized error handlers.');
    } catch (e) {
      debugPrint('[Crashlytics] Initialization error: $e');
    }
  }

  /// Records a non-fatal error with optional stack trace and reason
  Future<void> recordError(
    dynamic exception,
    StackTrace? stack, {
    String? reason,
    bool fatal = false,
  }) async {
    final client = _crashlytics;
    if (client == null) {
      throw StateError('Crashlytics chưa được kết nối.');
    }

    try {
      await client.recordError(exception, stack, reason: reason, fatal: fatal);
    } catch (e) {
      debugPrint('[Crashlytics] recordError error: $e');
      rethrow;
    }
  }

  /// Logs custom message to Crashlytics breadcrumbs
  Future<void> log(String message) async {
    final client = _crashlytics;
    if (client == null) {
      debugPrint(
        '[Crashlytics] Firebase not initialized — skipped log: $message',
      );
      return;
    }

    try {
      await client.log(message);
    } catch (e) {
      debugPrint('[Crashlytics] log error: $e');
    }
  }

  /// Associates the current user ID with crash reports
  Future<void> setUserId(String userId) async {
    final client = _crashlytics;
    if (client == null) {
      debugPrint(
        '[Crashlytics] Firebase not initialized — skipped setUserId: $userId',
      );
      return;
    }

    try {
      await client.setUserIdentifier(userId);
    } catch (e) {
      debugPrint('[Crashlytics] setUserId error: $e');
    }
  }

  /// Attaches a custom key/value to subsequent crash reports (Lab 3 §4.2
  /// requires ≥1 custom key — used for `auth_method` after sign-in).
  Future<void> setCustomKey(String key, Object value) async {
    final client = _crashlytics;
    if (client == null) {
      debugPrint(
        '[Crashlytics] Firebase not initialized — skipped setCustomKey: $key=$value',
      );
      return;
    }

    try {
      await client.setCustomKey(key, value);
    } catch (e) {
      debugPrint('[Crashlytics] setCustomKey error: $e');
    }
  }
}
