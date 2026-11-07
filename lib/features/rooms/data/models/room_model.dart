import 'package:cloud_firestore/cloud_firestore.dart' hide Type;
import '../../../../core/utils/firestore_helpers.dart';
import '../../domain/entities/room.dart';

/// Data Transfer Object (DTO) for [Room] handling Cloud Firestore serialization.
class RoomModel extends Room {
  const RoomModel({
    required super.id,
    required super.name,
    super.iconName = 'chair',
    super.targetTemperature = 22.0,
    super.deviceCount = 0,
    super.activeDeviceCount = 0,
    super.humidity = 50,
    super.imageAsset,
    super.createdAt,
    super.updatedAt,
  });

  /// Factory creating a [RoomModel] from a raw Firestore Map and document [id].
  factory RoomModel.fromMap(
    Map<String, dynamic> map, {
    required String id,
  }) {
    return RoomModel(
      id: id,
      name: FirestoreHelpers.parseString(map['name'], 'Oda'),
      iconName: FirestoreHelpers.parseString(
        map['icon'] ?? map['iconName'],
        'chair',
      ),
      targetTemperature: FirestoreHelpers.parseDouble(
        map['targetTemperature'],
        22.0,
      ),
      deviceCount: FirestoreHelpers.parseInt(map['deviceCount'], 0),
      activeDeviceCount: FirestoreHelpers.parseInt(map['activeDeviceCount'], 0),
      humidity: FirestoreHelpers.parseInt(map['humidity'], 50),
      imageAsset: map['imageAsset'] as String?,
      createdAt: FirestoreHelpers.parseDateTime(map['createdAt']),
      updatedAt: FirestoreHelpers.parseDateTime(map['updatedAt']),
    );
  }

  /// Factory creating a [RoomModel] from a Firestore [DocumentSnapshot].
  factory RoomModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    return RoomModel.fromMap(
      snapshot.data() ?? {},
      id: snapshot.id,
    );
  }

  /// Factory creating a [RoomModel] from a pure domain [Room] entity.
  factory RoomModel.fromEntity(Room room) {
    return RoomModel(
      id: room.id,
      name: room.name,
      iconName: room.iconName,
      targetTemperature: room.targetTemperature,
      deviceCount: room.deviceCount,
      activeDeviceCount: room.activeDeviceCount,
      humidity: room.humidity,
      imageAsset: room.imageAsset,
      createdAt: room.createdAt,
      updatedAt: room.updatedAt,
    );
  }

  /// Converts this model into a Firestore write payload with [FieldValue.serverTimestamp].
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'icon': iconName,
      'targetTemperature': targetTemperature,
      'deviceCount': deviceCount,
      'activeDeviceCount': activeDeviceCount,
      'humidity': humidity,
      if (imageAsset != null) 'imageAsset': imageAsset,
      'createdAt': FirestoreHelpers.dateTimeToTimestamp(createdAt),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  /// Converts this model into a serializable standard Dart Map (e.g. for testing or local cache).
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'icon': iconName,
      'targetTemperature': targetTemperature,
      'deviceCount': deviceCount,
      'activeDeviceCount': activeDeviceCount,
      'humidity': humidity,
      if (imageAsset != null) 'imageAsset': imageAsset,
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
    };
  }

  /// Pure domain conversion.
  Room toEntity() => Room(
        id: id,
        name: name,
        iconName: iconName,
        targetTemperature: targetTemperature,
        deviceCount: deviceCount,
        activeDeviceCount: activeDeviceCount,
        humidity: humidity,
        imageAsset: imageAsset,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
}
