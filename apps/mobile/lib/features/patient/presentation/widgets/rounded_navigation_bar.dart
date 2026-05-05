import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/services/visit_context.dart';

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
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.medical_services,
                    color: Theme.of(context).colorScheme.primary,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'What would you like to do?',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            // Action Options
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _buildVisitActionOption(
                      'Audio Record Conversation',
                      'Record your doctor visit for automatic summary',
                      Icons.mic,
                      Colors.blue,
                      () {
                        Navigator.of(context).pop();
                        // Start a new visit and navigate to recording
                        final visitId = VisitContext().startNewVisit();
                        context.go('/patient/record-visit/$visitId');
                      },
                    ),
                    const SizedBox(height: 24),
                    _buildVisitActionOption(
                      'Capture & Scan',
                      'Take photos of reports, pill bottles, and documents',
                      Icons.camera_alt,
                      Colors.green,
                      () {
                        Navigator.of(context).pop();
                        final visitContext = VisitContext();
                        final visitId = visitContext.getCurrentVisitId() ??
                            visitContext.startNewVisit();
                        context.go('/patient/camera/$visitId');
                      },
                    ),
                  ],
                ),
              ),
            ),

            // Close Button
            Container(
              padding: const EdgeInsets.all(20),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
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
    );
  }

  Widget _buildVisitActionOption(
    String title,
    String description,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
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
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 14,
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
        ),
        border: const Border(
          top: BorderSide(
            color: Colors.white,
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: widget.routes != null
            ? _caregiverNavItems()
            : _patientNavItems(),
      ),
    );
  }

  List<Widget> _patientNavItems() {
    return [
      _buildNavItem(
        NavigationItem.home,
        Icons.home_outlined,
        Icons.home,
        'Home',
      ),
      _buildNavItem(
        NavigationItem.visits,
        Icons.grid_view,
        Icons.grid_view,
        'Visits',
      ),
      _buildNavItem(
        NavigationItem.overview,
        Icons.assignment,
        Icons.assignment,
        'Overview',
      ),
      _buildNavItem(
        NavigationItem.careTeam,
        Icons.group,
        Icons.group,
        'Care Team',
      ),
      _buildNavItem(
        NavigationItem.profile,
        Icons.account_circle_outlined,
        Icons.account_circle,
        'Profile',
      ),
    ];
  }

  List<Widget> _caregiverNavItems() {
    return [
      _buildNavItem(
        NavigationItem.home,
        Icons.home_outlined,
        Icons.home,
        'Home',
        compact: true,
      ),
      _buildNavItem(
        NavigationItem.visits,
        Icons.grid_view,
        Icons.grid_view,
        'Visits',
        compact: true,
      ),
      _buildNavItem(
        NavigationItem.overview,
        Icons.assignment,
        Icons.assignment,
        'Overview',
        compact: true,
      ),
      _buildNavItem(
        NavigationItem.careTeam,
        Icons.group,
        Icons.group,
        'Care\nTeam',
        compact: true,
      ),
      _buildNavItem(
        NavigationItem.profile,
        Icons.account_circle_outlined,
        Icons.account_circle,
        'Profile',
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

    return GestureDetector(
      onTap: () => _onItemTapped(item),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 4 : 12,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF2C6E6E)
                  .withOpacity(0.9) // Subtle teal pill-shape glow
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? activeIcon : inactiveIcon,
              color: isSelected
                  ? const Color(0xFFFFD700) // Brighter gold for active state
                  : const Color(0xFFE6CFA1), // Soft gold for inactive state
              size: compact ? 22 : 24,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: compact ? 9 : 11,
                height: 1.05,
                color: isSelected
                    ? Colors.white // White/beige for active state
                    : const Color(0xFFE6CFA1), // Soft gold for inactive state
                fontWeight: FontWeight.w500, // Regular to medium weight
                fontFamily: 'Roboto', // Clean sans-serif font
              ),
            ),
          ],
        ),
      ),
    );
  }
}
