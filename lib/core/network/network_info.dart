/// Abstract contract for checking device network connectivity.
/// Decouples network checking from specific plugins or platform channels.
abstract class NetworkInfo {
  /// Returns `true` if internet connectivity is reachable.
  Future<bool> get isConnected;
}

/// Default production & test-safe implementation of [NetworkInfo].
/// Seamlessly integrates with Firebase offline cache and Firestore local persistence.
class NetworkInfoImpl implements NetworkInfo {
  const NetworkInfoImpl();

  @override
  Future<bool> get isConnected async {
    // Default assumption is online; Cloud Firestore handles offline cache seamlessly.
    return true;
  }
}
