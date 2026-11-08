import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/devices/data/models/device_model.dart';
import '../../features/devices/domain/entities/device.dart';
import '../../features/notifications/data/models/notification_model.dart';
import '../../features/notifications/domain/entities/app_notification.dart';
import '../../features/profile/data/models/user_profile_model.dart';
import '../../features/profile/domain/entities/user_profile.dart';
import '../../features/rooms/data/models/room_model.dart';
import '../../features/rooms/domain/entities/room.dart';
import '../constants/seed_data.dart';

/// Centralized local persistent cache service for Nestora simulation state.
/// Ensures that even in offline, demo, or unauthenticated modes, all devices,
/// rooms, profiles, and notifications are 100% interactive, never get locked out,
/// and preserve state across app hot-reloads and restarts.
class LocalCacheService {
  final SharedPreferences? prefs;

  static const String _keyDevices = 'nestora_cached_devices_v1';
  static const String _keyRooms = 'nestora_cached_rooms_v1';
  static const String _keyProfile = 'nestora_cached_profile_v1';
  static const String _keyNotifications = 'nestora_cached_notifications_v1';

  LocalCacheService({this.prefs});

  // ==================== DEVICES ====================

  List<Device> loadDevices() {
    try {
      final jsonStr = prefs?.getString(_keyDevices);
      if (jsonStr != null && jsonStr.isNotEmpty) {
        final List<dynamic> list = jsonDecode(jsonStr) as List<dynamic>;
        final devices = list.map((item) {
          final map = item as Map<String, dynamic>;
          final id = map['id'] as String? ?? 'dev-unknown';
          return DeviceModel.fromMap(map, id: id).toEntity();
        }).toList();
        if (devices.isNotEmpty) return devices;
      }
    } catch (e) {
      debugPrint('LocalCacheService: loadDevices error: $e');
    }
    return List<Device>.from(SeedData.defaultDevices);
  }

  Future<void> saveDevices(List<Device> devices) async {
    try {
      final list = devices.map((d) => DeviceModel.fromEntity(d).toMap()).toList();
      await prefs?.setString(_keyDevices, jsonEncode(list));
    } catch (e) {
      debugPrint('LocalCacheService: saveDevices error: $e');
    }
  }

  // ==================== ROOMS ====================

  List<Room> loadRooms() {
    try {
      final jsonStr = prefs?.getString(_keyRooms);
      if (jsonStr != null && jsonStr.isNotEmpty) {
        final List<dynamic> list = jsonDecode(jsonStr) as List<dynamic>;
        final rooms = list.map((item) {
          final map = item as Map<String, dynamic>;
          final id = map['id'] as String? ?? 'room-unknown';
          return RoomModel.fromMap(map, id: id).toEntity();
        }).toList();
        if (rooms.isNotEmpty) return rooms;
      }
    } catch (e) {
      debugPrint('LocalCacheService: loadRooms error: $e');
    }
    return List<Room>.from(SeedData.defaultRooms);
  }

  Future<void> saveRooms(List<Room> rooms) async {
    try {
      final list = rooms.map((r) => RoomModel.fromEntity(r).toMap()).toList();
      await prefs?.setString(_keyRooms, jsonEncode(list));
    } catch (e) {
      debugPrint('LocalCacheService: saveRooms error: $e');
    }
  }

  // ==================== PROFILE ====================

  UserProfile loadProfile() {
    try {
      final jsonStr = prefs?.getString(_keyProfile);
      if (jsonStr != null && jsonStr.isNotEmpty) {
        final map = jsonDecode(jsonStr) as Map<String, dynamic>;
        final uid = map['uid'] as String? ?? 'usr-1';
        return UserProfileModel.fromMap(map, uid: uid).toEntity();
      }
    } catch (e) {
      debugPrint('LocalCacheService: loadProfile error: $e');
    }
    return SeedData.defaultProfile;
  }

  Future<void> saveProfile(UserProfile profile) async {
    try {
      final map = UserProfileModel.fromEntity(profile).toMap();
      await prefs?.setString(_keyProfile, jsonEncode(map));
    } catch (e) {
      debugPrint('LocalCacheService: saveProfile error: $e');
    }
  }

  // ==================== NOTIFICATIONS ====================

  List<AppNotification> loadNotifications() {
    try {
      final jsonStr = prefs?.getString(_keyNotifications);
      if (jsonStr != null && jsonStr.isNotEmpty) {
        final List<dynamic> list = jsonDecode(jsonStr) as List<dynamic>;
        final notifs = list.map((item) {
          final map = item as Map<String, dynamic>;
          final id = map['id'] as String? ?? 'notif-unknown';
          return NotificationModel.fromMap(map, id: id).toEntity();
        }).toList();
        if (notifs.isNotEmpty) return notifs;
      }
    } catch (e) {
      debugPrint('LocalCacheService: loadNotifications error: $e');
    }
    return List<AppNotification>.from(SeedData.defaultNotifications);
  }

  Future<void> saveNotifications(List<AppNotification> notifications) async {
    try {
      final list = notifications
          .map((n) => NotificationModel.fromEntity(n).toMap())
          .toList();
      await prefs?.setString(_keyNotifications, jsonEncode(list));
    } catch (e) {
      debugPrint('LocalCacheService: saveNotifications error: $e');
    }
  }
}
