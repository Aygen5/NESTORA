import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../features/profile/presentation/cubit/profile_cubit.dart';
import '../../features/profile/presentation/cubit/profile_state.dart';

/// Universal temperature formatting and conversion utility for Nestora.
/// Accurately translates Celsius to Fahrenheit and formats labels with °C or °F
/// consistently across all screens based on user preference.
class TemperatureFormatter {
  TemperatureFormatter._();

  /// Converts a Celsius value to target unit ('C' or 'F').
  static double convert(double celsius, {String unit = 'C'}) {
    if (unit.toUpperCase() == 'F') {
      return (celsius * 9.0 / 5.0) + 32.0;
    }
    return celsius;
  }

  /// Converts a value in [unit] back to Celsius.
  static double toCelsius(double value, {String unit = 'C'}) {
    if (unit.toUpperCase() == 'F') {
      return (value - 32.0) * 5.0 / 9.0;
    }
    return value;
  }

  /// Formats temperature as a human-readable string.
  /// Examples:
  /// format(22.0, unit: 'C') -> "22°C"
  /// format(22.0, unit: 'F') -> "72°F"
  /// format(22.4, unit: 'C', precision: 1) -> "22.4°C"
  static String format(
    double celsius, {
    String unit = 'C',
    bool showUnit = true,
    int? precision,
  }) {
    final isF = unit.toUpperCase() == 'F';
    final converted = convert(celsius, unit: unit);
    final symbol = showUnit ? (isF ? '°F' : '°C') : '°';

    if (precision != null) {
      return '${converted.toStringAsFixed(precision)}$symbol';
    }

    if (converted == converted.truncateToDouble()) {
      return '${converted.toInt()}$symbol';
    }
    return '${converted.toStringAsFixed(1)}$symbol';
  }

  /// Returns numeric value formatted as string without degree symbol.
  static String formatValue(
    double celsius, {
    String unit = 'C',
    int? precision,
  }) {
    final converted = convert(celsius, unit: unit);
    if (precision != null) {
      return converted.toStringAsFixed(precision);
    }
    if (converted == converted.truncateToDouble()) {
      return converted.toInt().toString();
    }
    return converted.toStringAsFixed(1);
  }

  /// Returns unit symbol '°C' or '°F'.
  static String unitSymbol({String unit = 'C'}) {
    return unit.toUpperCase() == 'F' ? '°F' : '°C';
  }

  /// Reads current preferred temperature unit from [BuildContext].
  static String currentUnit(BuildContext context) {
    try {
      final state = context.watch<ProfileCubit>().state;
      if (state is ProfileLoaded) {
        return state.profile.preferences.temperatureUnit;
      }
    } catch (_) {}
    return 'C';
  }
}

