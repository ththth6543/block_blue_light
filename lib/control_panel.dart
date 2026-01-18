import 'package:block_blue_light/color_data.dart';
import 'package:flutter/material.dart';
import 'package:block_blue_light/screen_size.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class ControlPanel extends StatefulWidget {
  const ControlPanel({super.key});

  @override
  State<ControlPanel> createState() => _ControlPanelState();
}

class _ControlPanelState extends State<ControlPanel> {
  static const String _strengthKey = 'strength';
  static const String _brightnessKey = 'brightness';
  static const String _adUnitId = "ca-app-pub-3940256099942544/6300978111"; // Test ID

  BannerAd? _bannerAd;
  ColorData _colorData = ColorData(strength: 120, brightness: 0);
  bool _isScheduleEnabled = false;
  TimeOfDay _startTime = TimeOfDay(hour: 22, minute: 0);
  TimeOfDay _endTime = TimeOfDay(hour: 7, minute: 0);


  @override
  void initState() {
    super.initState();
    _loadSettings();
    _loadBannerAd();
  }

  Future<void> _loadSettings() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _colorData.strength = prefs.getInt(_strengthKey) ?? 128;
      _colorData.brightness = prefs.getInt(_brightnessKey) ?? 0;
      _isScheduleEnabled = prefs.getBool('scheduleEnabled') ?? false;
      _startTime = TimeOfDay(
          hour: prefs.getInt('startTimeHour') ?? 22,
          minute: prefs.getInt('startTimeMinute') ?? 0);
      _endTime = TimeOfDay(
          hour: prefs.getInt('endTimeHour') ?? 7,
          minute: prefs.getInt('endTimeMinute') ?? 0);
    });
  }

  Future<void> _saveSettings() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_strengthKey, _colorData.strength);
    await prefs.setInt(_brightnessKey, _colorData.brightness);
    await prefs.setBool('scheduleEnabled', _isScheduleEnabled);
    await prefs.setInt('startTimeHour', _startTime.hour);
    await prefs.setInt('startTimeMinute', _startTime.minute);
    await prefs.setInt('endTimeHour', _endTime.hour);
    await prefs.setInt('endTimeMinute', _endTime.minute);
  }

  void _loadBannerAd() async {
    BannerAd(
      adUnitId: _adUnitId,
      request: const AdRequest(),
      size: AdSize.banner,
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          debugPrint("Ad was loaded.");
          setState(() {
            _bannerAd = ad as BannerAd;
          });
        },
        onAdFailedToLoad: (ad, err) {
          debugPrint("Ad failed to load with error: $err");
          ad.dispose();
        },
      ),
    ).load();
  }

  Widget _showBannerAd() {
    if (_bannerAd != null) {
      return Align(
        alignment: Alignment.bottomCenter,
        child: SafeArea(
          child: SizedBox(
            width: _bannerAd!.size.width.toDouble(),
            height: _bannerAd!.size.height.toDouble(),
            child: AdWidget(ad: _bannerAd!),
          ),
        ),
      );
    }
    else {
      return Container(color: Colors.blue,);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildFilterSettingsPanel(),
        SizedBox(height: ScreenSize.height * 0.015),
        _buildSchedulePanel(),
        SizedBox(height: ScreenSize.height * 0.015),
        _showBannerAd(),
      ],
    );
  }

  Widget _buildFilterSettingsPanel() {
    final edge = ScreenSize.width * 0.025;
    const titleStyle = TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.bold,
      color: Colors.white,
    );
    final valueStyle = TextStyle(
      fontSize: ScreenSize.width * 0.08,
      color: Colors.white,
    );

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(20),
      ),
      margin: EdgeInsets.only(top: edge, left: edge, right: edge),
      width: ScreenSize.width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Filter Settings", style: titleStyle),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.opacity, color: Colors.orangeAccent),
              const SizedBox(width: 10),
              Text("Strength", style: TextStyle(color: Colors.grey[300])),
              Expanded(
                child: Slider(
                  value: _colorData.strength.toDouble(),
                  min: 0,
                  max: 255,
                  onChanged: (value) {
                    setState(() {
                      _colorData.strength = value.toInt();
                    });
                    FlutterOverlayWindow.shareData(_colorData.toMap());
                    _saveSettings();
                  },
                ),
              ),
              Text("${(_colorData.strength / 255 * 100).toInt()}%", style: valueStyle),
            ],
          ),
          Row(
            children: [
              const Icon(Icons.brightness_4, color: Colors.yellowAccent),
              const SizedBox(width: 10),
              Text("Brightness", style: TextStyle(color: Colors.grey[300])),
              Expanded(
                child: Slider(
                  value: _colorData.brightness.toDouble(),
                  min: 0,
                  max: 50,
                  onChanged: (value) {
                    setState(() {
                      _colorData.brightness = value.toInt();
                    });
                    _saveSettings();
                    FlutterOverlayWindow.shareData(_colorData.toMap());
                  },
                ),
              ),
              Text("-${(_colorData.brightness / 50 * 100).toInt()}%", style: valueStyle),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSchedulePanel() {
    final edge = ScreenSize.width * 0.025;
    return Container(
      padding: EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(20),
      ),
      margin: EdgeInsets.only(top: edge, left: edge, right: edge),
      width: ScreenSize.width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Schedule",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Switch(
                value: _isScheduleEnabled,
                onChanged: (value) {
                  setState(() {
                    _isScheduleEnabled = value;
                  });
                  _saveSettings();
                },
              ),
            ],
          ),
          SizedBox(height: edge),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Expanded(
                child: _buildTimePicker("Start", _startTime, (newTime) {
                  setState(() => _startTime = newTime);
                  _saveSettings();
                }),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Text("~", style: TextStyle(fontSize: 24, color: Colors.white),),
              ),
              Expanded(
                child: _buildTimePicker("End", _endTime, (newTime) {
                  setState(() => _endTime = newTime);
                  _saveSettings();
                }),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimePicker(String title, TimeOfDay time,
      Function(TimeOfDay) onTimeChanged) {
    return GestureDetector(
      onTap: () async {
        final newTime = await showTimePicker(
          context: context,
          initialTime: time,
        );
        if (newTime != null) {
          onTimeChanged(newTime);
        }
      },
      child: Column(
        children: [
          Text(title, style: TextStyle(color: Colors.grey[300], fontSize: 16)),
          Text(
            time.format(context),
            style: TextStyle(
              fontSize: ScreenSize.width * 0.1,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }


}

