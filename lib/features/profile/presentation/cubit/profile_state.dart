import 'package:flutter/foundation.dart';
import '../../domain/entities/user_profile.dart';

/// Base state for [ProfileCubit].
@immutable
abstract class ProfileState {
  const ProfileState();
}

/// Initial uninitialized profile state.
class ProfileInitial extends ProfileState {
  const ProfileInitial();
}

/// Profile is actively loading from Firestore or local cache.
class ProfileLoading extends ProfileState {
  final String? message;
  const ProfileLoading({this.message});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProfileLoading &&
          runtimeType == other.runtimeType &&
          message == other.message;

  @override
  int get hashCode => message.hashCode;
}

/// Profile loaded and active, containing full user details and preferences.
class ProfileLoaded extends ProfileState {
  final UserProfile profile;
  final bool isSaving;
  final String? feedbackMessage;
  final String? errorMessage;

  const ProfileLoaded({
    required this.profile,
    this.isSaving = false,
    this.feedbackMessage,
    this.errorMessage,
  });

  ProfileLoaded copyWith({
    UserProfile? profile,
    bool? isSaving,
    String? feedbackMessage,
    String? errorMessage,
    bool clearFeedback = false,
    bool clearError = false,
  }) {
    return ProfileLoaded(
      profile: profile ?? this.profile,
      isSaving: isSaving ?? this.isSaving,
      feedbackMessage:
          clearFeedback ? null : (feedbackMessage ?? this.feedbackMessage),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProfileLoaded &&
          runtimeType == other.runtimeType &&
          profile == other.profile &&
          isSaving == other.isSaving &&
          feedbackMessage == other.feedbackMessage &&
          errorMessage == other.errorMessage;

  @override
  int get hashCode =>
      profile.hashCode ^
      isSaving.hashCode ^
      (feedbackMessage?.hashCode ?? 0) ^
      (errorMessage?.hashCode ?? 0);
}

/// An unrecoverable error occurred while loading profile.
class ProfileError extends ProfileState {
  final String message;
  final String? code;

  const ProfileError(this.message, {this.code});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProfileError &&
          runtimeType == other.runtimeType &&
          message == other.message &&
          code == other.code;

  @override
  int get hashCode => message.hashCode ^ (code?.hashCode ?? 0);
}
