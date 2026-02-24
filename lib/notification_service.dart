import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';

const String _channelId = 'block_blue_light_channel';
const String _channelName = 'Blue Light Filter Control';
const String _channelDescription =
    'Notification to control the blue light filter';
const int _notificationId = 1;
const String turnOffActionId = 'turn_off_action';

@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse notificationResponse) {
  debugPrint('[BACKGROUND] Callback started.');
  debugPrint(
    '[BACKGROUND] Notification action tapped: ${notificationResponse.actionId}',
  );
  if (notificationResponse.actionId == turnOffActionId) {
    FlutterOverlayWindow.closeOverlay();
  }
  debugPrint('[BACKGROUND] Callback finished.');
}

class NotificationService {
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  final StreamController<String?> onNotificationClick =
      StreamController.broadcast();

  Future<void> init() async {
    debugPrint('[NotificationService] Initializing...');

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (response) {
        debugPrint(
          '[FOREGROUND] Notification action tapped: ${response.actionId}',
        );

        if (response.actionId == turnOffActionId) {
          debugPrint('[fore] closing overlay');
          FlutterOverlayWindow.closeOverlay();
        }
        onNotificationClick.add(response.actionId);
      },
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );

    // 알림창 권한 요청
    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
        _flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();
    await androidImplementation?.requestNotificationsPermission();

    // 알림 채널 생성
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDescription,
      importance: Importance.defaultImportance,
    );
    await androidImplementation?.createNotificationChannel(channel);

    debugPrint('[NotificationService] Initialization complete.');
  }

  Future<void> showFilterNotification() async {
    const AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDescription,
          importance: Importance.low,
          priority: Priority.defaultPriority,
          playSound: false,
          ongoing: true,
          autoCancel: false,
          actions: <AndroidNotificationAction>[
            AndroidNotificationAction(
              turnOffActionId,
              '끄기', // 'Turn Off'
              showsUserInterface: true,
            ),
          ],
        );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidNotificationDetails,
    );

    await _flutterLocalNotificationsPlugin.show(
      _notificationId,
      '블루라이트 필터가 활성화되어 있습니다',
      '알림을 통해 필터를 끌 수 있습니다.',
      notificationDetails,
    );
  }

  Future<void> cancelFilterNotification() async {
    await _flutterLocalNotificationsPlugin.cancel(_notificationId);
  }

  void dispose() {
    onNotificationClick.close();
  }
}
