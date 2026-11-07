import 'package:flutter/material.dart';
import '../features/devices/domain/device_model.dart';
import '../features/rooms/domain/room_model.dart';
import '../features/notifications/domain/notification_model.dart';

class AppState extends ChangeNotifier {
  // User Profile
  String userName = 'Aygen Yıldırım';
  String userEmail = 'aygenyildirim27@gmail.com';
  String homeName = "Aygen'in Evi";

  // Rooms
  late List<RoomModel> rooms;

  // Devices
  late List<DeviceModel> devices;

  // Notifications
  late List<NotificationModel> notifications;

  AppState() {
    _initData();
  }

  void _initData() {
    rooms = [
      RoomModel(
        id: 'room-1',
        name: 'Salon',
        type: 'Salon',
        icon: Icons.chair_rounded,
        deviceCount: 3,
        activeDeviceCount: 2,
        temperature: 22.4,
        humidity: 48,
        imageAsset: 'assets/screens/nestora_salon_oda_detay.png',
      ),
      RoomModel(
        id: 'room-2',
        name: 'Yatak Odası',
        type: 'Yatak Odası',
        icon: Icons.bed_rounded,
        deviceCount: 2,
        activeDeviceCount: 1,
        temperature: 24.0,
        humidity: 50,
        imageAsset: 'assets/screens/nestora_yatak_odas_klima_kontrol.png',
      ),
      RoomModel(
        id: 'room-3',
        name: 'Mutfak',
        type: 'Mutfak',
        icon: Icons.restaurant_rounded,
        deviceCount: 1,
        activeDeviceCount: 0,
        temperature: 21.8,
        humidity: 52,
        imageAsset: 'assets/screens/nestora_odalar_m.png',
      ),
      RoomModel(
        id: 'room-4',
        name: 'Çalışma Odası',
        type: 'Çalışma Odası',
        icon: Icons.desk_rounded,
        deviceCount: 1,
        activeDeviceCount: 1,
        temperature: 23.1,
        humidity: 45,
        imageAsset: 'assets/screens/nestora_ana_sayfa_dashboard.png',
      ),
    ];

    devices = [
      DeviceModel(
        id: 'dev-1',
        name: 'Salon Lambası',
        room: 'Salon',
        type: DeviceType.bulb,
        isPoweredOn: true,
        brightness: 72,
        colorName: 'Sıcak Günışığı (2700K)',
        colorHex: '#E1C1A0',
        isFavorite: true,
      ),
      DeviceModel(
        id: 'dev-2',
        name: 'Televizyon',
        room: 'Salon',
        type: DeviceType.tv,
        isPoweredOn: false,
        isFavorite: false,
      ),
      DeviceModel(
        id: 'dev-3',
        name: 'Akıllı Priz',
        room: 'Salon',
        type: DeviceType.plug,
        isPoweredOn: true,
        isFavorite: true,
      ),
      DeviceModel(
        id: 'dev-4',
        name: 'Masa Lambası',
        room: 'Çalışma Odası',
        type: DeviceType.bulb,
        isPoweredOn: true,
        brightness: 85,
        colorName: 'Doğal Beyaz (4000K)',
        colorHex: '#EAF0E6',
        isFavorite: true,
      ),
      DeviceModel(
        id: 'dev-5',
        name: 'Yatak Odası Kliması',
        room: 'Yatak Odası',
        type: DeviceType.ac,
        isPoweredOn: true,
        targetTemp: 24,
        acMode: AcMode.auto,
        fanSpeed: FanSpeed.mid,
        isFavorite: false,
      ),
      DeviceModel(
        id: 'dev-6',
        name: 'Komodin Lambası',
        room: 'Yatak Odası',
        type: DeviceType.bulb,
        isPoweredOn: true,
        brightness: 50,
        colorName: 'Gece Modu',
        colorHex: '#FEDDBB',
        isFavorite: false,
      ),
      DeviceModel(
        id: 'dev-7',
        name: 'Kahve Makinesi',
        room: 'Mutfak',
        type: DeviceType.plug,
        isPoweredOn: false,
        isFavorite: false,
      ),
    ];

    notifications = [
      NotificationModel(
        id: 'notif-1',
        title: 'Salon Lambası açıldı.',
        description: 'Salon ortamında parlaklık %72 olarak devreye girdi.',
        timeAgo: '5 dakika önce',
        isUnread: true,
        icon: Icons.lightbulb_rounded,
        iconBg: const Color(0xFFFEDDBB),
      ),
      NotificationModel(
        id: 'notif-2',
        title: 'Masa Lambası parlaklığı %85 olarak değiştirildi.',
        description: 'Çalışma Odası için odak aydınlatması güncellendi.',
        timeAgo: '24 dakika önce',
        isUnread: true,
        icon: Icons.tune_rounded,
        iconBg: const Color(0xFFDCE5D7),
      ),
      NotificationModel(
        id: 'notif-3',
        title: 'Yeni cihaz eklendi.',
        description: 'Yatak Odası Kliması başarıyla tanımlandı.',
        timeAgo: '2 saat önce',
        isUnread: true,
        icon: Icons.add_circle_outline_rounded,
        iconBg: const Color(0xFFD3E8D5),
      ),
      NotificationModel(
        id: 'notif-4',
        title: 'Yatak Odası Kliması için sıcaklık hedefi güncellendi.',
        description: 'Hedef sanal sıcaklık 24°C olarak ayarlandı.',
        timeAgo: 'Dün, 18:30',
        isUnread: false,
        icon: Icons.thermostat_rounded,
        iconBg: const Color(0xFFE4EAE1),
      ),
      NotificationModel(
        id: 'notif-5',
        title: 'Yeni oda oluşturuldu.',
        description: '‘Çalışma Odası’ listene dahil edildi.',
        timeAgo: 'Dün',
        isUnread: false,
        icon: Icons.meeting_room_outlined,
        iconBg: const Color(0xFFE4EAE1),
      ),
    ];
  }

  // Device Methods
  int get activeDeviceCount => devices.where((d) => d.isPoweredOn).length;

  DeviceModel get salonLamp =>
      devices.firstWhere((d) => d.id == 'dev-1', orElse: () => devices.first);

  DeviceModel get bedroomAc =>
      devices.firstWhere((d) => d.id == 'dev-5', orElse: () => devices.first);

  void toggleDevicePower(String id) {
    final idx = devices.indexWhere((d) => d.id == id);
    if (idx != -1) {
      devices[idx].isPoweredOn = !devices[idx].isPoweredOn;
      _syncRoomActiveCounts();
      notifyListeners();
    }
  }

  void setLampBrightness(String id, int val) {
    final idx = devices.indexWhere((d) => d.id == id);
    if (idx != -1) {
      devices[idx].brightness = val.clamp(1, 100);
      if (val > 0 && !devices[idx].isPoweredOn) {
        devices[idx].isPoweredOn = true;
      }
      _syncRoomActiveCounts();
      notifyListeners();
    }
  }

  void setLampColor(String id, String colorName, String colorHex) {
    final idx = devices.indexWhere((d) => d.id == id);
    if (idx != -1) {
      devices[idx].colorName = colorName;
      devices[idx].colorHex = colorHex;
      notifyListeners();
    }
  }

  void setAcTargetTemp(String id, int temp) {
    final idx = devices.indexWhere((d) => d.id == id);
    if (idx != -1) {
      devices[idx].targetTemp = temp.clamp(16, 30);
      notifyListeners();
    }
  }

  void setAcMode(String id, AcMode mode) {
    final idx = devices.indexWhere((d) => d.id == id);
    if (idx != -1) {
      devices[idx].acMode = mode;
      notifyListeners();
    }
  }

  void setAcFanSpeed(String id, FanSpeed speed) {
    final idx = devices.indexWhere((d) => d.id == id);
    if (idx != -1) {
      devices[idx].fanSpeed = speed;
      notifyListeners();
    }
  }

  void toggleFavorite(String id) {
    final idx = devices.indexWhere((d) => d.id == id);
    if (idx != -1) {
      devices[idx].isFavorite = !devices[idx].isFavorite;
      notifyListeners();
    }
  }

  void addDevice(DeviceModel newDevice) {
    devices.insert(0, newDevice);
    _syncRoomActiveCounts();
    notifications.insert(
      0,
      NotificationModel(
        id: 'notif-${DateTime.now().millisecondsSinceEpoch}',
        title: 'Yeni cihaz eklendi.',
        description: '${newDevice.name} başarıyla ${newDevice.room} odasına tanımlandı.',
        timeAgo: 'Şimdi',
        isUnread: true,
        icon: Icons.add_circle_outline_rounded,
        iconBg: const Color(0xFFD3E8D5),
      ),
    );
    notifyListeners();
  }

  void deleteDevice(String id) {
    devices.removeWhere((d) => d.id == id);
    _syncRoomActiveCounts();
    notifyListeners();
  }

  // Room Methods
  void addRoom(RoomModel room) {
    rooms.add(room);
    notifications.insert(
      0,
      NotificationModel(
        id: 'notif-${DateTime.now().millisecondsSinceEpoch}',
        title: 'Yeni oda oluşturuldu.',
        description: '‘${room.name}’ listene dahil edildi.',
        timeAgo: 'Şimdi',
        isUnread: true,
        icon: Icons.meeting_room_outlined,
        iconBg: const Color(0xFFE4EAE1),
      ),
    );
    notifyListeners();
  }

  void deleteRoom(String id) {
    rooms.removeWhere((r) => r.id == id);
    notifyListeners();
  }

  void toggleAllInRoom(String roomName, bool powerState) {
    for (final dev in devices) {
      if (dev.room == roomName) {
        dev.isPoweredOn = powerState;
      }
    }
    _syncRoomActiveCounts();
    notifyListeners();
  }

  // Notification Methods
  int get unreadNotificationCount =>
      notifications.where((n) => n.isUnread).length;

  void markAllNotificationsAsRead() {
    for (final n in notifications) {
      n.isUnread = false;
    }
    notifyListeners();
  }

  void markNotificationAsRead(String id) {
    final idx = notifications.indexWhere((n) => n.id == id);
    if (idx != -1) {
      notifications[idx].isUnread = false;
      notifyListeners();
    }
  }

  void _syncRoomActiveCounts() {
    for (final room in rooms) {
      final roomDevices = devices.where((d) => d.room == room.name).toList();
      room.deviceCount = roomDevices.length;
      room.activeDeviceCount = roomDevices.where((d) => d.isPoweredOn).length;
    }
  }
}

class AppStateScope extends InheritedNotifier<AppState> {
  const AppStateScope({
    super.key,
    required AppState super.notifier,
    required super.child,
  });

  static AppState of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppStateScope>();
    assert(scope != null, 'No AppStateScope found in context');
    return scope!.notifier!;
  }
}

