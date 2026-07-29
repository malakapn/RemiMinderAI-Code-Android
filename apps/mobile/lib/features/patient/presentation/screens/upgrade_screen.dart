import 'package:flutter/material.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import '../../../../core/services/revenuecat_service.dart';

class UpgradeScreen extends StatefulWidget {
  const UpgradeScreen({super.key});

  @override
  State<UpgradeScreen> createState() => _UpgradeScreenState();
}

class _UpgradeScreenState extends State<UpgradeScreen> {
  static const Color _navy = Color(0xFF1A3A5C);
  static const Color _navyLight = Color(0xFF4A7FB5);
  static const Color _cream = Color(0xFFF8F4E8);
  static const Color _gold = Color(0xFFC9A84C);

  List<Package> _packages = [];
  bool _loading = true;
  bool _purchasing = false;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadOfferings();
  }

  Future<void> _loadOfferings() async {
    final packages = await RevenueCatService().getOfferings();
    if (mounted) {
      setState(() {
        _packages = packages;
        _loading = false;
      });
    }
  }

  Future<void> _purchase() async {
    if (_purchasing || _packages.isEmpty) return;
    setState(() => _purchasing = true);
    try {
      final success = await RevenueCatService().purchase(_packages[_selectedIndex]);
      if (!mounted) return;
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Welcome to Premium!')),
        );
        Navigator.of(context).pop(true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Purchase was cancelled.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Purchase failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _purchasing = false);
    }
  }

  Future<void> _restore() async {
    setState(() => _loading = true);
    await RevenueCatService().restorePurchases();
    if (!mounted) return;
    if (RevenueCatService().isPremium) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Premium restored!')),
      );
      Navigator.of(context).pop(true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No previous purchase found.')),
      );
    }
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _cream,
      appBar: AppBar(
        backgroundColor: _navy,
        foregroundColor: Colors.white,
        title: const Text('Upgrade to Premium'),
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 16),
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: _gold.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.workspace_premium, size: 36, color: _gold),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'RemiMinderAI Premium',
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: _navy),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Unlock the full power of your care companion',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 32),

                  // Features
                  ..._buildFeatures(),

                  const SizedBox(height: 32),

                  // Plans
                  if (_packages.isNotEmpty) ...[
                    ..._packages.asMap().entries.map((e) => _buildPlanCard(e.key, e.value)),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _purchasing ? null : _purchase,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _navy,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 0,
                        ),
                        child: Text(
                          _purchasing ? 'Processing...' : 'Subscribe Now',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ] else ...[
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Column(
                        children: [
                          const Icon(Icons.hourglass_top, size: 40, color: _navyLight),
                          const SizedBox(height: 12),
                          const Text(
                            'Premium plans coming soon!',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: _navy),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'We\'re preparing subscription plans for you. Check back soon.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: _restore,
                    child: const Text(
                      'Restore Purchases',
                      style: TextStyle(color: _navyLight, fontSize: 14),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    '14-day free trial included with all plans.\nCancel anytime.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
    );
  }

  List<Widget> _buildFeatures() {
    final features = [
      ('Unlimited recorded visits', Icons.mic),
      ('Up to 5 caregivers', Icons.people),
      ('Prescription scans', Icons.document_scanner),
      ('Smart medication reminders', Icons.notifications_active),
      ('Unlimited recording history', Icons.history),
      ('Priority email support', Icons.support_agent),
    ];
    return features.map((f) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(f.$2, color: _navyLight, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(f.$1, style: const TextStyle(fontSize: 15, color: _navy)),
          ),
          const Icon(Icons.check_circle, color: _gold, size: 20),
        ],
      ),
    )).toList();
  }

  Widget _buildPlanCard(int index, Package package) {
    final isSelected = _selectedIndex == index;
    final product = package.storeProduct;
    final isAnnual = package.packageType == PackageType.annual;

    return GestureDetector(
      onTap: () => setState(() => _selectedIndex = index),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? _navy : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: isSelected ? _navy : Colors.grey[400]!, width: 2),
                color: isSelected ? _navy : Colors.transparent,
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        isAnnual ? 'Annual' : 'Monthly',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? _navy : Colors.grey[700],
                        ),
                      ),
                      if (isAnnual) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: _gold.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text('SAVE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _gold)),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    product.priceString,
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
