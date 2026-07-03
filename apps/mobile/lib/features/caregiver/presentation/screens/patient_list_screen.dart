import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/utils/locale_format.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../care_team/data/models/care_team_member.dart';
import '../../../care_team/data/services/care_team_api_service.dart';

class PatientListScreen extends StatefulWidget {
  const PatientListScreen({super.key});

  @override
  State<PatientListScreen> createState() => _PatientListScreenState();
}

class _PatientListScreenState extends State<PatientListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedFilter = 'All';

  bool _isLoading = true;
  String? _error;
  List<Map<String, dynamic>> _allPatients = [];

  List<Map<String, dynamic>> get _filteredPatients {
    var patients = _allPatients;

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      patients = patients.where((patient) {
        final name = patient['name'].toLowerCase();
        final relationship = patient['relationship'].toLowerCase();
        final condition = patient['condition'].toLowerCase();
        final query = _searchQuery.toLowerCase();
        return name.contains(query) ||
            relationship.contains(query) ||
            condition.contains(query);
      }).toList();
    }

    // Apply status filter
    if (_selectedFilter != 'All') {
      patients = patients
          .where(
              (patient) => patient['status'] == _selectedFilter.toLowerCase())
          .toList();
    }

    return patients;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadPatients();
  }

  Future<void> _loadPatients() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });
      final members = await CareTeamApiService().getCareTeam();
      if (!mounted) return;
      setState(() {
        _allPatients = members.map(_mapMemberToPatient).toList();
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
          onPressed: () => context.go('/caregiver/home'),
        ),
        title: const Text(
          'My Patients',
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
            onPressed: _showFilterDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText:
                    'Search patients by name, relationship, or condition...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: _clearSearch,
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey.withOpacity(0.1),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),

          // Results Count
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                Text(
                  '${LocaleFormat.number(context, _filteredPatients.length)} ${l10n.navPatients}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                if (_selectedFilter != 'All') ...[
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getFilterColor(_selectedFilter).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _selectedFilter,
                      style: TextStyle(
                        fontSize: 12,
                        color: _getFilterColor(_selectedFilter),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
                const Spacer(),
                if (_selectedFilter != 'All')
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _selectedFilter = 'All';
                      });
                    },
                    child: const Text('Clear Filter'),
                  ),
              ],
            ),
          ),

          // Patient List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? _buildErrorState()
                    : _filteredPatients.isEmpty
                        ? _buildEmptyState()
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _filteredPatients.length,
                            itemBuilder: (context, index) {
                              final patient = _filteredPatients[index];
                              return _buildPatientCard(patient);
                            },
                          ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.go('/caregiver/accept-invitations?filter=pending'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        child: const Icon(Icons.person_add),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: 80,
            color: Theme.of(context).colorScheme.secondary.withOpacity(0.5),
          ),
          const SizedBox(height: 24),
          Text(
            _searchQuery.isNotEmpty
                ? 'No patients match your search'
                : 'No patients found',
            style: TextStyle(
              fontSize: 20,
              color: Theme.of(context).colorScheme.secondary,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isNotEmpty
                ? 'Try adjusting your search terms'
                : 'Add patients to start managing their care',
            style: TextStyle(
              fontSize: 16,
              color: Theme.of(context).colorScheme.secondary.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
          if (_searchQuery.isEmpty) ...[
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () =>
                  context.go('/caregiver/accept-invitations?filter=pending'),
              icon: const Icon(Icons.person_add),
              label: const Text('View Invitations'),
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              _error ?? 'Failed to load patients',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.error,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadPatients,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPatientCard(Map<String, dynamic> patient) {
    final l10n = AppLocalizations.of(context)!;
    final status = patient['status'] as String;
    final medicationAdherence = patient['medicationAdherence'] as int;
    final upcomingAppointments = patient['upcomingAppointments'] as int;
    final unreadAlerts = patient['unreadAlerts'] as int;
    final patientId = patient['id'] as String;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () =>
            context.go('/caregiver/patient-overview?patientId=$patientId'),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Header Row
              Row(
                children: [
                  // Avatar with Status
                  Stack(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: _getStatusColor(status).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Icon(
                          Icons.person,
                          color: _getStatusColor(status),
                          size: 30,
                        ),
                      ),
                      if (unreadAlerts > 0)
                        Positioned(
                          top: 0,
                          right: 0,
                          child: Container(
                            width: 20,
                            height: 20,
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                LocaleFormat.number(context, unreadAlerts),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  // Patient Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              patient['name'],
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: _getStatusColor(status).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                status.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 10,
                                  color: _getStatusColor(status),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        Text(
                          '${patient['relationship']} • ${LocaleFormat.number(context, patient['age'] as int)}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Theme.of(context).colorScheme.secondary,
                          ),
                        ),
                        Text(
                          patient['condition'],
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
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Theme.of(context)
                        .colorScheme
                        .secondary
                        .withOpacity(0.5),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Stats Row
              Row(
                children: [
                  _buildStatItem(
                    'Adherence',
                    LocaleFormat.percent(context, medicationAdherence),
                    medicationAdherence >= 80
                        ? Colors.green
                        : medicationAdherence >= 60
                            ? Colors.orange
                            : Colors.red,
                  ),
                  _buildStatItem(
                    'Appointments',
                    LocaleFormat.number(context, upcomingAppointments),
                    upcomingAppointments > 0 ? Colors.blue : Colors.grey,
                  ),
                  _buildStatItem(
                    'Last Visit',
                    _formatLastVisit(patient['lastVisit'] as DateTime, l10n),
                    Colors.purple,
                  ),
                ],
              ),

              // Quick Actions
              if (unreadAlerts > 0 || upcomingAppointments > 0) ...[
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),
                Row(
                  children: [
                    if (unreadAlerts > 0)
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _viewAlerts(patient),
                          icon: const Icon(Icons.notifications, size: 16),
                          label: Text(
                              'View $unreadAlerts Alert${unreadAlerts > 1 ? 's' : ''}'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                        ),
                      ),
                    if (unreadAlerts > 0 && upcomingAppointments > 0)
                      const SizedBox(width: 8),
                    if (upcomingAppointments > 0)
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _viewAppointments(patient),
                          icon: const Icon(Icons.calendar_today, size: 16),
                          label: Text(
                              '$upcomingAppointments Appointment${upcomingAppointments > 1 ? 's' : ''}'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
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
              fontSize: 16,
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

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Patients'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildFilterOption('All'),
            _buildFilterOption('Active'),
            _buildFilterOption('Attention'),
            _buildFilterOption('Critical'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterOption(String filter) {
    return RadioListTile<String>(
      title: Text(filter),
      value: filter,
      groupValue: _selectedFilter,
      onChanged: (value) {
        setState(() {
          _selectedFilter = value!;
        });
        Navigator.of(context).pop();
      },
      activeColor: Theme.of(context).colorScheme.primary,
    );
  }

  void _clearSearch() {
    setState(() {
      _searchQuery = '';
      _searchController.clear();
    });
  }

  void _viewAlerts(Map<String, dynamic> patient) {
    final patientId = (patient['id'] ?? patient['patientId'] ?? '').toString();
    if (patientId.isEmpty) return;
    context.go(
      Uri(
        path: '/caregiver/patient-overview',
        queryParameters: {'patientId': patientId, 'tab': 'reminders'},
      ).toString(),
    );
  }

  void _viewAppointments(Map<String, dynamic> patient) {
    final patientId = (patient['id'] ?? patient['patientId'] ?? '').toString();
    if (patientId.isEmpty) return;
    context.go(
      Uri(
        path: '/caregiver/patient-overview',
        queryParameters: {'patientId': patientId},
      ).toString(),
    );
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

  Color _getFilterColor(String filter) {
    switch (filter.toLowerCase()) {
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

  String _formatLastVisit(DateTime lastVisit, AppLocalizations l10n) {
    return LocaleFormat.visitRelativeDate(context, lastVisit, l10n);
  }

  Map<String, dynamic> _mapMemberToPatient(CareTeamMember member) {
    return {
      'id': member.patientId,
      'name': member.fullName ?? member.email ?? member.memberUserId,
      'age': 0,
      'relationship': member.role,
      'condition': 'Care team member',
      'status': 'active',
      'lastVisit': DateTime.now(),
      'medicationAdherence': 0,
      'upcomingAppointments': 0,
      'unreadAlerts': 0,
      'phone': '',
      'emergencyContact': '',
    };
  }
}
