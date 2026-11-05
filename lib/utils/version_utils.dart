/// Pure version-string helpers used by the Remote Config version gate.
///
/// Kept free of Flutter/Firebase imports so they are trivially unit-testable
/// and safe to call from `build`.
library;

/// Compares dotted numeric versions (`1.2.3`, optional `-tag` / `+build`).
/// Missing segments count as 0, so `1.0` == `1.0.0`.
///
/// Unparsable input yields 0 (equal) — see [isOutdatedVersion].
int compareVersions(String a, String b) {
  final left = _numericSegments(a);
  final right = _numericSegments(b);
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
