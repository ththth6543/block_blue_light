import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:block_blue_light/screen_size.dart';

class OverlayWindow extends StatefulWidget {
  const OverlayWindow({super.key});

  @override
  State<OverlayWindow> createState() => _OverlayWindowState();
}

class _OverlayWindowState extends State<OverlayWindow> {
  Color panelColor = Color.fromARGB(120, 255, 180, 70);

  @override
  void dispose() {
    super.dispose();
    FlutterOverlayWindow.disposeOverlayListener();
  }


  @override
  void initState() {
    super.initState();
    FlutterOverlayWindow.overlayListener.listen((data) {
      setState(() {
        changePanelColor(data);
      });
    });
  }

  void changePanelColor(dynamic data) {
    Color baseColor = Color.fromARGB(data["strength"], 255, 180, 70);
    HSLColor hslColor = HSLColor.fromColor(baseColor);

    double brightnessReduction = data["brightness"] / 100;
    double newLightness = hslColor.lightness * (1.0 - brightnessReduction);
    HSLColor newHSLColor = hslColor.withLightness(newLightness);

    setState(() {
      panelColor = newHSLColor.toColor();
    });
  }

  @override
  Widget build(BuildContext context) {
    ScreenSize.init(context);
    final phoneWidth = ScreenSize.width;
    final phoneHeight = ScreenSize.height;
    return Material(
      color: Colors.transparent,
      child: Container(
        width: phoneWidth,
        height: phoneHeight,
        decoration: BoxDecoration(color: panelColor),
      ),
    );
  }
}
