/// Automatic version checks run at most once per [interval].
///
/// A manual check passes [manual] true and always runs.
bool isCheckDue({
  required DateTime now,
  required DateTime? lastCheck,
  Duration interval = const Duration(hours: 24),
  bool manual = false,
}) {
  if (manual) return true;
  if (lastCheck == null) return true;
  // A clock that jumped backwards must not lock the check forever.
  if (now.isBefore(lastCheck)) return true;
  return now.difference(lastCheck) >= interval;
}
