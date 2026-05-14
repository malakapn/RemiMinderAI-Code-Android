import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/config/environment.dart';
import '../../data/services/patient_api_service.dart';
import '../../data/models/summary_item.dart';
import '../../../care_team/data/models/care_team_member.dart';
import '../../../care_team/data/services/care_team_api_service.dart';

class OverviewScreen extends StatefulWidget {
  const OverviewScreen({super.key});

  @override
  State<OverviewScreen> createState() => _OverviewScreenState();
}

class _OverviewScreenState extends State<OverviewScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // Summaries state
  List<SummaryItem> _summaries = [];
  bool _isLoadingSummaries = true;
  String? _summariesError;
  final Set<String> _seenSummaryIds = {};
  bool _hasLoadedSummariesOnce = false;
  bool _isLatestVisitProcessing = false;

  // Sharing state
  CareTeamMember? _activeCaregiver;
  bool _isLoadingCaregiver = true;
  String? _caregiverError;
  bool _isUpdatingShare = false;

  // Lab / scan state
  List<Map<String, dynamic>> _labResults = [];
  List<Map<String, dynamic>> _scannedDocs = [];
  bool _isLoadingLabResults = true;
  bool _isLoadingScannedDocs = true;
  String? _labResultsError;
  String? _scannedDocsError;

  // Selection state
  bool _isSelectionMode = false;
  final Set<String> _selectedSummaryIds = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _searchController.addListener(_onSearchChanged);
    _loadSeenSummaryIds().then((_) => _fetchSummaries());
    _loadCaregiver();
    _fetchLabResults();
    _fetchScannedDocs();
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

  Future<void> _loadSeenSummaryIds() async {
    final prefs = await SharedPreferences.getInstance();
    final storedIds = prefs.getStringList('seen_summary_ids') ?? [];
    _seenSummaryIds
      ..clear()
      ..addAll(storedIds);
  }

  Future<void> _persistSeenSummaryIds() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('seen_summary_ids', _seenSummaryIds.toList());
  }

  Future<void> _fetchSummaries() async {
    try {
      if (!mounted) return;
      final cachedSummaries = PatientApiService.getCachedSummaries();
      final cachedStatus = PatientApiService.getCachedLatestVisitStatus();
      if (cachedSummaries != null && mounted) {
        setState(() {
          _summaries = cachedSummaries;
          _isLoadingSummaries = false;
          _summariesError = null;
          _isLatestVisitProcessing = cachedStatus?['processing'] == true;
        });
      } else {
        setState(() {
          _isLoadingSummaries = true;
          _summariesError = null;
        });
      }

      final authToken = await AuthService().getAccessToken();
      if (authToken == null) {
        throw Exception('Authentication required');
      }

      final apiService = PatientApiService(
        baseUrl: Environment.apiBaseUrl,
        authToken: authToken,
      );

      Map<String, dynamic> status = {'processing': false};
      try {
        status = await apiService.getLatestVisitStatus();
        PatientApiService.setCachedLatestVisitStatus(status);
      } catch (_) {
        // Keep summaries usable even if status endpoint is down.
      }

      final summaries = await apiService.getSummaries();
      PatientApiService.setCachedSummaries(summaries);
      final newSummaryIds = summaries
          .map((summary) => summary.summaryId)
          .where((summaryId) => !_seenSummaryIds.contains(summaryId))
          .toList();

      if (!mounted) return;
      final summariesChanged = _summariesChanged(summaries);
      final statusChanged = _statusChanged(status);
      if (summariesChanged || statusChanged) {
        setState(() {
          _summaries = summaries;
          _isLoadingSummaries = false;
          _isLatestVisitProcessing = status['processing'] == true;
        });
      }

      _seenSummaryIds.addAll(summaries.map((summary) => summary.summaryId));
      await _persistSeenSummaryIds();
      if (_hasLoadedSummariesOnce && newSummaryIds.isNotEmpty && mounted) {
        final newSummary = summaries.firstWhere(
          (summary) => newSummaryIds.contains(summary.summaryId),
          orElse: () => summaries.first,
        );
        if (!mounted) return;
        await showDialog<void>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('🎉 Your visit summary is ready!'),
            content: const Text(
              'After your recording, the pipeline writes a structured summary '
              '(summary, decisions, medications, and actions). '
              'Would you like to view it now?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Later'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  context.go(
                      '/patient/visit-details?visitId=${newSummary.visitId}');
                },
                child: const Text('View Summary'),
              ),
            ],
          ),
        );
      }
      _hasLoadedSummariesOnce = true;
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _summariesError = e.toString();
        _isLoadingSummaries = false;
        _isLatestVisitProcessing = false;
      });
    }
  }

  bool _summariesChanged(List<SummaryItem> next) {
    if (_summaries.length != next.length) {
      return true;
    }
    for (var i = 0; i < next.length; i++) {
      if (_summaries[i].summaryId != next[i].summaryId) {
        return true;
      }
    }
    return false;
  }

  bool _statusChanged(Map<String, dynamic> next) {
    final currentProcessing = _isLatestVisitProcessing;
    final nextProcessing = next['processing'] == true;
    if (currentProcessing != nextProcessing) {
      return true;
    }
    if (nextProcessing) {
      final currentVisitId = _summaries.isNotEmpty ? _summaries.first.visitId : null;
      final nextVisitId = next['visit_id'];
      if (currentVisitId != null && nextVisitId != currentVisitId) {
        return true;
      }
    }
    return false;
  }

  Future<void> _loadCaregiver() async {
    try {
      if (!mounted) return;
      setState(() {
        _isLoadingCaregiver = true;
        _caregiverError = null;
      });

      final members = await CareTeamApiService().getCareTeam();
      if (!mounted) return;
      setState(() {
        _activeCaregiver = members.isNotEmpty ? members.first : null;
        _isLoadingCaregiver = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _caregiverError = e.toString();
        _isLoadingCaregiver = false;
      });
    }
  }

  Future<void> _fetchLabResults() async {
    if (!mounted) return;
    setState(() {
      _isLoadingLabResults = true;
      _labResultsError = null;
    });
    try {
      final token = await AuthService().getAccessToken();
      if (token == null) throw Exception('Authentication required');
      final apiService =
          PatientApiService(baseUrl: Environment.apiBaseUrl, authToken: token);
      final rows = await apiService.getLabResults();
      if (!mounted) return;
      setState(() {
        _labResults = rows;
        _isLoadingLabResults = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _labResultsError = e.toString();
        _isLoadingLabResults = false;
      });
    }
  }

  Future<void> _fetchScannedDocs() async {
    if (!mounted) return;
    setState(() {
      _isLoadingScannedDocs = true;
      _scannedDocsError = null;
    });
    try {
      final token = await AuthService().getAccessToken();
      if (token == null) throw Exception('Authentication required');
      final apiService =
          PatientApiService(baseUrl: Environment.apiBaseUrl, authToken: token);
      final rows = await apiService.getScannedDocs();
      if (!mounted) return;
      setState(() {
        _scannedDocs = rows;
        _isLoadingScannedDocs = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _scannedDocsError = e.toString();
        _isLoadingScannedDocs = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Custom Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF1A4D4D), // Dark teal-green
                    Color(0xFF051818), // Very dark green/black
                  ],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 48),
                  Expanded(
                    child: const Text(
                      'Overview',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.delete_outline,
                      color: Colors.white,
                    ),
                    onPressed: _isSelectionMode
                        ? _deleteSelectedSummaries
                        : _enterSelectionMode,
                  ),
                ],
              ),
            ),

            // Search Box
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search summaries...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surface,
                ),
              ),
            ),

            const SizedBox(height: 8),

            // Tabs
            TabBar(
              controller: _tabController,
              isScrollable: false,
              labelColor: Theme.of(context).colorScheme.primary,
              unselectedLabelColor: Theme.of(context).colorScheme.secondary,
              indicatorColor: Theme.of(context).colorScheme.primary,
              indicatorWeight: 3,
              tabs: const [
                Tab(text: 'SUMMARIES'),
                Tab(text: 'LAB RESULTS'),
                Tab(text: 'SCANNED DOCS'),
              ],
            ),

            // Tab Content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildSummariesTab(),
                  _buildLabResultsTab(),
                  _buildScannedDocsTab(),
                ],
              ),
            ),

            // Extra space for bottom navigation
            const SizedBox(height: 120),
          ],
        ),
      ),
    );
  }

  void _enterSelectionMode() {
    setState(() {
      _isSelectionMode = true;
      _selectedSummaryIds.clear();
    });
  }

  void _exitSelectionMode() {
    setState(() {
      _isSelectionMode = false;
      _selectedSummaryIds.clear();
    });
  }

  void _deleteSelectedSummaries() {
    if (_selectedSummaryIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select at least one summary')),
      );
      return;
    }

    final count = _selectedSummaryIds.length;
    final isSingular = count == 1;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isSingular ? 'Delete summary?' : 'Delete summaries?'),
        content: Text(
          isSingular
              ? 'Are you sure you want to delete this summary? This cannot be undone.'
              : 'Are you sure you want to delete $count summaries? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _confirmDelete();
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete() async {
    try {
      // Get authentication token
      final authToken = await AuthService().getAccessToken();
      if (authToken == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Authentication error. Please log in again.')),
        );
        return;
      }

      // Create API service
      final apiService = PatientApiService(
        baseUrl: Environment.apiBaseUrl,
        authToken: authToken,
      );

      // Delete each selected summary
      final summariesToDelete = _selectedSummaryIds
          .toSet(); // Copy to avoid modification during iteration

      for (final summaryId in summariesToDelete) {
        try {
          await apiService.deleteSummary(summaryId);
          // Remove from local list on successful deletion
          if (!mounted) return;
          setState(() {
            _summaries.removeWhere((summary) => summary.summaryId == summaryId);
            _selectedSummaryIds.remove(summaryId);
          });
        } catch (e) {
          // Continue with other deletions even if one fails
        }
      }

      // Show success message
      final deletedCount =
          summariesToDelete.length - _selectedSummaryIds.length;
      if (deletedCount > 0) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Successfully deleted $deletedCount summary${deletedCount == 1 ? '' : 'ies'}')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Failed to delete summaries. Please try again.')),
      );
    } finally {
      if (!mounted) return;
      _exitSelectionMode();
    }
  }

  void _toggleShare(bool value) {
    if (_activeCaregiver == null || _isUpdatingShare) {
      if (!_isLoadingCaregiver && _caregiverError == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No caregiver added yet')),
        );
      }
      return;
    }
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(value ? 'Share summary?' : 'Stop sharing?'),
        content: Text(
          value
              ? 'You are about to share this summary with your caregivers. They will be able to view this visit summary.'
              : 'Caregivers will no longer be able to view this summary.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _confirmShareToggle(value);
            },
            style: TextButton.styleFrom(
              foregroundColor:
                  value ? Theme.of(context).colorScheme.primary : Colors.red,
            ),
            child: Text(value ? 'Share' : 'Stop Sharing'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmShareToggle(bool value) async {
    final caregiver = _activeCaregiver;
    if (caregiver == null) return;

    final previousPermission = caregiver.permission;
    final newPermission = value ? 'full' : 'view';

    setState(() {
      _isUpdatingShare = true;
      _activeCaregiver = CareTeamMember(
        id: caregiver.id,
        patientId: caregiver.patientId,
        memberUserId: caregiver.memberUserId,
        fullName: caregiver.fullName,
        email: caregiver.email,
        role: caregiver.role,
        permission: newPermission,
        status: caregiver.status,
      );
    });

    try {
      await CareTeamApiService().updatePermission(
        memberId: caregiver.id,
        permission: newPermission,
      );
      if (!mounted) return;
      setState(() {
        _isUpdatingShare = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(value
              ? 'Caregiver sharing enabled'
              : 'Caregiver sharing disabled'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isUpdatingShare = false;
        _activeCaregiver = CareTeamMember(
          id: caregiver.id,
          patientId: caregiver.patientId,
          memberUserId: caregiver.memberUserId,
          fullName: caregiver.fullName,
          email: caregiver.email,
          role: caregiver.role,
          permission: previousPermission,
          status: caregiver.status,
        );
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  void _toggleSummarySelection(String summaryId) {
    setState(() {
      if (_selectedSummaryIds.contains(summaryId)) {
        _selectedSummaryIds.remove(summaryId);
      } else {
        _selectedSummaryIds.add(summaryId);
      }
    });
  }

  Widget _buildSummariesTab() {
    if (_isLoadingSummaries) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_summariesError != null) {
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
              'Failed to load summaries',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _summariesError!,
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchSummaries,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_summaries.isEmpty && !_isLatestVisitProcessing) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.description_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No summaries yet',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your visit summaries will appear here',
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
    }

    final filteredSummaries = _searchQuery.isEmpty
        ? _summaries
        : _summaries.where((summary) {
            return summary.doctorName.toLowerCase().contains(_searchQuery) ||
                summary.specialty.toLowerCase().contains(_searchQuery) ||
                summary.summaryPreview.toLowerCase().contains(_searchQuery);
          }).toList();

    final processingOffset = _isLatestVisitProcessing ? 1 : 0;

    return Container(
      constraints: const BoxConstraints(minHeight: 200),
      child: RefreshIndicator(
        onRefresh: _fetchSummaries,
        child: ListView.builder(
          shrinkWrap: true,
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          itemCount: filteredSummaries.length + processingOffset,
          itemBuilder: (context, index) {
            if (_isLatestVisitProcessing && index == 0) {
              return _buildProcessingCard();
            }
            final summary = filteredSummaries[index - processingOffset];
            return _buildSummaryCard(summary);
          },
        ),
      ),
    );
  }

  Widget _buildProcessingCard() {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: Colors.orange.withOpacity(0.08),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.orange.withOpacity(0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(
              Icons.access_time,
              color: Colors.orange,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    '🕒 Your latest visit is being processed',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  SizedBox(height: 4),
                  Text('We’ll notify you when it’s ready.'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(SummaryItem summary) {
    final summaryId = summary.summaryId;
    final isSelected = _selectedSummaryIds.contains(summaryId);
    final isShared = _activeCaregiver?.permission == 'full';
    final isShareDisabled =
        _activeCaregiver == null || _isUpdatingShare || _isLoadingCaregiver;
    final doctorText = _formatDoctorName(summary.doctorName);
    final hasTitle = (summary.title ?? '').trim().isNotEmpty;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: _isSelectionMode && isSelected
          ? Theme.of(context).colorScheme.primary.withOpacity(0.05)
          : null,
      child: InkWell(
        onTap: _isSelectionMode
            ? () => _toggleSummarySelection(summaryId)
            : () {
                final visitDateParam = summary.visitDate;
                final visitDateQuery = visitDateParam == null
                    ? ''
                    : '&visitDate=${Uri.encodeComponent(visitDateParam)}';
                context.push(
                    '/patient/visit-details?visitId=${summary.visitId}$visitDateQuery');
              },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row with doctor info and action
              Row(
                children: [
                  Icon(
                    Icons.person,
                    size: 20,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (hasTitle)
                          Text(
                            summary.title!,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                        if (!hasTitle)
                          Text(
                            doctorText,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                        if (hasTitle && doctorText.trim().isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              doctorText,
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context)
                                    .colorScheme
                                    .secondary,
                              ),
                            ),
                          ),
                        if (summary.specialty.trim().isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              summary.specialty,
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context)
                                    .colorScheme
                                    .secondary,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  // Action widget (Checkbox or Share toggle)
                  if (_isSelectionMode) ...[
                    Checkbox(
                      value: isSelected,
                      onChanged: (value) => _toggleSummarySelection(summaryId),
                      activeColor: Theme.of(context).colorScheme.primary,
                    ),
                  ] else ...[
                    // Share toggle
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Share',
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).colorScheme.secondary,
                          ),
                        ),
                        Switch(
                          value: isShared,
                          onChanged: isShareDisabled
                              ? null
                              : (value) => _toggleShare(value),
                          activeThumbColor:
                              Theme.of(context).colorScheme.primary,
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                        ),
                      ],
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 8),

              // Visit date
              if (summary.visitDate != null)
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 16,
                      color: Colors.grey[500],
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _formatSmartTime(DateTime.parse(summary.visitDate!)),
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),

              const SizedBox(height: 12),

              // Summary preview
              Text(
                summary.summaryPreview,
                style: TextStyle(
                  color: Colors.grey[800],
                  fontSize: 14,
                  height: 1.4,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDoctorName(String? doctorName) {
    final rawName = (doctorName ?? '').trim();
    if (rawName.isEmpty || rawName.toLowerCase() == 'unknown doctor') {
      return 'Doctor Visit';
    }

    final normalized = rawName
        .replaceFirst(RegExp(r'^(dr\.?|doctor)\s+', caseSensitive: false), '')
        .trim();

    if (normalized.isEmpty) {
      return 'Doctor Visit';
    }
    return 'Dr. $normalized';
  }

  String _formatSmartTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 60) {
      final minutes = difference.inMinutes < 1 ? 1 : difference.inMinutes;
      return '$minutes min ago';
    }

    final isSameDay = now.year == dateTime.year &&
        now.month == dateTime.month &&
        now.day == dateTime.day;
    if (isSameDay) {
      return 'Today, ${_formatTimeOfDay(dateTime)}';
    }

    final yesterday = now.subtract(const Duration(days: 1));
    final isYesterday = yesterday.year == dateTime.year &&
        yesterday.month == dateTime.month &&
        yesterday.day == dateTime.day;
    if (isYesterday) {
      return 'Yesterday, ${_formatTimeOfDay(dateTime)}';
    }

    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final month = months[dateTime.month - 1];
    return '$month ${dateTime.day}, ${dateTime.year}';
  }

  String _formatTimeOfDay(DateTime dateTime) {
    final hour = dateTime.hour;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final hour12 = hour % 12 == 0 ? 12 : hour % 12;
    return '$hour12:$minute $period';
  }

  Future<void> _openDocumentUrl(String rawUrl) async {
    final uri = Uri.tryParse(rawUrl);
    if (uri == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid document URL')),
      );
      return;
    }

    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to open document')),
        );
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to open document')),
      );
    }
  }

  Widget _buildLabResultsTab() {
    if (_isLoadingLabResults) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_labResultsError != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Failed to load lab results',
                style: TextStyle(color: Colors.grey[700])),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _fetchLabResults,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }
    if (_labResults.isEmpty) {
      return Center(
        child: Text('No lab results found',
            style: TextStyle(color: Colors.grey[600])),
      );
    }
    return RefreshIndicator(
      onRefresh: _fetchLabResults,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        itemCount: _labResults.length,
        itemBuilder: (context, index) {
          final item = _labResults[index];
          final title = (item['visit_title'] ?? 'Lab report').toString();
          final preview = (item['result_preview'] ?? '').toString();
          final imageUrl = (item['image_url'] ?? '').toString();
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: const Icon(Icons.science),
              title: Text(title),
              subtitle: Text(
                preview.isEmpty ? 'OCR pending' : preview,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: imageUrl.isNotEmpty
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: 'Open',
                          icon: const Icon(Icons.open_in_new, size: 20),
                          onPressed: () => _openDocumentUrl(imageUrl),
                        ),
                        IconButton(
                          tooltip: 'Download',
                          icon: const Icon(Icons.download_rounded, size: 20),
                          onPressed: () => _openDocumentUrl(imageUrl),
                        ),
                      ],
                    )
                  : null,
              onTap: imageUrl.isNotEmpty ? () => _openDocumentUrl(imageUrl) : null,
            ),
          );
        },
      ),
    );
  }

  Widget _buildScannedDocsTab() {
    if (_isLoadingScannedDocs) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_scannedDocsError != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Failed to load scanned documents',
                style: TextStyle(color: Colors.grey[700])),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _fetchScannedDocs,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }
    if (_scannedDocs.isEmpty) {
      return Center(
        child: Text('No scanned documents yet',
            style: TextStyle(color: Colors.grey[600])),
      );
    }
    return RefreshIndicator(
      onRefresh: _fetchScannedDocs,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        itemCount: _scannedDocs.length,
        itemBuilder: (context, index) {
          final item = _scannedDocs[index];
          final title = (item['visit_title'] ?? 'Scanned report').toString();
          final preview = (item['ocr_preview'] ?? '').toString();
          final imageUrl = (item['image_url'] ?? '').toString();
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: const Icon(Icons.description_outlined),
              title: Text(title),
              subtitle: Text(
                preview.isEmpty ? 'Saved image report' : preview,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: imageUrl.isNotEmpty
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: 'Open',
                          icon: const Icon(Icons.open_in_new, size: 20),
                          onPressed: () => _openDocumentUrl(imageUrl),
                        ),
                        IconButton(
                          tooltip: 'Download',
                          icon: const Icon(Icons.download_rounded, size: 20),
                          onPressed: () => _openDocumentUrl(imageUrl),
                        ),
                      ],
                    )
                  : null,
              onTap: imageUrl.isNotEmpty ? () => _openDocumentUrl(imageUrl) : null,
            ),
          );
        },
      ),
    );
  }
}
