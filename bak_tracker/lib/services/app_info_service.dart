import 'package:package_info_plus/package_info_plus.dart';

class AppInfoService {
  String appVersion = '';
  String buildNumber = '';

  // Method to fetch app info
  Future<void> initializeAppInfo() async {
    final packageInfo = await PackageInfo.fromPlatform();
    appVersion = packageInfo.version;
    buildNumber = packageInfo.buildNumber;
  }
}
