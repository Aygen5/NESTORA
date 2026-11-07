import 'package:cloud_firestore/cloud_firestore.dart' hide Type;
import '../../../../core/utils/firestore_helpers.dart';
import '../../domain/entities/device.dart';

/// Data Transfer Object (DTO) for [Device] handling Cloud Firestore serialization.
class DeviceModel extends Device {
  const DeviceModel({
    required super.id,
    required super.name,
    required super.roomId,
    required super.type,
    super.isPoweredOn = false,
    super.brightness = 72,
    super.colorHex = '#E1C1A0',
    super.colorName = 'Sıcak Günışığı (2700K)',
    super.targetTemp = 24.0,
    super.acMode = AcMode.auto,
    super.fanSpeed = FanSpeed.mid,
    super.currentPowerWatts = 0.0,
    super.isFavorite = false,
    super.createdAt,
    super.updatedAt,
  });

  /// Factory creating a [DeviceModel] from a raw Firestore Map and document [id].
  factory DeviceModel.fromMap(
    Map<String, dynamic> map, {
    required String id,
  }) {
    return DeviceModel(
      id: id,
      name: FirestoreHelpers.parseString(map['name'], 'Cihaz'),
      roomId: FirestoreHelpers.parseString(
        map['roomId'] ?? map['room'],
        'room-1',
      ),
      type: DeviceType.fromString(map['type'] as String?),
      isPoweredOn: FirestoreHelpers.parseBool(
        map['isOn'] ?? map['isPoweredOn'],
        false,
      ),
      brightness: FirestoreHelpers.parseInt(map['brightness'], 72),
      colorHex: FirestoreHelpers.parseString(
        map['color'] ?? map['colorHex'],
        '#E1C1A0',
      ),
      colorName: FirestoreHelpers.parseString(
        map['colorName'],
        'Sıcak Günışığı (2700K)',
      ),
      targetTemp: FirestoreHelpers.parseDouble(
        map['targetTemperature'] ?? map['targetTemp'],
        24.0,
      ),
      acMode: AcMode.fromString(
        map['mode'] ?? map['acMode'] as String?,
      ),
      fanSpeed: FanSpeed.fromString(map['fanSpeed'] as String?),
      currentPowerWatts: FirestoreHelpers.parseDouble(
        map['currentPowerWatts'],
        0.0,
      ),
      isFavorite: FirestoreHelpers.parseBool(map['isFavorite'], false),
      createdAt: FirestoreHelpers.parseDateTime(map['createdAt']),
      updatedAt: FirestoreHelpers.parseDateTime(map['updatedAt']),
    );
  }

  /// Factory creating a [DeviceModel] from a Firestore [DocumentSnapshot].
  factory DeviceModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    return DeviceModel.fromMap(
      snapshot.data() ?? {},
      id: snapshot.id,
    );
  }

  /// Factory creating a [DeviceModel] from a pure domain [Device] entity.
  factory DeviceModel.fromEntity(Device device) {
    return DeviceModel(
      id: device.id,
      name: device.name,
      roomId: device.roomId,
      type: device.type,
      isPoweredOn: device.isPoweredOn,
      brightness: device.brightness,
      colorHex: device.colorHex,
      colorName: device.colorName,
      targetTemp: device.targetTemp,
      acMode: device.acMode,
      fanSpeed: device.fanSpeed,
      currentPowerWatts: device.currentPowerWatts,
      isFavorite: device.isFavorite,
      createdAt: device.createdAt,
      updatedAt: device.updatedAt,
    );
  }

  /// Converts this model into a Firestore write payload with [FieldValue.serverTimestamp].
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'roomId': roomId,
      'type': type.toShortString(),
      'isOn': isPoweredOn,
      'brightness': brightness,
      'color': colorHex,
      'colorName': colorName,
      'targetTemperature': targetTemp,
      'mode': acMode.toShortString(),
      'fanSpeed': fanSpeed.toShortString(),
      'currentPowerWatts': currentPowerWatts,
      'isFavorite': isFavorite,
      'createdAt': FirestoreHelpers.dateTimeToTimestamp(createdAt),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  /// Converts this model into a serializable standard Dart Map (e.g. for testing or local cache).
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'roomId': roomId,
      'type': type.toShortString(),
      'isOn': isPoweredOn,
      'brightness': brightness,
      'color': colorHex,
      'colorName': colorName,
      'targetTemperature': targetTemp,
      'mode': acMode.toShortString(),
      'fanSpeed': fanSpeed.toShortString(),
      'currentPowerWatts': currentPowerWatts,
      'isFavorite': isFavorite,
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
    };
  }

  /// Pure domain conversion.
  Device toEntity() => Device(
        id: id,
        name: name,
        roomId: roomId,
        type: type,
        isPoweredOn: isPoweredOn,
        brightness: brightness,
        colorHex: colorHex,
        colorName: colorName,
        targetTemp: targetTemp,
        acMode: acMode,
        fanSpeed: fanSpeed,
        currentPowerWatts: currentPowerWatts,
        isFavorite: isFavorite,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
}
