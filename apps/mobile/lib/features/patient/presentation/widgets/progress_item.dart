import 'package:flutter/material.dart';
import '../../../../core/utils/locale_format.dart';

class ProgressItem extends StatelessWidget {
  final String title;
  final double progress;
  final String subtitle;

  const ProgressItem({
    super.key,
    required this.title,
    required this.progress,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: progress),
      duration: const Duration(seconds: 1),
      curve: Curves.easeOut,
      builder: (context, animatedProgress, child) {
        return Column(
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 60,
                  height: 60,
                  child: CircularProgressIndicator(
                    value: animatedProgress,
                    backgroundColor:
                        Theme.of(context).colorScheme.primary.withOpacity(0.2),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      progress == 1.0
                          ? Colors.green
                          : Theme.of(context).colorScheme.primary,
                    ),
                    strokeWidth: 6,
                  ),
                ),
                TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0.0, end: animatedProgress),
                  duration: const Duration(milliseconds: 500),
                  builder: (context, textProgress, child) {
                    return Text(
                      LocaleFormat.percent(context, textProgress * 100),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 10,
                color: Theme.of(context).colorScheme.secondary.withOpacity(0.7),
              ),
            ),
          ],
        );
      },
    );
  }
}
