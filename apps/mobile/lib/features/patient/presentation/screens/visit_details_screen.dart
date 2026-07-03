import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import '../../../../core/services/auth_service.dart';
import '../../../../core/config/environment.dart';
import '../../../../core/utils/locale_format.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/services/patient_api_service.dart';

class VisitDetailsScreen extends StatefulWidget {
  final String visitId;
  final String? visitDate;
  final String? patientId;

  VisitDetailsScreen({
    super.key,
    required this.visitId,
    this.visitDate,
    this.patientId,
  }) {
    if (kDebugMode) {
      print("🧨🧨🧨 Opening VisitDetailsScreen with visitId = $visitId");
    }
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
  List<String> _keyDiagnoses = [];
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
    if (kDebugMode) {
      print("🔍 _fetchAISummary called for visitId: ${widget.visitId}");
    }

    setState(() {
      _isLoadingSummary = true;
      _summaryStatus = 'loading';
    });

    try {
      final firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser == null) throw Exception('Authentication required');
      final authToken = await firebaseUser.getIdToken(true);
      if (kDebugMode) {
        print("🔍 Auth token available: ${authToken != null}");
      }

      final apiService = PatientApiService(
        baseUrl: Environment.apiBaseUrl,
        authToken: authToken ?? '',
      );

      if (kDebugMode) {
        print(
            "🔥🔥🔥 Calling GET /api/visits/${widget.visitId}/summary-structured");
      }
      final data = await apiService.getVisitSummaryStructured(
        widget.visitId,
        patientId: widget.patientId,
      );
      if (kDebugMode) {
        print("🔍 API response: $data");
      }

      if (data['status'] == 'processing') {
        if (kDebugMode) {
          print("🔍 Summary still processing, setting processing state");
        }
        setState(() {
          _summaryStatus = 'processing';
          _isLoadingSummary = false;
        });
      } else if (_hasStructuredSummaryPayload(data)) {
        if (kDebugMode) {
          print("🔍 Found structured summary, setting to ready state");
        }
        final parsed = _parseStructuredSummary(data);
        setState(() {
          _summaryText = parsed.summarization;
          _decisions = parsed.decisions;
          _medications = parsed.medications;
          _actions = parsed.actions;
          _keyDiagnoses = parsed.keyDiagnoses;
          _summaryStatus = 'ready';
          _isLoadingSummary = false;
        });
      } else {
        if (kDebugMode) {
          print("🔍 Unexpected response format: $data");
        }
        setState(() {
          _summaryStatus = 'error';
          _isLoadingSummary = false;
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print("🔍 Error fetching summary: $e");
      }
      setState(() {
        _summaryStatus = 'error';
        _isLoadingSummary = false;
      });
    }
  }

  Future<void> _fetchVisitMetadata() async {
    try {
      final firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser == null) throw Exception('Authentication required');
      final authToken = await firebaseUser.getIdToken(true);
      if (authToken == null) {
        throw Exception('Authentication required');
      }

      final uri = Uri.parse('${Environment.apiBaseUrl}/api/visits/${widget.visitId}')
          .replace(
        queryParameters: widget.patientId != null && widget.patientId!.isNotEmpty
            ? {'patient_id': widget.patientId!}
            : null,
      );
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

  bool _hasStructuredSummaryPayload(Map<String, dynamic> data) {
    if (data.containsKey('summary')) return true;
    if (data.containsKey('summarization')) return true;
    return data.containsKey('decision') ||
        data.containsKey('decisions') ||
        data.containsKey('medication') ||
        data.containsKey('medications') ||
        data.containsKey('action') ||
        data.containsKey('actions') ||
        data.containsKey('action_items') ||
        data.containsKey('keyPoints') ||
        data.containsKey('key_diagnoses') ||
        data.containsKey('questions_next_visit');
  }

  String _readSummaryText(Map<String, dynamic> data) {
    final summarizationMap = data['summarization'];
    if (summarizationMap is Map) {
      final text = summarizationMap['text']?.toString().trim() ?? '';
      if (text.isNotEmpty) return text;
    }
    return data['summary']?.toString().trim() ?? '';
  }

  /// Merges V1 (`decision`/`action` sections) and V2 (`decisions`/`actions` lists).
  List<String> _readSectionItems(
    Map<String, dynamic> data, {
    required String singularKey,
    required String pluralKey,
    List<String> legacyKeys = const [],
  }) {
    final seen = <String>{};
    final merged = <String>[];
    void append(List<String> items) {
      for (final item in _nonEmptyItems(items)) {
        if (seen.add(item)) merged.add(item);
      }
    }

    append(_itemsFromSection(data[singularKey]));
    append(_toStringList(data[pluralKey]));
    for (final legacyKey in legacyKeys) {
      append(_toStringList(data[legacyKey]));
    }
    return merged;
  }

  ({
    String summarization,
    List<String> decisions,
    List<String> medications,
    List<String> actions,
    List<String> keyDiagnoses,
  }) _parseStructuredSummary(Map<String, dynamic> data) {
    return (
      summarization: _readSummaryText(data),
      decisions: _readSectionItems(
        data,
        singularKey: 'decision',
        pluralKey: 'decisions',
      ),
      medications: _readSectionItems(
        data,
        singularKey: 'medication',
        pluralKey: 'medications',
      ),
      actions: _readSectionItems(
        data,
        singularKey: 'action',
        pluralKey: 'actions',
        legacyKeys: const ['action_items', 'keyPoints'],
      ),
      keyDiagnoses: _toStringList(data['key_diagnoses']),
    );
  }

  List<String> _itemsFromSection(dynamic section) {
    if (section is Map) {
      return _toStringList(section['items']);
    }
    return _toStringList(section);
  }

  void _handleBack() {
    if (context.canPop()) {
      context.pop();
      return;
    }

    final path = GoRouterState.of(context).uri.path;
    if (path.startsWith('/caregiver/')) {
      final patientId = widget.patientId;
      if (patientId != null && patientId.isNotEmpty) {
        context.go('/caregiver/patient-overview?patientId=$patientId');
      } else {
        context.go('/caregiver/patients');
      }
      return;
    }

    context.go('/patient/overview');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Theme.of(context).colorScheme.primary,
          ),
          onPressed: _handleBack,
        ),
        title: Text(
          l10n.visitDetails,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _fetchAISummary,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),

                if (!_isLoadingVisit && _hasVisitMetadata())
                  _buildVisitHeader(),
                if (!_isLoadingVisit && _hasVisitMetadata())
                  const SizedBox(height: 16),

                _buildSummaryStatusSection(l10n),
                if (_summaryStatus == 'ready') ...[
                  const SizedBox(height: 16),
                  ..._buildReadySummaryCards(l10n),
                  const SizedBox(height: 8),
                  _buildAiSummaryDisclaimer(),
                ],

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryStatusSection(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.smart_toy,
                  color: Colors.blue,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.healthVisitSummary,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.blue,
                      ),
                    ),
                    if (widget.visitDate != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          _formatVisitDate(widget.visitDate!),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              IconButton(
                onPressed: _fetchAISummary,
                icon: const Icon(Icons.refresh),
                tooltip: l10n.refreshSummaryTooltip,
              ),
            ],
          ),
          if (_summaryStatus != 'ready') ...[
            const SizedBox(height: 16),
            if (_isLoadingSummary)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_summaryStatus == 'processing')
              _buildInlineStatusBanner(
                icon: Icons.psychology,
                color: Colors.orange,
                title: l10n.preparingVisitSummary,
                subtitle: l10n.preparingVisitSubtitle,
              )
            else if (_summaryStatus == 'error')
              _buildInlineStatusBanner(
                icon: Icons.error_outline,
                color: Colors.red,
                title: l10n.unableToLoadVisitSummary,
                showRetry: true,
                retryLabel: l10n.retry,
              )
            else
              _buildInlineStatusBanner(
                icon: Icons.error_outline,
                color: Colors.grey,
                title: l10n.visitSummaryUnavailable,
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildInlineStatusBanner({
    required IconData icon,
    required Color color,
    required String title,
    String? subtitle,
    bool showRetry = false,
    String retryLabel = 'Retry',
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
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
                    color: color,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: color.withOpacity(0.85),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (showRetry)
            TextButton(
              onPressed: _fetchAISummary,
              child: Text(retryLabel),
            ),
        ],
      ),
    );
  }

  static const _nextToDoPlaceholderPhrases = {
    'no clinical decisions mentioned in the conversation',
    'no follow-up actions mentioned in the conversation',
  };

  List<String> _nonEmptyItems(List<String> items) {
    return items.map((item) => item.trim()).where((item) => item.isNotEmpty).toList();
  }

  List<String> _meaningfulNextToDoItems(List<String> items) {
    return _nonEmptyItems(items)
        .where(
          (item) => !_nextToDoPlaceholderPhrases.contains(item.toLowerCase()),
        )
        .toList();
  }

  List<Widget> _buildReadySummaryCards(AppLocalizations l10n) {
    final cards = <Widget>[];
    void addCard(Widget? card) {
      if (card == null) return;
      if (cards.isNotEmpty) {
        cards.add(const SizedBox(height: 12));
      }
      cards.add(card);
    }

    addCard(_buildVisitSummaryCard(l10n));
    addCard(_buildMedicationCard(l10n));
    addCard(_buildNextToDoCard(l10n));
    return cards;
  }

  static const _labFollowUpKeywords = [
    'lab',
    'fasting',
    'blood',
    'panel',
    'metabolic',
    'lipid',
  ];

  List<String> _labFollowUpLines() {
    final lines = <String>[];
    for (final item in _meaningfulNextToDoItems(_actions)) {
      final lower = item.toLowerCase();
      if (!_labFollowUpKeywords.any(lower.contains)) continue;
      lines.add(_condenseLabFollowUpLine(item));
    }
    return lines;
  }

  String _condenseLabFollowUpLine(String item) {
    final lower = item.toLowerCase();
    if (lower.contains('fasting') &&
        (lower.contains('lab') ||
            lower.contains('blood') ||
            lower.contains('panel'))) {
      return 'Lab results while fasting';
    }
    return item;
  }

  Widget _buildSummarySubheading(String label) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  Widget _buildAiSummaryDisclaimer() {
    return Text(
      'AI-generated summary. Not a substitute for professional medical advice.',
      style: TextStyle(
        fontSize: 12,
        fontStyle: FontStyle.italic,
        color: Colors.grey[600],
      ),
    );
  }

  Widget? _buildVisitSummaryCard(AppLocalizations l10n) {
    final overview = (_summaryText ?? '').trim();
    final diagnoses = _nonEmptyItems(_keyDiagnoses);
    final followUps = _labFollowUpLines();
    if (overview.isEmpty && diagnoses.isEmpty && followUps.isEmpty) {
      return null;
    }

    return _buildSummaryCategoryCard(
      title: l10n.visitSummary,
      icon: Icons.summarize_outlined,
      accentColor: const Color(0xFF2E7D62),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (overview.isNotEmpty)
            Text(
              overview,
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.secondary,
                height: 1.4,
              ),
            ),
          if (diagnoses.isNotEmpty) ...[
            if (overview.isNotEmpty) const SizedBox(height: 14),
            _buildSummarySubheading(l10n.conditionsDiscussed),
            const SizedBox(height: 8),
            _buildBulletList(diagnoses),
          ],
          if (followUps.isNotEmpty) ...[
            if (overview.isNotEmpty || diagnoses.isNotEmpty)
              const SizedBox(height: 14),
            _buildSummarySubheading(l10n.followUp),
            const SizedBox(height: 8),
            _buildBulletList(followUps),
          ],
        ],
      ),
    );
  }

  Widget? _buildMedicationCard(AppLocalizations l10n) {
    final items = _nonEmptyItems(_medications);
    if (items.isEmpty) return null;

    return _buildSummaryCategoryCard(
      title: l10n.medication,
      icon: Icons.medication_outlined,
      accentColor: const Color(0xFF3AA8A1),
      child: _buildBulletList(items),
    );
  }

  bool _isLabFollowUpAction(String item) {
    final lower = item.toLowerCase();
    return _labFollowUpKeywords.any(lower.contains);
  }

  /// Merged decisions + actions in one list (decisions first, then actions).
  Widget? _buildNextToDoCard(AppLocalizations l10n) {
    final items = [
      ..._meaningfulNextToDoItems(_decisions),
      ..._meaningfulNextToDoItems(_actions)
          .where((item) => !_isLabFollowUpAction(item)),
    ];
    if (items.isEmpty) return null;

    return _buildSummaryCategoryCard(
      title: l10n.nextToDo,
      icon: Icons.playlist_add_check_outlined,
      accentColor: const Color(0xFF557A7F),
      child: _buildBulletList(items),
    );
  }

  Widget _buildSummaryCategoryCard({
    required String title,
    required IconData icon,
    required Color accentColor,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accentColor.withOpacity(0.18)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: accentColor, size: 22),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: accentColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildBulletList(List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items.map((item) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '• ',
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).colorScheme.secondary,
                ),
              ),
              Expanded(
                child: Text(
                  item,
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).colorScheme.secondary,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  bool _hasVisitMetadata() {
    return (_visitDoctor != null && _visitDoctor!.trim().isNotEmpty) ||
        (_visitSpecialty != null && _visitSpecialty!.trim().isNotEmpty) ||
        (_visitTitle != null && _visitTitle!.trim().isNotEmpty);
  }

  Widget _buildVisitHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_visitTitle != null && _visitTitle!.trim().isNotEmpty)
          Text(
            _visitTitle!,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
        if (_visitDoctor != null && _visitDoctor!.trim().isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              _visitDoctor!,
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.primary,
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
                color: Theme.of(context).colorScheme.secondary,
              ),
            ),
          ),
      ],
    );
  }

  String _formatVisitDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return LocaleFormat.dateMedium(context, date);
    } catch (e) {
      return dateString;
    }
  }
}
