import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/theme.dart';
import '../../core/widgets/remi_shell_ui.dart';
import '../../core/utils/locale_format.dart';
import '../../l10n/app_localizations.dart';
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
    final l10n = AppLocalizations.of(context)!;
    final asyncPatients = ref.watch(myPatientsProvider);

    return Scaffold(
      backgroundColor: RemiCareUiColors.bodyBackground,
      body: Column(
        children: [
          RemiShellUi.screenHeader(
            context: context,
            title: l10n.myPatientsTitle,
            subtitle: l10n.patientsConnectedSubtitle,
            trailing: IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              onPressed: _onRefresh,
            ),
          ),
          Expanded(
            child: asyncPatients.when(
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
            return _EmptyState(l10n: l10n);
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
                    Text(
                      l10n.myPatientsSection,
                      style: const TextStyle(
                        color: RemiCareUiColors.sectionHeaderText,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Merriweather',
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
                        LocaleFormat.localizeDigitsInText(
                          context,
                          l10n.connectedCount(patients.length),
                        ),
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
                    hintText: l10n.searchPatientsHint,
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
                    ? Center(
                        child: Text(
                          l10n.noPatientsMatchSearch,
                          style: const TextStyle(
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
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.people_outline,
              size: 44,
              color: RemiCareUiColors.declineBorder,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.noPatientsConnectedYet,
              style: const TextStyle(
                color: RemiCareUiColors.subtitleSecondary,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              l10n.acceptInvitationToSeePatient,
              style: const TextStyle(
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
