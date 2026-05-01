import 'package:flutter/material.dart';

import '../../../core/config/theme.dart';
import '../../../models/connected_patient.dart';

class PatientCard extends StatefulWidget {
  final ConnectedPatient patient;

  const PatientCard({super.key, required this.patient});

  @override
  State<PatientCard> createState() => _PatientCardState();
}

class _PatientCardState extends State<PatientCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final p = widget.patient;
    final (avatarBg, avatarFg) = p.avatarColors;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color: RemiCareUiColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        boxShadow: RemiCareUiColors.cardShadow,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            alignment: Alignment.topCenter,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => setState(() => _expanded = !_expanded),
                    borderRadius: BorderRadius.circular(8),
                    child: _collapsedHeader(p, avatarBg, avatarFg),
                  ),
                ),
                if (_expanded) ...[
                  const Divider(thickness: 0.5, color: Color(0xFFEEEEEE)),
                  const SizedBox(height: 12),
                  _detailGrid(p),
                  if (p.medications.isNotEmpty) _medicationsSection(p),
                  if (p.alerts.isNotEmpty) _alertsSection(p),
                  const SizedBox(height: 12),
                  _actionRow(context),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _collapsedHeader(
    ConnectedPatient p,
    Color avatarBg,
    Color avatarFg,
  ) {
    final genderDob = <String>[];
    if (p.gender != null && p.gender!.isNotEmpty) {
      genderDob.add(p.gender!);
    }
    if (p.dob != null && p.dob!.isNotEmpty) {
      genderDob.add(p.dob!);
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(color: avatarBg, shape: BoxShape.circle),
          alignment: Alignment.center,
          child: Text(
            p.initials,
            style: TextStyle(
              color: avatarFg,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      p.displayName,
                      style: const TextStyle(
                        color: RemiCareUiColors.sectionHeaderText,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (p.isNew) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: RemiCareUiColors.newBadgeBg,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: RemiCareUiColors.newBadgeBorder),
                      ),
                      child: const Text(
                        'New',
                        style: TextStyle(
                          color: RemiCareUiColors.newBadgeText,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              if (genderDob.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  genderDob.join(' · '),
                  style: const TextStyle(
                    color: RemiCareUiColors.confidenceText,
                    fontSize: 12,
                  ),
                ),
              ],
              if (p.role.isNotEmpty) ...[
                const SizedBox(height: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: RemiCareUiColors.rolePillBg,
                    borderRadius: BorderRadius.circular(20),
                    border:
                        Border.all(color: RemiCareUiColors.rolePillBorder),
                  ),
                  child: Text(
                    p.role,
                    style: const TextStyle(
                      color: RemiCareUiColors.rolePillText,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (p.joinedLabel.isNotEmpty)
              Text(
                p.joinedLabel,
                style: const TextStyle(
                  color: RemiCareUiColors.confidenceText,
                  fontSize: 11,
                ),
              ),
            AnimatedRotation(
              turns: _expanded ? 0.5 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: const Icon(
                Icons.keyboard_arrow_down,
                size: 16,
                color: RemiCareUiColors.confidenceText,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _detailGrid(ConnectedPatient p) {
    final primary = p.primaryCondition;
    final allergies = p.allergies;
    final dob = p.dob;

    final hasPrimary = primary != null && primary.isNotEmpty;
    final hasAllergies = allergies != null && allergies.isNotEmpty;
    final hasDob = dob != null && dob.isNotEmpty;

    if (!hasPrimary && !hasAllergies && !hasDob) {
      return _syncRowOnly(p);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (hasPrimary)
              Expanded(
                child: _labelValue(
                  'Primary condition',
                  primary!,
                  syncDot: false,
                ),
              ),
            if (hasPrimary) const SizedBox(width: 12),
            Expanded(
              child: _labelValue(
                'Last synced',
                p.lastSyncLabel,
                syncDot: true,
              ),
            ),
          ],
        ),
        if (hasAllergies || hasDob) ...[
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (hasAllergies)
                Expanded(
                  child: _labelValue(
                    'Allergies',
                    allergies!,
                    syncDot: false,
                  ),
                ),
              if (hasAllergies && hasDob) const SizedBox(width: 12),
              if (hasDob)
                Expanded(
                  child: _labelValue(
                    'Date of birth',
                    dob!,
                    syncDot: false,
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _syncRowOnly(ConnectedPatient p) {
    return _labelValue(
      'Last synced',
      p.lastSyncLabel,
      syncDot: true,
    );
  }

  Widget _labelValue(String label, String value, {required bool syncDot}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: RemiCareUiColors.confidenceText,
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 2),
        syncDot
            ? Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    margin: const EdgeInsets.only(right: 6, top: 2),
                    decoration: const BoxDecoration(
                      color: RemiCareUiColors.syncDot,
                      shape: BoxShape.circle,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      value,
                      style: const TextStyle(
                        color: RemiCareUiColors.sectionHeaderText,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              )
            : Text(
                value,
                style: const TextStyle(
                  color: RemiCareUiColors.sectionHeaderText,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
      ],
    );
  }

  Widget _medicationsSection(ConnectedPatient p) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 10),
        const Text(
          'Current medications',
          style: TextStyle(
            color: RemiCareUiColors.confidenceText,
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: p.medications
              .map(
                (m) => Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                  decoration: BoxDecoration(
                    color: RemiCareUiColors.medChipBg,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: RemiCareUiColors.medChipBorder),
                  ),
                  child: Text(
                    m,
                    style: const TextStyle(
                      color: RemiCareUiColors.medChipText,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }

  Widget _alertsSection(ConnectedPatient p) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 10),
        const Text(
          'Alerts',
          style: TextStyle(
            color: RemiCareUiColors.confidenceText,
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: p.alerts
              .map(
                (a) => Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                  decoration: BoxDecoration(
                    color: RemiCareUiColors.alertChipBg,
                    borderRadius: BorderRadius.circular(20),
                    border:
                        Border.all(color: RemiCareUiColors.alertChipBorder),
                  ),
                  child: Text(
                    a,
                    style: const TextStyle(
                      color: RemiCareUiColors.alertChipText,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }

  Widget _actionRow(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 36,
            child: OutlinedButton(
              onPressed: () {
                // TODO: navigate to CarePlanScreen
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: RemiCareUiColors.carePlanButtonText,
                side: const BorderSide(color: RemiCareUiColors.declineBorder),
                elevation: 0,
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'View care plan',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: SizedBox(
            height: 36,
            child: ElevatedButton(
              onPressed: () {
                // TODO: navigate to RemindersScreen
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: RemiCareUiColors.tealAcceptButton,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Reminders',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
