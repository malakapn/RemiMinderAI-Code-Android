import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/services/visit_context.dart';
import '../../../../l10n/app_localizations.dart';

enum NavigationItem {
  home,
  visits,
  overview,
  careTeam,
  profile,
}

class RoundedNavigationBar extends StatefulWidget {
  final NavigationItem currentItem;
  final Map<NavigationItem, String>? routes;

  const RoundedNavigationBar({
    super.key,
    required this.currentItem,
    this.routes,
  });

  @override
  State<RoundedNavigationBar> createState() => _RoundedNavigationBarState();
}

class _RoundedNavigationBarState extends State<RoundedNavigationBar> {
  void _onItemTapped(NavigationItem item) {
    if (item == widget.currentItem) return;

    if (widget.routes != null) {
      final route = widget.routes![item];
      if (route != null) {
        context.go(route);
      }
      return;
    }

    switch (item) {
      case NavigationItem.home:
        context.go('/patient/home');
        break;
      case NavigationItem.visits:
        _showVisitActionSelection();
        break;
      case NavigationItem.overview:
        context.go('/patient/overview');
        break;
      case NavigationItem.careTeam:
        context.go('/patient/care-team');
        break;
      case NavigationItem.profile:
        context.go('/patient/profile');
        break;
    }
  }

  void _showVisitActionSelection() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final compactLayout = MediaQuery.sizeOf(sheetContext).height < 700;
        final sheetPadding = compactLayout ? 16.0 : 20.0;
        final gapBetweenOptions = compactLayout ? 16.0 : 24.0;
        final maxSheetHeight = MediaQuery.sizeOf(sheetContext).height * 0.85;

        return Container(
          constraints: BoxConstraints(maxHeight: maxSheetHeight),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: EdgeInsets.all(sheetPadding),
                    decoration: BoxDecoration(
                      color: Theme.of(sheetContext)
                          .colorScheme
                          .primary
                          .withOpacity(0.1),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.medical_services,
                          color:
                              Theme.of(sheetContext).colorScheme.primary,
                          size: compactLayout ? 24 : 28,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'What would you like to do?',
                            style: TextStyle(
                              fontSize: compactLayout ? 18 : 20,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.all(sheetPadding),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildVisitActionOption(
                          sheetContext,
                          'Audio Record Conversation',
                          'Record your doctor visit for automatic summary',
                          Icons.mic,
                          Colors.blue,
                          compactLayout: compactLayout,
                          onTap: () {
                            Navigator.of(sheetContext).pop();
                            final visitId = VisitContext().startNewVisit();
                            context.go('/patient/record-visit/$visitId');
                          },
                        ),
                        SizedBox(height: gapBetweenOptions),
                        _buildVisitActionOption(
                          sheetContext,
                          'Capture & Scan',
                          'Take photos of reports, pill bottles, and documents',
                          Icons.camera_alt,
                          Colors.green,
                          compactLayout: compactLayout,
                          onTap: () {
                            Navigator.of(sheetContext).pop();
                            final visitContext = VisitContext();
                            final visitId =
                                visitContext.getCurrentVisitId() ??
                                    visitContext.startNewVisit();
                            context.go('/patient/camera/$visitId');
                          },
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      sheetPadding,
                      0,
                      sheetPadding,
                      sheetPadding,
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(sheetContext).pop(),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildVisitActionOption(
    BuildContext context,
    String title,
    String description,
    IconData icon,
    Color color, {
    required VoidCallback onTap,
    bool compactLayout = false,
  }) {
    final iconSize = compactLayout ? 44.0 : 50.0;
    final contentPadding = compactLayout ? 12.0 : 16.0;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: EdgeInsets.all(contentPadding),
          decoration: BoxDecoration(
            color: color.withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: color.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: iconSize,
                height: iconSize,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: compactLayout ? 22 : 24,
                ),
              ),
              SizedBox(width: compactLayout ? 12 : 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: compactLayout ? 15 : 16,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    SizedBox(height: compactLayout ? 2 : 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: compactLayout ? 13 : 14,
                        color: Theme.of(context)
                            .colorScheme
                            .secondary
                            .withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: Theme.of(context).colorScheme.secondary.withOpacity(0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 20, right: 20, top: 16, bottom: 12),
      height: 70,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF1A4D4D), // Dark teal-green
            Color(0xFF051818), // Very dark green/black
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(35),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 25,
            offset: const Offset(0, 8),
          ),
        ],
        border: const Border(
          top: BorderSide(
            color: Colors.white,
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: widget.routes != null
            ? _caregiverNavItems(AppLocalizations.of(context)!)
            : _patientNavItems(AppLocalizations.of(context)!),
      ),
    );
  }

  List<Widget> _patientNavItems(AppLocalizations l10n) {
    return [
      _buildNavItem(
        NavigationItem.home,
        Icons.home_outlined,
        Icons.home,
        l10n.navHome,
      ),
      _buildNavItem(
        NavigationItem.visits,
        Icons.grid_view,
        Icons.grid_view,
        l10n.navVisits,
      ),
      _buildNavItem(
        NavigationItem.overview,
        Icons.assignment,
        Icons.assignment,
        l10n.navOverview,
      ),
      _buildNavItem(
        NavigationItem.careTeam,
        Icons.group,
        Icons.group,
        l10n.navCareTeam,
      ),
      _buildNavItem(
        NavigationItem.profile,
        Icons.account_circle_outlined,
        Icons.account_circle,
        l10n.navProfile,
      ),
    ];
  }

  List<Widget> _caregiverNavItems(AppLocalizations l10n) {
    return [
      _buildNavItem(
        NavigationItem.home,
        Icons.home_outlined,
        Icons.home,
        l10n.navHome,
        compact: true,
      ),
      _buildNavItem(
        NavigationItem.visits,
        Icons.people_outline,
        Icons.people,
        l10n.navPatients,
        compact: true,
      ),
      _buildNavItem(
        NavigationItem.overview,
        Icons.assignment,
        Icons.assignment,
        l10n.navOverview,
        compact: true,
      ),
      _buildNavItem(
        NavigationItem.careTeam,
        Icons.group,
        Icons.group,
        l10n.navCareTeam,
        compact: true,
      ),
      _buildNavItem(
        NavigationItem.profile,
        Icons.account_circle_outlined,
        Icons.account_circle,
        l10n.navProfile,
        compact: true,
      ),
    ];
  }

  Widget _buildNavItem(
    NavigationItem item,
    IconData inactiveIcon,
    IconData activeIcon,
    String label, {
    bool compact = false,
  }) {
    final isSelected = item == widget.currentItem;

    return Expanded(
      child: GestureDetector(
        onTap: () => _onItemTapped(item),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 2 : 4,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFF2C6E6E).withOpacity(0.9)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isSelected ? activeIcon : inactiveIcon,
                color: isSelected
                    ? const Color(0xFFFFD700)
                    : const Color(0xFFE6CFA1),
                size: compact ? 22 : 24,
              ),
              const SizedBox(height: 2),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: compact ? 9 : 10,
                    height: 1.05,
                    color: isSelected
                        ? Colors.white
                        : const Color(0xFFE6CFA1),
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Roboto',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
