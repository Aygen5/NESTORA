import 'dart:async';
import 'package:firebase_performance/firebase_performance.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// Wraps an active performance measurement session.
/// Synchronizes with native [Trace] on mobile and keeps memory diagnostics
/// for testing and desktop/web compatibility.
class PerformanceTrace {
  final String name;
  final Trace? nativeTrace;
  final Stopwatch _stopwatch = Stopwatch();

  final Map<String, int> _metrics = {};
  final Map<String, String> _attributes = {};

  bool _isStarted = false;
  bool _isStopped = false;

  PerformanceTrace({
    required this.name,
    this.nativeTrace,
  });

  bool get isRunning => _isStarted && !_isStopped;
  bool get isStopped => _isStopped;
  int get durationMs => _stopwatch.elapsedMilliseconds;
  Map<String, int> get metrics => Map.unmodifiable(_metrics);
  Map<String, String> get attributes => Map.unmodifiable(_attributes);

  /// Starts the trace timer.
  Future<void> start() async {
    if (_isStarted) return;
    _isStarted = true;
    _stopwatch.start();

    if (nativeTrace != null) {
      try {
        await nativeTrace!.start();
      } catch (e) {
        debugPrint('PerformanceTrace.start native error: $e');
      }
    }
  }

  /// Stops the trace and records the final execution duration metric.
  Future<void> stop() async {
    if (!_isStarted || _isStopped) return;
    _stopwatch.stop();
    _isStopped = true;

    setMetric('duration_ms', _stopwatch.elapsedMilliseconds);

    if (nativeTrace != null) {
      try {
        await nativeTrace!.stop();
      } catch (e) {
        debugPrint('PerformanceTrace.stop native error: $e');
      }
    }
  }

  /// Sets or updates a numeric metric.
  void setMetric(String metricName, int value) {
    _metrics[metricName] = value;
    if (nativeTrace != null && isRunning) {
      try {
        nativeTrace!.setMetric(metricName, value);
      } catch (_) {}
    }
  }

  /// Alias for setMetric.
  void putMetric(String metricName, int value) => setMetric(metricName, value);

  /// Increments an existing metric or initializes it.
  void incrementMetric(String metricName, [int by = 1]) {
    final current = _metrics[metricName] ?? 0;
    setMetric(metricName, current + by);
    if (nativeTrace != null && isRunning) {
      try {
        nativeTrace!.incrementMetric(metricName, by);
      } catch (_) {}
    }
  }

  /// Returns the current value of metric [metricName].
  int getMetric(String metricName) => _metrics[metricName] ?? 0;

  /// Sets a custom string attribute.
  void putAttribute(String attribute, String value) {
    _attributes[attribute] = value;
    if (nativeTrace != null && isRunning) {
      try {
        nativeTrace!.putAttribute(attribute, value);
      } catch (_) {}
    }
  }

  /// Returns custom attribute value.
  String? getAttribute(String attribute) => _attributes[attribute];
}

/// Service managing application execution traces, network request latency,
/// and route transition render timings through [FirebasePerformance].
class PerformanceService {
  final FirebasePerformance? performance;
  final bool enableDebugLogs;

  /// In-memory historical records for unit tests and local performance inspection.
  final List<PerformanceTrace> completedTraces = [];
  final Map<String, PerformanceTrace> activeTraces = {};
  final List<Map<String, dynamic>> recordedNetworkMetrics = [];

  PerformanceService({
    this.performance,
    this.enableDebugLogs = false,
  });

  /// Returns true if native Firebase Performance is supported on the running platform.
  bool get isSupported {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  /// Initializes performance monitoring and enables collection.
  Future<void> initialize() async {
    if (isSupported && performance != null) {
      try {
        await performance!.setPerformanceCollectionEnabled(!kDebugMode);
      } catch (e) {
        debugPrint('PerformanceService initialize notice: $e');
      }
    }
  }

  /// Creates and immediately starts a new [PerformanceTrace].
  Future<PerformanceTrace> startTrace(String traceName) async {
    Trace? nativeTrace;
    if (isSupported && performance != null) {
      try {
        nativeTrace = performance!.newTrace(traceName);
      } catch (e) {
        debugPrint('PerformanceService.newTrace error: $e');
      }
    }

    final trace = PerformanceTrace(
      name: traceName,
      nativeTrace: nativeTrace,
    );
    activeTraces[traceName] = trace;
    await trace.start();

    if (enableDebugLogs) {
      debugPrint('[PerformanceService] Started trace: $traceName');
    }

    return trace;
  }

  /// Stops an active trace and moves it to completed history.
  Future<void> stopTrace(String traceName) async {
    final trace = activeTraces.remove(traceName);
    if (trace != null) {
      await trace.stop();
      completedTraces.add(trace);

      if (enableDebugLogs) {
        debugPrint('[PerformanceService] Stopped trace: $traceName (${trace.durationMs}ms)');
      }
    }
  }

  /// Measures a discrete asynchronous operation and records its execution time.
  Future<T> measureOperation<T>(
    String traceName,
    Future<T> Function() operation, {
    Map<String, String>? attributes,
    Map<String, int>? metrics,
  }) async {
    final trace = await startTrace(traceName);

    if (attributes != null) {
      for (final entry in attributes.entries) {
        trace.putAttribute(entry.key, entry.value);
      }
    }

    if (metrics != null) {
      for (final entry in metrics.entries) {
        trace.setMetric(entry.key, entry.value);
      }
    }

    try {
      final result = await operation();
      return result;
    } finally {
      await stopTrace(traceName);
    }
  }

  /// Records network latency and payload metrics.
  Future<void> measureNetworkCall({
    required String url,
    required String method,
    required int responseCode,
    required int durationMs,
    int? requestPayloadBytes,
    int? responsePayloadBytes,
  }) async {
    recordedNetworkMetrics.add({
      'url': url,
      'method': method,
      'responseCode': responseCode,
      'durationMs': durationMs,
      'requestPayloadBytes': requestPayloadBytes,
      'responsePayloadBytes': responsePayloadBytes,
      'timestamp': DateTime.now().toIso8601String(),
    });

    if (isSupported && performance != null) {
      try {
        final httpMethod = _mapHttpMethod(method);
        final metric = performance!.newHttpMetric(url, httpMethod);
        await metric.start();
        metric.httpResponseCode = responseCode;
        if (requestPayloadBytes != null) {
          metric.requestPayloadSize = requestPayloadBytes;
        }
        if (responsePayloadBytes != null) {
          metric.responsePayloadSize = responsePayloadBytes;
        }
        await metric.stop();
      } catch (e) {
        debugPrint('PerformanceService.measureNetworkCall error: $e');
      }
    }

    if (enableDebugLogs) {
      debugPrint('[PerformanceService] Network call: $method $url -> $responseCode (${durationMs}ms)');
    }
  }

  /// Maps string HTTP verb to [HttpMethod].
  HttpMethod _mapHttpMethod(String method) {
    switch (method.toUpperCase()) {
      case 'GET':
        return HttpMethod.Get;
      case 'POST':
        return HttpMethod.Post;
      case 'PUT':
        return HttpMethod.Put;
      case 'DELETE':
        return HttpMethod.Delete;
      case 'PATCH':
        return HttpMethod.Patch;
      default:
        return HttpMethod.Get;
    }
  }

  /// Creates a [NavigatorObserver] that monitors route load and render durations.
  NavigatorObserver getRouteObserver() {
    return PerformanceRouteObserver(this);
  }
}

/// Navigator observer that records page transition render times.
class PerformanceRouteObserver extends NavigatorObserver {
  final PerformanceService _performanceService;

  PerformanceRouteObserver(this._performanceService);

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    _measureRouteLoad(route);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    if (newRoute != null) {
      _measureRouteLoad(newRoute);
    }
  }

  void _measureRouteLoad(Route<dynamic> route) {
    final routeName = route.settings.name ?? route.runtimeType.toString();
    final traceName = 'screen_render_$routeName';

    _performanceService.startTrace(traceName).then((trace) {
      trace.putAttribute('route_name', routeName);

      // Stop measurement right after the first frame of this route is drawn
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _performanceService.stopTrace(traceName);
      });
    });
  }
}
