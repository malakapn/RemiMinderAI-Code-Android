import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../features/auth/presentation/providers/auth_provider.dart';
import '../features/auth/data/models/auth_state.dart';
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
import '../features/caregiver/presentation/screens/caregiver_alert_create_screen.dart';
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
import '../features/patient/presentation/screens/send_invitations_screen.dart';
import '../features/patient/presentation/screens/notification_settings_screen.dart';
import '../features/patient/presentation/screens/history_list_screen.dart';

import '../features/patient/presentation/widgets/patient_app_shell.dart';
import '../features/patient/presentation/widgets/rounded_navigation_bar.dart';

class PlaceholderScreen extends StatelessWidget {
  final String title;
  const PlaceholderScreen({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Text('$title Screen\nComing Soon!', textAlign: TextAlign.center),
      ),
    );
  }
}

/// Bridges Riverpod auth state into a Listenable for GoRouter's refreshListenable.
/// Implements both Notifier (Riverpod) and Listenable (go_router) interfaces.
class _RouterNotifier extends Notifier<void> implements Listenable {
  final List<VoidCallback> _listeners = [];

  @override
  void build() {
    ref.listen<AuthState>(authNotifierProvider, (_, __) {
      for (final l in List.of(_listeners)) {
        l();
      }
    });
  }

  AuthState get authState => ref.read(authNotifierProvider);

  @override
  void addListener(VoidCallback listener) => _listeners.add(listener);

  @override
  void removeListener(VoidCallback listener) => _listeners.remove(listener);
}

final _routerNotifierProvider =
    NotifierProvider<_RouterNotifier, void>(_RouterNotifier.new);

/// App router — created once, uses refreshListenable so redirect re-runs on
/// auth changes without recreating the GoRouter.
final appRouterProvider = Provider<GoRouter>((ref) {
  final notifier = ref.watch(_routerNotifierProvider.notifier);

  bool isPublicAuthPath(String path) =>
      path == '/welcome' ||
      path == '/role-selection' ||
      path == '/login' ||
      path == '/register' ||
      path == '/forgot-password';

  bool isCaregiverPath(String path) => path.startsWith('/caregiver');

  bool isPatientPath(String path) =>
      path.startsWith('/patient') && path != '/patient/visit-details';

  return GoRouter(
    initialLocation: '/welcome',
    refreshListenable: notifier,
    redirect: (context, state) {
      final authState = notifier.authState;
      final path = state.uri.path;
      final loggedIn = authState.isAuthenticated;
      final user = authState.user;

      // Auth still resolving — stay on public auth stack (Welcome is first paint).
      if (authState.status == AuthStatus.initial ||
          authState.status == AuthStatus.loading) {
        if (isPublicAuthPath(path)) return null;
        return '/welcome';
      }

      // Signed out (or error) — keep onboarding routes; everything else → Welcome.
      if (!loggedIn) {
        return isPublicAuthPath(path) ? null : '/welcome';
      }

      // Logged in — leave protected routes alone, push off auth pages
      if (isPublicAuthPath(path)) {
        return (user?.isCaregiver ?? false)
            ? '/caregiver/home'
            : '/patient/home';
      }

      // Role-based enforcement
      if (isCaregiverPath(path) && !(user?.isCaregiver ?? false)) {
        return '/patient/home';
      }
      if (isPatientPath(path) && !(user?.isPatient ?? false)) {
        return '/caregiver/home';
      }

      return null;
    },
    routes: [
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
        builder: (context, state) => RegisterScreen(
          inviteToken: state.uri.queryParameters['inviteToken'],
        ),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),

      ShellRoute(
        builder: (context, state, child) {
          final location = state.uri.path;
          final currentItem = getCurrentNavigationItem(location);
          final isCaregiver = location.startsWith('/caregiver');
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
            path: '/caregiver/alerts',
            builder: (context, state) => AlertListScreen(
              initialPatientId: state.uri.queryParameters['patientId'],
              initialPatientName: state.uri.queryParameters['patientName'],
            ),
          ),
          GoRoute(
            path: '/caregiver/accept-invitations',
            builder: (context, state) => const AcceptInvitationsScreen(),
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

      GoRoute(
        path: '/caregiver/patient-overview',
        builder: (context, state) => const PatientOverviewScreen(),
      ),
      GoRoute(
        path: '/caregiver/alerts/create',
        builder: (context, state) => const CaregiverAlertCreateScreen(),
      ),
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
          return VisitDetailsScreen(visitId: visitId, visitDate: visitDate);
        },
      ),
      GoRoute(
        path: '/patient/reminders',
        builder: (context, state) {
          final q = state.uri.queryParameters;
          final openAdd = q['add'] == '1' || q['openAdd'] == 'true';
          final prefill =
              q['prefill_title'] ?? q['title'] ?? q['prefillTitle'];
          return RemindersScreen(
            openAddOnLaunch: openAdd,
            prefillReminderTitle: prefill,
          );
        },
      ),
      GoRoute(
        path: '/patient/reminder/:reminderId',
        builder: (context, state) {
          final id = state.pathParameters['reminderId']!;
          return ReminderDetailScreen(reminderId: id);
        },
      ),
      GoRoute(
        path: '/patient/invitations',
        builder: (context, state) => const SendInvitationsScreen(),
      ),
      GoRoute(
        path: '/patient/notifications',
        builder: (context, state) => const NotificationSettingsScreen(),
      ),
      GoRoute(
        path: '/patient/history',
        builder: (context, state) => const HistoryListScreen(),
      ),
    ],
  );
});
