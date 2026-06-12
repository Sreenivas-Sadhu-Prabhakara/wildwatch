import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

/// A stable anonymous identifier for this install.
///
/// Reporting is anonymous (no account). This id is generated once and reused so
/// the agency can correlate multiple reports from the same device if needed,
/// without tying them to a personal identity.
class DeviceId {
  static const _key = 'wildwatch.deviceId';
  static String? _cached;

  static Future<String> get() async {
    if (_cached != null) return _cached!;
    final prefs = await SharedPreferences.getInstance();
    var id = prefs.getString(_key);
    if (id == null) {
      id = const Uuid().v4();
      await prefs.setString(_key, id);
    }
    _cached = id;
    return id;
  }
}
