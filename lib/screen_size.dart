import 'package:flutter/widgets.dart';

class ScreenSize {
  static late double width;
  static late double height;

  static bool _isInitialized = false;

  static void init(BuildContext context) {
    if(!_isInitialized) {
      width = MediaQuery.of(context).size.width;
      height = MediaQuery.of(context).size.height;
      _isInitialized = true;
    }
  }
}