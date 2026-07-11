import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/config/environment.dart';
import '../../../../core/utils/locale_format.dart';
import '../../../../core/widgets/remi_shell_ui.dart';
import '../../../../l10n/app_localizations.dart';
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
  String? _latestVisitProcessingError;
  String? _processingVisitId;
  Timer? _processingPollTimer;

  // Sharing state
  CareTeamMember? _activeCaregiver;
  bool _isLoadingCaregiver = true;
  String? _caregiverError;
  bool _isUpdatingShare = false;

  // Scanned docs state
  List<Map<String, dynamic>> _scannedDocs = [];
  bool _isLoadingScannedDocs = true;
  String? _scannedDocsError;

  // Lab results state (filtered from scanned docs)
  List<Map<String, dynamic>> _labResults = [];
  bool _isLoadingLabResults = true;

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
    _fetchScannedDocs();
  }

  @override
  void dispose() {
    _processingPollTimer?.cancel();
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _syncProcessingPollTimer() {
    final shouldPoll =
        _isLatestVisitProcessing && (_latestVisitProcessingError?.isEmpty ?? true);
    if (shouldPoll) {
      _processingPollTimer ??= Timer.periodic(const Duration(seconds: 5), (_) {
        if (mounted) {
          _fetchSummaries();
        }
      });
    } else {
      _processingPollTimer?.cancel();
      _processingPollTimer = null;
    }
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
          _latestVisitProcessingError = cachedStatus?['failed'] == true
              ? (cachedStatus?['error']?.toString())
              : null;
          _processingVisitId = cachedStatus?['visit_id']?.toString();
        });
        _syncProcessingPollTimer();
      } else {
        setState(() {
          _isLoadingSummaries = true;
          _summariesError = null;
        });
      }

      // Force fresh Firebase ID token — never use cached/expired token
      final firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser == null) throw Exception('Authentication required');
      final authToken = await firebaseUser.getIdToken(true);
      if (authToken == null) throw Exception('Failed to get auth token');

      final apiService = PatientApiService(
        baseUrl: Environment.apiBaseUrl,
        authToken: authToken,
      );

      final status = await apiService.getLatestVisitStatus();
      final summaries = await apiService.getSummaries();
      PatientApiService.setCachedLatestVisitStatus(status);
      PatientApiService.setCachedSummaries(summaries);
      final newSummaryIds = summaries
          .map((summary) => summary.summaryId)
          .where((summaryId) => !_seenSummaryIds.contains(summaryId))
          .toList();

      if (!mounted) return;
      final summariesChanged = _summariesChanged(summaries);
      setState(() {
        _summaries = summaries;
        _isLoadingSummaries = false;
        _summariesError = null;
        _isLatestVisitProcessing = status['processing'] == true;
        _latestVisitProcessingError = status['failed'] == true
            ? status['error']?.toString()
            : null;
        _processingVisitId = status['visit_id']?.toString();
      });
      _syncProcessingPollTimer();

      _seenSummaryIds.addAll(summaries.map((summary) => summary.summaryId));
      await _persistSeenSummaryIds();
      if (_hasLoadedSummariesOnce &&
          summariesChanged &&
          newSummaryIds.isNotEmpty &&
          mounted) {
        final newSummary = summaries.firstWhere(
          (summary) => newSummaryIds.contains(summary.summaryId),
          orElse: () => summaries.first,
        );
        if (!mounted) return;
        await showDialog<void>(
          context: context,
          builder: (dialogContext) {
            final l10n = AppLocalizations.of(dialogContext)!;
            return AlertDialog(
            title: Text(l10n.summaryReadyTitle),
            content: Text(l10n.summaryReadyBody),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: Text(l10n.later),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  context.go(
                      '/patient/visit-details?visitId=${newSummary.visitId}');
                },
                child: Text(l10n.viewSummary),
              ),
            ],
          );
          },
        );
      }
      _hasLoadedSummariesOnce = true;
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _summariesError = e.toString();
        _isLoadingSummaries = false;
        _isLatestVisitProcessing = false;
        _latestVisitProcessingError = null;
      });
    }
  }

  Future<void> _retryAudioProcessing(String visitId) async {
    try {
      final authToken = await AuthService().getAccessToken();
      if (authToken == null) {
        throw Exception('Authentication required');
      }
      final apiService = PatientApiService(
        baseUrl: Environment.apiBaseUrl,
        authToken: authToken,
      );
      await apiService.triggerVisitAudioProcessing(visitId);
      if (!mounted) return;
      setState(() {
        _isLatestVisitProcessing = true;
        _latestVisitProcessingError = null;
      });
      _syncProcessingPollTimer();
      await _fetchSummaries();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.summaryGenerationRestarted)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.retryFailed('$e'))),
      );
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            RemiShellUi.screenHeader(
              context: context,
              title: l10n.navOverview,
              trailing: IconButton(
                icon: const Icon(
                  Icons.delete_outline,
                  color: Colors.white,
                ),
                onPressed: _isSelectionMode
                    ? _deleteSelectedSummaries
                    : _enterSelectionMode,
              ),
            ),

            // Search Box
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: l10n.searchSummariesHint,
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
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              labelColor: Theme.of(context).colorScheme.primary,
              unselectedLabelColor: Theme.of(context).colorScheme.secondary,
              indicatorColor: Theme.of(context).colorScheme.primary,
              indicatorWeight: 3,
              tabs: [
                Tab(text: l10n.tabSummaries),
                Tab(text: l10n.tabLabResults),
                Tab(text: l10n.tabScannedDocs),
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
    final l10n = AppLocalizations.of(context)!;
    if (_selectedSummaryIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.selectAtLeastOneSummary)),
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
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _confirmDelete();
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: Text(AppLocalizations.of(context)!.delete),
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
          SnackBar(
              content: Text(
                  AppLocalizations.of(context)!.authenticationErrorLoginAgain)),
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
        SnackBar(
            content: Text(AppLocalizations.of(context)!.failedToDeleteSummaries)),
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
          SnackBar(content: Text(AppLocalizations.of(context)!.noCaregiverAddedYet)),
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
            child: Text(AppLocalizations.of(context)!.cancel),
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

  Future<void> _fetchScannedDocs() async {
    try {
      setState(() {
        _isLoadingScannedDocs = true;
        _isLoadingLabResults = true;
        _scannedDocsError = null;
      });

      final user = await AuthService().getCurrentUser();
      final uid = user?.authUid ?? user?.id;
      if (uid == null) throw Exception('Not authenticated');

      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('scanned_docs')
          .orderBy('timestamp', descending: true)
          .get();

      final docs = snapshot.docs
          .map((d) => {'id': d.id, ...d.data()})
          .toList();

      final labs = docs.where((d) {
        final text = (d['parsed_text'] ?? '').toString().toLowerCase();
        return text.contains('lab') ||
            text.contains('result') ||
            text.contains('test') ||
            text.contains('blood') ||
            text.contains('cholesterol') ||
            text.contains('glucose');
      }).toList();

      if (!mounted) return;
      setState(() {
        _scannedDocs = docs;
        _labResults = labs;
        _isLoadingScannedDocs = false;
        _isLoadingLabResults = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _scannedDocsError = e.toString();
        _isLoadingScannedDocs = false;
        _isLoadingLabResults = false;
      });
    }
  }

  Widget _buildScannedDocCard(Map<String, dynamic> doc) {
    final l10n = AppLocalizations.of(context)!;
    final timestamp = doc['timestamp'];
    String dateStr = '';
    if (timestamp is Timestamp) {
      final dt = timestamp.toDate();
      dateStr = _formatSmartTime(dt, l10n);
    }
    final parsedText = (doc['parsed_text'] ?? '').toString();
    final preview = parsedText.length > 120
        ? '${parsedText.substring(0, 120)}...'
        : parsedText;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showScannedDocDetail(context, dateStr, parsedText),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.description_outlined,
                      size: 20,
                      color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      dateStr.isNotEmpty
                          ? l10n.scannedOn(dateStr)
                          : l10n.scannedDocument,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 15),
                    ),
                  ),
                  Icon(Icons.chevron_right, size: 18, color: Colors.grey[400]),
                ],
              ),
              if (preview.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  preview,
                  style: TextStyle(
                      color: Colors.grey[700],
                      fontSize: 13,
                      height: 1.4),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummariesTab() {
    final l10n = AppLocalizations.of(context)!;
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
              l10n.failedToLoadSummaries,
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
              child: Text(l10n.retry),
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
              l10n.noSummariesYet,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.summariesWillAppearHere,
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

    final showProcessingBanner =
        _isLatestVisitProcessing || (_latestVisitProcessingError?.isNotEmpty ?? false);
    final processingOffset = showProcessingBanner ? 1 : 0;

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
            if (showProcessingBanner && index == 0) {
              return _buildProcessingCard(l10n);
            }
            final summary = filteredSummaries[index - processingOffset];
            return _buildSummaryCard(summary, l10n);
          },
        ),
      ),
    );
  }

  Widget _buildProcessingCard(AppLocalizations l10n) {
    final failed = _latestVisitProcessingError?.isNotEmpty ?? false;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: failed
          ? Colors.red.withOpacity(0.08)
          : Colors.orange.withOpacity(0.08),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: failed
              ? Colors.red.withOpacity(0.3)
              : Colors.orange.withOpacity(0.3),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              failed ? Icons.error_outline : Icons.access_time,
              color: failed ? Colors.red : Colors.orange,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    failed
                        ? l10n.summaryCouldNotGenerate
                        : '🕒 ${l10n.preparingVisitSummary}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    failed
                        ? (_latestVisitProcessingError ?? l10n.summaryCouldNotGenerate)
                        : l10n.summaryProcessingHint,
                  ),
                  if (_processingVisitId != null) ...[
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton(
                        onPressed: _isLoadingSummaries
                            ? null
                            : () => _retryAudioProcessing(_processingVisitId!),
                        child: Text(
                          failed ? l10n.retrySummary : l10n.stuckRetrySummary,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(SummaryItem summary, AppLocalizations l10n) {
    final summaryId = summary.summaryId;
    final isSelected = _selectedSummaryIds.contains(summaryId);
    final isShared = _activeCaregiver?.permission == 'full';
    final isShareDisabled =
        _activeCaregiver == null || _isUpdatingShare || _isLoadingCaregiver;
    final doctorText = _formatDoctorName(summary.doctorName, l10n);
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
                        Flexible(
                          child: Text(
                            l10n.shareLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context).colorScheme.secondary,
                            ),
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
                      _formatSmartTime(DateTime.parse(summary.visitDate!), l10n),
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
              const SizedBox(height: 8),
              Text(
                'AI-generated summary. Not a substitute for professional medical advice.',
                style: TextStyle(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDoctorName(String? doctorName, AppLocalizations l10n) {
    final rawName = (doctorName ?? '').trim();
    if (rawName.isEmpty || rawName.toLowerCase() == 'unknown doctor') {
      return l10n.doctorVisit;
    }

    final normalized = rawName
        .replaceFirst(RegExp(r'^(dr\.?|doctor)\s+', caseSensitive: false), '')
        .trim();

    if (normalized.isEmpty) {
      return l10n.doctorVisit;
    }
    return 'Dr. $normalized';
  }

  String _formatSmartTime(DateTime dateTime, AppLocalizations l10n) {
    return LocaleFormat.smartDateTime(context, dateTime, l10n);
  }

  Widget _buildLabResultsTab() {
    final l10n = AppLocalizations.of(context)!;
    if (_isLoadingLabResults) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_scannedDocsError != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red[400]),
            const SizedBox(height: 12),
            Text(_scannedDocsError!,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600], fontSize: 13)),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _fetchScannedDocs, child: Text(l10n.retry)),
          ],
        ),
      );
    }
    if (_labResults.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.biotech_outlined, size: 64,
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.4)),
              const SizedBox(height: 16),
              Text(l10n.noLabResultsYet,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Text(l10n.labResultsScanHint,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6))),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => context.go('/patient/visits'),
                icon: const Icon(Icons.camera_alt_outlined),
                label: Text(l10n.captureAndScan),
              ),
            ],
          ),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _fetchScannedDocs,
      child: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: _labResults.length,
        itemBuilder: (context, index) => _buildScannedDocCard(_labResults[index]),
      ),
    );
  }

  Widget _buildScannedDocsTab() {
    final l10n = AppLocalizations.of(context)!;
    if (_isLoadingScannedDocs) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_scannedDocsError != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red[400]),
            const SizedBox(height: 12),
            Text(_scannedDocsError!,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600], fontSize: 13)),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _fetchScannedDocs, child: Text(l10n.retry)),
          ],
        ),
      );
    }
    if (_scannedDocs.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.document_scanner_outlined, size: 64,
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.4)),
              const SizedBox(height: 16),
              Text(l10n.noScannedDocsYet,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Text(l10n.scannedDocsHint,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6))),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => context.go('/patient/visits'),
                icon: const Icon(Icons.camera_alt_outlined),
                label: Text(l10n.captureAndScan),
              ),
            ],
          ),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _fetchScannedDocs,
      child: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: _scannedDocs.length,
        itemBuilder: (context, index) => _buildScannedDocCard(_scannedDocs[index]),
      ),
    );
  }

  void _showScannedDocDetail(BuildContext context, String dateStr, String parsedText) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        maxChildSize: 0.95,
        minChildSize: 0.4,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  Icon(Icons.description_outlined,
                      color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      dateStr.isNotEmpty ? 'Scanned $dateStr' : 'Scanned document',
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: SingleChildScrollView(
                controller: scrollController,
                padding: const EdgeInsets.all(20),
                child: Text(
                  parsedText,
                  style: const TextStyle(fontSize: 14, height: 1.6),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
