import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/widgets/nestora_bottom_nav.dart';
import '../features/devices/presentation/pages/devices_page.dart';
import '../features/home/presentation/pages/dashboard_page.dart';
import '../features/profile/presentation/pages/profile_page.dart';
import '../features/rooms/presentation/pages/rooms_page.dart';
import 'theme/app_colors.dart';

class AppShell extends StatefulWidget {
  final VoidCallback? onLogout;
  final Widget? child;

  const AppShell({super.key, this.onLogout, this.child});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _currentIndex = 0;
  DeviceStatusFilter _devicesInitialStatus = DeviceStatusFilter.all;

  int _calculateSelectedIndex(BuildContext context) {
    if (widget.child == null) return _currentIndex;
    try {
      final location = GoRouterState.of(context).matchedLocation;
      if (location.startsWith('/rooms')) return 1;
      if (location.startsWith('/devices')) return 2;
      if (location.startsWith('/profile')) return 3;
      return 0;
    } catch (_) {
      return _currentIndex;
    }
  }

  void _onItemTapped(int index, BuildContext context) {
    if (widget.child != null) {
      switch (index) {
        case 0:
          context.go('/dashboard');
          break;
        case 1:
          context.go('/rooms');
          break;
        case 2:
          context.go('/devices');
          break;
        case 3:
          context.go('/profile');
          break;
      }
    } else {
      setState(() {
        _currentIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final pages = [
      DashboardPage(
        onNavigateToRooms: () => setState(() => _currentIndex = 1),
        onNavigateToDevices: ({DeviceStatusFilter? status}) {
          setState(() {
            _currentIndex = 2;
            if (status != null) {
              _devicesInitialStatus = status;
            }
          });
        },
        onNavigateToProfile: () => setState(() => _currentIndex = 3),
      ),
      const RoomsPage(),
      DevicesPage(
        initialStatusFilter: _devicesInitialStatus,
        onNavigateToProfile: () => setState(() => _currentIndex = 3),
      ),
      ProfilePage(
        onLogout: widget.onLogout,
      ),
    ];

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightScaffold,
      body: widget.child ??
          IndexedStack(
            sizing: StackFit.expand,
            index: _currentIndex,
            children: pages,
          ),
      bottomNavigationBar: NestoraBottomNav(
        currentIndex: _calculateSelectedIndex(context),
        onTap: (index) => _onItemTapped(index, context),
      ),
    );
  }
}
