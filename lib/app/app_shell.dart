import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/widgets/nestora_bottom_nav.dart';
import '../features/auth/presentation/pages/forgot_password_page.dart';
import '../features/auth/presentation/pages/login_page.dart';
import '../features/auth/presentation/pages/onboarding_page.dart';
import '../features/auth/presentation/pages/register_page.dart';
import '../features/auth/presentation/pages/splash_page.dart';
import '../features/auth/presentation/pages/welcome_page.dart';
import '../features/components_preview/presentation/pages/components_preview_page.dart';
import '../features/devices/presentation/pages/ac_control_page.dart';
import '../features/devices/presentation/pages/add_edit_device_page.dart';
import '../features/devices/presentation/pages/devices_page.dart';
import '../features/devices/presentation/pages/lamp_control_page.dart';
import '../features/home/presentation/pages/dashboard_page.dart';
import '../features/notifications/presentation/pages/notifications_page.dart';
import '../features/profile/presentation/pages/profile_page.dart';
import '../features/rooms/presentation/pages/add_edit_room_page.dart';
import '../features/rooms/presentation/pages/room_detail_page.dart';
import '../features/rooms/presentation/pages/rooms_page.dart';
import 'app_state.dart';
import 'theme/app_colors.dart';
import 'theme/app_typography.dart';

class AppShell extends StatefulWidget {
  final VoidCallback? onLogout;
  final Widget? child;

  const AppShell({super.key, this.onLogout, this.child});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _currentIndex = 0;

  int _calculateSelectedIndex(BuildContext context) {
    if (widget.child == null) return _currentIndex;
    try {
      final location = GoRouterState.of(context).matchedLocation;
      if (location.startsWith('/devices')) return 1;
      if (location.startsWith('/profile')) return 2;
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
          context.go('/devices');
          break;
        case 2:
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
    final appState = AppStateScope.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final pages = [
      DashboardPage(
        onNavigateToDevices: () => setState(() => _currentIndex = 1),
        onNavigateToProfile: () => setState(() => _currentIndex = 2),
      ),
      DevicesPage(
        onNavigateToProfile: () => setState(() => _currentIndex = 2),
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
      floatingActionButton: kDebugMode
          ? FloatingActionButton.extended(
              onPressed: () => _showScreenNavigator(context, appState),
              backgroundColor: AppColors.primaryContainer,
              foregroundColor: Colors.white,
              elevation: 4,
              icon: const Icon(Icons.grid_view_rounded, size: 20),
              label: Text(
                '16 Ekran Galerisi',
                style: AppTypography.labelSmall.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          : null,
    );
  }

  void _showScreenNavigator(BuildContext context, AppState appState) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final screens = [
      {'num': '1', 'title': 'Nestora - Açılış (Splash)', 'page': const SplashPage()},
      {'num': '1B', 'title': 'Nestora - Açılış / Kaydırarak Başla (Onboarding)', 'page': const OnboardingPage()},
      {'num': '2', 'title': 'Nestora - Odalarım', 'page': const RoomsPage()},
      {'num': '3', 'title': 'Nestora - Cihazlarım', 'page': const DevicesPage()},
      {'num': '4', 'title': 'Nestora - Yatak Odası Klima Kontrolü', 'page': const AcControlPage()},
      {
        'num': '5',
        'title': 'Nestora - Salon Oda Detayı',
        'page': RoomDetailPage(room: appState.rooms.first),
      },
      {'num': '6', 'title': 'Nestora - Oda Ekle ve Düzenle', 'page': const AddEditRoomPage()},
      {'num': '7', 'title': 'Nestora - Salon Lambası Kontrolü', 'page': const LampControlPage()},
      {'num': '8', 'title': 'Nestora - Cihaz Ekle ve Düzenle', 'page': const AddEditDevicePage()},
      {'num': '9', 'title': 'Nestora - Giriş Yap', 'page': const LoginPage()},
      {'num': '10', 'title': 'Nestora - Karşılama (Welcome)', 'page': const WelcomePage()},
      {'num': '11', 'title': 'Nestora - Şifremi Unuttum', 'page': const ForgotPasswordPage()},
      {'num': '12', 'title': 'Nestora - Ana Sayfa (Dashboard)', 'page': const DashboardPage()},
      {'num': '13', 'title': 'Nestora - Profil ve Ayarlar', 'page': const ProfilePage()},
      {'num': '14', 'title': 'Nestora - Bildirimler', 'page': const NotificationsPage()},
      {'num': '15', 'title': 'Nestora - Kayıt Ol', 'page': const RegisterPage()},
      {'num': '16', 'title': 'Nestora - Bileşenler ve Durumlar', 'page': const ComponentsPreviewPage()},
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Container(
          height: MediaQuery.of(sheetContext).size.height * 0.85,
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : AppColors.lightCard,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.secondary.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Nestora 16 Ekran Galerisi',
                          style: AppTypography.headlineMedium.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                          ),
                        ),
                        Text(
                          'Stitch Proje ID: 9851939946750442552',
                          style: AppTypography.caption.copyWith(color: AppColors.secondary),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(sheetContext),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  itemCount: screens.length,
                  separatorBuilder: (ctx, i) => const SizedBox(height: 8),
                  itemBuilder: (ctx, i) {
                    final item = screens[i];
                    return ListTile(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: BorderSide(
                          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                        ),
                      ),
                      tileColor: isDark ? AppColors.darkCardSecondary : AppColors.lightCardSecondary,
                      leading: Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: AppColors.primaryContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            item['num'] as String,
                            style: AppTypography.labelMedium.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      title: Text(
                        item['title'] as String,
                        style: AppTypography.bodyMedium.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                        ),
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.secondary),
                      onTap: () {
                        Navigator.pop(sheetContext);
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => item['page'] as Widget),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
