import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/models/user.dart';
import '../../../../l10n/app_localizations.dart';
import '../providers/auth_provider.dart';

class RoleSelectionScreen extends ConsumerWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedRole = ref.watch(selectedRoleProvider);
    final l10n = AppLocalizations.of(context)!;

    final compactLayout = MediaQuery.sizeOf(context).height < 820;
    final gapAfterHeader = compactLayout ? 12.0 : 20.0;
    final gapBetweenCards = compactLayout ? 10.0 : 14.0;
    final gapBeforeContinue = compactLayout ? 14.0 : 20.0;
    final gapBeforeDots = compactLayout ? 10.0 : 14.0;
    final gapBottom = compactLayout ? 8.0 : 12.0;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Theme.of(context).colorScheme.primary,
          ),
          onPressed: () => context.go('/welcome'),
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: compactLayout ? 2 : 8),
                    Text(
                      l10n.chooseYourRole,
                      style:
                          Theme.of(context).textTheme.headlineLarge?.copyWith(
                                fontSize: compactLayout ? 24 : 28,
                                fontWeight: FontWeight.w700,
                              ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      l10n.chooseYourRoleSubtitle,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Theme.of(context).colorScheme.secondary,
                            fontSize: compactLayout ? 15 : 17,
                          ),
                    ),
                    SizedBox(height: gapAfterHeader),
                    _RoleCard(
                      title: l10n.patientRole,
                      description: l10n.patientRoleCardDescription,
                      iconPath: 'assets/images/patient_icon.svg',
                      isSelected: selectedRole == UserRole.patient,
                      compactLayout: compactLayout,
                      onTap: () => ref
                          .read(selectedRoleProvider.notifier)
                          .selectRole(UserRole.patient),
                    ),
                    SizedBox(height: gapBetweenCards),
                    _RoleCard(
                      title: l10n.caregiverRole,
                      description: l10n.caregiverRoleCardDescription,
                      iconPath: 'assets/images/caregiver_icon.svg',
                      isSelected: selectedRole == UserRole.caregiver,
                      compactLayout: compactLayout,
                      onTap: () => ref
                          .read(selectedRoleProvider.notifier)
                          .selectRole(UserRole.caregiver),
                    ),
                    SizedBox(height: gapBeforeContinue),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: selectedRole != null
                            ? () => _onContinue(context, ref, selectedRole)
                            : null,
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(
                            vertical: compactLayout ? 13 : 15,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                          backgroundColor: selectedRole != null
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).disabledColor,
                        ),
                        child: Text(
                          l10n.continueButton,
                          style: TextStyle(
                            fontSize: compactLayout ? 16 : 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: gapBeforeDots),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _IndicatorDot(isActive: false),
                        SizedBox(width: 8),
                        _IndicatorDot(isActive: true),
                        SizedBox(width: 8),
                        _IndicatorDot(isActive: false),
                      ],
                    ),
                    SizedBox(height: gapBottom),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _onContinue(BuildContext context, WidgetRef ref, UserRole selectedRole) {
    final roleParam =
        selectedRole == UserRole.patient ? 'patient' : 'caregiver';
    context.go('/login?role=$roleParam');
  }
}

class _RoleCard extends StatelessWidget {
  static const Color _cream = Color(0xFFF8F4E8);
  static const Color _teal = Color(0xFF1A3A5C);

  final String title;
  final String description;
  final String iconPath;
  final bool isSelected;
  final bool compactLayout;
  final VoidCallback onTap;

  const _RoleCard({
    required this.title,
    required this.description,
    required this.iconPath,
    required this.isSelected,
    this.compactLayout = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = isSelected ? _cream : _teal;
    final iconSize = compactLayout ? 26.0 : 30.0;
    final textScaler = MediaQuery.textScalerOf(context).clamp(
      maxScaleFactor: 1.1,
    );

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        width: double.infinity,
        padding: EdgeInsets.symmetric(
          horizontal: compactLayout ? 12 : 16,
          vertical: compactLayout ? 10 : 14,
        ),
        decoration: BoxDecoration(
          color: isSelected ? _teal : _cream,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _teal,
            width: 2,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SvgPicture.asset(
                  iconPath,
                  width: iconSize,
                  height: iconSize,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    textScaler: textScaler,
                    style: TextStyle(
                      fontSize: compactLayout ? 17 : 19,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Merriweather',
                      color: textColor,
                    ),
                  ),
                ),
                if (isSelected)
                  Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: Icon(
                      Icons.check_circle,
                      color: _cream,
                      size: compactLayout ? 20 : 22,
                    ),
                  ),
              ],
            ),
            SizedBox(height: compactLayout ? 5 : 6),
            Padding(
              padding: EdgeInsets.only(left: iconSize + 10),
              child: Text(
                description,
                textScaler: textScaler,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: compactLayout ? 12.5 : 13.5,
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w400,
                  color: textColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IndicatorDot extends StatelessWidget {
  final bool isActive;

  const _IndicatorDot({required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: isActive
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
        shape: BoxShape.circle,
      ),
    );
  }
}
