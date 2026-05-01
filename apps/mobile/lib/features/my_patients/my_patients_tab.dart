import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/theme.dart';
import '../../models/connected_patient.dart';
import '../../providers/my_patients_provider.dart';
import 'widgets/patient_card.dart';

/// Caregiver dashboard: Firestore-connected patients list.
class MyPatientsTab extends ConsumerStatefulWidget {
  const MyPatientsTab({super.key});

  @override
  ConsumerState<MyPatientsTab> createState() => _MyPatientsTabState();
}

class _MyPatientsTabState extends ConsumerState<MyPatientsTab> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _query = _searchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _onRefresh() async {
    ref.invalidate(myPatientsProvider);
  }

  List<ConnectedPatient> _filterByName(List<ConnectedPatient> patients) {
    if (_query.isEmpty) return patients;
    return patients
        .where((p) => p.displayName.toLowerCase().contains(_query))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final asyncPatients = ref.watch(myPatientsProvider);

    return Scaffold(
      backgroundColor: RemiCareUiColors.bodyBackground,
      appBar: AppBar(
        backgroundColor: RemiCareUiColors.primaryDarkTeal,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'My Patients',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Patients connected to you',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 13,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _onRefresh,
          ),
        ],
      ),
      body: asyncPatients.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Text(
              e.toString(),
              textAlign: TextAlign.center,
              style: TextStyle(color: theme.colorScheme.error),
            ),
          ),
        ),
        data: (patients) {
          if (patients.isEmpty) {
            return const _EmptyState();
          }

          final filtered = _filterByName(patients);
          final showNoResults = filtered.isEmpty && _query.isNotEmpty;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Row(
                  children: [
                    const Text(
                      'My patients',
                      style: TextStyle(
                        color: RemiCareUiColors.sectionHeaderText,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: RemiCareUiColors.searchBarBg,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${patients.length} connected',
                        style: const TextStyle(
                          color: RemiCareUiColors.subtitleSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: _searchController,
                  style: const TextStyle(
                    fontSize: 13,
                    color: RemiCareUiColors.sectionHeaderText,
                  ),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: RemiCareUiColors.searchBarBg,
                    hintText: 'Search patients...',
                    hintStyle: const TextStyle(
                      color: RemiCareUiColors.confidenceText,
                      fontSize: 13,
                    ),
                    prefixIcon: const Icon(
                      Icons.search,
                      color: RemiCareUiColors.confidenceText,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: showNoResults
                    ? const Center(
                        child: Text(
                          'No patients match your search.',
                          style: TextStyle(
                            color: RemiCareUiColors.confidenceText,
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          return PatientCard(patient: filtered[index]);
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.people_outline,
              size: 44,
              color: RemiCareUiColors.declineBorder,
            ),
            SizedBox(height: 16),
            Text(
              'No patients connected yet',
              style: TextStyle(
                color: RemiCareUiColors.subtitleSecondary,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8),
            Text(
              'Accept an invitation to see a patient here.',
              style: TextStyle(
                color: RemiCareUiColors.confidenceText,
                fontSize: 13,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
