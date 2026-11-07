import '../errors/failures.dart';

/// A lightweight, robust and type-safe monadic Result type for repository & data layer operations.
/// Prevents throwing exceptions across architectural boundaries without requiring heavy external FP packages.
class Result<T> {
  final T? _data;
  final Failure? _failure;

  const Result._({this._data, this._failure});

  /// Creates a successful Result containing [data].
  factory Result.success(T data) => Result._(data: data);

  /// Creates a failed Result containing [failure].
  factory Result.failure(Failure failure) => Result._(failure: failure);

  /// Returns true if this instance represents a successful operation.
  bool get isSuccess => _failure == null;

  /// Returns true if this instance represents a failed operation.
  bool get isFailure => _failure != null;

  /// Retrieves the success data. Throws [StateError] if this result is a failure.
  T get data {
    if (_failure != null) {
      throw StateError('Cannot get data from a failed Result: $_failure');
    }
    return _data as T;
  }

  /// Retrieves the failure. Throws [StateError] if this result is a success.
  Failure get failure {
    if (_failure == null) {
      throw StateError('Cannot get failure from a successful Result');
    }
    return _failure;
  }

  /// Returns data if success, or null if failure.
  T? get dataOrNull => _data;

  /// Returns failure if failed, or null if success.
  Failure? get failureOrNull => _failure;

  /// Pattern-matching folding function for clean handling in Cubits/UI.
  R when<R>({
    required R Function(T data) success,
    required R Function(Failure failure) failure,
  }) {
    if (isSuccess) {
      return success(data);
    } else {
      return failure(this.failure);
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Result<T> &&
          runtimeType == other.runtimeType &&
          _data == other._data &&
          _failure == other._failure;

  @override
  int get hashCode => (_data?.hashCode ?? 0) ^ (_failure?.hashCode ?? 0);

  @override
  String toString() {
    if (isSuccess) {
      return 'Result.success($data)';
    } else {
      return 'Result.failure($failure)';
    }
  }
}
