import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import '../../../patient/data/models/summary_item.dart';
import '../../../patient/data/services/patient_api_service.dart';
import '../../../care_team/data/services/care_team_api_service.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/config/environment.dart';
import '../../../../core/services/reminder_notification_sync.dart';
import '../../../../shared/widgets/twelve_hour_time_picker.dart';

class PatientOverviewScreen extends StatefulWidget {
  const PatientOverviewScreen({super.key});

  @override
  State<PatientOverviewScreen> createState() => _PatientOverviewScreenState();
}

class _PatientOverviewScreenState extends State<PatientOverviewScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _patientId;
  bool _hasLoaded = false;
  bool _isLoading = true;
  String? _error;

  Map<String, dynamic> _patientData = {
    'id': '',
    'name': '',
    'age': 0,
    'relationship': 'Care Team',
    'condition': 'Authorized access',
    'status': 'active',
    'phone': '',
    'emergencyContact': '',
    'address': '',
    'primaryCarePhysician': '',
    'lastVisit': DateTime.now(),
    'medicationAdherence': 0,
    'upcomingAppointments': 0,
  };

  List<Map<String, dynamic>> _visits = [];

  List<Map<String, dynamic>> _reminders = [];

  List<Map<String, dynamic>> _notes = [];
  bool _notesLoading = false;
  String? _caregiverId;

  List<Map<String, dynamic>> _symptoms = [];
  bool _symptomsLoading = false;
  String? _symptomsError;
  bool _symptomsRequested = false;
  String _symptomRange = '30d';
  String _symptomSeverityQuery = '';
  Map<String, dynamic>? _symptomFiltersApplied;
  List<Map<String, dynamic>> _scannedDocs = [];
  bool _scannedDocsLoading = false;
  String? _scannedDocsError;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) return;
      if (_tabController.index == 2 && _notes.isEmpty && !_notesLoading) {
        _loadNotes();
      }
      if (_tabController.index == 3 && !_symptomsRequested) {
        _symptomsRequested = true;
        _loadSymptoms();
      }
      if (_tabController.index == 4 &&
          _scannedDocs.isEmpty &&
          !_scannedDocsLoading) {
        _loadScannedDocs();
      }
      setState(() {});
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_hasLoaded) return;
    final state = GoRouterState.of(context);
    _patientId = state.uri.queryParameters['patientId'];
    final openSymptoms =
        state.uri.queryParameters['tab']?.toLowerCase() == 'symptoms';
    _hasLoaded = true;
    _loadPatientData();
    if (openSymptoms) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() {
          _tabController.index = 3;
          _symptomsRequested = true;
        });
        _loadSymptoms();
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadPatientData() async {
    if (_patientId == null || _patientId!.isEmpty) {
      setState(() {
        _error = 'Missing patientId';
        _isLoading = false;
      });
      return;
    }

    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final user = await AuthService().getCurrentUser();
      if (user == null) {
        throw Exception('Authentication required');
      }
      _caregiverId = user.authUid ?? user.id;

      final authToken = await AuthService().getAccessToken();
      if (authToken == null) throw Exception('Authentication required');

      // Fetch patient info from care team
      final patients = await CareTeamApiService().getMyPatients();
      final patientInfo = patients.firstWhere(
        (p) => p['patient_id']?.toString() == _patientId,
        orElse: () => <String, dynamic>{},
      );

      final name = (patientInfo['full_name'] as String?)?.trim().isNotEmpty == true
          ? patientInfo['full_name'] as String
          : (patientInfo['email'] as String?) ?? 'Patient';
      final relationship = patientInfo['relationship']?.toString() ?? 'Care Team';
      final adherence = (patientInfo['medication_adherence'] as num?)?.toInt() ?? 0;
      final appointments = (patientInfo['upcoming_appointments'] as num?)?.toInt() ?? 0;

      // Fetch patient's reminders
      final remindersResp = await http.get(
        Uri.parse('${Environment.apiBaseUrl}/api/reminders/patient/$_patientId'),
        headers: {
          'Authorization': 'Bearer $authToken',
          'Content-Type': 'application/json',
        },
      );
      List<Map<String, dynamic>> reminders = [];
      if (remindersResp.statusCode == 200) {
        final data = json.decode(remindersResp.body) as Map<String, dynamic>;
        final all = <dynamic>[
          ...(data['today'] as List<dynamic>? ?? []),
          ...(data['upcoming'] as List<dynamic>? ?? []),
          ...(data['past'] as List<dynamic>? ?? []),
        ];
        reminders = all.whereType<Map<String, dynamic>>().map((r) => {
          'id': r['id']?.toString() ?? '',
          'title': r['title']?.toString() ?? 'Reminder',
          'type': r['reminder_type']?.toString() ?? 'task',
          'status': r['status']?.toString() ?? 'pending',
          'nextDue': (DateTime.tryParse(r['scheduled_time']?.toString() ?? '') ?? DateTime.now()).toLocal(),
          'adherence': 0,
          'dosage': null,
          'frequency': r['recurrence']?.toString(),
        }).toList();
      }

      // Fetch visits/summaries
      final apiService = PatientApiService(baseUrl: Environment.apiBaseUrl, authToken: authToken);
      List<Map<String, dynamic>> visits = [];
      try {
        final summaries = await apiService.getSummaries();
        visits = summaries.map(_mapSummaryToVisit).toList();
      } catch (_) {}

      if (!mounted) return;
      setState(() {
        _patientData = {
          'id': _patientId ?? '',
          'name': name,
          'relationship': relationship,
          'condition': 'Authorized access',
          'status': adherence >= 80 ? 'active' : 'attention',
          'phone': '',
          'emergencyContact': '',
          'address': '',
          'primaryCarePhysician': '',
          'lastVisit': visits.isNotEmpty ? visits.first['date'] : DateTime.now(),
          'medicationAdherence': adherence,
          'upcomingAppointments': appointments,
        };
        _visits = visits;
        _reminders = reminders;
        _isLoading = false;
      });
      _loadScannedDocs();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadScannedDocs() async {
    if (_patientId == null || _patientId!.isEmpty) return;
    setState(() {
      _scannedDocsLoading = true;
      _scannedDocsError = null;
    });
    try {
      final docs = await CareTeamApiService().getPatientScannedDocs(_patientId!);
      if (!mounted) return;
      setState(() {
        _scannedDocs = docs;
        _scannedDocsLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _scannedDocsError = e.toString();
        _scannedDocsLoading = false;
      });
    }
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

  Future<void> _syncCaregiverLocalNotifications() async {
    try {
      final user = await AuthService().getCurrentUser();
      if (user != null && user.isCaregiver) {
        await ReminderNotificationSync.syncAfterAuth(AuthService(), user);
      }
    } catch (_) {}
  }

  Future<void> _loadNotes() async {
    if (_patientId == null || _caregiverId == null) return;
    setState(() => _notesLoading = true);
    try {
      final headers = await AuthService().getAuthHeaders();
      final response = await http.get(
        Uri.parse(
            '${Environment.apiBaseUrl}/api/caregiver-notes?patient_id=$_patientId'),
        headers: headers,
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          _notes = data.map((item) => _mapNote(item as Map<String, dynamic>)).toList();
          _notesLoading = false;
        });
      } else {
        setState(() => _notesLoading = false);
      }
    } catch (_) {
      setState(() => _notesLoading = false);
    }
  }

  Future<void> _loadSymptoms() async {
    if (_patientId == null || _patientId!.isEmpty) return;
    setState(() {
      _symptomsLoading = true;
      _symptomsError = null;
      _symptomFiltersApplied = null;
    });
    try {
      DateTime? from;
      DateTime? to;
      final now = DateTime.now();
      if (_symptomRange == '7d') {
        from = DateTime(now.year, now.month, now.day)
            .subtract(const Duration(days: 7));
        to = DateTime(now.year, now.month, now.day);
      } else if (_symptomRange == '30d') {
        from = DateTime(now.year, now.month, now.day)
            .subtract(const Duration(days: 30));
        to = DateTime(now.year, now.month, now.day);
      }
      final data = await CareTeamApiService().getPatientSymptomJournal(
        _patientId!,
        {
          if (from != null) 'date_from': from.toIso8601String(),
          if (to != null) 'date_to': to.toIso8601String(),
          if (_symptomSeverityQuery.trim().isNotEmpty)
            'severity_contains': _symptomSeverityQuery.trim(),
        },
      );
      if (!mounted) return;
      final raw = data['entries'];
      final list = raw is List
          ? raw.whereType<Map<String, dynamic>>().toList()
          : <Map<String, dynamic>>[];
      final fa = data['filters_applied'];
      Map<String, dynamic>? filtersMap;
      if (fa is Map) {
        filtersMap = Map<String, dynamic>.from(fa);
      }
      setState(() {
        _symptoms = list;
        _symptomFiltersApplied = filtersMap;
        _symptomsLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _symptomsError = e.toString();
        _symptomsLoading = false;
        _symptomFiltersApplied = null;
      });
    }
  }

  String _symptomFiltersSummary(
    Map<String, dynamic> f, {
    required int listLength,
  }) {
    final bits = <String>[
      '$listLength ${listLength == 1 ? 'entry' : 'entries'} returned',
    ];
    if (f['date_from'] != null && '${f['date_from']}'.isNotEmpty) {
      bits.add('from ${f['date_from']}');
    }
    if (f['date_to'] != null && '${f['date_to']}'.isNotEmpty) {
      bits.add('to ${f['date_to']}');
    }
    if (f['severity_substring'] != null &&
        '${f['severity_substring']}'.trim().isNotEmpty) {
      bits.add('severity contains "${f['severity_substring']}"');
    }
    return bits.join(' · ');
  }

  Map<String, dynamic> _mapNote(Map<String, dynamic> raw) {
    DateTime createdAt;
    try {
      createdAt = DateTime.parse(raw['created_at'] as String);
    } catch (_) {
      createdAt = DateTime.now();
    }
    return {
      'id': raw['id'] as String,
      'title': raw['title'] as String? ?? '',
      'content': raw['content'] as String? ?? '',
      'author': 'Me',
      'date': createdAt,
      'priority': 'medium',
      'visitId': raw['visit_id']?.toString(),
      'reminderId': raw['reminder_id']?.toString(),
    };
  }

  String _notePrivacyLinkLine(Map<String, dynamic> note) {
    final v = note['visitId']?.toString();
    if (v != null && v.isNotEmpty) {
      return 'Private · linked to visit';
    }
    final r = note['reminderId']?.toString();
    if (r != null && r.isNotEmpty) {
      return 'Private · linked to reminder';
    }
    return 'Private · general coordination';
  }

  Future<void> _createNote(
    String title,
    String content, {
    String? visitId,
    String? reminderId,
  }) async {
    if (_patientId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Patient not loaded. Try again.')),
        );
      }
      return;
    }
    try {
      final headers = await AuthService().getAuthHeaders();
      final body = <String, dynamic>{
        'patient_id': _patientId,
        'title': title,
        'content': content,
      };
      if (visitId != null && visitId.trim().isNotEmpty) {
        body['visit_id'] = visitId.trim();
      }
      if (reminderId != null && reminderId.trim().isNotEmpty) {
        body['reminder_id'] = reminderId.trim();
      }
      final response = await http.post(
        Uri.parse('${Environment.apiBaseUrl}/api/caregiver-notes'),
        headers: headers,
        body: jsonEncode(body),
      );
      if (!mounted) return;
      if (response.statusCode == 201) {
        await _loadNotes();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Private note saved.')),
        );
      } else {
        final detail = response.body.trim();
        final msg = detail.isNotEmpty && detail.length < 180
            ? 'Could not save note (${response.statusCode}): $detail'
            : 'Could not save note (HTTP ${response.statusCode}).';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not save note: $e')),
        );
      }
    }
  }

  Future<void> _updateNote(String noteId, String title, String content) async {
    try {
      final headers = await AuthService().getAuthHeaders();
      final response = await http.put(
        Uri.parse('${Environment.apiBaseUrl}/api/caregiver-notes/$noteId'),
        headers: headers,
        body: jsonEncode({'title': title, 'content': content}),
      );
      if (response.statusCode == 200) {
        await _loadNotes();
      }
    } catch (_) {}
  }

  Future<void> _deleteNote(String noteId) async {
    try {
      final headers = await AuthService().getAuthHeaders();
      await http.delete(
        Uri.parse('${Environment.apiBaseUrl}/api/caregiver-notes/$noteId'),
        headers: headers,
      );
      setState(() {
        _notes.removeWhere((n) => n['id'] == noteId);
      });
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            // App Bar
            SliverAppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: Icon(
                  Icons.arrow_back,
                  color: Theme.of(context).colorScheme.primary,
                ),
                onPressed: () => context.go('/caregiver/patients'),
              ),
              title: const Text(
                'Patient Overview',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
              actions: [
                IconButton(
                  icon: Icon(
                    Icons.edit,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  onPressed: _editPatient,
                ),
                IconButton(
                  icon: Icon(
                    Icons.more_vert,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  onPressed: _showMoreOptions,
                ),
              ],
            ),

            // Patient Header
            SliverToBoxAdapter(
              child: _buildPatientHeader(),
            ),

            // Tab Bar
            SliverPersistentHeader(
              pinned: true,
              delegate: _SliverAppBarDelegate(
                TabBar(
                  controller: _tabController,
                  tabs: const [
                    Tab(text: 'Visits', icon: Icon(Icons.medical_services)),
                    Tab(text: 'Reminders', icon: Icon(Icons.notifications)),
                    Tab(text: 'My notes', icon: Icon(Icons.note)),
                    Tab(text: 'Symptoms', icon: Icon(Icons.healing)),
                    Tab(text: 'Scanned Docs', icon: Icon(Icons.description_outlined)),
                  ],
                  labelColor: Theme.of(context).colorScheme.primary,
                  unselectedLabelColor: Theme.of(context).colorScheme.secondary,
                  indicatorColor: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildVisitsTab(),
            _buildRemindersTab(),
            _buildNotesTab(),
            _buildSymptomsTab(),
            _buildScannedDocsTab(),
          ],
        ),
      ),
      floatingActionButton: (_tabController.index == 3 || _tabController.index == 4)
          ? null
          : FloatingActionButton(
              onPressed: _addNewItem,
              backgroundColor: Theme.of(context).colorScheme.primary,
              child: Icon(_getFabIcon()),
            ),
    );
  }

  Widget _buildPatientHeader() {
    return Container(
      margin: const EdgeInsets.all(16),
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
        children: [
          // Avatar and Basic Info
          Row(
            children: [
              Stack(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: _getStatusColor(_patientData['status'])
                          .withOpacity(0.1),
                      borderRadius: BorderRadius.circular(40),
                    ),
                    child: Icon(
                      Icons.person,
                      color: _getStatusColor(_patientData['status']),
                      size: 40,
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: _getStatusColor(_patientData['status']),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: Icon(
                        _getStatusIcon(_patientData['status']),
                        color: Colors.white,
                        size: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _patientData['name'],
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    Text(
                      _patientData['relationship'],
                      style: TextStyle(
                        fontSize: 16,
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _patientData['condition'],
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context)
                            .colorScheme
                            .secondary
                            .withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Health Stats
          Row(
            children: [
              _buildStatItem(
                'Adherence',
                '${_patientData['medicationAdherence']}%',
                _patientData['medicationAdherence'] >= 80
                    ? Colors.green
                    : Colors.orange,
              ),
              _buildStatItem(
                'Appointments',
                _patientData['upcomingAppointments'].toString(),
                Colors.blue,
              ),
              _buildStatItem(
                'Last Visit',
                _formatLastVisit(_patientData['lastVisit']),
                Colors.purple,
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Contact Info
          Row(
            children: [
              Icon(
                Icons.phone,
                size: 16,
                color: Theme.of(context).colorScheme.secondary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _patientData['phone'],
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.emergency,
                size: 16,
                color: Theme.of(context).colorScheme.secondary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _patientData['emergencyContact'],
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVisitsTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(child: Text(_error!));
    }
    if (_visits.isEmpty) {
      return const Center(child: Text('No visits available'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _visits.length,
      itemBuilder: (context, index) {
        final visit = _visits[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.medical_services,
                color: Colors.white,
              ),
            ),
            title: Text(
              '${visit['doctor']} - ${visit['type']}',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _formatDate(visit['date']),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                ),
                Text(
                  visit['summary'],
                  style: TextStyle(
                    color: Theme.of(context)
                        .colorScheme
                        .secondary
                        .withOpacity(0.8),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: 'Add private note for this visit',
                  icon: const Icon(Icons.note_add_outlined, size: 22),
                  onPressed: () {
                    final id = visit['id']?.toString() ?? '';
                    if (id.isEmpty) return;
                    _tabController.index = 2;
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) {
                        _showAddNoteDialog(initialVisitId: id);
                      }
                    });
                  },
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Theme.of(context)
                      .colorScheme
                      .secondary
                      .withOpacity(0.5),
                ),
              ],
            ),
            onTap: () => _viewVisitDetails(visit),
          ),
        );
      },
    );
  }

  Widget _buildRemindersTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(child: Text(_error!));
    }
    if (_reminders.isEmpty) {
      return const Center(child: Text('No reminders available'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _reminders.length,
      itemBuilder: (context, index) {
        final reminder = _reminders[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _getReminderTypeColor(reminder['type']).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _getReminderTypeIcon(reminder['type']),
                color: _getReminderTypeColor(reminder['type']),
              ),
            ),
            title: Text(
              reminder['title'],
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (reminder['dosage'] != null)
                  Text(
                    '${reminder['dosage']} • ${reminder['frequency']}',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                  ),
                Text(
                  'Next: ${_formatDateTime(reminder['nextDue'])} • ${reminder['adherence']}% adherence',
                  style: TextStyle(
                    color: Theme.of(context)
                        .colorScheme
                        .secondary
                        .withOpacity(0.8),
                  ),
                ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: 'Add private note for this reminder',
                  icon: const Icon(Icons.note_add_outlined, size: 22),
                  onPressed: () {
                    final id = reminder['id']?.toString() ?? '';
                    if (id.isEmpty) return;
                    _tabController.index = 2;
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) {
                        _showAddNoteDialog(initialReminderId: id);
                      }
                    });
                  },
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getReminderStatusColor(reminder['status'])
                        .withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    reminder['status'].toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      color: _getReminderStatusColor(reminder['status']),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            onTap: () => _viewReminderDetails(reminder),
          ),
        );
      },
    );
  }

  Widget _buildNotesTab() {
    if (_notesLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_notes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.note_outlined, size: 64,
                color: Theme.of(context).colorScheme.secondary.withOpacity(0.4)),
            const SizedBox(height: 16),
            Text('No notes yet',
                style: TextStyle(
                    fontSize: 18,
                    color: Theme.of(context).colorScheme.secondary)),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'Notes are private to you and stored with this patient’s ID. '
                'Optionally link a note to a visit or reminder.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: Theme.of(context).colorScheme.secondary,
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _showAddNoteDialog(),
              icon: const Icon(Icons.add),
              label: const Text('Add First Note'),
            ),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _notes.length,
      itemBuilder: (context, index) {
        final note = _notes[index];
        return Dismissible(
          key: Key(note['id']),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          confirmDismiss: (direction) async {
            return await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Delete Note'),
                    content: const Text('Are you sure you want to delete this note?'),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.of(ctx).pop(false),
                          child: const Text('Cancel')),
                      TextButton(
                          onPressed: () => Navigator.of(ctx).pop(true),
                          child: const Text('Delete',
                              style: TextStyle(color: Colors.red))),
                    ],
                  ),
                ) ??
                false;
          },
          onDismissed: (_) => _deleteNote(note['id'] as String),
          child: Card(
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.note,
                    color: Theme.of(context).colorScheme.primary),
              ),
              title: Text(
                note['title'],
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text(
                    _notePrivacyLinkLine(note),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.9),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    note['content'],
                    style:
                        TextStyle(color: Theme.of(context).colorScheme.secondary),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatDate(note['date']),
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
              trailing: IconButton(
                icon: const Icon(Icons.edit_outlined, size: 20),
                onPressed: () => _showEditNoteDialog(note),
              ),
              onTap: () => _showEditNoteDialog(note),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSymptomsTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Shared symptom entries from visit summaries (read-only). '
                'Filters are applied on the server.',
                style: TextStyle(
                  fontSize: 13,
                  color: Theme.of(context).colorScheme.secondary,
                ),
              ),
              if (_symptomFiltersApplied != null && !_symptomsLoading) ...[
                const SizedBox(height: 4),
                Text(
                  _symptomFiltersSummary(_symptomFiltersApplied!, listLength: _symptoms.length),
                  style: TextStyle(
                    fontSize: 11,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.55),
                  ),
                ),
              ],
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  ChoiceChip(
                    label: const Text('All time'),
                    selected: _symptomRange == 'all',
                    onSelected: (v) {
                      if (!v) return;
                      setState(() => _symptomRange = 'all');
                      _loadSymptoms();
                    },
                  ),
                  ChoiceChip(
                    label: const Text('Last 7 days'),
                    selected: _symptomRange == '7d',
                    onSelected: (v) {
                      if (!v) return;
                      setState(() => _symptomRange = '7d');
                      _loadSymptoms();
                    },
                  ),
                  ChoiceChip(
                    label: const Text('Last 30 days'),
                    selected: _symptomRange == '30d',
                    onSelected: (v) {
                      if (!v) return;
                      setState(() => _symptomRange = '30d');
                      _loadSymptoms();
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: const InputDecoration(
                        labelText: 'Filter by severity text',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      onChanged: (v) => _symptomSeverityQuery = v,
                      onEditingComplete: _loadSymptoms,
                      onSubmitted: (_) => _loadSymptoms(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filledTonal(
                    onPressed: _loadSymptoms,
                    icon: const Icon(Icons.search),
                    tooltip: 'Apply filters',
                  ),
                ],
              ),
            ],
          ),
        ),
        if (_symptomsError != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              _symptomsError!,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadSymptoms,
            child: _symptomsLoading && _symptoms.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: const [
                      SizedBox(height: 120),
                      Center(child: CircularProgressIndicator()),
                    ],
                  )
                : _symptoms.isEmpty
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(24),
                        children: [
                          Icon(
                            Icons.healing_outlined,
                            size: 56,
                            color: Theme.of(context)
                                .colorScheme
                                .secondary
                                .withOpacity(0.35),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _symptomsLoading
                                ? 'Loading…'
                                : 'No symptom entries yet. They appear when visit summaries include a symptoms section.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.secondary,
                            ),
                          ),
                        ],
                      )
                    : ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                        itemCount: _symptoms.length,
                        itemBuilder: (context, index) {
                          final s = _symptoms[index];
                          final desc =
                              (s['description'] as String?)?.trim() ?? '';
                          final sev =
                              (s['severity'] as String?)?.trim() ?? '';
                          final dur =
                              (s['duration'] as String?)?.trim() ?? '';
                          final preview =
                              (s['note_preview'] as String?)?.trim() ?? '';
                          final title =
                              (s['visit_title'] as String?)?.trim() ?? '';
                          final doctor =
                              (s['doctor_name'] as String?)?.trim() ?? '';
                          DateTime logged;
                          try {
                            logged = DateTime.parse(
                                s['logged_at'] as String? ?? '');
                          } catch (_) {
                            logged = DateTime.now();
                          }
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              isThreeLine: true,
                              title: Text(
                                desc.isEmpty ? 'Symptom' : desc,
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  if (sev.isNotEmpty || dur.isNotEmpty)
                                    Wrap(
                                      spacing: 6,
                                      runSpacing: 4,
                                      children: [
                                        if (sev.isNotEmpty)
                                          Chip(
                                            visualDensity: VisualDensity.compact,
                                            label: Text(
                                              sev,
                                              style:
                                                  const TextStyle(fontSize: 12),
                                            ),
                                          ),
                                        if (dur.isNotEmpty)
                                          Chip(
                                            visualDensity: VisualDensity.compact,
                                            label: Text(
                                              'Duration: $dur',
                                              style:
                                                  const TextStyle(fontSize: 12),
                                            ),
                                          ),
                                      ],
                                    ),
                                  if (title.isNotEmpty || doctor.isNotEmpty)
                                    Text(
                                      [title, doctor]
                                          .where((e) => e.isNotEmpty)
                                          .join(' · '),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .secondary,
                                      ),
                                    ),
                                  Text(
                                    _formatDateTime(logged),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .secondary
                                          .withOpacity(0.85),
                                    ),
                                  ),
                                  if (preview.isNotEmpty) ...[
                                    const SizedBox(height: 6),
                                    Text(
                                      preview,
                                      maxLines: 3,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface
                                            .withOpacity(0.75),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ),
      ],
    );
  }

  Widget _buildScannedDocsTab() {
    if (_scannedDocsLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_scannedDocsError != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Failed to load scanned documents',
              style: TextStyle(color: Theme.of(context).colorScheme.secondary),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _loadScannedDocs,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }
    if (_scannedDocs.isEmpty) {
      return Center(
        child: Text(
          'No scanned documents available',
          style: TextStyle(color: Theme.of(context).colorScheme.secondary),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadScannedDocs,
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

  Widget _buildStatItem(String label, String value, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.secondary.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _editPatient() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Patient profile'),
        content: const Text(
          'Patient profile details are read-only for caregivers in Phase 1. '
          'Use reminders, notes, and symptoms tabs for care coordination.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showMoreOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.phone),
            title: const Text('Call Patient'),
            onTap: () {
              Navigator.of(context).pop();
            },
          ),
          ListTile(
            leading: const Icon(Icons.message),
            title: const Text('Send Message'),
            onTap: () {
              Navigator.of(context).pop();
            },
          ),
          ListTile(
            leading: const Icon(Icons.emergency),
            title: const Text('Emergency Contact'),
            onTap: () {
              Navigator.of(context).pop();
            },
          ),
          ListTile(
            leading: const Icon(Icons.share),
            title: const Text('Share Patient Info'),
            onTap: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }

  void _addNewItem() {
    switch (_tabController.index) {
      case 0:
        _showAddReminderDialog(initialType: 'appointment');
        break;
      case 1:
        _showAddReminderDialog();
        break;
      case 2:
        _showAddNoteDialog();
        break;
      case 3:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Symptom journal is read-only. Use filters on the Symptoms tab.',
            ),
          ),
        );
        break;
      default:
        break;
    }
  }

  String _timeOfDay12h(TimeOfDay t) {
    final h = t.hour;
    final m = t.minute.toString().padLeft(2, '0');
    final p = h >= 12 ? 'PM' : 'AM';
    final h12 = h % 12 == 0 ? 12 : h % 12;
    return '$h12:$m $p';
  }

  void _showAddReminderDialog({String initialType = 'medication'}) {
    final titleController = TextEditingController();
    String selectedType = initialType;
    if (!['medication', 'appointment', 'task'].contains(selectedType)) {
      selectedType = 'medication';
    }
    String selectedRecurrence = 'once';
    DateTime selectedDate = DateTime.now().add(const Duration(hours: 1));
    TimeOfDay selectedTime = TimeOfDay.fromDateTime(selectedDate);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Add Reminder for ${_patientData['name']}',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Title',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedType,
                  decoration: const InputDecoration(labelText: 'Type', border: OutlineInputBorder()),
                  items: const [
                    DropdownMenuItem(value: 'medication', child: Text('Medication')),
                    DropdownMenuItem(value: 'appointment', child: Text('Appointment')),
                    DropdownMenuItem(value: 'task', child: Text('Task')),
                  ],
                  onChanged: (v) => setModal(() => selectedType = v!),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedRecurrence,
                  decoration: const InputDecoration(labelText: 'Frequency', border: OutlineInputBorder()),
                  items: const [
                    DropdownMenuItem(value: 'once', child: Text('Once')),
                    DropdownMenuItem(value: 'twice', child: Text('Twice')),
                    DropdownMenuItem(value: 'daily', child: Text('Daily')),
                    DropdownMenuItem(value: 'weekly', child: Text('Weekly')),
                  ],
                  onChanged: (v) => setModal(() => selectedRecurrence = v!),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.calendar_today),
                        label: Text('${selectedDate.day}/${selectedDate.month}/${selectedDate.year}'),
                        onPressed: () async {
                          final d = await showDatePicker(
                            context: ctx,
                            initialDate: selectedDate,
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                          );
                          if (d != null) {
                            setModal(() => selectedDate = DateTime(d.year, d.month, d.day, selectedTime.hour, selectedTime.minute));
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.access_time),
                        label: Text(_timeOfDay12h(selectedTime)),
                        onPressed: () async {
                          final t = await showTwelveHourTimePickerSheet(
                            ctx,
                            initialTime: selectedTime,
                          );
                          if (t != null) {
                            setModal(() {
                              selectedTime = t;
                              selectedDate = DateTime(selectedDate.year, selectedDate.month, selectedDate.day, t.hour, t.minute);
                            });
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1B4E59),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () async {
                      final title = titleController.text.trim();
                      if (title.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please enter a title')),
                        );
                        return;
                      }
                      Navigator.of(ctx).pop();
                      await _createReminderForPatient(
                        title: title,
                        type: selectedType,
                        scheduledTime: selectedDate,
                        recurrence: selectedRecurrence,
                      );
                    },
                    child: const Text('Create Reminder', style: TextStyle(color: Colors.white, fontSize: 16)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _createReminderForPatient({
    required String title,
    required String type,
    required DateTime scheduledTime,
    required String recurrence,
  }) async {
    try {
      final tzName = await FlutterTimezone.getLocalTimezone();
      await CareTeamApiService().createPatientReminder(_patientId!, {
        'user_id': '',
        'reminder_type': type,
        'title': title,
        'scheduled_time': scheduledTime.toUtc().toIso8601String(),
        'timezone': tzName,
        'recurrence': recurrence,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reminder created for patient!')),
        );
      }
      await _loadPatientData();
      await _syncCaregiverLocalNotifications();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create reminder: $e')),
        );
      }
    }
  }

  void _showAddNoteDialog({String? initialVisitId, String? initialReminderId}) {
    final titleCtrl = TextEditingController();
    final contentCtrl = TextEditingController();
    final messenger = ScaffoldMessenger.of(context);
    showDialog(
      context: context,
      builder: (ctx) {
        var linkKind = (initialVisitId?.isNotEmpty ?? false)
            ? 'visit'
            : ((initialReminderId?.isNotEmpty ?? false) ? 'reminder' : 'none');
        String? visitVal =
            (initialVisitId?.isNotEmpty ?? false) ? initialVisitId : null;
        String? reminderVal =
            (initialReminderId?.isNotEmpty ?? false) ? initialReminderId : null;

        return StatefulBuilder(
          builder: (ctx, setSt) {
            final visitItems = _visits
                .where((v) => (v['id']?.toString() ?? '').isNotEmpty)
                .map(
                  (v) => DropdownMenuItem<String>(
                    value: v['id']?.toString(),
                    child: Text(
                      '${v['doctor']} · ${_formatDate(v['date'])}',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                )
                .toList();
            final reminderItems = _reminders
                .where((r) => (r['id']?.toString() ?? '').isNotEmpty)
                .map(
                  (r) => DropdownMenuItem<String>(
                    value: r['id']?.toString(),
                    child: Text(
                      r['title']?.toString() ?? 'Reminder',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                )
                .toList();

            final visitDropdownValue = visitVal != null &&
                    visitItems.any((e) => e.value == visitVal)
                ? visitVal
                : (visitItems.isNotEmpty ? visitItems.first.value : null);
            final reminderDropdownValue = reminderVal != null &&
                    reminderItems.any((e) => e.value == reminderVal)
                ? reminderVal
                : (reminderItems.isNotEmpty ? reminderItems.first.value : null);

            return AlertDialog(
              title: const Text('Add private note'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Stored with your caregiver ID and this patient. '
                      'Only you can read these notes (not the patient).',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: titleCtrl,
                      decoration: const InputDecoration(labelText: 'Title'),
                      onChanged: (_) => setSt(() {}),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: contentCtrl,
                      decoration: const InputDecoration(labelText: 'Content'),
                      maxLines: 4,
                      onChanged: (_) => setSt(() {}),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: linkKind,
                      decoration: const InputDecoration(
                        labelText: 'Link (optional)',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      isExpanded: true,
                      items: const [
                        DropdownMenuItem(
                          value: 'none',
                          child: Text('General (not linked)'),
                        ),
                        DropdownMenuItem(
                          value: 'visit',
                          child: Text('Link to a visit'),
                        ),
                        DropdownMenuItem(
                          value: 'reminder',
                          child: Text('Link to a reminder'),
                        ),
                      ],
                      onChanged: (v) {
                        if (v == null) return;
                        setSt(() {
                          linkKind = v;
                          if (linkKind != 'visit') visitVal = null;
                          if (linkKind != 'reminder') reminderVal = null;
                        });
                      },
                    ),
                    if (linkKind == 'visit') ...[
                      const SizedBox(height: 8),
                      if (visitItems.isEmpty)
                        Text(
                          'No visits to link.',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        )
                      else
                        DropdownButtonFormField<String>(
                          value: visitDropdownValue,
                          decoration: const InputDecoration(
                            labelText: 'Visit',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          isExpanded: true,
                          items: visitItems,
                          onChanged: (v) => setSt(() => visitVal = v),
                        ),
                    ],
                    if (linkKind == 'reminder') ...[
                      const SizedBox(height: 8),
                      if (reminderItems.isEmpty)
                        Text(
                          'No reminders to link.',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        )
                      else
                        DropdownButtonFormField<String>(
                          value: reminderDropdownValue,
                          decoration: const InputDecoration(
                            labelText: 'Reminder',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          isExpanded: true,
                          items: reminderItems,
                          onChanged: (v) => setSt(() => reminderVal = v),
                        ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final t = titleCtrl.text.trim();
                    final c = contentCtrl.text.trim();
                    if (t.isEmpty) {
                      messenger.showSnackBar(
                        const SnackBar(
                          content: Text('Please enter a title.'),
                        ),
                      );
                      return;
                    }
                    if (c.isEmpty) {
                      messenger.showSnackBar(
                        const SnackBar(
                          content: Text('Please enter note content.'),
                        ),
                      );
                      return;
                    }
                    final resolvedVisit = linkKind == 'visit'
                        ? (visitVal ?? visitDropdownValue)
                        : null;
                    final resolvedReminder = linkKind == 'reminder'
                        ? (reminderVal ?? reminderDropdownValue)
                        : null;
                    if (linkKind == 'visit') {
                      if (visitItems.isEmpty) {
                        messenger.showSnackBar(
                          const SnackBar(
                            content: Text(
                              'No visits available. Choose General or add a visit first.',
                            ),
                          ),
                        );
                        return;
                      }
                      if (resolvedVisit == null || resolvedVisit.isEmpty) {
                        messenger.showSnackBar(
                          const SnackBar(
                            content: Text('Please select a visit to link.'),
                          ),
                        );
                        return;
                      }
                    }
                    if (linkKind == 'reminder') {
                      if (reminderItems.isEmpty) {
                        messenger.showSnackBar(
                          const SnackBar(
                            content: Text(
                              'No reminders available. Choose General or add a reminder first.',
                            ),
                          ),
                        );
                        return;
                      }
                      if (resolvedReminder == null ||
                          resolvedReminder.isEmpty) {
                        messenger.showSnackBar(
                          const SnackBar(
                            content: Text('Please select a reminder to link.'),
                          ),
                        );
                        return;
                      }
                    }
                    Navigator.of(ctx).pop();
                    _createNote(
                      t,
                      c,
                      visitId: resolvedVisit,
                      reminderId: resolvedReminder,
                    );
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showEditNoteDialog(Map<String, dynamic> note) {
    final titleCtrl = TextEditingController(text: note['title'] as String);
    final contentCtrl = TextEditingController(text: note['content'] as String);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Note'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleCtrl,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: contentCtrl,
              decoration: const InputDecoration(labelText: 'Content'),
              maxLines: 4,
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final t = titleCtrl.text.trim();
              final c = contentCtrl.text.trim();
              if (t.isNotEmpty && c.isNotEmpty) {
                Navigator.of(ctx).pop();
                _updateNote(note['id'] as String, t, c);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _viewVisitDetails(Map<String, dynamic> visit) {
    final visitId = visit['id']?.toString() ?? '';
    if (visitId.isEmpty) return;
    final date = visit['date'];
    final dateParam = date is DateTime ? '&visitDate=${date.toIso8601String()}' : '';
    context.push('/patient/visit-details?visitId=$visitId$dateParam');
  }

  void _viewReminderDetails(Map<String, dynamic> reminder) {
    final rid = reminder['id']?.toString() ?? '';
    if (rid.isEmpty || _patientId == null || _patientId!.isEmpty) return;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.55,
        minChildSize: 0.35,
        maxChildSize: 0.9,
        builder: (ctx, scrollCtrl) => FutureBuilder<Map<String, dynamic>>(
          future: CareTeamApiService().getPatientReminder(_patientId!, rid),
          builder: (ctx, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            if (snap.hasError || !snap.hasData) {
              return Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  snap.error?.toString() ?? 'Could not load reminder',
                ),
              );
            }
            final r = snap.data!;
            final msg = r['message']?.toString() ?? '';
            final st = DateTime.tryParse(r['scheduled_time']?.toString() ?? '')
                    ?.toLocal() ??
                DateTime.now();
            final rec = r['recurrence']?.toString() ?? 'once';
            final rtype = r['reminder_type']?.toString() ?? 'task';
            final stat = r['status']?.toString() ?? 'pending';
            return ListView(
              controller: scrollCtrl,
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              children: [
                Text(
                  r['title']?.toString() ?? 'Reminder',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text('Type: $rtype'),
                Text('Status: $stat'),
                Text('Repeat: $rec'),
                Text('Scheduled: ${_formatDateTime(st)}'),
                if (msg.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(msg, style: const TextStyle(fontSize: 15)),
                ],
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.edit),
                        label: const Text('Edit'),
                        onPressed: () {
                          Navigator.of(ctx).pop();
                          _showEditReminderDialog(r);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.tonalIcon(
                        icon: const Icon(Icons.delete_outline),
                        label: const Text('Delete'),
                        style: FilledButton.styleFrom(
                          foregroundColor: Colors.red.shade800,
                        ),
                        onPressed: () {
                          Navigator.of(ctx).pop();
                          _confirmDeleteReminder(
                            rid,
                            r['title']?.toString() ?? 'this reminder',
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _showEditReminderDialog(Map<String, dynamic> apiReminder) {
    final rid = apiReminder['id']?.toString() ?? '';
    if (rid.isEmpty || _patientId == null) return;

    final titleController =
        TextEditingController(text: apiReminder['title']?.toString() ?? '');
    String selectedType =
        (apiReminder['reminder_type']?.toString() ?? 'medication').trim();
    if (!['medication', 'task', 'appointment'].contains(selectedType)) {
      selectedType = 'task';
    }
    String selectedRecurrence =
        (apiReminder['recurrence']?.toString() ?? 'once').trim();
    if (!['once', 'twice', 'daily', 'weekly'].contains(selectedRecurrence)) {
      selectedRecurrence = 'once';
    }
    final parsed = DateTime.tryParse(
            apiReminder['scheduled_time']?.toString() ?? '') ??
        DateTime.now().add(const Duration(hours: 1));
    DateTime selectedDate = parsed.toLocal();
    TimeOfDay selectedTime = TimeOfDay.fromDateTime(selectedDate);

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            padding: const EdgeInsets.all(24),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Edit reminder',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: 'Title',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: selectedType,
                    decoration: const InputDecoration(
                      labelText: 'Type',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(
                          value: 'medication', child: Text('Medication')),
                      DropdownMenuItem(
                          value: 'appointment', child: Text('Appointment')),
                      DropdownMenuItem(value: 'task', child: Text('Task')),
                    ],
                    onChanged: (v) => setModal(() => selectedType = v!),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: selectedRecurrence,
                    decoration: const InputDecoration(
                      labelText: 'Frequency',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'once', child: Text('Once')),
                      DropdownMenuItem(value: 'twice', child: Text('Twice')),
                      DropdownMenuItem(value: 'daily', child: Text('Daily')),
                      DropdownMenuItem(value: 'weekly', child: Text('Weekly')),
                    ],
                    onChanged: (v) => setModal(() => selectedRecurrence = v!),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.calendar_today),
                          label: Text(
                              '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}'),
                          onPressed: () async {
                            final d = await showDatePicker(
                              context: ctx,
                              initialDate: selectedDate,
                              firstDate: DateTime.now()
                                  .subtract(const Duration(days: 1)),
                              lastDate: DateTime.now()
                                  .add(const Duration(days: 365)),
                            );
                            if (d != null) {
                              setModal(() => selectedDate = DateTime(
                                    d.year,
                                    d.month,
                                    d.day,
                                    selectedTime.hour,
                                    selectedTime.minute,
                                  ));
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.access_time),
                          label: Text(_timeOfDay12h(selectedTime)),
                          onPressed: () async {
                            final t = await showTwelveHourTimePickerSheet(
                              ctx,
                              initialTime: selectedTime,
                            );
                            if (t != null) {
                              setModal(() {
                                selectedTime = t;
                                selectedDate = DateTime(
                                  selectedDate.year,
                                  selectedDate.month,
                                  selectedDate.day,
                                  t.hour,
                                  t.minute,
                                );
                              });
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1B4E59),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () async {
                        final title = titleController.text.trim();
                        if (title.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Please enter a title')),
                          );
                          return;
                        }
                        final tzName = await FlutterTimezone.getLocalTimezone();
                        if (!ctx.mounted) return;
                        Navigator.of(ctx).pop();
                        try {
                          await CareTeamApiService().updatePatientReminder(
                            _patientId!,
                            rid,
                            {
                              'title': title,
                              'scheduled_time':
                                  selectedDate.toUtc().toIso8601String(),
                              'timezone': tzName,
                              'recurrence': selectedRecurrence,
                            },
                          );
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Reminder updated')),
                            );
                          }
                          await _loadPatientData();
                          await _syncCaregiverLocalNotifications();
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text('Failed to update: $e')),
                            );
                          }
                        }
                      },
                      child: const Text(
                        'Save changes',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDeleteReminder(String reminderId, String title) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete reminder'),
        content: Text('Remove "$title" for this patient?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text('Delete', style: TextStyle(color: Colors.red.shade800)),
          ),
        ],
      ),
    );
    if (ok != true || _patientId == null) return;
    try {
      await CareTeamApiService()
          .deletePatientReminder(_patientId!, reminderId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reminder deleted')),
        );
      }
      await _loadPatientData();
      await _syncCaregiverLocalNotifications();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete: $e')),
        );
      }
    }
  }

  void _viewNoteDetails(Map<String, dynamic> note) {
    _showEditNoteDialog(note);
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'active':
        return Colors.green;
      case 'attention':
        return Colors.orange;
      case 'critical':
        return Colors.red;
      default:
        return Theme.of(context).colorScheme.primary;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'active':
        return Icons.check;
      case 'attention':
        return Icons.warning;
      case 'critical':
        return Icons.error;
      default:
        return Icons.info;
    }
  }

  Color _getReminderTypeColor(String type) {
    switch (type) {
      case 'medication':
        return Colors.blue;
      case 'appointment':
        return Colors.purple;
      case 'measurement':
        return Colors.green;
      default:
        return Theme.of(context).colorScheme.primary;
    }
  }

  IconData _getReminderTypeIcon(String type) {
    switch (type) {
      case 'medication':
        return Icons.medication;
      case 'appointment':
        return Icons.calendar_today;
      case 'measurement':
        return Icons.monitor_heart;
      default:
        return Icons.notifications;
    }
  }

  Color _getReminderStatusColor(String status) {
    switch (status) {
      case 'active':
        return Colors.green;
      case 'upcoming':
        return Colors.blue;
      case 'overdue':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Color _getNotePriorityColor(String priority) {
    switch (priority) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.green;
      default:
        return Theme.of(context).colorScheme.primary;
    }
  }

  IconData _getFabIcon() {
    switch (_tabController.index) {
      case 0:
        return Icons.add_alarm; // For scheduling appointments
      case 1:
        return Icons.notification_add; // For adding reminders
      case 2:
        return Icons.note_add; // For adding notes
      default:
        return Icons.add;
    }
  }

  String _formatLastVisit(DateTime lastVisit) {
    final now = DateTime.now();
    final difference = now.difference(lastVisit).inDays;

    if (difference == 0) {
      return 'Today';
    } else if (difference == 1) {
      return 'Yesterday';
    } else if (difference < 7) {
      return '$difference days ago';
    } else if (difference < 30) {
      final weeks = (difference / 7).floor();
      return '$weeks week${weeks > 1 ? 's' : ''} ago';
    } else {
      final months = (difference / 30).floor();
      return '$months month${months > 1 ? 's' : ''} ago';
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date).inDays;

    if (difference == 0) {
      return 'Today';
    } else if (difference == 1) {
      return 'Yesterday';
    } else if (difference < 7) {
      return '$difference days ago';
    } else {
      return '${date.month}/${date.day}/${date.year}';
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = dateTime.difference(now);

    if (difference.isNegative) {
      return 'Overdue';
    } else if (difference.inHours < 24) {
      return 'In ${difference.inHours} hours';
    } else {
      return '${dateTime.month}/${dateTime.day} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    }
  }

  Map<String, dynamic> _mapSummaryToVisit(SummaryItem summary) {
    final dateSource = summary.visitDate ?? summary.summaryCreatedAt;
    final parsedDate = DateTime.tryParse(dateSource) ?? DateTime.now();
    return {
      'id': summary.visitId,
      'doctor': summary.doctorName,
      'specialty': summary.specialty,
      'date': parsedDate,
      'type': summary.specialty.isNotEmpty ? summary.specialty : 'Visit',
      'summary': summary.summaryPreview,
      'nextAppointment': parsedDate,
    };
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;

  _SliverAppBarDelegate(this.tabBar);

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}
