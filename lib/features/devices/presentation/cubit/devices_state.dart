import 'package:flutter/foundation.dart';
import '../../domain/entities/device.dart';

/// Base state for [DevicesCubit].
@immutable
abstract class DevicesState {
  const DevicesState();
}

/// Initial uninitialized state.
class DevicesInitial extends DevicesState {
  const DevicesInitial();
}

/// Devices are loading from Firestore.
class DevicesLoading extends DevicesState {
  final String? message;
  const DevicesLoading({this.message});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DevicesLoading &&
          runtimeType == other.runtimeType &&
          message == other.message;

  @override
  int get hashCode => message.hashCode;
}

/// Single Source of Truth for all virtual smart devices across the app.
class DevicesLoaded extends DevicesState {
  final List<Device> devices;
  final DeviceType? selectedCategory;
  final String searchQuery;
  final bool isSaving;
  final String? feedbackMessage;
  final String? errorMessage;

  const DevicesLoaded({
    required this.devices,
    this.selectedCategory,
    this.searchQuery = '',
    this.isSaving = false,
    this.feedbackMessage,
    this.errorMessage,
  });

  /// Filtered list based on [selectedCategory] and [searchQuery].
  List<Device> get filteredDevices {
    var result = devices;
    if (selectedCategory != null) {
      result = result.where((d) => d.type == selectedCategory).toList();
    }
    final query = searchQuery.trim().toLowerCase();
    if (query.isNotEmpty) {
      result = result.where((d) => d.name.toLowerCase().contains(query)).toList();
    }
    return result;
  }

  /// All devices currently turned on.
  List<Device> get activeDevices =>
      devices.where((d) => d.isPoweredOn).toList();

  /// All favorite devices pinned for quick access.
  List<Device> get favoriteDevices =>
      devices.where((d) => d.isFavorite).toList();

  /// Devices associated with a specific [roomId].
  List<Device> getDevicesByRoom(String roomId) =>
      devices.where((d) => d.roomId == roomId.trim()).toList();

  /// Total count of devices in the home.
  int get totalCount => devices.length;

  /// Total count of active (powered-on) devices.
  int get activeCount => activeDevices.length;

  /// Total virtual power consumption across all active devices in Watts.
  double get totalPowerWatts =>
      activeDevices.fold(0.0, (sum, d) => sum + d.currentPowerWatts);

  /// Looks up a device by [deviceId], or returns null if not found.
  Device? findDeviceById(String deviceId) {
    try {
      return devices.firstWhere((d) => d.id == deviceId.trim());
    } catch (_) {
      return null;
    }
  }

  DevicesLoaded copyWith({
    List<Device>? devices,
    DeviceType? selectedCategory,
    bool clearCategory = false,
    String? searchQuery,
    bool? isSaving,
    String? feedbackMessage,
    String? errorMessage,
    bool clearFeedback = false,
    bool clearError = false,
    bool clearSearch = false,
  }) {
    return DevicesLoaded(
      devices: devices ?? this.devices,
      selectedCategory:
          clearCategory ? null : (selectedCategory ?? this.selectedCategory),
      searchQuery: clearSearch ? '' : (searchQuery ?? this.searchQuery),
      isSaving: isSaving ?? this.isSaving,
      feedbackMessage:
          clearFeedback ? null : (feedbackMessage ?? this.feedbackMessage),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DevicesLoaded &&
          runtimeType == other.runtimeType &&
          listEquals(devices, other.devices) &&
          selectedCategory == other.selectedCategory &&
          searchQuery == other.searchQuery &&
          isSaving == other.isSaving &&
          feedbackMessage == other.feedbackMessage &&
          errorMessage == other.errorMessage;

  @override
  int get hashCode =>
      devices.hashCode ^
      selectedCategory.hashCode ^
      searchQuery.hashCode ^
      isSaving.hashCode ^
      (feedbackMessage?.hashCode ?? 0) ^
      (errorMessage?.hashCode ?? 0);
}

/// Fatal error state when loading devices fails.
class DevicesError extends DevicesState {
  final String message;
  final String? code;

  const DevicesError(this.message, {this.code});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DevicesError &&
          runtimeType == other.runtimeType &&
          message == other.message &&
          code == other.code;

  @override
  int get hashCode => message.hashCode ^ (code?.hashCode ?? 0);
}
