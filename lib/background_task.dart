import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';

const checkScheduleTask = "checkScheduleTask";

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    if (task == checkScheduleTask) {
      await checkSchedule();
    }
    return Future.value(true);
  });
}

Future<void> checkSchedule() async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  final bool isScheduleEnabled = prefs.getBool('scheduleEnabled') ?? false;

  if (isScheduleEnabled) {
    final now = DateTime.now();
    final startTimeHour = prefs.getInt('startTimeHour') ?? 22;
    final startTimeMinute = prefs.getInt('startTimeMinute') ?? 0;
    final endTimeHour = prefs.getInt('endTimeHour') ?? 7;
    final endTimeMinute = prefs.getInt('endTimeMinute') ?? 0;

    final startTime = DateTime(now.year, now.month, now.day, startTimeHour, startTimeMinute);
    final endTime = DateTime(now.year, now.month, now.day, endTimeHour, endTimeMinute);

    bool isNight = false;
    if (startTime.isAfter(endTime)) { // e.g., 10 PM to 7 AM
      if (now.isAfter(startTime) || now.isBefore(endTime)) {
        isNight = true;
      }
    } else { // e.g., 7 AM to 10 PM
      if (now.isAfter(startTime) && now.isBefore(endTime)) {
        isNight = true;
      }
    }

    if (isNight) {
      if (!await FlutterOverlayWindow.isActive()) {
        await FlutterOverlayWindow.showOverlay(
          alignment: OverlayAlignment.bottomCenter,
          visibility: NotificationVisibility.visibilitySecret,
          flag: OverlayFlag.clickThrough,
          positionGravity: PositionGravity.auto,
        );
      }
    } else {
      if (await FlutterOverlayWindow.isActive()) {
        await FlutterOverlayWindow.closeOverlay();
      }
    }
  }
}
