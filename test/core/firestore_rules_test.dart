import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Firestore Security Rules File Verification Tests', () {
    test('firestore.rules file exists in root and defines valid structure', () {
      final file = File('firestore.rules');
      expect(file.existsSync(), isTrue, reason: 'firestore.rules must exist');

      final content = file.readAsStringSync();

      expect(content.contains("rules_version = '2'"), isTrue);
      expect(content.contains('service cloud.firestore'), isTrue);
      expect(content.contains('function isAuthenticated()'), isTrue);
      expect(content.contains('function isOwner(userId)'), isTrue);
      expect(content.contains('request.auth.uid == userId'), isTrue);

      // Verify all collections are covered
      expect(content.contains('match /users/{userId}'), isTrue);
      expect(content.contains('match /rooms/{roomId}'), isTrue);
      expect(content.contains('match /devices/{deviceId}'), isTrue);
      expect(content.contains('match /notifications/{notificationId}'), isTrue);

      // Verify default deny
      expect(content.contains('match /{document=**}'), isTrue);
      expect(content.contains('allow read, write: if false;'), isTrue);
    });

    test('firebase.json references firestore.rules and has valid json format', () {
      final file = File('firebase.json');
      expect(file.existsSync(), isTrue);

      final content = file.readAsStringSync();
      final json = jsonDecode(content) as Map<String, dynamic>;

      expect(json.containsKey('firestore'), isTrue);
      final firestoreConfig = json['firestore'] as Map<String, dynamic>;
      expect(firestoreConfig['rules'], 'firestore.rules');
    });
  });
}
