import 'package:flutter/material.dart';

import '../../features/devices/domain/device_model.dart';
import '../../features/devices/domain/entities/device.dart';
import '../../features/notifications/domain/entities/app_notification.dart';
import '../../features/notifications/domain/notification_model.dart';
import '../../features/profile/domain/entities/user_profile.dart';
import '../../features/rooms/domain/entities/room.dart';
import '../../features/rooms/domain/room_model.dart';

/// Centralized seed data for Nestora smart home simulation.
/// Used for initial state fallbacks, demo accounts, and testing.
abstract class SeedData {
  static final UserProfile defaultProfile = UserProfile(
    uid: 'usr-1',
    displayName: 'Aygen Yıldırım',
    email: 'aygenyildirim27@gmail.com',
    homeName: "Aygen'in Evi",
    roleTitle: 'Ev Sahibi',
    photoPath: 'assets/profile/user_avatar.jpg',
    preferences: const UserPreferences(
      notificationsEnabled: true,
      ecoModeEnabled: true,
      temperatureUnit: 'C',
    ),
    createdAt: DateTime.now(),
  );

  static final List<Room> defaultRooms = [
    const Room(
      id: 'room-1',
      name: 'Salon',
      iconName: 'chair',
      targetTemperature: 22.4,
      deviceCount: 3,
      activeDeviceCount: 2,
      humidity: 48,
      imageAsset: 'assets/rooms/salon.jpg',
    ),
    const Room(
      id: 'room-2',
      name: 'Yatak Odası',
      iconName: 'bed',
      targetTemperature: 24.0,
      deviceCount: 2,
      activeDeviceCount: 1,
      humidity: 50,
      imageAsset: 'assets/rooms/yatak_odasi.jpg',
    ),
    const Room(
      id: 'room-3',
      name: 'Mutfak',
      iconName: 'restaurant',
      targetTemperature: 21.8,
      deviceCount: 1,
      activeDeviceCount: 0,
      humidity: 52,
      imageAsset: 'assets/rooms/mutfak.jpg',
    ),
    const Room(
      id: 'room-4',
      name: 'Çalışma Odası',
      iconName: 'desk',
      targetTemperature: 23.1,
      deviceCount: 1,
      activeDeviceCount: 1,
      humidity: 45,
      imageAsset: 'assets/rooms/calisma_odasi.jpg',
    ),
  ];

  /// Returns a curated modern room photography asset matching the given room name,
  /// or null if it is a completely novel custom room.
  static String? getSmartRoomAsset(String roomName) {
    final lower = roomName.toLowerCase();
    if (lower.contains('salon') || lower.contains('oturma')) return 'assets/rooms/salon.jpg';
    if (lower.contains('yatak')) return 'assets/rooms/yatak_odasi.jpg';
    if (lower.contains('mutfak')) return 'assets/rooms/mutfak.jpg';
    if (lower.contains('çalışma') || lower.contains('calisma') || lower.contains('ofis')) {
      return 'assets/rooms/calisma_odasi.jpg';
    }
    if (lower.contains('banyo')) return 'assets/rooms/banyo.jpg';
    if (lower.contains('balkon') || lower.contains('teras')) return 'assets/rooms/balkon.jpg';
    return null;
  }

  static final List<Device> defaultDevices = [
    const Device(
      id: 'dev-1',
      name: 'Salon Lambası',
      roomId: 'room-1',
      type: DeviceType.bulb,
      isPoweredOn: true,
      brightness: 72,
      colorName: 'Sıcak Günışığı (2700K)',
      colorHex: '#E1C1A0',
      isFavorite: true,
      currentPowerWatts: 12.0,
    ),
    const Device(
      id: 'dev-2',
      name: 'Televizyon',
      roomId: 'room-1',
      type: DeviceType.tv,
      isPoweredOn: false,
      isFavorite: false,
      currentPowerWatts: 0.0,
    ),
    const Device(
      id: 'dev-3',
      name: 'Akıllı Priz',
      roomId: 'room-1',
      type: DeviceType.plug,
      isPoweredOn: true,
      isFavorite: true,
      currentPowerWatts: 120.0,
    ),
    const Device(
      id: 'dev-4',
      name: 'Masa Lambası',
      roomId: 'room-4',
      type: DeviceType.bulb,
      isPoweredOn: true,
      brightness: 85,
      colorName: 'Doğal Beyaz (4000K)',
      colorHex: '#EAF0E6',
      isFavorite: true,
      currentPowerWatts: 15.0,
    ),
    const Device(
      id: 'dev-5',
      name: 'Yatak Odası Kliması',
      roomId: 'room-2',
      type: DeviceType.ac,
      isPoweredOn: true,
      targetTemp: 24.0,
      acMode: AcMode.auto,
      fanSpeed: FanSpeed.mid,
      isFavorite: false,
      currentPowerWatts: 850.0,
    ),
    const Device(
      id: 'dev-6',
      name: 'Komodin Lambası',
      roomId: 'room-2',
      type: DeviceType.bulb,
      isPoweredOn: true,
      brightness: 50,
      colorName: 'Gece Modu',
      colorHex: '#FEDDBB',
      isFavorite: false,
      currentPowerWatts: 8.0,
    ),
    const Device(
      id: 'dev-7',
      name: 'Kahve Makinesi',
      roomId: 'room-3',
      type: DeviceType.plug,
      isPoweredOn: false,
      isFavorite: false,
      currentPowerWatts: 0.0,
    ),
    const Device(
      id: 'dev-8',
      name: 'Giriş Güvenlik Kamerası',
      roomId: 'room-5',
      type: DeviceType.security,
      isPoweredOn: true,
      isFavorite: false,
      currentPowerWatts: 4.5,
    ),
  ];

  static final List<AppNotification> defaultNotifications = [
    AppNotification(
      id: 'notif-1',
      title: 'Salon Lambası açıldı.',
      message: 'Salon ortamında parlaklık %72 olarak devreye girdi.',
      type: NotificationType.device,
      isRead: false,
      relatedRoomId: 'room-1',
      relatedDeviceId: 'dev-1',
      createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
    ),
    AppNotification(
      id: 'notif-2',
      title: 'Masa Lambası parlaklığı %85 olarak değiştirildi.',
      message: 'Çalışma Odası için odak aydınlatması güncellendi.',
      type: NotificationType.device,
      isRead: false,
      relatedRoomId: 'room-4',
      relatedDeviceId: 'dev-2',
      createdAt: DateTime.now().subtract(const Duration(minutes: 24)),
    ),
    AppNotification(
      id: 'notif-3',
      title: 'Yeni cihaz eklendi.',
      message: 'Yatak Odası Kliması başarıyla tanımlandı.',
      type: NotificationType.device,
      isRead: false,
      relatedRoomId: 'room-2',
      relatedDeviceId: 'dev-5',
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    AppNotification(
      id: 'notif-4',
      title: 'Yatak Odası Kliması için sıcaklık hedefi güncellendi.',
      message: 'Hedef sanal sıcaklık 24°C olarak ayarlandı.',
      type: NotificationType.device,
      isRead: true,
      relatedRoomId: 'room-2',
      relatedDeviceId: 'dev-5',
      createdAt: DateTime.now().subtract(const Duration(days: 1, hours: 2)),
    ),
    AppNotification(
      id: 'notif-5',
      title: 'Yeni oda oluşturuldu.',
      message: '‘Çalışma Odası’ listene dahil edildi.',
      type: NotificationType.device,
      isRead: true,
      relatedRoomId: 'room-4',
      createdAt: DateTime.now().subtract(const Duration(days: 1, hours: 5)),
    ),
    AppNotification(
      id: 'notif-6',
      title: 'Sanal güvenlik kontrolü tamamlandı.',
      message: 'Tüm sanal kapılar, pencereler ve sensörler güvenli durumda.',
      type: NotificationType.security,
      isRead: true,
      relatedRoomId: 'room-5',
      relatedDeviceId: 'dev-8',
      createdAt: DateTime.now().subtract(const Duration(days: 4)),
    ),
    AppNotification(
      id: 'notif-7',
      title: 'Haftalık enerji özeti hazırlandı.',
      message: 'Geçen hafta toplam 48,2 kWh sanal enerji tasarrufu sağlandı.',
      type: NotificationType.eco,
      isRead: true,
      createdAt: DateTime.now().subtract(const Duration(days: 6)),
    ),
  ];

  /// UI prototype model representations
  static List<RoomModel> get defaultRoomModels =>
      defaultRooms.map(roomToModel).toList();

  static List<DeviceModel> get defaultDeviceModels =>
      defaultDevices.map(deviceToModel).toList();

  static List<NotificationModel> get defaultNotificationModels =>
      defaultNotifications.map(notificationToModel).toList();

  static RoomModel roomToModel(Room room) {
    IconData icon;
    switch (room.iconName) {
      case 'bed':
        icon = Icons.bed_rounded;
        break;
      case 'restaurant':
        icon = Icons.restaurant_rounded;
        break;
      case 'desk':
        icon = Icons.desk_rounded;
        break;
      case 'chair':
      default:
        icon = Icons.chair_rounded;
        break;
    }
    return RoomModel(
      id: room.id,
      name: room.name,
      type: room.name,
      icon: icon,
      deviceCount: room.deviceCount,
      activeDeviceCount: room.activeDeviceCount,
      temperature: room.targetTemperature,
      humidity: room.humidity,
      imageAsset: room.imageAsset,
    );
  }

  static DeviceModel deviceToModel(Device device) {
    String roomName = 'Salon';
    if (device.roomId == 'room-2') roomName = 'Yatak Odası';
    if (device.roomId == 'room-3') roomName = 'Mutfak';
    if (device.roomId == 'room-4') roomName = 'Çalışma Odası';
    if (device.roomId == 'room-5') roomName = 'Giriş / Dış';

    return DeviceModel(
      id: device.id,
      roomId: device.roomId,
      name: device.name,
      room: roomName,
      type: device.type,
      isPoweredOn: device.isPoweredOn,
      brightness: device.brightness,
      colorName: device.colorName,
      colorHex: device.colorHex,
      targetTemp: device.targetTemp,
      acMode: device.acMode,
      fanSpeed: device.fanSpeed,
      isFavorite: device.isFavorite,
      currentPowerWatts: device.currentPowerWatts,
    );
  }

  static NotificationModel notificationToModel(AppNotification notif) {
    IconData icon = Icons.notifications_rounded;
    Color iconBg = const Color(0xFFDCE5D7);

    if (notif.title.contains('Lamba') || notif.title.contains('parlaklığı')) {
      icon = Icons.lightbulb_rounded;
      iconBg = const Color(0xFFFEDDBB);
    } else if (notif.title.contains('Klima') || notif.title.contains('sıcaklık')) {
      icon = Icons.thermostat_rounded;
      iconBg = const Color(0xFFE4EAE1);
    } else if (notif.title.contains('Yeni cihaz') || notif.title.contains('Priz')) {
      icon = Icons.add_circle_outline_rounded;
      iconBg = const Color(0xFFD3E8D5);
    } else if (notif.title.contains('Yeni oda') || notif.title.contains('oda')) {
      icon = Icons.meeting_room_outlined;
      iconBg = const Color(0xFFE4EAE1);
    } else if (notif.type == NotificationType.security) {
      icon = Icons.security_rounded;
      iconBg = const Color(0xFFFDE8E8);
    } else if (notif.type == NotificationType.eco) {
      icon = Icons.eco_rounded;
      iconBg = const Color(0xFFE0F2E9);
    }

    return NotificationModel(
      id: notif.id,
      title: notif.title,
      description: notif.message,
      timeAgo: notif.timeAgoFormatted,
      isUnread: !notif.isRead,
      icon: icon,
      iconBg: iconBg,
      createdAt: notif.createdAt,
      relatedRoomId: notif.relatedRoomId,
      relatedDeviceId: notif.relatedDeviceId,
      type: notif.type,
    );
  }
}
