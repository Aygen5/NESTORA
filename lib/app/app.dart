import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/data/datasources/auth_remote_data_source.dart';
import '../features/auth/data/repositories/auth_repository_impl.dart';
import '../features/auth/domain/repositories/auth_repository.dart';
import '../features/auth/presentation/cubit/auth_cubit.dart';
import '../features/auth/presentation/cubit/auth_state.dart';
import '../features/devices/data/datasources/devices_remote_data_source.dart';
import '../features/devices/data/repositories/devices_repository_impl.dart';
import '../features/devices/domain/repositories/devices_repository.dart';
import '../features/devices/presentation/cubit/devices_cubit.dart';
import '../features/notifications/data/datasources/notifications_remote_data_source.dart';
import '../features/notifications/data/repositories/notifications_repository_impl.dart';
import '../features/notifications/domain/repositories/notifications_repository.dart';
import '../features/notifications/presentation/cubit/notifications_cubit.dart';
import '../features/profile/data/datasources/profile_photo_service.dart';
import '../features/profile/data/datasources/profile_remote_data_source.dart';
import '../features/profile/data/repositories/profile_repository_impl.dart';
import '../features/profile/domain/repositories/profile_repository.dart';
import '../features/profile/presentation/cubit/profile_cubit.dart';
import '../features/rooms/data/datasources/rooms_remote_data_source.dart';
import '../features/rooms/data/repositories/rooms_repository_impl.dart';
import '../features/rooms/domain/repositories/rooms_repository.dart';
import '../features/rooms/presentation/cubit/rooms_cubit.dart';
import 'di/injection.dart';
import 'router/app_router.dart';
import 'theme/app_theme.dart';
import 'theme/theme_cubit.dart';

/// Root application widget for Nestora.
/// Connects [ThemeCubit], [AuthCubit], [ProfileCubit], [RoomsCubit],
/// [DevicesCubit], and [NotificationsCubit] via [MultiBlocProvider]
/// and provides the centralized [GoRouter] configuration.
class NestoraApp extends StatefulWidget {
  final GoRouter? router;
  final ThemeCubit? themeCubit;
  final AuthCubit? authCubit;
  final ProfileCubit? profileCubit;
  final RoomsCubit? roomsCubit;
  final DevicesCubit? devicesCubit;
  final NotificationsCubit? notificationsCubit;

  const NestoraApp({
    super.key,
    this.router,
    this.themeCubit,
    this.authCubit,
    this.profileCubit,
    this.roomsCubit,
    this.devicesCubit,
    this.notificationsCubit,
  });

  @override
  State<NestoraApp> createState() => _NestoraAppState();
}

class _NestoraAppState extends State<NestoraApp> {
  late final GoRouter _router;
  late final ThemeCubit _themeCubit;
  late final AuthCubit _authCubit;
  late final ProfileCubit _profileCubit;
  late final RoomsCubit _roomsCubit;
  late final DevicesCubit _devicesCubit;
  late final NotificationsCubit _notificationsCubit;

  @override
  void initState() {
    super.initState();
    _router = widget.router ?? createAppRouter();
    _themeCubit = widget.themeCubit ??
        (sl.isRegistered<ThemeCubit>() ? sl<ThemeCubit>() : ThemeCubit());
    _authCubit = widget.authCubit ??
        (sl.isRegistered<AuthCubit>()
            ? sl<AuthCubit>()
            : AuthCubit(
                authRepository: sl.isRegistered<AuthRepository>()
                    ? sl<AuthRepository>()
                    : AuthRepositoryImpl(
                        remoteDataSource: AuthRemoteDataSourceImpl(),
                      ),
              ));
    _profileCubit = widget.profileCubit ??
        (sl.isRegistered<ProfileCubit>()
            ? sl<ProfileCubit>()
            : ProfileCubit(
                profileRepository: sl.isRegistered<ProfileRepository>()
                    ? sl<ProfileRepository>()
                    : ProfileRepositoryImpl(
                        remoteDataSource: ProfileRemoteDataSourceImpl(),
                      ),
                photoService: sl.isRegistered<ProfilePhotoService>()
                    ? sl<ProfilePhotoService>()
                    : ProfilePhotoServiceImpl(),
              ));
    _roomsCubit = widget.roomsCubit ??
        (sl.isRegistered<RoomsCubit>()
            ? sl<RoomsCubit>()
            : RoomsCubit(
                roomsRepository: sl.isRegistered<RoomsRepository>()
                    ? sl<RoomsRepository>()
                    : RoomsRepositoryImpl(
                        remoteDataSource: RoomsRemoteDataSourceImpl(),
                      ),
                devicesRepository: sl.isRegistered<DevicesRepository>()
                    ? sl<DevicesRepository>()
                    : DevicesRepositoryImpl(
                        remoteDataSource: DevicesRemoteDataSourceImpl(),
                      ),
              ));
    _devicesCubit = widget.devicesCubit ??
        (sl.isRegistered<DevicesCubit>()
            ? sl<DevicesCubit>()
            : DevicesCubit(
                devicesRepository: sl.isRegistered<DevicesRepository>()
                    ? sl<DevicesRepository>()
                    : DevicesRepositoryImpl(
                        remoteDataSource: DevicesRemoteDataSourceImpl(),
                      ),
              ));
    _notificationsCubit = widget.notificationsCubit ??
        (sl.isRegistered<NotificationsCubit>()
            ? sl<NotificationsCubit>()
            : NotificationsCubit(
                notificationsRepository: sl.isRegistered<NotificationsRepository>()
                    ? sl<NotificationsRepository>()
                    : NotificationsRepositoryImpl(
                        remoteDataSource: NotificationsRemoteDataSourceImpl(),
                      ),
              ));
  }

  @override
  void dispose() {
    if (widget.router == null) {
      _router.dispose();
    }
    if (widget.themeCubit == null) {
      _themeCubit.close();
    }
    if (widget.authCubit == null) {
      _authCubit.close();
    }
    if (widget.profileCubit == null) {
      _profileCubit.close();
    }
    if (widget.roomsCubit == null) {
      _roomsCubit.close();
    }
    if (widget.devicesCubit == null) {
      _devicesCubit.close();
    }
    if (widget.notificationsCubit == null) {
      _notificationsCubit.close();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<ThemeCubit>.value(value: _themeCubit),
        BlocProvider<AuthCubit>.value(value: _authCubit),
        BlocProvider<ProfileCubit>.value(value: _profileCubit),
        BlocProvider<RoomsCubit>.value(value: _roomsCubit),
        BlocProvider<DevicesCubit>.value(value: _devicesCubit),
        BlocProvider<NotificationsCubit>.value(value: _notificationsCubit),
      ],
      child: BlocListener<AuthCubit, AuthState>(
        listener: (context, authState) {
          if (authState is Authenticated) {
            final uid = authState.user.id;
            _profileCubit.loadProfile(uid);
            _roomsCubit.loadRooms(uid);
            _devicesCubit.loadDevices(uid);
            _notificationsCubit.loadNotifications(uid);
          }
        },
        child: BlocBuilder<ThemeCubit, ThemeMode>(
          builder: (context, themeMode) {
            return MaterialApp.router(
              title: 'Nestora Smart Home',
              debugShowCheckedModeBanner: false,
              theme: AppTheme.lightTheme,
              darkTheme: AppTheme.darkTheme,
              themeMode: themeMode == ThemeMode.system ? ThemeMode.light : themeMode,
              routerConfig: _router,
            );
          },
        ),
      ),
    );
  }
}
