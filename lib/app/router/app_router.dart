import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/app_constants.dart';
import '../../core/services/analytics_service.dart';
import '../../core/services/performance_service.dart';
import '../di/injection.dart';
import 'auth_guard.dart';

export 'auth_guard.dart';

import '../../features/auth/presentation/pages/forgot_password_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/onboarding_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/auth/presentation/pages/splash_page.dart';
import '../../features/auth/presentation/pages/welcome_page.dart';
import '../../features/components_preview/presentation/pages/components_preview_page.dart';
import '../../features/devices/domain/device_model.dart';
import '../../features/devices/presentation/pages/ac_control_page.dart';
import '../../features/devices/presentation/pages/add_edit_device_page.dart';
import '../../features/devices/presentation/pages/coffee_machine_control_page.dart';
import '../../features/devices/presentation/pages/devices_page.dart';
import '../../features/devices/presentation/pages/lamp_control_page.dart';
import '../../features/devices/presentation/pages/plug_control_page.dart';
import '../../features/devices/presentation/pages/tv_control_page.dart';
import '../../features/home/presentation/pages/dashboard_page.dart';
import '../../features/notifications/presentation/pages/notifications_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/rooms/domain/room_model.dart';
import '../../features/rooms/presentation/pages/add_edit_room_page.dart';
import '../../features/rooms/presentation/pages/room_detail_page.dart';
import '../../features/rooms/presentation/pages/rooms_page.dart';
import '../app_shell.dart';
import '../../core/constants/seed_data.dart';
import '../../features/rooms/presentation/cubit/rooms_cubit.dart';
import '../../features/rooms/presentation/cubit/rooms_state.dart';

/// URL and Path definitions for all 16 application screens and preview tools.
abstract class AppRoutePaths {
  static const String splash = '/splash';
  static const String onboarding = '/onboarding';
  static const String welcome = '/welcome';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';

  // Shell Tabs
  static const String dashboard = '/dashboard';
  static const String rooms = '/rooms';
  static const String devices = '/devices';
  static const String profile = '/profile';

  // Standalone Full-Page Routes
  static const String roomDetail = '/rooms/:roomId';
  static const String addEditRoom = '/rooms/add-edit';
  static const String lampControl = '/devices/lamp/:deviceId';
  static const String climateControl = '/devices/climate/:deviceId';
  static const String tvControl = '/devices/tv/:deviceId';
  static const String plugControl = '/devices/plug/:deviceId';
  static const String coffeeControl = '/devices/coffee/:deviceId';
  static const String addEditDevice = '/devices/add-edit';
  static const String notifications = '/notifications';

  // Dev / Debug Preview
  static const String componentsPreview = '/components-preview';
}

/// Named routes for type-safe and clear routing.
abstract class AppRouteNames {
  static const String splash = 'splash';
  static const String onboarding = 'onboarding';
  static const String welcome = 'welcome';
  static const String login = 'login';
  static const String register = 'register';
  static const String forgotPassword = 'forgot-password';

  // Shell Tabs
  static const String dashboard = 'dashboard';
  static const String devices = 'devices';
  static const String profile = 'profile';

  // Standalone Full-Page Routes
  static const String rooms = 'rooms';
  static const String roomDetail = 'room-detail';
  static const String addEditRoom = 'add-edit-room';
  static const String lampControl = 'lamp-control';
  static const String climateControl = 'climate-control';
  static const String tvControl = 'tv-control';
  static const String plugControl = 'plug-control';
  static const String coffeeControl = 'coffee-control';
  static const String addEditDevice = 'add-edit-device';
  static const String notifications = 'notifications';

  // Dev / Debug Preview
  static const String componentsPreview = 'components-preview';
}

/// Global navigator keys for root and shell navigators.
final GlobalKey<NavigatorState> rootNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'rootNav');
final GlobalKey<NavigatorState> shellNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'shellNav');

/// Central GoRouter factory function.
GoRouter createAppRouter({
  String initialLocation = AppRoutePaths.splash,
  AppAuthListenable? authListenable,
  Listenable? refreshListenable,
  GoRouterRedirect? redirect,
  List<NavigatorObserver>? observers,
}) {
  final effectiveAuthListenable = authListenable ??
      (sl.isRegistered<AppAuthListenable>() ? sl<AppAuthListenable>() : null);

  final effectiveRefreshListenable =
      refreshListenable ?? effectiveAuthListenable;

  final effectiveRedirect = redirect ??
      (effectiveAuthListenable != null
          ? (context, state) => defaultRedirectGuard(
                location: state.matchedLocation,
                isAuthenticated: effectiveAuthListenable.isAuthenticated,
              )
          : null);

  final effectiveObservers = observers ??
      [
        if (sl.isRegistered<AnalyticsService>())
          sl<AnalyticsService>().getAnalyticsObserver(),
        if (sl.isRegistered<PerformanceService>())
          sl<PerformanceService>().getRouteObserver(),
      ];

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: initialLocation,
    debugLogDiagnostics: kDebugMode,
    refreshListenable: effectiveRefreshListenable,
    redirect: effectiveRedirect,
    observers: effectiveObservers,
    routes: [
      // 1. Splash
      GoRoute(
        path: AppRoutePaths.splash,
        name: AppRouteNames.splash,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => SplashPage(
          onFinish: () {
            if (effectiveAuthListenable?.isAuthenticated ?? false) {
              context.go(AppRoutePaths.dashboard);
            } else {
              bool hasSeenOnboarding = false;
              if (sl.isRegistered<SharedPreferences>()) {
                hasSeenOnboarding = sl<SharedPreferences>()
                        .getBool(AppConstants.prefHasSeenOnboarding) ??
                    false;
              }
              if (hasSeenOnboarding) {
                context.go(AppRoutePaths.welcome);
              } else {
                context.go(AppRoutePaths.onboarding);
              }
            }
          },
        ),
      ),

      // 2. Onboarding
      GoRoute(
        path: AppRoutePaths.onboarding,
        name: AppRouteNames.onboarding,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => OnboardingPage(
          onStart: () async {
            if (sl.isRegistered<SharedPreferences>()) {
              await sl<SharedPreferences>()
                  .setBool(AppConstants.prefHasSeenOnboarding, true);
            }
            if (context.mounted) {
              context.go(AppRoutePaths.welcome);
            }
          },
          onBack: () => context.go(AppRoutePaths.splash),
        ),
      ),

      // 3. Welcome
      GoRoute(
        path: AppRoutePaths.welcome,
        name: AppRouteNames.welcome,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => WelcomePage(
          onGetStarted: () {
            effectiveAuthListenable?.setAuthenticated(true);
            context.go(AppRoutePaths.dashboard);
          },
          onLogin: () => context.go(AppRoutePaths.login),
        ),
      ),

      // 4. Login
      GoRoute(
        path: AppRoutePaths.login,
        name: AppRouteNames.login,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => LoginPage(
          onLoginSuccess: () {
            effectiveAuthListenable?.setAuthenticated(true);
            context.go(AppRoutePaths.dashboard);
          },
          onNavigateToRegister: () => context.go(AppRoutePaths.register),
          onNavigateToForgotPassword: () =>
              context.go(AppRoutePaths.forgotPassword),
        ),
      ),

      // 5. Register
      GoRoute(
        path: AppRoutePaths.register,
        name: AppRouteNames.register,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => RegisterPage(
          onRegisterSuccess: () {
            effectiveAuthListenable?.setAuthenticated(true);
            context.go(AppRoutePaths.dashboard);
          },
          onNavigateToLogin: () => context.go(AppRoutePaths.login),
        ),
      ),

      // 6. Forgot Password
      GoRoute(
        path: AppRoutePaths.forgotPassword,
        name: AppRouteNames.forgotPassword,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => ForgotPasswordPage(
          onBackToLogin: () => context.go(AppRoutePaths.login),
        ),
      ),

      // 7. ShellRoute: Dashboard (Tab 0), Rooms (Tab 1), Devices (Tab 2), Profile (Tab 3)
      ShellRoute(
        navigatorKey: shellNavigatorKey,
        builder: (context, state, child) {
          return AppShell(child: child);
        },
        routes: [
          GoRoute(
            path: AppRoutePaths.dashboard,
            name: AppRouteNames.dashboard,
            builder: (context, state) => DashboardPage(
              onNavigateToRooms: () => context.go(AppRoutePaths.rooms),
              onNavigateToDevices: ({status}) => context.go(AppRoutePaths.devices),
              onNavigateToProfile: () => context.go(AppRoutePaths.profile),
            ),
          ),
          GoRoute(
            path: AppRoutePaths.rooms,
            name: AppRouteNames.rooms,
            builder: (context, state) => const RoomsPage(),
          ),
          GoRoute(
            path: AppRoutePaths.devices,
            name: AppRouteNames.devices,
            builder: (context, state) => DevicesPage(
              onNavigateToProfile: () => context.go(AppRoutePaths.profile),
            ),
          ),
          GoRoute(
            path: AppRoutePaths.profile,
            name: AppRouteNames.profile,
            builder: (context, state) => ProfilePage(
              onLogout: () {
                effectiveAuthListenable?.setAuthenticated(false);
                context.go(AppRoutePaths.welcome);
              },
            ),
          ),
        ],
      ),

      // 9. Add / Edit Room (/rooms/add-edit) - Must precede /rooms/:roomId to prevent param collision
      GoRoute(
        path: AppRoutePaths.addEditRoom,
        name: AppRouteNames.addEditRoom,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final room =
              state.extra is RoomModel ? state.extra as RoomModel : null;
          return AddEditRoomPage(
            isEditing: room != null,
            room: room,
          );
        },
      ),

      // 10. Room Detail (/rooms/:roomId)
      GoRoute(
        path: AppRoutePaths.roomDetail,
        name: AppRouteNames.roomDetail,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final roomId = state.pathParameters['roomId'] ?? 'room-1';
          RoomModel? room;
          if (state.extra is RoomModel) {
            room = state.extra as RoomModel;
          } else {
            try {
              final roomsCubit = context.read<RoomsCubit>();
              final roomsState = roomsCubit.state;
              if (roomsState is RoomsLoaded) {
                final found = roomsState.rooms.where((r) => r.id == roomId).firstOrNull ??
                    roomsState.rooms.firstOrNull;
                if (found != null) {
                  room = SeedData.roomToModel(found);
                }
              }
            } catch (_) {}
            room ??= SeedData.defaultRoomModels.firstWhere(
              (r) => r.id == roomId,
              orElse: () => SeedData.defaultRoomModels.first,
            );
          }

          return RoomDetailPage(room: room);
        },
      ),

      // 11. Lamp Control (/devices/lamp/:deviceId)
      GoRoute(
        path: AppRoutePaths.lampControl,
        name: AppRouteNames.lampControl,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => LampControlPage(
          deviceId: state.pathParameters['deviceId'],
        ),
      ),

      // 12. Climate Control (/devices/climate/:deviceId)
      GoRoute(
        path: AppRoutePaths.climateControl,
        name: AppRouteNames.climateControl,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => AcControlPage(
          deviceId: state.pathParameters['deviceId'],
        ),
      ),

      // TV Control (/devices/tv/:deviceId)
      GoRoute(
        path: AppRoutePaths.tvControl,
        name: AppRouteNames.tvControl,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => TvControlPage(
          deviceId: state.pathParameters['deviceId'],
        ),
      ),

      // Plug Control (/devices/plug/:deviceId)
      GoRoute(
        path: AppRoutePaths.plugControl,
        name: AppRouteNames.plugControl,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => PlugControlPage(
          deviceId: state.pathParameters['deviceId'],
        ),
      ),

      // Coffee Machine Control (/devices/coffee/:deviceId)
      GoRoute(
        path: AppRoutePaths.coffeeControl,
        name: AppRouteNames.coffeeControl,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => CoffeeMachineControlPage(
          deviceId: state.pathParameters['deviceId'],
        ),
      ),

      // 13. Add / Edit Device (/devices/add-edit)
      GoRoute(
        path: AppRoutePaths.addEditDevice,
        name: AppRouteNames.addEditDevice,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final extraMap = state.extra is Map<String, dynamic>
              ? state.extra as Map<String, dynamic>
              : (state.extra is Map ? (state.extra as Map).cast<String, dynamic>() : null);
          final initialRoom = state.uri.queryParameters['room'] ??
              (state.extra is String ? state.extra as String : null) ??
              (extraMap?['initialRoom'] as String?);
          final isEditing = state.uri.queryParameters['mode'] == 'edit' ||
              extraMap?['isEditing'] == true;
          final device = state.extra is DeviceModel
              ? state.extra as DeviceModel
              : (extraMap?['device'] as DeviceModel?);
          final deviceId = state.uri.queryParameters['deviceId'] ??
              (extraMap?['deviceId'] as String?);
          return AddEditDevicePage(
            initialRoom: initialRoom,
            isEditing: isEditing || device != null || deviceId != null,
            device: device,
            deviceId: deviceId,
          );
        },
      ),

      // 14. Notifications (/notifications)
      GoRoute(
        path: AppRoutePaths.notifications,
        name: AppRouteNames.notifications,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const NotificationsPage(),
      ),

      // 15. Components Preview (/components-preview)
      GoRoute(
        path: AppRoutePaths.componentsPreview,
        name: AppRouteNames.componentsPreview,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const ComponentsPreviewPage(),
      ),
    ],
  );
}

/// Helper navigation extension methods on BuildContext for clean call sites.
extension NestoraNavigationExtension on BuildContext {
  void goToSplash() => go(AppRoutePaths.splash);
  void goToOnboarding() => go(AppRoutePaths.onboarding);
  void goToWelcome() => go(AppRoutePaths.welcome);
  void goToLogin() => go(AppRoutePaths.login);
  void goToRegister() => go(AppRoutePaths.register);
  void goToForgotPassword() => go(AppRoutePaths.forgotPassword);
  void goToDashboard() => go(AppRoutePaths.dashboard);
  void goToRooms() => go(AppRoutePaths.rooms);
  void goToDevices() => go(AppRoutePaths.devices);
  void goToProfile() => go(AppRoutePaths.profile);
  void goToRoomDetail(String roomId, {RoomModel? room}) =>
      push('/rooms/$roomId', extra: room);
  void goToAddEditRoom({RoomModel? room}) =>
      push(AppRoutePaths.addEditRoom, extra: room);
  void goToLampControl(String deviceId) =>
      push('/devices/lamp/$deviceId');
  void goToClimateControl(String deviceId) =>
      push('/devices/climate/$deviceId');
  void goToTvControl(String deviceId) =>
      push('/devices/tv/$deviceId');
  void goToPlugControl(String deviceId) =>
      push('/devices/plug/$deviceId');
  void goToCoffeeControl(String deviceId) =>
      push('/devices/coffee/$deviceId');
  void goToAddEditDevice({
    String? initialRoom,
    bool isEditing = false,
    DeviceModel? device,
    String? deviceId,
  }) =>
      push(
        AppRoutePaths.addEditDevice,
        extra: {
          'initialRoom': initialRoom,
          'isEditing': isEditing,
          'device': device,
          'deviceId': deviceId,
        },
      );
  void goToNotifications() => push(AppRoutePaths.notifications);
  void goToComponentsPreview() => push(AppRoutePaths.componentsPreview);
}
