import 'package:flutter/services.dart';

class NetworkService {
  static const platform = MethodChannel('com.example.drug_interaction_app/network');

  static Future<bool> checkConnectivity() async {
    try {
      final bool result = await platform.invokeMethod('checkNetworkConnectivity');
      print('Native connectivity check result: $result');
      return result;
    } on PlatformException catch (e) {
      print('Failed to get connectivity status: ${e.message}');
      return false;
    }
  }
} 