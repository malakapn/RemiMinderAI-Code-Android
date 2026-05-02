/// Bootstrap screen while auth resolves. The app route `/loading` uses [LoadingScreen].
///
/// The branch `feature/FCM-notification-api-Integration` on RemiMinderAI-Mobile does not
/// contain `splash_screen.dart`; this file aliases the shared implementation and keeps
/// splash asset naming (`splash_screen_logo.png`, etc.) consistent in the tree.
export '../shared/presentation/screens/loading_screen.dart' show LoadingScreen;

typedef SplashScreen = LoadingScreen;
