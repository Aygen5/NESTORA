import 'package:flutter/material.dart';

class RoomModel {
  final String id;
  String name;
  String type;
  IconData icon;
  int deviceCount;
  int activeDeviceCount;
  double temperature;
  int humidity;
  String? imageAsset;

  RoomModel({
    required this.id,
    required this.name,
    required this.type,
    required this.icon,
    required this.deviceCount,
    required this.activeDeviceCount,
    this.temperature = 22.4,
    this.humidity = 48,
    this.imageAsset,
  });

  RoomModel copyWith({
    String? name,
    String? type,
    IconData? icon,
    int? deviceCount,
    int? activeDeviceCount,
    double? temperature,
    int? humidity,
    String? imageAsset,
  }) {
    return RoomModel(
      id: id,
      name: name ?? this.name,
      type: type ?? this.type,
      icon: icon ?? this.icon,
      deviceCount: deviceCount ?? this.deviceCount,
      activeDeviceCount: activeDeviceCount ?? this.activeDeviceCount,
      temperature: temperature ?? this.temperature,
      humidity: humidity ?? this.humidity,
      imageAsset: imageAsset ?? this.imageAsset,
    );
  }
}

