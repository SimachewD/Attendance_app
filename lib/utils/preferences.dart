import 'package:shared_preferences/shared_preferences.dart';

class PreferencesUtil {
  static Future<bool> getOnlineStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool('isOnline') ?? false; // Default to false
  }

  static Future<void> setOnlineStatus(bool value) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setBool('isOnline', value);
  }
}
