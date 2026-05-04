import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import '../../../../core/services/auth_service.dart';
import '../../../../core/config/environment.dart';
import '../../data/services/patient_api_service.dart';

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
        print("🔍 Summary still processing, setting processing state");
        setState(() {
          _summaryStatus = 'processing';
          _isLoadingSummary = false;
        });
      } else if (data.containsKey('summary')) {
        print("🔍 Found structured summary, setting to ready state");
        final decisions = _toStringList(data['decisions']);
        final medications = _toStringList(data['medications']);
        final actions = _toStringList(data['actions']);
        setState(() {
          _summaryText = data['summary'];
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

  @override
  Widget build(BuildContext context) {
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
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Visit Details',
          style: TextStyle(
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

                // AI Summary Card
                _buildAISummaryCard(),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAISummaryCard() {
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
                    const Text(
                      'Health Visit Summary',
                      style: TextStyle(
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
                tooltip: 'Refresh summary',
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_isLoadingSummary)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(),
              ),
            )
          else if (_summaryStatus == 'processing')
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.orange.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.psychology,
                    color: Colors.orange,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Preparing visit summary...',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.orange,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'This may take a minute.',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.orange.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )
          else if (_summaryStatus == 'ready' && _summaryText != null)
            _buildStructuredSummary()
          else if (_summaryStatus == 'error')
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.red.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: Colors.red,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: const Text(
                      'Unable to load visit summary',
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: _fetchAISummary,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            )
          else
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.error_outline,
                    color: Colors.grey,
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Visit summary is unavailable',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
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

  Widget _buildStructuredSummary() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSummarySection(
          title: 'Visit Summary',
          content: Text(
            _summaryText ?? '',
            style: TextStyle(
              fontSize: 16,
              color: Theme.of(context).colorScheme.secondary,
              height: 1.5,
            ),
          ),
        ),
        if (_decisions.isNotEmpty)
          _buildListSection(title: 'Clinical Decisions', items: _decisions),
        if (_medications.isNotEmpty)
          _buildListSection(title: 'Medications', items: _medications),
        if (_actions.isNotEmpty)
          _buildListSection(title: 'Next Steps', items: _actions),
      ],
    );
  }

  Widget _buildSummarySection({
    required String title,
    required Widget content,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.green.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          content,
        ],
      ),
    );
  }

  Widget _buildListSection({
    required String title,
    required List<String> items,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('•  '),
                  Expanded(
                    child: Text(
                      item,
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).colorScheme.secondary,
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
