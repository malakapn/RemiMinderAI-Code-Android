import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/models/user.dart';
import '../providers/auth_provider.dart';

class RoleSelectionScreen extends ConsumerWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedRole = ref.watch(selectedRoleProvider);

    final compactLayout = MediaQuery.sizeOf(context).height < 700;
    final gapAfterHeader = compactLayout ? 24.0 : 48.0;
    final gapBetweenCards = compactLayout ? 16.0 : 24.0;
    final gapBeforeContinue = compactLayout ? 16.0 : 32.0;
    final gapBeforeDots = compactLayout ? 16.0 : 24.0;
    final gapBottom = compactLayout ? 12.0 : 16.0;

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
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: compactLayout ? 12 : 20),
              Text(
                'Choose Your Role',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      fontSize: compactLayout ? 28 : 32,
                      fontWeight: FontWeight
                          .w700, // Explicit bold weight for Merriweather
                    ),
              ),
              const SizedBox(height: 12),
              Text(
                'Select how you\'ll be using RemiMinder',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.secondary,
                      fontSize: 18,
                    ),
              ),
              SizedBox(height: gapAfterHeader),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _RoleCard(
                        title: 'Patient',
                        description:
                            'Manage your own medications, appointments, and health records',
                        iconPath: 'assets/images/patient_icon.svg',
                        isSelected: selectedRole == UserRole.patient,
                        compactLayout: compactLayout,
                        onTap: () => ref
                            .read(selectedRoleProvider.notifier)
                            .selectRole(UserRole.patient),
                      ),
                      SizedBox(height: gapBetweenCards),
                      _RoleCard(
                        title: 'Caregiver',
                        description:
                            'Help manage medications and care for family members or patients',
                        iconPath: 'assets/images/caregiver_icon.svg',
                        isSelected: selectedRole == UserRole.caregiver,
                        compactLayout: compactLayout,
                        onTap: () => ref
                            .read(selectedRoleProvider.notifier)
                            .selectRole(UserRole.caregiver),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: gapBeforeContinue),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: selectedRole != null
                      ? () => _onContinue(context, ref, selectedRole)
                      : null,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                    backgroundColor: selectedRole != null
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).disabledColor,
                  ),
                  child: const Text(
                    'Continue',
                    style: TextStyle(
                      fontSize: 18,
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
      ),
    );
  }

  void _onContinue(BuildContext context, WidgetRef ref, UserRole selectedRole) {
    // Pass the selected role to the login/register screens
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

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: EdgeInsets.all(compactLayout ? 16 : 24),
        decoration: BoxDecoration(
          color: isSelected ? _teal : _cream,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _teal,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            SvgPicture.asset(
              iconPath,
              width: 32,
              height: 32,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Merriweather',
                      color: textColor,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 15,
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w400,
                      color: textColor,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check,
                color: _cream,
                size: 24,
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
