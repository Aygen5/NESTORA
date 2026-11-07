/// Virtual device types supported by Nestora smart home simulation.
enum DeviceType {
  bulb,
  ac,
  plug,
  tv,
  fan,
  security;

  String toShortString() => name;

  static DeviceType fromString(String? value) {
    if (value == null) return DeviceType.bulb;
    final normalized = value.trim().toLowerCase();
    return DeviceType.values.firstWhere(
      (e) => e.name == normalized,
      orElse: () => DeviceType.bulb,
    );
  }
}

/// Air conditioner operating modes.
enum AcMode {
  cool,
  heat,
  auto,
  fanOnly;

  String toShortString() => name;

  static AcMode fromString(String? value) {
    if (value == null) return AcMode.auto;
    final normalized = value.trim().toLowerCase();
    return AcMode.values.firstWhere(
      (e) => e.name == normalized,
      orElse: () => AcMode.auto,
    );
  }
}

/// Air conditioner fan speeds.
enum FanSpeed {
  low,
  mid,
  high,
  auto;

  String toShortString() => name;

  static FanSpeed fromString(String? value) {
    if (value == null) return FanSpeed.mid;
    final normalized = value.trim().toLowerCase();
    return FanSpeed.values.firstWhere(
      (e) => e.name == normalized,
      orElse: () => FanSpeed.mid,
    );
  }
}

/// Pure domain entity representing a simulated smart device in Nestora.
/// Independent of UI icons or Firestore database SDKs.
class Device {
  final String id;
  final String name;
  final String roomId;
  final DeviceType type;
  final bool isPoweredOn;
  final int brightness;
  final String colorHex;
  final String colorName;
  final double targetTemp;
  final AcMode acMode;
  final FanSpeed fanSpeed;
  final double currentPowerWatts;
  final bool isFavorite;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Device({
    required this.id,
    required this.name,
    required this.roomId,
    required this.type,
    this.isPoweredOn = false,
    this.brightness = 72,
    this.colorHex = '#E1C1A0',
    this.colorName = 'Sıcak Günışığı (2700K)',
    this.targetTemp = 24.0,
    this.acMode = AcMode.auto,
    this.fanSpeed = FanSpeed.mid,
    this.currentPowerWatts = 0.0,
    this.isFavorite = false,
    this.createdAt,
    this.updatedAt,
  });

  bool get isLamp => type == DeviceType.bulb;
  bool get isClimate => type == DeviceType.ac;
  bool get isPlug => type == DeviceType.plug;
  bool get isSecurity => type == DeviceType.security;

  Device copyWith({
    String? id,
    String? name,
    String? roomId,
    DeviceType? type,
    bool? isPoweredOn,
    int? brightness,
    String? colorHex,
    String? colorName,
    double? targetTemp,
    AcMode? acMode,
    FanSpeed? fanSpeed,
    double? currentPowerWatts,
    bool? isFavorite,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Device(
      id: id ?? this.id,
      name: name ?? this.name,
      roomId: roomId ?? this.roomId,
      type: type ?? this.type,
      isPoweredOn: isPoweredOn ?? this.isPoweredOn,
      brightness: brightness ?? this.brightness,
      colorHex: colorHex ?? this.colorHex,
      colorName: colorName ?? this.colorName,
      targetTemp: targetTemp ?? this.targetTemp,
      acMode: acMode ?? this.acMode,
      fanSpeed: fanSpeed ?? this.fanSpeed,
      currentPowerWatts: currentPowerWatts ?? this.currentPowerWatts,
      isFavorite: isFavorite ?? this.isFavorite,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Device &&
          id == other.id &&
          name == other.name &&
          roomId == other.roomId &&
          type == other.type &&
          isPoweredOn == other.isPoweredOn &&
          brightness == other.brightness &&
          colorHex == other.colorHex &&
          colorName == other.colorName &&
          targetTemp == other.targetTemp &&
          acMode == other.acMode &&
          fanSpeed == other.fanSpeed &&
          currentPowerWatts == other.currentPowerWatts &&
          isFavorite == other.isFavorite &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt;

  @override
  int get hashCode =>
      id.hashCode ^
      name.hashCode ^
      roomId.hashCode ^
      type.hashCode ^
      isPoweredOn.hashCode ^
      brightness.hashCode ^
      colorHex.hashCode ^
      colorName.hashCode ^
      targetTemp.hashCode ^
      acMode.hashCode ^
      fanSpeed.hashCode ^
      currentPowerWatts.hashCode ^
      isFavorite.hashCode ^
      createdAt.hashCode ^
      updatedAt.hashCode;

  @override
  String toString() =>
      'Device(id: $id, name: $name, type: $type, roomId: $roomId, isPoweredOn: $isPoweredOn, power: ${currentPowerWatts}W)';
}

