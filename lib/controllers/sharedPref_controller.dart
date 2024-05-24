import 'dart:convert';

import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SharedPrefController extends GetxController {
  Future<void> saveMatesWavedTo() async {
    final prefs = await SharedPreferences.getInstance();
    final measurements = prefs.getStringList('wavedMates') ?? [];

    // Convert the Measurement object to a JSON string before saving

    measurements.add(
      jsonEncode(
        {
          "": "",
        },
      ),
    );

    await prefs.setStringList('wavedMates', measurements);
  }
}
