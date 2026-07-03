import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../widgets/widgets.dart';
import '../../../../core/utils/locale_format.dart';

class HistoryListScreen extends StatefulWidget {
  const HistoryListScreen({super.key});

  @override
  State<HistoryListScreen> createState() => _HistoryListScreenState();
}

class _HistoryListScreenState extends State<HistoryListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  List<dynamic> _visitSummaries = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _searchController.addListener(_onSearchChanged);
    _fetchVisitSummaries();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
    });
  }

  Future<void> _fetchVisitSummaries() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // TODO: Uncomment when getVisits is re-enabled
      // final visits = await apiService.getVisits();

      // Temporary stub until getVisits is re-enabled - return sample data for UI testing
      final data = <Map<String, dynamic>>[
        {
          'id': 'sample-visit-1',
          'title': 'Sample Visit',
          'doctor': 'Dr. Sample',
          'specialty': 'General Medicine',
          'date': '2024-01-15',
          'time': '10:00',
          'duration': '30 minutes',
          'summary': 'Sample visit summary',
          'status': 'completed',
        }
      ];

      setState(() {
        _visitSummaries = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
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
              Icons.filter_list,
              color: Theme.of(context).colorScheme.primary,
            ),
            onPressed: () {
              // TODO: Implement advanced filters
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                // Search Box
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search events, documents, visits...',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _searchController.clear();
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                      ),
                    ),
                  ),
                ),

                // Tabs
                TabBar(
                  controller: _tabController,
                  isScrollable: false,
                  labelColor: Theme.of(context).colorScheme.primary,
                  unselectedLabelColor: Theme.of(context).colorScheme.secondary,
                  indicatorColor: Theme.of(context).colorScheme.primary,
                  indicatorWeight: 3,
                  tabs: const [
                    Tab(text: 'ALL'),
                    Tab(text: 'SCANNED DOCS'),
                    Tab(text: 'LAB RESULTS'),
                  ],
                ),

                // Tab Content
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildAllEvents(),
                      _buildScannedDocuments(),
                      _buildLabResults(),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Rounded Navigation Bar
          const RoundedNavigationBar(currentItem: NavigationItem.overview),
        ],
      ),
    );
  }

  Widget _buildAllEvents() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to load history',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchVisitSummaries,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    // Convert visit summaries to HistoryEvent objects
    final events = _visitSummaries.map((summary) {
      return HistoryEvent(
        title: summary['title'] ?? 'Visit Summary',
        description: summary['summary'] ?? 'No summary available',
        date: _formatVisitDateTime(context, summary),
        type: 'visit_recording',
        category: 'visit',
        icon: Icons.mic,
        color: Colors.blue,
        categoryColor: Colors.blue,
        visitId: summary['visitId'] ?? 'mock-visit-from-summary',
      );
    }).toList();

    final filteredEvents = _searchQuery.isEmpty
        ? events
        : events
            .where((event) =>
                event.title.toLowerCase().contains(_searchQuery) ||
                event.description.toLowerCase().contains(_searchQuery) ||
                event.type.toLowerCase().contains(_searchQuery))
            .toList();

    return _buildEventList(filteredEvents);
  }

  Widget _buildScannedDocuments() {
    // For now, show empty state since we only have visit recordings
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.document_scanner,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No scanned documents yet',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Scanned prescriptions and documents will appear here',
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildLabResults() {
    // For now, show empty state since we only have visit recordings
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.science,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No lab results yet',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Lab results and test reports will appear here',
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEventList(List<HistoryEvent> events) {
    if (events.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isNotEmpty
                  ? 'No events found for "$_searchQuery"'
                  : 'No events yet',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: events.length,
      itemBuilder: (context, index) {
        final event = events[index];
        return _buildEventCard(event);
      },
    );
  }

  Widget _buildEventCard(HistoryEvent event) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _onEventTap(event),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: event.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  event.icon,
                  color: event.color,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            event.title,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: event.categoryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            event.category.toUpperCase(),
                            style: TextStyle(
                              color: event.categoryColor,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      event.description,
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      event.date,
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

  String _formatVisitDateTime(
    BuildContext context,
    Map<String, dynamic> summary,
  ) {
    final dateRaw = summary['date']?.toString();
    final timeRaw = summary['time']?.toString();

    if (dateRaw == null || dateRaw.isEmpty) {
      if (timeRaw != null && timeRaw.isNotEmpty) {
        return LocaleFormat.localizeDigitsInText(context, timeRaw);
      }
      return '';
    }

    DateTime? dateTime = DateTime.tryParse(dateRaw);
    if (dateTime == null && timeRaw != null && timeRaw.isNotEmpty) {
      dateTime = DateTime.tryParse('$dateRaw $timeRaw');
    }
    if (dateTime == null) {
      return LocaleFormat.localizeDigitsInText(
        context,
        timeRaw != null && timeRaw.isNotEmpty ? '$dateRaw $timeRaw' : dateRaw,
      );
    }

    if (timeRaw != null && timeRaw.isNotEmpty) {
      final parts = timeRaw.split(':');
      if (parts.length >= 2) {
        final hour = int.tryParse(parts[0]) ?? 0;
        final minute = int.tryParse(parts[1]) ?? 0;
        dateTime = DateTime(
          dateTime.year,
          dateTime.month,
          dateTime.day,
          hour,
          minute,
        );
      }
    }

    return LocaleFormat.dateTimeMedium(context, dateTime);
  }

  void _onEventTap(HistoryEvent event) {
    switch (event.type) {
      case 'visit_recording':
        // Navigate to visit details screen with REAL visit ID
        const realVisitId = '5565cad1-4cd1-4be8-96e0-a4412d39636b';
        if (kDebugMode) {
          print(
              "🧨🧨🧨 Navigating to VisitDetailsScreen with REAL visitId = $realVisitId");
        }
        context.go('/patient/visit-details?visitId=$realVisitId');
        break;
      case 'document_scan':
      case 'lab_report':
        context.go('/patient/overview');
        break;
      case 'medication_taken':
        context.go('/patient/reminders');
        break;
      default:
        if (event.visitId != null && event.visitId!.isNotEmpty) {
          context.go('/patient/visit-details?visitId=${event.visitId}');
        }
    }
  }
}

class HistoryEvent {
  final String title;
  final String description;
  final String date;
  final String type;
  final String category;
  final IconData icon;
  final Color color;
  final Color categoryColor;
  final String? visitId;

  HistoryEvent({
    required this.title,
    required this.description,
    required this.date,
    required this.type,
    required this.category,
    required this.icon,
    required this.color,
    required this.categoryColor,
    this.visitId,
  });
}
