import 'package:flutter/foundation.dart';
import '../../domain/entities/room.dart';

/// Base state for [RoomsCubit].
@immutable
abstract class RoomsState {
  const RoomsState();
}

/// Initial uninitialized state.
class RoomsInitial extends RoomsState {
  const RoomsInitial();
}

/// Rooms are loading from Firestore.
class RoomsLoading extends RoomsState {
  final String? message;
  const RoomsLoading({this.message});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RoomsLoading &&
          runtimeType == other.runtimeType &&
          message == other.message;

  @override
  int get hashCode => message.hashCode;
}

/// Rooms successfully loaded, supporting real-time sync, search filtering,
/// and in-flight saving states.
class RoomsLoaded extends RoomsState {
  final List<Room> rooms;
  final String searchQuery;
  final bool isSaving;
  final String? feedbackMessage;
  final String? errorMessage;

  const RoomsLoaded({
    required this.rooms,
    this.searchQuery = '',
    this.isSaving = false,
    this.feedbackMessage,
    this.errorMessage,
  });

  /// Filtered rooms based on [searchQuery].
  List<Room> get filteredRooms {
    final query = searchQuery.trim().toLowerCase();
    if (query.isEmpty) return rooms;
    return rooms.where((r) => r.name.toLowerCase().contains(query)).toList();
  }

  /// Total count of rooms.
  int get totalRooms => rooms.length;

  /// Total count of devices configured across all rooms.
  int get totalDevices => rooms.fold(0, (sum, r) => sum + r.deviceCount);

  /// Total count of currently active devices across all rooms.
  int get totalActiveDevices =>
      rooms.fold(0, (sum, r) => sum + r.activeDeviceCount);

  /// Looks up a room by its [roomId], or returns null if not found.
  Room? findRoomById(String roomId) {
    try {
      return rooms.firstWhere((r) => r.id == roomId);
    } catch (_) {
      return null;
    }
  }

  RoomsLoaded copyWith({
    List<Room>? rooms,
    String? searchQuery,
    bool? isSaving,
    String? feedbackMessage,
    String? errorMessage,
    bool clearFeedback = false,
    bool clearError = false,
    bool clearSearch = false,
  }) {
    return RoomsLoaded(
      rooms: rooms ?? this.rooms,
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
      other is RoomsLoaded &&
          runtimeType == other.runtimeType &&
          listEquals(rooms, other.rooms) &&
          searchQuery == other.searchQuery &&
          isSaving == other.isSaving &&
          feedbackMessage == other.feedbackMessage &&
          errorMessage == other.errorMessage;

  @override
  int get hashCode =>
      rooms.hashCode ^
      searchQuery.hashCode ^
      isSaving.hashCode ^
      (feedbackMessage?.hashCode ?? 0) ^
      (errorMessage?.hashCode ?? 0);
}

/// Fatal error state when loading rooms from Firestore fails.
class RoomsError extends RoomsState {
  final String message;
  final String? code;

  const RoomsError(this.message, {this.code});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RoomsError &&
          runtimeType == other.runtimeType &&
          message == other.message &&
          code == other.code;

  @override
  int get hashCode => message.hashCode ^ (code?.hashCode ?? 0);
}
