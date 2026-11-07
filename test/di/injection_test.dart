import 'package:flutter_test/flutter_test.dart';
import 'package:nestora/app/di/injection.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SampleService {
  final String id;
  SampleService(this.id);
}

abstract class SampleRepository {
  String getData();
}

class SampleRepositoryImpl implements SampleRepository {
  @override
  String getData() => 'test_data';
}

void main() {
  setUp(() {
    sl.reset();
  });

  tearDown(() {
    sl.reset();
  });

  group('ServiceLocator Core Functionality Tests', () {
    test('registerSingleton stores and retrieves the identical instance', () {
      final service = SampleService('singleton_1');
      sl.registerSingleton<SampleService>(service);

      expect(sl.isRegistered<SampleService>(), isTrue);
      expect(sl.get<SampleService>(), same(service));
      expect(sl<SampleService>(), same(service));
      expect(locator<SampleService>(), same(service));
    });

    test('registerSingleton throws StateError when registering duplicate type', () {
      final service1 = SampleService('s1');
      final service2 = SampleService('s2');

      sl.registerSingleton<SampleService>(service1);
      expect(
        () => sl.registerSingleton<SampleService>(service2),
        throwsA(isA<StateError>()),
      );
    });

    test('registerLazySingleton instantiates only on first access and caches', () {
      int factoryCallCount = 0;
      sl.registerLazySingleton<SampleService>(() {
        factoryCallCount++;
        return SampleService('lazy_1');
      });

      expect(sl.isRegistered<SampleService>(), isTrue);
      expect(factoryCallCount, equals(0)); // Not called yet

      final firstAccess = sl<SampleService>();
      expect(factoryCallCount, equals(1));
      expect(firstAccess.id, equals('lazy_1'));

      final secondAccess = sl<SampleService>();
      expect(factoryCallCount, equals(1)); // Still 1, cached instance returned
      expect(secondAccess, same(firstAccess));
    });

    test('registerFactory returns a fresh instance on each access', () {
      int factoryCallCount = 0;
      sl.registerFactory<SampleService>(() {
        factoryCallCount++;
        return SampleService('factory_$factoryCallCount');
      });

      expect(sl.isRegistered<SampleService>(), isTrue);

      final instance1 = sl<SampleService>();
      final instance2 = sl<SampleService>();

      expect(factoryCallCount, equals(2));
      expect(instance1.id, equals('factory_1'));
      expect(instance2.id, equals('factory_2'));
      expect(instance1, isNot(same(instance2)));
    });

    test('registers abstract contract and resolves concrete implementation', () {
      sl.registerSingleton<SampleRepository>(SampleRepositoryImpl());

      expect(sl.isRegistered<SampleRepository>(), isTrue);
      expect(sl<SampleRepository>().getData(), equals('test_data'));
    });

    test('unregister removes registration cleanly', () {
      final service = SampleService('to_remove');
      sl.registerSingleton<SampleService>(service);
      expect(sl.isRegistered<SampleService>(), isTrue);

      sl.unregister<SampleService>();
      expect(sl.isRegistered<SampleService>(), isFalse);
      expect(() => sl<SampleService>(), throwsA(isA<StateError>()));
    });

    test('reset clears all registered types', () {
      sl.registerSingleton<SampleService>(SampleService('s1'));
      sl.registerFactory<SampleRepository>(() => SampleRepositoryImpl());

      expect(sl.isRegistered<SampleService>(), isTrue);
      expect(sl.isRegistered<SampleRepository>(), isTrue);

      sl.reset();

      expect(sl.isRegistered<SampleService>(), isFalse);
      expect(sl.isRegistered<SampleRepository>(), isFalse);
    });

    test('get throws StateError when accessing an unregistered type', () {
      expect(
        () => sl.get<SampleService>(),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            contains('Type SampleService is not registered'),
          ),
        ),
      );
    });
  });

  group('initDependencies Tests', () {
    test('registers SharedPreferences as singleton', () async {
      SharedPreferences.setMockInitialValues({'test_key': 'nestora_value'});
      final prefs = await SharedPreferences.getInstance();

      await initDependencies(sharedPreferences: prefs);

      expect(sl.isRegistered<SharedPreferences>(), isTrue);
      expect(sl<SharedPreferences>().getString('test_key'), equals('nestora_value'));
    });
  });
}

