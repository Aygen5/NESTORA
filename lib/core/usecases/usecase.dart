import '../utils/result.dart';

/// Base contract for all asynchronous Use Cases with parameters.
/// [T] is the successful result type, [Params] is the parameter object.
abstract class UseCase<T, Params> {
  Future<Result<T>> call(Params params);
}

/// Base contract for asynchronous Use Cases without parameters.
abstract class NoParamsUseCase<T> {
  Future<Result<T>> call();
}

/// Base contract for streaming Use Cases with parameters.
abstract class StreamUseCase<T, Params> {
  Stream<T> call(Params params);
}

/// Base contract for streaming Use Cases without parameters.
abstract class NoParamsStreamUseCase<T> {
  Stream<T> call();
}

/// Sentinel class used when a Use Case does not require any parameters.
class NoParams {
  const NoParams();
}
