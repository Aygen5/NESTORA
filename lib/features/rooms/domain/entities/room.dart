/// Pure domain entity representing a room within the user's smart home.
/// Decoupled from external SDKs and UI frameworks.
class Room {
  final String id;
  final String name;
  final String iconName;
  final double targetTemperature;
  final int deviceCount;
  final int activeDeviceCount;
  final int humidity;
  final String? imageAsset;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Room({
    required this.id,
    required this.name,
    this.iconName = 'chair',
    this.targetTemperature = 22.0,
    this.deviceCount = 0,
    this.activeDeviceCount = 0,
    this.humidity = 50,
    this.imageAsset,
    this.createdAt,
    this.updatedAt,
  });

  Room copyWith({
    String? id,
    String? name,
    String? iconName,
    double? targetTemperature,
    int? deviceCount,
    int? activeDeviceCount,
    int? humidity,
    String? imageAsset,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Room(
      id: id ?? this.id,
      name: name ?? this.name,
      iconName: iconName ?? this.iconName,
      targetTemperature: targetTemperature ?? this.targetTemperature,
      deviceCount: deviceCount ?? this.deviceCount,
      activeDeviceCount: activeDeviceCount ?? this.activeDeviceCount,
      humidity: humidity ?? this.humidity,
      imageAsset: imageAsset ?? this.imageAsset,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Room &&
          id == other.id &&
          name == other.name &&
          iconName == other.iconName &&
          targetTemperature == other.targetTemperature &&
          deviceCount == other.deviceCount &&
          activeDeviceCount == other.activeDeviceCount &&
          humidity == other.humidity &&
          imageAsset == other.imageAsset &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt;

  @override
  int get hashCode =>
      id.hashCode ^
      name.hashCode ^
      iconName.hashCode ^
      targetTemperature.hashCode ^
      deviceCount.hashCode ^
      activeDeviceCount.hashCode ^
      humidity.hashCode ^
      imageAsset.hashCode ^
      createdAt.hashCode ^
      updatedAt.hashCode;

  @override
  String toString() =>
      'Room(id: $id, name: $name, iconName: $iconName, targetTemp: $targetTemperature°C, devices: $deviceCount, active: $activeDeviceCount)';
}

