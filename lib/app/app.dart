import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'app_shell.dart';
import 'app_state.dart';
import 'theme/app_theme.dart';
import 'theme/theme_cubit.dart';
import '../features/auth/presentation/pages/onboarding_page.dart';
import '../features/auth/presentation/pages/splash_page.dart';
import '../features/auth/presentation/pages/welcome_page.dart';

class NestoraApp extends StatefulWidget {
  const NestoraApp({super.key});

  @override
  State<NestoraApp> createState() => _NestoraAppState();
}

class _NestoraAppState extends State<NestoraApp> {
  late final AppState _appState;

  @override
  void initState() {
    super.initState();
    _appState = AppState();
  }

  @override
  void dispose() {
    _appState.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ThemeCubit(),
      child: AppStateScope(
        notifier: _appState,
        child: BlocBuilder<ThemeCubit, ThemeMode>(
          builder: (context, themeMode) {
            return MaterialApp(
              title: 'Nestora Smart Home',
              debugShowCheckedModeBanner: false,
              theme: AppTheme.lightTheme,
              darkTheme: AppTheme.darkTheme,
              themeMode: themeMode,
              home: _AppNavigatorRoot(),
            );
          },
        ),
      ),
    );
  }
}

class _AppNavigatorRoot extends StatefulWidget {
  @override
  State<_AppNavigatorRoot> createState() => _AppNavigatorRootState();
}

class _AppNavigatorRootState extends State<_AppNavigatorRoot> {
  bool _splashCompleted = false;
  bool _onboardingCompleted = false;
  bool _isAuthenticated = false;

  @override
  Widget build(BuildContext context) {
    if (!_splashCompleted) {
      return SplashPage(
        onFinish: () {
          setState(() {
            _splashCompleted = true;
          });
        },
      );
    }

    if (!_onboardingCompleted) {
      return OnboardingPage(
        onStart: () {
          setState(() {
            _onboardingCompleted = true;
          });
        },
      );
    }

    if (!_isAuthenticated) {
      return WelcomePage(
        onGetStarted: () {
          setState(() {
            _isAuthenticated = true;
          });
        },
        onLogin: () {
          setState(() {
            _isAuthenticated = true;
          });
        },
      );
    }

    return AppShell(
      onLogout: () {
        setState(() {
          _isAuthenticated = false;
        });
      },
    );
  }
}

