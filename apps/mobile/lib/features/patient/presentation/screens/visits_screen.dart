import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/utils/locale_format.dart';
import '../../../../l10n/app_localizations.dart';
import '../widgets/widgets.dart';
import '../../../../core/services/visit_context.dart';

class VisitsScreen extends StatefulWidget {
  const VisitsScreen({super.key});

  @override
  State<VisitsScreen> createState() => _VisitsScreenState();
}

class _VisitsScreenState extends State<VisitsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Visits',
          style: TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 24),

                  // Quick Actions for Visits
                  Container(
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
                        QuickActionItem(
                          label: 'Record Visit',
                          icon: Icons.mic,
                          color: Colors.blue,
                          onTap: () {
                            // Start a new visit and navigate to recording
                            final visitId = VisitContext().startNewVisit();
                            context.go('/patient/record-visit/$visitId');
                          },
                        ),
                        const SizedBox(height: 20),
                        QuickActionItem(
                          label: 'Camera',
                          icon: Icons.camera_alt,
                          color: Colors.blue,
                          onTap: () {
                            // Use current visit or start new one for camera
                            final visitContext = VisitContext();
                            final visitId = visitContext.getCurrentVisitId() ??
                                visitContext.startNewVisit();
                            context.go('/patient/camera/$visitId');
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Recent Visits
                  const SectionHeader(
                    title: 'Recent Visits',
                    icon: Icons.history,
                  ),
                  const SizedBox(height: 16),

                  _buildRecentVisits(),

                  const SizedBox(height: 32),

                  // Upcoming Appointments
                  const SectionHeader(
                    title: 'Upcoming Appointments',
                    icon: Icons.calendar_today,
                  ),
                  const SizedBox(height: 16),

                  _buildUpcomingAppointments(),

                  const SizedBox(height: 120),
                ],
              ),
            ),
          ),

          // Rounded Navigation Bar
          const RoundedNavigationBar(currentItem: NavigationItem.visits),
        ],
      ),
    );
  }

  Widget _buildRecentVisits() {
    final uid = _auth.currentUser?.uid;
    if (uid == null || uid.isEmpty) {
      return _buildVisitsCardContainer(
        const Text('Sign in to see your recent visits'),
      );
    }

    return _buildVisitsCardContainer(
      StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _firestore
            .collection('users')
            .doc(uid)
            .collection('visits')
            .orderBy('visitDateTime', descending: true)
            .limit(10)
            .snapshots(),
        builder: (context, snapshot) {
          final l10n = AppLocalizations.of(context)!;
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          if (snapshot.hasError) {
            return const Text('Unable to load visits right now');
          }
          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Text('No recorded visits yet');
          }
          return Column(
            children: List.generate(docs.length, (index) {
              final data = docs[index].data();
              final visitId = data['id'] as String? ?? docs[index].id;
              final doctor = (data['doctorName'] as String?)?.trim().isNotEmpty == true
                  ? data['doctorName'] as String
                  : 'Doctor Visit';
              final type = (data['specialty'] as String?)?.trim().isNotEmpty == true
                  ? data['specialty'] as String
                  : 'General visit';
              final location = (data['location'] as String?)?.trim().isNotEmpty == true
                  ? data['location'] as String
                  : 'Unknown location';
              final dateIso = data['visitDateTime'] as String?;
              final hasRecording = data['hasRecording'] == true ||
                  ((data['summary'] as String?)?.trim().isNotEmpty == true);
              final item = _buildVisitItem(
                visitId,
                doctor,
                type,
                _formatRelativeDate(dateIso, l10n),
                location,
                hasRecording,
              );
              if (index == docs.length - 1) {
                return item;
              }
              return Column(
                children: [
                  item,
                  const Divider(height: 16),
                ],
              );
            }),
          );
        },
      ),
    );
  }

  Widget _buildVisitsCardContainer(Widget child) {
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
      child: child,
    );
  }

  Widget _buildVisitItem(String visitId, String doctor, String type, String date,
      String location, bool hasRecording) {
    return InkWell(
      onTap: () {
        context.go('/patient/visit-details?visitId=$visitId');
      },
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              hasRecording ? Icons.mic : Icons.medical_services,
              color: Theme.of(context).colorScheme.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  doctor,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                Text(
                  type,
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                ),
                Text(
                  '$date • $location',
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
          if (hasRecording)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Recorded',
                style: TextStyle(
                  color: Colors.blue,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _formatRelativeDate(String? dateIso, AppLocalizations l10n) {
    if (dateIso == null || dateIso.trim().isEmpty) {
      return l10n.timeNow;
    }
    final date = DateTime.tryParse(dateIso);
    if (date == null) {
      return l10n.timeNow;
    }
    return LocaleFormat.relativePastOrDate(context, date.toLocal(), l10n);
  }

  Widget _buildUpcomingAppointments() {
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
        children: [
          _buildAppointmentItem(
            'Dr. Sarah Johnson',
            'Cardiology Checkup',
            'Tomorrow, 2:30 PM',
            'City Medical Center',
          ),
          const SizedBox(height: 16),
          _buildAppointmentItem(
            'Dr. Michael Chen',
            'Blood Work',
            'Friday, 9:00 AM',
            'LabCorp Downtown',
          ),
        ],
      ),
    );
  }

  Widget _buildAppointmentItem(
      String doctor, String type, String dateTime, String location) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.secondary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.calendar_today,
            color: Theme.of(context).colorScheme.secondary,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                doctor,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              Text(
                type,
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).colorScheme.secondary,
                ),
              ),
              Text(
                '$dateTime • $location',
                style: TextStyle(
                  fontSize: 12,
                  color:
                      Theme.of(context).colorScheme.secondary.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
