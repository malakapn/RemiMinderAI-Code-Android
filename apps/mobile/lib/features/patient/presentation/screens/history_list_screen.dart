import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import '../../../../core/config/environment.dart';
import '../../../../core/services/auth_service.dart';
import '../widgets/widgets.dart';

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
  List<dynamic> _scannedDocs = [];
  List<dynamic> _labResults = [];
  bool _isLoading = true;
  bool _isLoadingDocs = true;
  bool _isLoadingLabs = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _searchController.addListener(_onSearchChanged);
    _fetchVisitSummaries();
    _fetchScannedDocs();
    _fetchLabResults();
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

      final token = await AuthService().getAccessToken();
      if (token == null) throw Exception('Authentication required');

      final response = await http.get(
        Uri.parse('${Environment.apiBaseUrl}/api/summaries'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to load history (${response.statusCode})');
      }

      final List<dynamic> raw = json.decode(response.body);
      final data = raw.whereType<Map<String, dynamic>>().map((s) {
        return <String, dynamic>{
          'id': s['summary_id']?.toString() ?? '',
          'visitId': s['visit_id']?.toString() ?? '',
          'title': (s['title'] as String?)?.trim().isNotEmpty == true
              ? s['title'] as String
              : '${s['specialty'] ?? 'Medical'} Visit',
          'doctor': s['doctor_name']?.toString() ?? 'Unknown Doctor',
          'specialty': s['specialty']?.toString() ?? '',
          'date': s['visit_date']?.toString() ?? s['summary_created_at']?.toString() ?? '',
          'time': '',
          'summary': s['summary_preview']?.toString() ?? 'No summary available',
          'status': 'completed',
        };
      }).toList();

      if (!mounted) return;
      setState(() {
        _visitSummaries = data;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchScannedDocs() async {
    try {
      final token = await AuthService().getAccessToken();
      if (token == null) {
        if (mounted) setState(() => _isLoadingDocs = false);
        return;
      }
      final response = await http.get(
        Uri.parse('${Environment.apiBaseUrl}/api/scanned-docs'),
        headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
      );
      if (!mounted) return;
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          _scannedDocs = data;
          _isLoadingDocs = false;
        });
      } else {
        setState(() => _isLoadingDocs = false);
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingDocs = false);
    }
  }

  Future<void> _fetchLabResults() async {
    try {
      final token = await AuthService().getAccessToken();
      if (token == null) {
        if (mounted) setState(() => _isLoadingLabs = false);
        return;
      }
      final response = await http.get(
        Uri.parse('${Environment.apiBaseUrl}/api/lab-results'),
        headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
      );
      if (!mounted) return;
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          _labResults = data;
          _isLoadingLabs = false;
        });
      } else {
        setState(() => _isLoadingLabs = false);
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingLabs = false);
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
                  child: Padding(
                    // Keep content clear of floating bottom navigation bar.
                    padding: const EdgeInsets.only(bottom: 110),
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildAllEvents(),
                        _buildScannedDocuments(),
                        _buildLabResults(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Rounded Navigation Bar (anchored to bottom)
          const Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              top: false,
              child: RoundedNavigationBar(currentItem: NavigationItem.visits),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAllEvents() {
    if (_isLoading || _isLoadingDocs || _isLoadingLabs) {
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

    // Convert visit summaries to HistoryEvent objects.
    final summaryEvents = _visitSummaries.map((summary) {
      return HistoryEvent(
        title: summary['title'] ?? 'Visit Summary',
        description: summary['summary'] ?? 'No summary available',
        date:
            '${summary['date'] ?? 'Unknown date'} at ${summary['time'] ?? 'Unknown time'}',
        type: 'visit_recording',
        category: 'visit',
        icon: Icons.mic,
        color: Colors.blue,
        categoryColor: Colors.blue,
        visitId: summary['visitId'] ?? 'mock-visit-from-summary',
      );
    });

    // Include scanned docs in ALL tab.
    final scannedDocEvents = _scannedDocs.whereType<Map<String, dynamic>>().map((doc) {
      final title = doc['visit_title']?.toString() ?? 'Scanned Document';
      final preview = (doc['ocr_preview'] ?? '').toString().trim();
      final date = doc['visit_date']?.toString() ?? '';
      return HistoryEvent(
        title: title,
        description: preview.isEmpty ? 'Saved image report' : preview,
        date: date.isEmpty ? 'Unknown date' : date,
        type: 'document_scan',
        category: 'document',
        icon: Icons.description,
        color: Colors.green,
        categoryColor: Colors.green,
      );
    });

    // Include lab results in ALL tab.
    final labEvents = _labResults.whereType<Map<String, dynamic>>().map((lab) {
      final title = lab['visit_title']?.toString() ?? 'Lab Report';
      final preview = (lab['result_preview'] ?? '').toString().trim();
      final date = lab['visit_date']?.toString() ?? '';
      return HistoryEvent(
        title: title,
        description: preview.isEmpty ? 'Lab report available' : preview,
        date: date.isEmpty ? 'Unknown date' : date,
        type: 'lab_report',
        category: 'lab',
        icon: Icons.science,
        color: Colors.purple,
        categoryColor: Colors.purple,
      );
    });

    final events = <HistoryEvent>[
      ...summaryEvents,
      ...scannedDocEvents,
      ...labEvents,
    ];

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
    if (_isLoadingDocs) return const Center(child: CircularProgressIndicator());
    if (_scannedDocs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.document_scanner, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text('No scanned documents yet',
                style: TextStyle(color: Colors.grey[600], fontSize: 16)),
            const SizedBox(height: 8),
            Text('Scanned prescriptions and documents will appear here',
                style: TextStyle(color: Colors.grey[500], fontSize: 12),
                textAlign: TextAlign.center),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _scannedDocs.length,
      itemBuilder: (context, index) => _buildDocCard(_scannedDocs[index], isLab: false),
    );
  }

  Widget _buildLabResults() {
    if (_isLoadingLabs) return const Center(child: CircularProgressIndicator());
    if (_labResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.science, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text('No lab results yet',
                style: TextStyle(color: Colors.grey[600], fontSize: 16)),
            const SizedBox(height: 8),
            Text('Lab results and test reports will appear here',
                style: TextStyle(color: Colors.grey[500], fontSize: 12),
                textAlign: TextAlign.center),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _labResults.length,
      itemBuilder: (context, index) => _buildDocCard(_labResults[index], isLab: true),
    );
  }

  Widget _buildDocCard(dynamic doc, {required bool isLab}) {
    final title = doc['visit_title']?.toString() ?? (isLab ? 'Lab Report' : 'Scanned Document');
    final ocrStatus = doc['ocr_status']?.toString() ?? 'pending';
    final preview = (doc['ocr_preview'] ?? doc['result_preview'] ?? '').toString();
    final date = doc['visit_date']?.toString() ?? '';
    final isExtracted = ocrStatus == 'completed' && preview.isNotEmpty;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 1,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showDocFullView(doc, isLab: isLab),
        child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Document icon
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: (isLab ? Colors.purple : Colors.blue).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                isLab ? Icons.science : Icons.description,
                color: isLab ? Colors.purple : Colors.blue,
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
                        child: Text(title,
                            style: const TextStyle(
                                fontSize: 15, fontWeight: FontWeight.w600)),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: isExtracted
                              ? Colors.green.withOpacity(0.1)
                              : Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          isExtracted ? 'Extracted' : 'Processing',
                          style: TextStyle(
                            fontSize: 11,
                            color: isExtracted ? Colors.green : Colors.orange,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (date.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      date.split('T').first,
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    ),
                  ],
                  if (isExtracted) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Text(
                        preview,
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[700],
                            height: 1.4),
                      ),
                    ),
                  ] else ...[
                    const SizedBox(height: 8),
                    Text(
                      'OCR extraction in progress...',
                      style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                          fontStyle: FontStyle.italic),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }

  void _showDocFullView(dynamic doc, {required bool isLab}) {
    final title = doc['visit_title']?.toString() ?? (isLab ? 'Lab Report' : 'Scanned Document');
    final ocrStatus = doc['ocr_status']?.toString() ?? 'pending';
    final preview = (doc['ocr_preview'] ?? doc['result_preview'] ?? '').toString();
    final date = doc['visit_date']?.toString() ?? '';
    final isExtracted = ocrStatus == 'completed' && preview.isNotEmpty;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        maxChildSize: 0.95,
        minChildSize: 0.4,
        builder: (_, controller) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: (isLab ? Colors.purple : Colors.blue).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        isLab ? Icons.science : Icons.description,
                        color: isLab ? Colors.purple : Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title,
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold)),
                          if (date.isNotEmpty)
                            Text(date.split('T').first,
                                style: TextStyle(
                                    fontSize: 12, color: Colors.grey[500])),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isExtracted
                            ? Colors.green.withOpacity(0.1)
                            : Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        isExtracted ? 'Extracted' : 'Processing',
                        style: TextStyle(
                          fontSize: 12,
                          color: isExtracted ? Colors.green : Colors.orange,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // Content
              Expanded(
                child: SingleChildScrollView(
                  controller: controller,
                  padding: const EdgeInsets.all(20),
                  child: isExtracted
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: preview
                              .split('\n')
                              .where((line) => line.trim().isNotEmpty)
                              .map((line) => Padding(
                                    padding: const EdgeInsets.only(bottom: 6),
                                    child: Text(
                                      line.trim(),
                                      style: const TextStyle(
                                          fontSize: 14, height: 1.5),
                                    ),
                                  ))
                              .toList(),
                        )
                      : Center(
                          child: Column(
                            children: [
                              const SizedBox(height: 40),
                              const CircularProgressIndicator(),
                              const SizedBox(height: 16),
                              Text(
                                'OCR extraction in progress...',
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Pull down to refresh once complete',
                                style: TextStyle(
                                    fontSize: 12, color: Colors.grey[500]),
                              ),
                            ],
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
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

  void _onEventTap(HistoryEvent event) {
    switch (event.type) {
      case 'visit_recording':
        final visitId = event.visitId;
        if (visitId != null && visitId.isNotEmpty) {
          context.go('/patient/visit-details?visitId=$visitId');
        }
        break;
      case 'document_scan':
      case 'lab_report':
        // Find the doc in scannedDocs or labResults and show full view
        final allDocs = [..._scannedDocs, ..._labResults];
        final matchingDoc = allDocs.firstWhere(
          (d) => d['visit_id']?.toString() == event.visitId,
          orElse: () => <String, dynamic>{
            'visit_title': event.title,
            'ocr_status': 'pending',
            'ocr_preview': event.description,
            'visit_date': '',
          },
        );
        _showDocFullView(matchingDoc,
            isLab: event.type == 'lab_report');
        break;
      case 'medication_taken':
        context.go('/patient/reminders');
        break;
      default:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Feature coming soon')),
        );
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
