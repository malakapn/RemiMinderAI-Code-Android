import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../widgets/widgets.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'History',
          style: TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.search,
              color: Theme.of(context).colorScheme.primary,
            ),
            onPressed: () {
              // TODO: Implement search
            },
          ),
          IconButton(
            icon: Icon(
              Icons.filter_list,
              color: Theme.of(context).colorScheme.primary,
            ),
            onPressed: () {
              // TODO: Implement filters
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Visits'),
            Tab(text: 'Documents'),
            Tab(text: 'Medications'),
          ],
        ),
      ),
      body: Stack(
        children: [
          TabBarView(
            controller: _tabController,
            children: [
              _buildAllHistory(),
              _buildVisitsHistory(),
              _buildDocumentsHistory(),
              _buildMedicationsHistory(),
            ],
          ),

          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              top: false,
              left: false,
              right: false,
              bottom: true,
              minimum: EdgeInsets.zero,
              maintainBottomViewPadding: true,
              child: const RoundedNavigationBar(
                  currentItem: NavigationItem.visits),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAllHistory() {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildHistoryItem(
            'Visit Recording',
            'Dr. Sarah Johnson - Cardiology Follow-up',
            '2 days ago',
            Icons.mic,
            Colors.blue,
            () => context
                .go('/patient/visit-details?visitId=visit-recording-001'),
          ),
          _buildHistoryItem(
            'Prescription Scanned',
            'Lisinopril 10mg - Dr. Johnson',
            '3 days ago',
            Icons.receipt,
            Colors.green,
            () => context.go('/patient/scan'),
          ),
          _buildHistoryItem(
            'Lab Results',
            'Blood Work - City Medical Labs',
            '1 week ago',
            Icons.science,
            Colors.purple,
            () {},
          ),
          _buildHistoryItem(
            'Medication Taken',
            'Lisinopril 10mg',
            'Yesterday',
            Icons.medication,
            Colors.teal,
            () {},
          ),
          _buildHistoryItem(
            'Visit Summary',
            'Dr. Michael Chen - Blood Work Review',
            '1 week ago',
            Icons.description,
            Colors.orange,
            () => context.go('/patient/visit-details?visitId=mock-visit-001'),
          ),
        ],
      ),
    );
  }

  Widget _buildVisitsHistory() {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildHistoryItem(
            'Audio Recording',
            'Dr. Sarah Johnson - Cardiology Follow-up',
            '2 days ago',
            Icons.mic,
            Colors.blue,
            () => context.go('/patient/visit-details?visitId=mock-visit-001'),
          ),
          _buildHistoryItem(
            'Visit Summary',
            'Dr. Michael Chen - Blood Work Review',
            '1 week ago',
            Icons.description,
            Colors.orange,
            () => context.go('/patient/visit-details?visitId=mock-visit-001'),
          ),
          _buildHistoryItem(
            'Telehealth Call',
            'Dr. Emily Chen - Follow-up',
            '2 weeks ago',
            Icons.video_call,
            Colors.purple,
            () => context.go('/patient/visit-details?visitId=mock-visit-001'),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentsHistory() {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildHistoryItem(
            'Prescription',
            'Lisinopril 10mg - Dr. Johnson',
            '3 days ago',
            Icons.receipt,
            Colors.green,
            () => context.go('/patient/scan'),
          ),
          _buildHistoryItem(
            'Lab Results',
            'Complete Blood Count',
            '1 week ago',
            Icons.science,
            Colors.purple,
            () {},
          ),
          _buildHistoryItem(
            'Insurance Card',
            'Scanned for verification',
            '2 weeks ago',
            Icons.credit_card,
            Colors.blue,
            () {},
          ),
        ],
      ),
    );
  }

  Widget _buildMedicationsHistory() {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildHistoryItem(
            'Medication Taken',
            'Lisinopril 10mg',
            'Today, 8:00 AM',
            Icons.check_circle,
            Colors.green,
            () {},
          ),
          _buildHistoryItem(
            'Medication Taken',
            'Metformin 500mg',
            'Yesterday, 2:00 PM',
            Icons.check_circle,
            Colors.green,
            () {},
          ),
          _buildHistoryItem(
            'Medication Missed',
            'Atorvastatin 20mg',
            '2 days ago, 8:00 PM',
            Icons.cancel,
            Colors.red,
            () {},
          ),
          _buildHistoryItem(
            'Medication Taken',
            'Lisinopril 10mg',
            '3 days ago, 8:00 AM',
            Icons.check_circle,
            Colors.green,
            () {},
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryItem(
    String type,
    String title,
    String date,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      type,
                      style: TextStyle(
                        fontSize: 12,
                        color: color,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      date,
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context)
                            .colorScheme
                            .secondary
                            .withOpacity(0.7),
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
}
