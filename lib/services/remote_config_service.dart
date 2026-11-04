import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';

/// Version of this build. Must match `version:` in `pubspec.yaml`; a test
/// asserts that, so the forced-update gate cannot silently drift (no
/// `package_info_plus` dependency is needed for one constant).
const String kAppVersion = '1.0.0';

/// Compares dotted numeric versions (`1.2.3`, optional `-tag` / `+build`).
/// Missing segments count as 0, so `1.0` == `1.0.0`.
int compareVersions(String a, String b) {
  final left = _numericSegments(a);
  final right = _numericSegments(b);
  // Unparsable input yields 0 (equal) — see [isVersionBelowMinimum].
  if (left == null || right == null) return 0;
  for (var i = 0; i < 3; i++) {
    final l = i < left.length ? left[i] : 0;
    final r = i < right.length ? right[i] : 0;
    if (l != r) return l.compareTo(r);
  }
  return 0;
}

/// True when [current] is older than [minimum]. Fails **open**: an empty or
/// malformed `minimum` from Remote Config never locks users out of the app.
bool isOutdatedVersion(String current, String minimum) =>
    compareVersions(current, minimum) < 0;

List<int>? _numericSegments(String raw) {
  final core = raw.trim().split('+').first.split('-').first;
  if (core.isEmpty) return null;
  final parts = <int>[];
  for (final segment in core.split('.')) {
    final value = int.tryParse(segment.trim());
    if (value == null) return null;
    parts.add(value);
  }
  return parts;
}

/// Firebase Remote Config service.
///
/// Lab 3 Requirement: ≥2 Remote Config parameters.
/// Here we configure 4 parameters with safe default fallbacks:
/// 1. `maintenance_mode` (bool)
/// 2. `feature_ai_advisor_enabled` (bool)
/// 3. `min_app_version` (String)
/// 4. `vault_sync_interval_mins` (int)
///
/// Defaults mirror `firebase/remote-config-defaults.json` (the committed,
/// externalized copy required by audit M-09).
class RemoteConfigService {
  /// [overrides] lets tests pose as a given Remote Config state without a
  /// Firebase app or a Console deploy (see `test/services/version_gate_test.dart`).
  RemoteConfigService({
    FirebaseRemoteConfig? remoteConfig,
    Map<String, dynamic>? overrides,
  })  : _remoteConfig = remoteConfig ??
            (Firebase.apps.isNotEmpty ? FirebaseRemoteConfig.instance : null),
        _overrides = overrides ?? const {};

  final FirebaseRemoteConfig? _remoteConfig;
  final Map<String, dynamic> _overrides;

  /// Override → live Remote Config → committed default.
  T _value<T>(String key, T Function(FirebaseRemoteConfig) read) {
    final override = _overrides[key];
    final client = _remoteConfig;
    if (override != null && client == null) return override as T;
    if (client == null) return _defaults[key] as T;
    if (override is T) return override;
    return read(client);
  }

  // Default values
  static const Map<String, dynamic> _defaults = {
    'maintenance_mode': false,
    'feature_ai_advisor_enabled': true,
    'min_app_version': '1.0.0',
    'vault_sync_interval_mins': 30,
  };

  Future<void> initialize() async {
    final client = _remoteConfig;
    if (client == null) {
      debugPrint('[RemoteConfig] No Firebase App initialized, using fallback defaults.');
      return;
    }

    try {
      await client.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(seconds: 10),
          minimumFetchInterval: kDebugMode
              ? const Duration(seconds: 0)
              : const Duration(hours: 1),
        ),
      );

      await client.setDefaults(_defaults);
      await fetchAndActivate();
      debugPrint('[RemoteConfig] Initialized successfully with defaults.');
    } catch (e) {
      debugPrint('[RemoteConfig] Initialization error: $e');
    }
  }

  Future<bool> fetchAndActivate() async {
    final client = _remoteConfig;
    if (client == null) return false;

    try {
      final updated = await client.fetchAndActivate();
      debugPrint('[RemoteConfig] fetchAndActivate: updated = $updated');
      return updated;
    } catch (e) {
      debugPrint('[RemoteConfig] fetchAndActivate error: $e');
      return false;
    }
  }

  // Parameter getters
  bool get isMaintenanceMode =>
      _value('maintenance_mode', (c) => c.getBool('maintenance_mode'));

  bool get isAiAdvisorEnabled => _value(
      'feature_ai_advisor_enabled', (c) => c.getBool('feature_ai_advisor_enabled'));

  String get minAppVersion =>
      _value('min_app_version', (c) => c.getString('min_app_version'));

  /// True when Remote Config demands a version newer than this build (M-09).
  bool get isVersionBelowMinimum =>
      isOutdatedVersion(kAppVersion, minAppVersion);

  int get vaultSyncIntervalMins => _value(
      'vault_sync_interval_mins', (c) => c.getInt('vault_sync_interval_mins'));
}
