import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'screens/announcement/announcement_screen.dart';
import 'screens/attendance/attendance_screen.dart';
import 'screens/branch/branch_screen.dart';
import 'screens/customer/customer_screen.dart';
import 'screens/dashboard/dashboard_screen.dart';
import 'screens/department/department_screen.dart';
import 'screens/employee/employee_screen.dart';
import 'screens/employee/employee_portal_screen.dart';
import 'screens/leave/leave_screen.dart';
import 'screens/login/login_screen.dart';
import 'screens/login/management_area_screen.dart';
import 'screens/position/position_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/salary/payroll_screen.dart';
import 'screens/service/commission_screen.dart';
import 'screens/service/service_history_screen.dart';
import 'services/supabase_service.dart';
import 'widgets/app_shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseService.initialize();
  runApp(const ProviderScope(child: HrApp()));
}

class HrApp extends ConsumerWidget {
  const HrApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = GoRouter(
      initialLocation: SupabaseService.isConfigured ? '/login' : '/',
      refreshListenable: Listenable.merge([
        EmployeeSession.notifier,
        EmployeeSession.managementAreaNotifier,
        EmployeeSession.branchScopeNotifier,
      ]),
      redirect: (context, state) {
        if (!SupabaseService.isConfigured || !SupabaseService.isInitialized) {
          return null;
        }
        final loggedIn = EmployeeSession.isLoggedIn;
        final loggingIn = state.matchedLocation == '/login';
        final choosingArea = state.matchedLocation == '/access';
        final hasArea = EmployeeSession.managementArea != null;
        if (!loggedIn && !loggingIn) return '/login';
        if (loggedIn && EmployeeSession.isEmployee) {
          return state.matchedLocation == '/employee' ? null : '/employee';
        }
        if (loggedIn && !hasArea && !choosingArea) return '/access';
        if (loggedIn && hasArea && (loggingIn || choosingArea)) {
          return '/';
        }

        const storePaths = {
          '/services',
          '/service-history',
          '/customers',
          '/branches',
          '/announcements',
        };
        const employeePaths = {
          '/employees',
          '/departments',
          '/positions',
          '/commissions',
          '/profile',
          '/attendance',
          '/leave',
          '/payroll',
        };
        if (loggedIn &&
            EmployeeSession.isStoreManagement &&
            employeePaths.contains(state.matchedLocation)) {
          return '/services';
        }
        if (loggedIn &&
            EmployeeSession.isEmployeeManagement &&
            storePaths.contains(state.matchedLocation)) {
          return '/';
        }
        if (loggedIn && state.matchedLocation == '/employee') {
          if (!hasArea) return '/access';
          return '/';
        }
        return null;
      },
      routes: [
        GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
        GoRoute(
          path: '/employee',
          builder: (_, __) => const EmployeePortalScreen(),
        ),
        GoRoute(
          path: '/access',
          builder: (_, __) => const ManagementAreaScreen(),
        ),
        ShellRoute(
          builder: (context, state, child) => AppShell(
            key: ValueKey(EmployeeSession.activeBranchId),
            child: child,
          ),
          routes: [
            GoRoute(path: '/', builder: (_, __) => const DashboardScreen()),
            GoRoute(
                path: '/employees', builder: (_, __) => const EmployeeScreen()),
            GoRoute(
                path: '/departments',
                builder: (_, __) => const DepartmentScreen()),
            GoRoute(
                path: '/branches', builder: (_, __) => const BranchScreen()),
            GoRoute(
                path: '/customers', builder: (_, __) => const CustomerScreen()),
            GoRoute(
                path: '/positions', builder: (_, __) => const PositionScreen()),
            GoRoute(
                path: '/attendance',
                builder: (_, __) => const AttendanceScreen()),
            GoRoute(path: '/leave', builder: (_, __) => const LeaveScreen()),
            GoRoute(
                path: '/payroll', builder: (_, __) => const PayrollScreen()),
            GoRoute(
                path: '/services',
                builder: (_, __) => const ServiceHistoryScreen()),
            GoRoute(
                path: '/service-history',
                builder: (_, __) =>
                    const ServiceHistoryScreen(historyOnly: true)),
            GoRoute(
                path: '/commissions',
                builder: (_, __) => const CommissionScreen()),
            GoRoute(
                path: '/announcements',
                builder: (_, __) => const AnnouncementScreen()),
            GoRoute(
                path: '/profile', builder: (_, __) => const ProfileScreen()),
          ],
        ),
      ],
    );

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: '22Twentytwo HR',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xffd4537e),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: Colors.white,
        fontFamily: 'Sarabun',
        fontFamilyFallback: const [
          'Noto Sans Thai',
          'Tahoma',
        ],
        visualDensity: VisualDensity.standard,
        textTheme: ThemeData.light().textTheme.apply(
              fontFamily: 'Sarabun',
              bodyColor: const Color(0xff1a1a1a),
              displayColor: const Color(0xff1a1a1a),
            ),
        cardTheme: const CardTheme(
          color: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(10)),
            side: BorderSide(color: Color(0xfff0f0f0)),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xffd4537e),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            textStyle: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xffd4537e),
            side: const BorderSide(color: Color(0xfff0f0f0)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            textStyle: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xfff0f0f0)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xfff0f0f0)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xffd4537e)),
          ),
        ),
      ),
      routerConfig: router,
    );
  }
}
