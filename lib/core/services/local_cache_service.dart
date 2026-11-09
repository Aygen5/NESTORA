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
///
/// Multi-user isolation: Every cache slot is strictly scoped to [userId] so that
/// different accounts (e.g. Demo vs. real Firebase users) never leak data to each other.
class LocalCacheService {
  final SharedPreferences? prefs;

  static const String _keyDevices = 'nestora_cached_devices_v1';
  static const String _keyRooms = 'nestora_cached_rooms_v1';
  static const String _keyProfile = 'nestora_cached_profile_v1';
  static const String _keyNotifications = 'nestora_cached_notifications_v1';

  LocalCacheService({this.prefs});

  String _devicesKey(String? userId) =>
      (userId != null && userId.trim().isNotEmpty)
          ? '${_keyDevices}_${userId.trim()}'
          : _keyDevices;

  String _roomsKey(String? userId) =>
      (userId != null && userId.trim().isNotEmpty)
          ? '${_keyRooms}_${userId.trim()}'
          : _keyRooms;

  String _profileKey(String? userId) =>
      (userId != null && userId.trim().isNotEmpty)
          ? '${_keyProfile}_${userId.trim()}'
          : _keyProfile;

  String _notificationsKey(String? userId) =>
      (userId != null && userId.trim().isNotEmpty)
          ? '${_keyNotifications}_${userId.trim()}'
          : _keyNotifications;

  // ==================== DEVICES ====================

  List<Device> loadDevices({String? userId}) {
    try {
      final key = _devicesKey(userId);
      final jsonStr = prefs?.getString(key);
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
    if (userId == null || userId.trim().isEmpty || userId.trim() == 'usr-1') {
      return List<Device>.from(SeedData.defaultDevices);
    }
    return <Device>[];
  }

  Future<void> saveDevices(List<Device> devices, {String? userId}) async {
    try {
      final key = _devicesKey(userId);
      final list = devices.map((d) => DeviceModel.fromEntity(d).toMap()).toList();
      await prefs?.setString(key, jsonEncode(list));
    } catch (e) {
      debugPrint('LocalCacheService: saveDevices error: $e');
    }
  }

  // ==================== ROOMS ====================

  List<Room> loadRooms({String? userId}) {
    try {
      final key = _roomsKey(userId);
      final jsonStr = prefs?.getString(key);
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
    if (userId == null || userId.trim().isEmpty || userId.trim() == 'usr-1') {
      return List<Room>.from(SeedData.defaultRooms);
    }
    return <Room>[];
  }

  Future<void> saveRooms(List<Room> rooms, {String? userId}) async {
    try {
      final key = _roomsKey(userId);
      final list = rooms.map((r) => RoomModel.fromEntity(r).toMap()).toList();
      await prefs?.setString(key, jsonEncode(list));
    } catch (e) {
      debugPrint('LocalCacheService: saveRooms error: $e');
    }
  }

  // ==================== PROFILE ====================

  UserProfile loadProfile({String? userId}) {
    try {
      final key = _profileKey(userId);
      final jsonStr = prefs?.getString(key);
      if (jsonStr != null && jsonStr.isNotEmpty) {
        final map = jsonDecode(jsonStr) as Map<String, dynamic>;
        final uid = map['uid'] as String? ?? userId ?? 'usr-1';
        return UserProfileModel.fromMap(map, uid: uid).toEntity();
      }
    } catch (e) {
      debugPrint('LocalCacheService: loadProfile error: $e');
    }
    if (userId != null && userId.trim().isNotEmpty && userId.trim() != 'usr-1') {
      return UserProfile(
        uid: userId.trim(),
        email: '',
        displayName: 'Nestora Kullanıcısı',
        roleTitle: 'Ev Sahibi',
        homeName: 'Evim',
        preferences: const UserPreferences(),
      );
    }
    return SeedData.defaultProfile;
  }

  Future<void> saveProfile(UserProfile profile, {String? userId}) async {
    try {
      final key = _profileKey(userId ?? profile.uid);
      final map = UserProfileModel.fromEntity(profile).toMap();
      await prefs?.setString(key, jsonEncode(map));
    } catch (e) {
      debugPrint('LocalCacheService: saveProfile error: $e');
    }
  }

  // ==================== NOTIFICATIONS ====================

  List<AppNotification> loadNotifications({String? userId}) {
    try {
      final key = _notificationsKey(userId);
      final jsonStr = prefs?.getString(key);
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
    if (userId == null || userId.trim().isEmpty || userId.trim() == 'usr-1') {
      return List<AppNotification>.from(SeedData.defaultNotifications);
    }
    return <AppNotification>[];
  }

  Future<void> saveNotifications(List<AppNotification> notifications, {String? userId}) async {
    try {
      final key = _notificationsKey(userId);
      final list = notifications
          .map((n) => NotificationModel.fromEntity(n).toMap())
          .toList();
      await prefs?.setString(key, jsonEncode(list));
    } catch (e) {
      debugPrint('LocalCacheService: saveNotifications error: $e');
    }
  }

  /// Completely purges user-specific cache on account deletion or test teardown.
  Future<void> clearUserCache(String userId) async {
    try {
      final cleanUid = userId.trim();
      if (cleanUid.isEmpty) return;
      await prefs?.remove(_devicesKey(cleanUid));
      await prefs?.remove(_roomsKey(cleanUid));
      await prefs?.remove(_profileKey(cleanUid));
      await prefs?.remove(_notificationsKey(cleanUid));
    } catch (e) {
      debugPrint('LocalCacheService: clearUserCache error: $e');
    }
  }
}
