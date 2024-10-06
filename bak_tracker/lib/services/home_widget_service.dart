import 'package:home_widget/home_widget.dart';

class WidgetService {
  static const String appGroup =
      "group.com.baktracker.shared"; // Your App Group identifier.

  // Generic function to save data
  static Future<void> saveData(String key, String value) async {
    await HomeWidget.saveWidgetData<String>(key, value);
  }

  static Future<void> deleteData(String key) async {
    await HomeWidget.saveWidgetData<String>(key, null);
  }

  // Generic function to retrieve data
  static Future<String?> getData(String key, {String? defaultValue}) async {
    return await HomeWidget.getWidgetData<String>(key,
        defaultValue: defaultValue);
  }

  // Update widget with latest data
  static Future<void> reloadWidgets() async {
    await HomeWidget.updateWidget(
      name: 'BAKWidget',
      androidName: 'BAKWidgetReceiver', // Only required for Android
      iOSName: 'BAKWidget',
    );
  }

  // Update drink information and refresh the widget
  static Future<void> updateDrinkInfo(
      String associationName, String chucked, String debt) async {
    await saveData('association_name', associationName);
    await saveData('chucked_drinks', chucked);
    await saveData('drink_debt', debt);
    await reloadWidgets();
  }

  static Future<void> resetWidget() async {
    await deleteData('association_name');
    await deleteData('chucked_drinks');
    await deleteData('drink_debt');
    await reloadWidgets();
  }
}
