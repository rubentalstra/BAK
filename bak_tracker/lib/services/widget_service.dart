import 'package:home_widget/home_widget.dart';

class WidgetService {
  static const String appGroup =
      "group.com.baktracker.shared"; // Your App Group identifier.

  // Save data to UserDefaults (iOS) or SharedPreferences (Android)
  static Future<void> saveWidgetData(String key, String value) async {
    await HomeWidget.saveWidgetData<String>(key, value);
  }

  // Retrieve data from UserDefaults (iOS) or SharedPreferences (Android)
  static Future<String?> getWidgetData(String key,
      {String? defaultValue}) async {
    return await HomeWidget.getWidgetData<String>(key,
        defaultValue: defaultValue);
  }

  // Update the widget to reflect the new data
  static Future<void> reloadWidgets() async {
    await HomeWidget.updateWidget(
      name: 'BAKWidget', // Name of the widget
      androidName: 'BAKWidgetReceiver', // Only required for Android
      iOSName: 'BAKWidget', // For iOS
    );
  }

  // Set drink information in shared data for the widget
  static Future<void> updateDrinkInfo(
      String associationName, String chucked, String debt) async {
    await saveWidgetData('association_name', associationName);
    await saveWidgetData('chucked_drinks', chucked);
    await saveWidgetData('drink_debt', debt);
    await reloadWidgets();
  }
}
