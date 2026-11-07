import 'package:flutter/material.dart';
import 'entities/device.dart';

export 'entities/device.dart' show DeviceType, AcMode, FanSpeed;

class DeviceModel {
  final String id;
  String name;
  String room;
  DeviceType type;
  bool isPoweredOn;
  int brightness; // 0 - 100
  String colorName;
  String colorHex;
  int targetTemp; // 16 - 30
  AcMode acMode;
  FanSpeed fanSpeed;
  bool isFavorite;

  DeviceModel({
    required this.id,
    required this.name,
    required this.room,
    required this.type,
    this.isPoweredOn = false,
    this.brightness = 72,
    this.colorName = 'Sıcak Günışığı (2700K)',
    this.colorHex = '#E1C1A0',
    this.targetTemp = 24,
    this.acMode = AcMode.auto,
    this.fanSpeed = FanSpeed.mid,
    this.isFavorite = false,
  });

  DeviceModel copyWith({
    String? name,
    String? room,
    DeviceType? type,
    bool? isPoweredOn,
    int? brightness,
    String? colorName,
    String? colorHex,
    int? targetTemp,
    AcMode? acMode,
    FanSpeed? fanSpeed,
    bool? isFavorite,
  }) {
    return DeviceModel(
      id: id,
      name: name ?? this.name,
      room: room ?? this.room,
      type: type ?? this.type,
      isPoweredOn: isPoweredOn ?? this.isPoweredOn,
      brightness: brightness ?? this.brightness,
      colorName: colorName ?? this.colorName,
      colorHex: colorHex ?? this.colorHex,
      targetTemp: targetTemp ?? this.targetTemp,
      acMode: acMode ?? this.acMode,
      fanSpeed: fanSpeed ?? this.fanSpeed,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }

  IconData get icon {
    switch (type) {
      case DeviceType.bulb:
        return Icons.lightbulb_outline_rounded;
      case DeviceType.ac:
        return Icons.thermostat_rounded;
      case DeviceType.plug:
        return Icons.power_outlined;
      case DeviceType.fan:
        return Icons.air_rounded;
      case DeviceType.tv:
        return Icons.tv_rounded;
    }
  }
}

