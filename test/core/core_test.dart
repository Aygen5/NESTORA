import 'package:flutter_test/flutter_test.dart';
import 'package:nestora/core/constants/app_constants.dart';
import 'package:nestora/core/errors/exceptions.dart';
import 'package:nestora/core/errors/failures.dart';
import 'package:nestora/core/utils/result.dart';

void main() {
  group('Core Failures & Exceptions Tests', () {
    test('AuthFailure holds message and optional code correctly', () {
      const failure = AuthFailure('Kullanıcı bulunamadı', code: 'user-not-found');
      expect(failure.message, 'Kullanıcı bulunamadı');
      expect(failure.code, 'user-not-found');
      expect(failure.toString(), contains('AuthFailure'));
    });

    test('ServerException formats toString as expected', () {
      const exception = ServerException('Bağlantı hatası', code: '500');
      expect(exception.message, 'Bağlantı hatası');
      expect(exception.code, '500');
      expect(exception.toString(), 'ServerException: Bağlantı hatası (code: 500)');
    });
  });

  group('Result<T> Monad Tests', () {
    test('Result.success returns data and folds correctly', () {
      final result = Result.success('Test verisi');

      expect(result.isSuccess, isTrue);
      expect(result.isFailure, isFalse);
      expect(result.data, 'Test verisi');
      expect(result.dataOrNull, 'Test verisi');
      expect(result.failureOrNull, isNull);

      final folded = result.when(
        success: (data) => 'Başarılı: $data',
        failure: (f) => 'Hata: ${f.message}',
      );
      expect(folded, 'Başarılı: Test verisi');
    });

    test('Result.failure returns failure and folds correctly', () {
      const failure = ServerFailure('Sunucuya ulaşılamadı');
      final result = Result<String>.failure(failure);

      expect(result.isSuccess, isFalse);
      expect(result.isFailure, isTrue);
      expect(result.failure, failure);
      expect(result.failureOrNull, failure);
      expect(result.dataOrNull, isNull);
      expect(() => result.data, throwsStateError);

      final folded = result.when(
        success: (data) => 'Başarılı: $data',
        failure: (f) => 'Hata: ${f.message}',
      );
      expect(folded, 'Hata: Sunucuya ulaşılamadı');
    });
  });

  group('AppConstants Tests', () {
    test('Email regex correctly identifies valid and invalid emails', () {
      expect(AppConstants.emailRegex.hasMatch('test@nestora.com'), isTrue);
      expect(AppConstants.emailRegex.hasMatch('aygen@gmail.com'), isTrue);
      expect(AppConstants.emailRegex.hasMatch('invalid-email'), isFalse);
      expect(AppConstants.emailRegex.hasMatch('@domain.com'), isFalse);
    });

    test('Password complexity regexes function as required by project.md', () {
      const validPass = 'Nestora2026!';
      expect(AppConstants.upperCaseRegex.hasMatch(validPass), isTrue);
      expect(AppConstants.lowerCaseRegex.hasMatch(validPass), isTrue);
      expect(AppConstants.digitRegex.hasMatch(validPass), isTrue);
      expect(AppConstants.specialCharRegex.hasMatch(validPass), isTrue);
      expect(validPass.length >= AppConstants.minPasswordLength, isTrue);
    });
  });
}

