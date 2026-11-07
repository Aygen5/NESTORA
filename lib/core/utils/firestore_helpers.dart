import 'package:cloud_firestore/cloud_firestore.dart' hide Type;

/// Centralized utility functions for safe Firestore deserialization and type conversions.
class FirestoreHelpers {
  FirestoreHelpers._();

  /// Safely converts [dynamic] Firestore values (Timestamp, DateTime, String, int) to [DateTime].
  static DateTime? parseDateTime(dynamic value, [DateTime? fallback]) {
    if (value == null) return fallback;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    if (value is String) return DateTime.tryParse(value) ?? fallback;
    return fallback;
  }

  /// Converts a [DateTime] into a Firestore [Timestamp] or returns [FieldValue.serverTimestamp] if null.
  static dynamic dateTimeToTimestamp(DateTime? dateTime) {
    if (dateTime == null) {
      return FieldValue.serverTimestamp();
    }
    return Timestamp.fromDate(dateTime);
  }

  /// Safely parses a [dynamic] value to [double], handling both `int` and `double` representations.
  static double parseDouble(dynamic value, [double fallback = 0.0]) {
    if (value == null) return fallback;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? fallback;
    return fallback;
  }

  /// Safely parses a [dynamic] value to [int], handling string numbers and doubles.
  static int parseInt(dynamic value, [int fallback = 0]) {
    if (value == null) return fallback;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? fallback;
    return fallback;
  }

  /// Safely parses a [dynamic] value to [String].
  static String parseString(dynamic value, [String fallback = '']) {
    if (value == null) return fallback;
    if (value is String) return value.trim();
    return value.toString().trim();
  }

  /// Safely parses a [dynamic] value to [bool].
  static bool parseBool(dynamic value, [bool fallback = false]) {
    if (value == null) return fallback;
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final lower = value.toLowerCase().trim();
      if (lower == 'true' || lower == '1' || lower == 'yes') return true;
      if (lower == 'false' || lower == '0' || lower == 'no') return false;
    }
    return fallback;
  }
}

