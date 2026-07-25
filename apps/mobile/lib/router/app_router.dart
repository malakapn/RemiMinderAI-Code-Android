import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../features/auth/presentation/providers/auth_provider.dart';
import '../features/auth/data/models/auth_state.dart';
import '../core/models/user.dart';
import '../features/auth/presentation/screens/welcome_screen.dart';
import '../features/auth/presentation/screens/role_selection_screen.dart';
import '../features/auth/presentation/screens/login_screen.dart';
import '../features/auth/presentation/screens/register_screen.dart';
import '../features/auth/presentation/screens/forgot_password_screen.dart';
import '../features/patient/presentation/screens/patient_home_screen.dart';
import '../features/caregiver/presentation/screens/caregiver_home_screen.dart';
import '../features/caregiver/presentation/screens/patient_tab_screen.dart';
import '../features/caregiver/presentation/screens/patient_overview_screen.dart';
import '../features/caregiver/presentation/screens/alert_list_screen.dart';
import '../features/caregiver/presentation/screens/accept_invitations_screen.dart';
import '../features/caregiver/presentation/screens/caregiver_reminder_timeline_screen.dart';
import '../features/patient/presentation/screens/visit_recording_screen.dart';
import '../features/patient/presentation/screens/visit_details_screen.dart';
import '../features/patient/presentation/screens/overview_screen.dart';
import '../features/patient/presentation/screens/reminders_screen.dart';
import '../features/patient/presentation/screens/reminder_detail_screen.dart';
import '../features/patient/presentation/screens/camera_screen.dart';
import '../features/patient/presentation/screens/care_team_screen.dart';
import '../features/patient/presentation/screens/profile_screen.dart';
import '../features/patient/presentation/screens/language_settings_screen.dart';
import '../features/patient/presentation/screens/send_invitations_screen.dart';

import '../features/shared/presentation/screens/loading_screen.dart';
import '../features/patient/presentation/widgets/patient_app_shell.dart';
import '../features/patient/presentation/widgets/rounded_navigation_bar.dart';

/// App router configuration using go_router
final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/loading',
    redirect: (context, state) {
      final authState = ref.read(authNotifierProvider);
      final location = state.uri.path;

      // Don't redirect during loading or on auth screens
      if (authState.status == AuthStatus.loading) return null;

      // Never redirect these screens
      const noRedirectRoutes = [
        '/loading', '/welcome', '/role-selection',
        '/login', '/register', '/forgot-password',
        '/patient/language-settings',
      ];
      if (noRedirectRoutes.contains(location) || location.startsWith('/auth')) {
        return null;
      }

      // If unauthenticated, go to welcome
      if (authState.status == AuthStatus.unauthenticated) {
        return '/welcome';
      }

      // If authenticated, enforce role-based routing
      // Use user.role (from SecureStorage) NOT profile.role (from backend)
      if (authState.status == AuthStatus.authenticated) {
        final role = authState.user?.role;
        final isCaregiver = role == UserRole.caregiver;
        final onCaregiverRoute = location.startsWith('/caregiver');
        final onPatientRoute = location.startsWith('/patient');

        // Only redirect if clearly on wrong role's routes
        // Don't redirect shared routes like /profile
        if (isCaregiver && onPatientRoute) return '/caregiver/home';
        if (!isCaregiver && onCaregiverRoute) return '/patient/home';
      }

      return null;
    },
    errorBuilder: (context, state) => Scaffold(
      backgroundColor: const Color(0xFFF5F0E8),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Color(0xFF1A3A5C)),
            const SizedBox(height: 16),
            const Text('Page not found', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1A3A5C))),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go('/patient/home'),
              child: const Text('Go Home'),
            ),
          ],
        ),
      ),
    ),
    routes: [
      // Loading screen - first screen users see
      GoRoute(
        path: '/loading',
        builder: (context, state) => const LoadingScreen(),
      ),

      // Auth routes
      GoRoute(
        path: '/welcome',
        builder: (context, state) => const WelcomeScreen(),
      ),
      GoRoute(
        path: '/role-selection',
        builder: (context, state) => const RoleSelectionScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),

      // Patient/Caregiver shell route with navigation
      ShellRoute(
        builder: (context, state, child) {
          final location = state.uri.path;
          final currentItem = getCurrentNavigationItem(location);
          // Shared routes like /profile don't start with /caregiver — use auth role.
          final isCaregiver =
              ref.read(authNotifierProvider).user?.role == UserRole.caregiver;
          final caregiverRoutes = isCaregiver
              ? {
                  NavigationItem.home: '/caregiver/home',
                  NavigationItem.visits: '/caregiver/patients',
                  NavigationItem.overview: '/caregiver/alerts',
                  NavigationItem.careTeam: '/caregiver/accept-invitations',
                  NavigationItem.profile: '/profile',
                }
              : null;
          return PatientAppShell(
            currentItem: currentItem,
            routes: caregiverRoutes,
            child: child,
          );
        },
        routes: [
          GoRoute(
            path: '/patient/home',
            builder: (context, state) => const PatientHomeScreen(),
          ),
          GoRoute(
            path: '/patient/overview',
            builder: (context, state) => const OverviewScreen(),
          ),
          GoRoute(
            path: '/patient/care-team',
            builder: (context, state) => const CareTeamScreen(),
          ),
          GoRoute(
            path: '/patient/profile',
            builder: (context, state) => const ProfileScreen(),
          ),
          GoRoute(
            path: '/patient/language-settings',
            builder: (context, state) => const LanguageSettingsScreen(),
          ),
          GoRoute(
            path: '/profile',
            builder: (context, state) => const ProfileScreen(),
          ),
          GoRoute(
            path: '/caregiver/home',
            builder: (context, state) => const CaregiverHomeScreen(),
          ),
          GoRoute(
            path: '/caregiver/patients',
            builder: (context, state) => const PatientTabScreen(),
          ),
          GoRoute(
            path: '/caregiver/patient-overview',
            builder: (context, state) => const PatientOverviewScreen(),
          ),
          GoRoute(
            path: '/caregiver/alerts',
            builder: (context, state) => const AlertListScreen(),
          ),
          GoRoute(
            path: '/caregiver/accept-invitations',
            builder: (context, state) {
              final token = state.uri.queryParameters['token'];
              return AcceptInvitationsScreen(inviteToken: token);
            },
          ),
          GoRoute(
            path: '/caregiver/reminders-timeline',
            builder: (context, state) => CaregiverReminderTimelineScreen(
              initialPatientId: state.uri.queryParameters['patientId'],
              initialReminderType: state.uri.queryParameters['type'],
            ),
          ),
        ],
      ),

      // Patient routes that don't use the navigation shell (modals, full-screen)
      GoRoute(
        path: '/patient/record-visit/:visitId',
        builder: (context, state) {
          final visitId = state.pathParameters['visitId']!;
          return VisitRecordingScreen(visitId: visitId);
        },
      ),
      GoRoute(
        path: '/patient/camera/:visitId',
        builder: (context, state) {
          final visitId = state.pathParameters['visitId']!;
          return CameraScreen(visitId: visitId);
        },
      ),
      GoRoute(
        path: '/patient/scan/:visitId',
        builder: (context, state) {
          final visitId = state.pathParameters['visitId']!;
          return CameraScreen(visitId: visitId);
        },
      ),
      GoRoute(
        path: '/patient/visit-details',
        builder: (context, state) {
          final visitId = state.uri.queryParameters['visitId']!;
          final visitDate = state.uri.queryParameters['visitDate'];
          final patientId = state.uri.queryParameters['patientId'];
          return VisitDetailsScreen(
            visitId: visitId,
            visitDate: visitDate,
            patientId: patientId,
          );
        },
      ),
      GoRoute(
        path: '/caregiver/visit-details',
        builder: (context, state) {
          final visitId = state.uri.queryParameters['visitId']!;
          final visitDate = state.uri.queryParameters['visitDate'];
          final patientId = state.uri.queryParameters['patientId'];
          return VisitDetailsScreen(
            visitId: visitId,
            visitDate: visitDate,
            patientId: patientId,
          );
        },
      ),
      GoRoute(
        path: '/patient/reminders',
        builder: (context, state) => const RemindersScreen(),
      ),
      GoRoute(
        path: '/patient/invitations',
        builder: (context, state) => const SendInvitationsScreen(),
      ),
      GoRoute(
        path: '/accept-invitation',
        builder: (context, state) {
          final token = state.uri.queryParameters['token'];
          return AcceptInvitationsScreen(inviteToken: token);
        },
      ),
      GoRoute(
        path: '/patient/reminder/:reminderId',
        builder: (context, state) {
          final id = state.pathParameters['reminderId']!;
          return ReminderDetailScreen(reminderId: id);
        },
      ),
    ],
  );
});
