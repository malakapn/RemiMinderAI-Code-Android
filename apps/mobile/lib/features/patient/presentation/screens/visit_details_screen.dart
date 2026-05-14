import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import '../../../../core/config/theme.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/config/environment.dart';
import '../../data/services/patient_api_service.dart';

/// After a recording, the backend pipeline writes a structured summary with
/// keys `summary`, `decisions`, `medications`, and `actions` (v2 normalizer output).
/// Placeholder-only lines from the model are filtered out in the UI.
class VisitDetailsScreen extends StatefulWidget {
  final String visitId;
  final String? visitDate;

  VisitDetailsScreen({
    super.key,
    required this.visitId,
    this.visitDate,
  }) {
    print("🧨🧨🧨 Opening VisitDetailsScreen with visitId = $visitId");
  }

  @override
  State<VisitDetailsScreen> createState() => _VisitDetailsScreenState();
}

class _VisitDetailsScreenState extends State<VisitDetailsScreen> {
  // AI Summary state
  String? _summaryText;
  List<String> _decisions = [];
  List<String> _medications = [];
  List<String> _actions = [];
  bool _isLoadingSummary = true;
  String _summaryStatus =
      'loading'; // 'loading', 'processing', 'ready', 'error'
  bool _isLoadingVisit = true;
  String? _visitDoctor;
  String? _visitSpecialty;
  String? _visitTitle;

  @override
  void initState() {
    super.initState();
    _fetchVisitMetadata();
    _fetchAISummary();
  }

  Future<void> _fetchAISummary() async {
    print("🔍 _fetchAISummary called for visitId: ${widget.visitId}");

    setState(() {
      _isLoadingSummary = true;
      _summaryStatus = 'loading';
    });

    try {
      final authToken = await AuthService().getAccessToken();
      print("🔍 Auth token available: ${authToken != null}");

      final apiService = PatientApiService(
        baseUrl: Environment.apiBaseUrl,
        authToken: authToken ?? '',
      );

      print(
          "🔥🔥🔥 Calling GET /api/visits/${widget.visitId}/summary-structured");
      final data = await apiService.getVisitSummaryStructured(widget.visitId);
      print("🔍 API response: $data");

      if (data['status'] == 'processing') {
        print("🔍 Structured summary missing or processing; trying plain summary");
        try {
          final plain = await apiService.getVisitSummary(widget.visitId);
          final text = plain['summary']?.toString().trim();
          if (text != null && text.isNotEmpty) {
            setState(() {
              _summaryText = text;
              _decisions = [];
              _medications = [];
              _actions = [];
              _summaryStatus = 'ready';
              _isLoadingSummary = false;
            });
            return;
          }
        } catch (e) {
          print("🔍 Plain summary fallback failed: $e");
        }
        print("🔍 Summary still processing, setting processing state");
        setState(() {
          _summaryStatus = 'processing';
          _isLoadingSummary = false;
        });
      } else if (data.containsKey('summary')) {
        print("🔍 Found structured summary, setting to ready state");
        final decisions = _toStringList(data['decisions']);
        final medications = _toStringList(data['medications']);
        final actions = _toStringList(
          data['actions'] ??
              data['action_items'] ??
              data['next_steps'],
        );
        setState(() {
          _summaryText = data['summary']?.toString();
          _decisions = decisions;
          _medications = medications;
          _actions = actions;
          _summaryStatus = 'ready';
          _isLoadingSummary = false;
        });
      } else {
        print("🔍 Unexpected response format: $data");
        setState(() {
          _summaryStatus = 'error';
          _isLoadingSummary = false;
        });
      }
    } catch (e) {
      print("🔍 Error fetching summary: $e");
      setState(() {
        _summaryStatus = 'error';
        _isLoadingSummary = false;
      });
    }
  }

  Future<void> _fetchVisitMetadata() async {
    try {
      final authToken = await AuthService().getAccessToken();
      if (authToken == null) {
        throw Exception('Authentication required');
      }

      final uri = Uri.parse(
          '${Environment.apiBaseUrl}/api/visits/${widget.visitId}');
      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $authToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        if (!mounted) return;
        setState(() {
          _visitDoctor = data['doctor'] as String?;
          _visitSpecialty = data['specialty'] as String?;
          _visitTitle = data['title'] as String?;
          _isLoadingVisit = false;
        });
        return;
      }

      if (!mounted) return;
      setState(() {
        _isLoadingVisit = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingVisit = false;
      });
    }
  }

  List<String> _toStringList(dynamic value) {
    if (value is List) {
      return value.map((item) => item.toString()).toList();
    }
    if (value is String && value.isNotEmpty) {
      return [value];
    }
    return [];
  }

  /// Normalizer emits English placeholders when lists are empty; hide those in UI.
  bool _isPlaceholderMedicationLine(String s) {
    final t = s.toLowerCase();
    return t.contains('no medications mentioned') ||
        t.contains('no medication mentioned');
  }

  bool _isPlaceholderActionLine(String s) {
    final t = s.toLowerCase();
    return t.contains('no follow-up actions') ||
        t.contains('no follow up actions') ||
        t.contains('no follow-up action');
  }

  bool _isPlaceholderDecisionLine(String s) {
    final t = s.toLowerCase();
    return t.contains('no clinical decisions');
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: primary,
          ),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Visit Details',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: primary,
            fontSize: 20,
          ),
        ),
        actions: [
          if (!_isLoadingSummary &&
              (_summaryStatus == 'ready' || _summaryStatus == 'processing'))
            IconButton(
              onPressed: _fetchAISummary,
              icon: Icon(Icons.refresh, color: primary),
              tooltip: 'Refresh summary',
            ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _fetchAISummary,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 8),
                if (!_isLoadingVisit && _hasVisitMetadata()) _buildVisitHeader(),
                if (!_isLoadingVisit && _hasVisitMetadata())
                  const SizedBox(height: 12),
                if (!_isLoadingVisit &&
                    !_hasVisitMetadata() &&
                    widget.visitDate != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      _formatVisitDate(widget.visitDate!),
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppTheme.accentColor,
                      ),
                    ),
                  ),
                _buildSummaryContent(),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Outer card chrome removed — stacked section cards match visit-summary design.
  Widget _buildSummaryContent() {
    if (_isLoadingSummary) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 48),
        child: Center(
          child: Column(
            children: [
              CircularProgressIndicator(
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                'Loading summary…',
                style: TextStyle(
                  fontSize: 15,
                  color: AppTheme.accentColor,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_summaryStatus == 'processing') {
      return _buildStatusCard(
        icon: Icons.psychology_outlined,
        title: 'Preparing visit summary…',
        subtitle: 'This may take a minute.',
        borderColor: AppTheme.secondaryColor.withOpacity(0.35),
        backgroundColor: AppTheme.secondaryColor.withOpacity(0.08),
        iconColor: AppTheme.primaryColor,
        titleColor: AppTheme.primaryColor,
        subtitleColor: AppTheme.accentColor,
      );
    }

    if (_summaryStatus == 'ready' && _summaryText != null) {
      return _buildStructuredSummary();
    }

    if (_summaryStatus == 'error') {
      return _buildStatusCard(
        icon: Icons.error_outline,
        title: 'Unable to load visit summary',
        subtitle: null,
        borderColor: AppTheme.errorColor.withOpacity(0.35),
        backgroundColor: AppTheme.errorColor.withOpacity(0.08),
        iconColor: AppTheme.errorColor,
        titleColor: AppTheme.errorColor,
        subtitleColor: AppTheme.accentColor,
        trailing: TextButton(
          onPressed: _fetchAISummary,
          child: const Text('Retry'),
        ),
      );
    }

    return _buildStatusCard(
      icon: Icons.info_outline,
      title: 'Visit summary is unavailable',
      subtitle: null,
      borderColor: AppTheme.accentColor.withOpacity(0.25),
      backgroundColor: Colors.white,
      iconColor: AppTheme.accentColor,
      titleColor: AppTheme.accentColor,
      subtitleColor: AppTheme.accentColor,
    );
  }

  Widget _buildStatusCard({
    required IconData icon,
    required String title,
    String? subtitle,
    required Color borderColor,
    required Color backgroundColor,
    required Color iconColor,
    required Color titleColor,
    required Color subtitleColor,
    Widget? trailing,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: titleColor,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: subtitleColor,
                      height: 1.35,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  bool _hasVisitMetadata() {
    return (_visitDoctor != null && _visitDoctor!.trim().isNotEmpty) ||
        (_visitSpecialty != null && _visitSpecialty!.trim().isNotEmpty) ||
        (_visitTitle != null && _visitTitle!.trim().isNotEmpty);
  }

  Widget _buildVisitHeader() {
    final primary = Theme.of(context).colorScheme.primary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_visitTitle != null && _visitTitle!.trim().isNotEmpty)
          Text(
            _visitTitle!,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: primary,
            ),
          ),
        if (_visitDoctor != null && _visitDoctor!.trim().isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              _visitDoctor!,
              style: TextStyle(
                fontSize: 14,
                color: primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        if (_visitSpecialty != null && _visitSpecialty!.trim().isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              _visitSpecialty!,
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.accentColor,
              ),
            ),
          ),
        if (widget.visitDate != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              _formatVisitDate(widget.visitDate!),
              style: TextStyle(
                fontSize: 13,
                color: AppTheme.accentColor,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildStructuredSummary() {
    final decisionsFiltered = _decisions
        .where((s) => !_isPlaceholderDecisionLine(s))
        .toList();
    final medsFiltered = _medications
        .where((s) => !_isPlaceholderMedicationLine(s))
        .toList();
    final stepsFiltered =
        _actions.where((s) => !_isPlaceholderActionLine(s)).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildNarrativeSummaryCard(),
        if (decisionsFiltered.isNotEmpty)
          _buildListSection(
            title: 'Clinical Decisions',
            items: decisionsFiltered,
          ),
        if (medsFiltered.isNotEmpty)
          _buildListSection(title: 'Medications', items: medsFiltered),
        if (stepsFiltered.isNotEmpty)
          _buildListSection(title: 'Next Steps', items: stepsFiltered),
      ],
    );
  }

  /// Top overview: light green tint, patient-facing paragraph only (no section title).
  Widget _buildNarrativeSummaryCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F4EF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.accentColor.withOpacity(0.18),
        ),
      ),
      child: Text(
        _summaryText ?? '',
        style: const TextStyle(
          fontSize: 16,
          color: AppTheme.accentColor,
          height: 1.5,
        ),
      ),
    );
  }

  static const _cardBorder = Color(0xFFE0E4E3);

  Widget _buildListSection({
    required String title,
    required List<String> items,
  }) {
    final primary = Theme.of(context).colorScheme.primary;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: primary,
            ),
          ),
          const SizedBox(height: 10),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '•  ',
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.45,
                      color: AppTheme.accentColor,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      item,
                      style: const TextStyle(
                        fontSize: 15,
                        color: AppTheme.accentColor,
                        height: 1.45,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  String _formatVisitDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
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
      final month = months[date.month - 1];
      return '$month ${date.day}, ${date.year}';
    } catch (e) {
      return dateString;
    }
  }
}
