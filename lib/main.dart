import 'package:block_blue_light/background_task.dart';
import 'package:block_blue_light/notification_service.dart';
import 'package:workmanager/workmanager.dart';
import 'dart:async';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:block_blue_light/overlay_window.dart';
import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:block_blue_light/control_panel.dart';
import 'package:block_blue_light/screen_size.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final NotificationService notificationService = NotificationService();
  await notificationService.init();

  await MobileAds.instance.initialize();
  await Workmanager().initialize(callbackDispatcher, isInDebugMode: true);
  Workmanager().registerPeriodicTask(
    "1",
    checkScheduleTask,
    frequency: const Duration(minutes: 15),
  );
  runApp(MyApp(notificationService: notificationService));
}

class MyApp extends StatelessWidget {
  final NotificationService notificationService;
  const MyApp({super.key, required this.notificationService});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: MyHomePage(notificationService: notificationService));
  }
}

class MyHomePage extends StatefulWidget {
  final NotificationService notificationService;
  const MyHomePage({super.key, required this.notificationService});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with WidgetsBindingObserver {
  bool _isToggle = false;
  late ImageProvider _sleepyImage;
  late ImageProvider _defaultImage;
  StreamSubscription? _notificationClickSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _updateToggleState();

    _sleepyImage = const AssetImage("assets/images/wallpaper_sleepy.jpg");
    _defaultImage = const AssetImage("assets/images/wallpaper.jpg");

    _notificationClickSubscription =
        widget.notificationService.onNotificationClick.stream.listen((actionId) {
      debugPrint('[UI] Received notification action via stream: $actionId');
      if (actionId == turnOffActionId) {
        _handleToggle(false);
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    precacheImage(_sleepyImage, context);
    precacheImage(_defaultImage, context);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _notificationClickSubscription?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      _updateToggleState();
    }
  }

  Future<void> _updateToggleState() async {
    final bool isActive = await FlutterOverlayWindow.isActive();
    if (!mounted) return;
    setState(() {
      _isToggle = isActive;
    });
    if (!isActive) {
      await widget.notificationService.cancelFilterNotification();
    }
  }


  Future<void> _requestPermission() async {
    final bool isOverlayGranted = await FlutterOverlayWindow.isPermissionGranted();
    if (!isOverlayGranted) {
      await FlutterOverlayWindow.requestPermission();
    }
  }

  Future<void> _showOverlay() async {
    if (await FlutterOverlayWindow.isActive()) return;

    await FlutterOverlayWindow.showOverlay(
      alignment: OverlayAlignment.bottomCenter,
      flag: OverlayFlag.clickThrough,
      visibility: NotificationVisibility.visibilityPrivate,
      positionGravity: PositionGravity.auto,
    );
  }

  Future<void> _handleToggle(bool value) async {
    if (!mounted) return;
    setState(() {
      _isToggle = value;
    });
    if (value) {
      await _requestPermission();
      await _showOverlay();
      await widget.notificationService.showFilterNotification();
    } else {
      await FlutterOverlayWindow.closeOverlay();
      await widget.notificationService.cancelFilterNotification();
    }
  }

  @override
  Widget build(BuildContext context) {
    ScreenSize.init(context);

    final double imageHeight = ScreenSize.height * 0.6;

    return Scaffold(
      appBar: _buildAppBar(_isToggle),
      backgroundColor: Colors.transparent,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final double minControlPanelHeight =
              constraints.maxHeight - imageHeight;
          return Stack(
            children: [
              Container(color: Colors.grey[850]),
              SingleChildScrollView(
                child: Container(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Column(
                    children: [
                      AnimatedCrossFade(
                        firstChild: _buildBackgroundImage(
                          _sleepyImage,
                          imageHeight,
                        ),
                        secondChild: _buildBackgroundImage(
                          _defaultImage,
                          imageHeight,
                        ),
                        crossFadeState: _isToggle
                            ? CrossFadeState.showFirst
                            : CrossFadeState.showSecond,
                        duration: const Duration(milliseconds: 500),
                      ),
                      Container(
                        constraints: BoxConstraints(
                          minHeight: minControlPanelHeight > 0
                              ? minControlPanelHeight
                              : 0,
                        ),
                        width: ScreenSize.width,
                        color: Colors.grey[850],
                        child: Center(
                          child: _isToggle
                              ? const ControlPanel()
                              : _buildPowerButton(ScreenSize.width),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  AppBar _buildAppBar(bool isToggle) {
    return AppBar(
      title: const Text("Block Blue Light", style: TextStyle(color: Colors.white)),
      backgroundColor: Colors.grey[850],
      elevation: 0,
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 20.0),
          child: Switch(
            activeThumbColor: Colors.grey[300],
            inactiveThumbColor: Colors.grey[300],
            inactiveTrackColor: Colors.grey[850],
            value: isToggle,
            onChanged: (value) {
              _handleToggle(value);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBackgroundImage(ImageProvider imageProvider, double screenHeight) {
    return Container(
      height: screenHeight,
      decoration: BoxDecoration(
        image: DecorationImage(image: imageProvider, fit: BoxFit.cover),
      ),
    );
  }

  Widget _buildPowerButton(double screenWidth) {
    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: screenWidth * 0.25,
            height: screenWidth * 0.25,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.grey[700],
            ),
          ),
          IconButton(
            color: Colors.yellow[200],
            iconSize: screenWidth * 0.25,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: () {
              debugPrint("전원 버튼 클릭");
              _handleToggle(!_isToggle);
            },
            icon: const Icon(Icons.power_settings_new),
          ),
        ],
      ),
    );
  }
}

@pragma("vm:entry-point")
void overlayMain() {
  runApp(
    const MaterialApp(debugShowCheckedModeBanner: false, home: OverlayWindow()),
  );
}
