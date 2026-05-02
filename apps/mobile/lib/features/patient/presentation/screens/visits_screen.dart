import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../widgets/widgets.dart';
import '../../../../core/services/visit_context.dart';

class VisitsScreen extends StatefulWidget {
  const VisitsScreen({super.key});

  @override
  State<VisitsScreen> createState() => _VisitsScreenState();
}

class _VisitsScreenState extends State<VisitsScreen> {
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
          _buildVisitItem(
            'Dr. Sarah Johnson',
            'Cardiology Follow-up',
            '2 days ago',
            'City Medical Center',
            true, // has recording
          ),
          const Divider(height: 16),
          _buildVisitItem(
            'Dr. Michael Chen',
            'Blood Work Review',
            '1 week ago',
            'LabCorp Downtown',
            false, // no recording
          ),
        ],
      ),
    );
  }

  Widget _buildVisitItem(String doctor, String type, String date,
      String location, bool hasRecording) {
    return InkWell(
      onTap: () {
        context.go('/patient/visit-details?visitId=mock-visit-002');
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
