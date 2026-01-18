class ColorData {
  int strength;
  int brightness;

  ColorData({required this.strength, required this.brightness});

  Map<String, int> toMap() {
    return {
      'strength': strength,
      'brightness': brightness,
    };
  }
}
