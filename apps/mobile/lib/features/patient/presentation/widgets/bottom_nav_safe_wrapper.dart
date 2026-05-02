import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';

/// Wraps floating bottom navigation so it clears the home indicator (iOS) and
/// system gesture/nav inset (Android). Uses [SafeArea] on iOS; on Android adds
/// explicit [MediaQuery.padding] bottom padding (SafeArea keeps top/left/right,
/// bottom is applied via padding to match the UX spec).
class BottomNavSafeWrapper extends StatelessWidget {
  const BottomNavSafeWrapper({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final isAndroid = defaultTargetPlatform == TargetPlatform.android;

    if (isAndroid) {
      return SafeArea(
        top: false,
        left: false,
        right: false,
        bottom: false,
        minimum: EdgeInsets.zero,
        child: Padding(
          padding: EdgeInsets.only(bottom: bottomInset),
          child: child,
        ),
      );
    }

    return SafeArea(
      top: false,
      left: false,
      right: false,
      bottom: true,
      minimum: EdgeInsets.zero,
      maintainBottomViewPadding: true,
      child: child,
    );
  }
}
