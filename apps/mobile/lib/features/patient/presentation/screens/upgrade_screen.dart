import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../../../../core/config/environment.dart';
import '../../../../core/models/monetization_status.dart';
import '../../../../core/services/revenuecat_service.dart';

enum _BillingPlan { monthly, yearly }

/// Premium upgrade: monthly / annual RevenueCat subscription.
class UpgradeScreen extends StatefulWidget {
  const UpgradeScreen({super.key});

  @override
  State<UpgradeScreen> createState() => _UpgradeScreenState();
}

class _UpgradeScreenState extends State<UpgradeScreen> {
  _BillingPlan _selectedPlan = _BillingPlan.monthly;
  bool _loading = false;
  bool _loadingOfferings = true;
  Package? _monthlyPackage;
  Package? _annualPackage;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadOfferings();
  }

  Future<void> _loadOfferings() async {
    try {
      final packages = await RevenueCatService().getOfferings();
      Package? byProductId(String productId) {
        for (final package in packages) {
          if (package.storeProduct.identifier == productId) return package;
        }
        return null;
      }

      Package? byType(PackageType type) {
        for (final package in packages) {
          if (package.packageType == type) return package;
        }
        return null;
      }

      if (!mounted) return;
      setState(() {
        _monthlyPackage = byProductId(Environment.revenueCatMonthlyProductId) ??
            byType(PackageType.monthly);
        _annualPackage = byProductId(Environment.revenueCatAnnualProductId) ??
            byType(PackageType.annual);
        _loadingOfferings = false;
        if (_monthlyPackage == null && _annualPackage == null) {
          _error = 'Premium plans are not available in your store yet.';
        } else if (_monthlyPackage == null) {
          _selectedPlan = _BillingPlan.yearly;
        } else if (_annualPackage == null) {
          _selectedPlan = _BillingPlan.monthly;
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not load Premium options. Please try again.';
        _loadingOfferings = false;
      });
    }
  }

  Future<void> _purchaseSelectedPlan() async {
    if (_loading) return;
    final package = _selectedPlan == _BillingPlan.monthly
        ? _monthlyPackage
        : _annualPackage;
    if (package == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Premium options are still loading.')),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      final premium = await RevenueCatService().purchase(package);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            premium
                ? 'Premium is active. Vox and Premium features are unlocked.'
                : 'Purchase completed, but Premium is not active yet. Please try restore purchases.',
          ),
        ),
      );
      if (premium) _closeUpgrade();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Purchase could not be completed: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _restorePurchases() async {
    if (_loading) return;
    setState(() => _loading = true);
    try {
      await RevenueCatService().restorePurchases();
      final premium = RevenueCatService().isPremium;
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            premium
                ? 'Purchases restored. Premium is active.'
                : 'No active Premium subscription was found.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Restore failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Package? _packageFor(_BillingPlan plan) =>
      plan == _BillingPlan.monthly ? _monthlyPackage : _annualPackage;

  String _priceFor(_BillingPlan plan) {
    final package = _packageFor(plan);
    final price = package?.storeProduct.priceString.trim();
    if (price != null && price.isNotEmpty) return price;
    return '—';
  }

  String _periodFor(_BillingPlan plan) {
    final package = _packageFor(plan);
    switch (package?.packageType) {
      case PackageType.monthly:
        return '/ month';
      case PackageType.annual:
        return '/ year';
      default:
        return plan == _BillingPlan.monthly ? '/ month' : '/ year';
    }
  }

  String _titleFor(_BillingPlan plan) {
    final package = _packageFor(plan);
    final title = package?.storeProduct.title.trim();
    if (title != null && title.isNotEmpty) {
      switch (package?.packageType) {
        case PackageType.monthly:
          return 'Monthly';
        case PackageType.annual:
          return 'Annual';
        default:
          break;
      }
    }
    return plan == _BillingPlan.monthly ? 'Monthly' : 'Annual';
  }

  /// Savings vs 12x monthly, computed from live store prices (null if unavailable).
  String? _annualSavingsBadge() {
    final monthly = _monthlyPackage?.storeProduct.price;
    final annual = _annualPackage?.storeProduct.price;
    if (monthly == null || annual == null || monthly <= 0 || annual <= 0) {
      return null;
    }
    final yearlyIfMonthly = monthly * 12;
    if (yearlyIfMonthly <= annual) return null;
    final pct = (((yearlyIfMonthly - annual) / yearlyIfMonthly) * 100).round();
    if (pct <= 0) return null;
    return 'Save $pct%';
  }

  void _closeUpgrade() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      context.go('/patient/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF1A3A5C), Color(0xFF0F2640)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: _closeUpgrade,
                  ),
                  const Expanded(
                    child: Text(
                      'RemiMinderAI Premium',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 120),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 88,
                      height: 88,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFC9A84C), width: 4),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFC9A84C).withOpacity(0.28),
                            blurRadius: 24,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Text(
                          'Vox',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 25,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Your AI healthcare companion',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: theme.colorScheme.primary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Vox reads medication reminders aloud, explains doctor visit summaries in plain language, and helps caregivers stay connected.',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: const Color(0xFF2D2D2D),
                        height: 1.35,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 28),
                    Container(
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE6F0FA),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        children: [
                          _buildBenefitItem('Unlimited doctor visit summaries', theme),
                          const SizedBox(height: 14),
                          _buildBenefitItem('Vox voice companion', theme),
                          const SizedBox(height: 14),
                          _buildBenefitItem(
                            'Invite up to ${MonetizationLimits.premiumCaregiverLimit} caregivers',
                            theme,
                          ),
                          const SizedBox(height: 14),
                          _buildBenefitItem('Future premium AI features', theme),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),
                    if (_loadingOfferings)
                      const Padding(
                        padding: EdgeInsets.all(16),
                        child: CircularProgressIndicator(),
                      )
                    else if (_error != null)
                      Text(
                        _error!,
                        style: TextStyle(color: theme.colorScheme.error),
                        textAlign: TextAlign.center,
                      ),
                    if (!_loadingOfferings &&
                        (_monthlyPackage != null || _annualPackage != null))
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_monthlyPackage != null)
                            Expanded(
                              child: _planCard(
                                theme: theme,
                                title: _titleFor(_BillingPlan.monthly),
                                price: _priceFor(_BillingPlan.monthly),
                                period: _periodFor(_BillingPlan.monthly),
                                selected: _selectedPlan == _BillingPlan.monthly,
                                onTap: () => setState(
                                  () => _selectedPlan = _BillingPlan.monthly,
                                ),
                              ),
                            ),
                          if (_monthlyPackage != null && _annualPackage != null)
                            const SizedBox(width: 14),
                          if (_annualPackage != null)
                            Expanded(
                              child: _planCard(
                                theme: theme,
                                title: _titleFor(_BillingPlan.yearly),
                                price: _priceFor(_BillingPlan.yearly),
                                period: _periodFor(_BillingPlan.yearly),
                                selected: _selectedPlan == _BillingPlan.yearly,
                                highlight: true,
                                badge: _annualSavingsBadge(),
                                onTap: () => setState(
                                  () => _selectedPlan = _BillingPlan.yearly,
                                ),
                              ),
                            ),
                        ],
                      ),
                    const SizedBox(height: 28),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: (_loading || _packageFor(_selectedPlan) == null)
                            ? null
                            : _purchaseSelectedPlan,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: _loading
                            ? const SizedBox(
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Text(
                                'Continue with Premium',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                              ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: _loading ? null : _restorePurchases,
                      child: const Text('Restore purchases'),
                    ),
                    TextButton(
                      onPressed: _loading ? null : _closeUpgrade,
                      child: Text(
                        "No thanks, I'll stay on the free plan",
                        style: TextStyle(
                          color: theme.colorScheme.onSurface.withOpacity(0.7),
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _planCard({
    required ThemeData theme,
    required String title,
    required String price,
    required String period,
    required bool selected,
    required VoidCallback onTap,
    bool highlight = false,
    String? badge,
  }) {
    final borderColor = selected
        ? const Color(0xFFC9A84C)
        : theme.colorScheme.primary.withOpacity(highlight ? 0.3 : 0.2);
    final borderWidth = selected ? 2.5 : 2.0;
    final bg = highlight ? const Color(0xFFC9A84C).withOpacity(0.12) : Colors.white;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: borderColor, width: borderWidth),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(highlight ? 0.08 : 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            if (badge != null)
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFC9A84C),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  badge,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.primary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              price,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: theme.colorScheme.primary,
              ),
            ),
            Text(
              period,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              selected ? 'Selected' : 'Cancel anytime',
              style: theme.textTheme.bodySmall?.copyWith(
                color: selected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurface.withOpacity(0.7),
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBenefitItem(String benefit, ThemeData theme) {
    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: const BoxDecoration(
            color: Color(0xFFC9A84C),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.check, color: theme.colorScheme.primary, size: 16),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            benefit,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: const Color(0xFF2D2D2D),
            ),
          ),
        ),
      ],
    );
  }
}
