import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/config/theme.dart';
import '../../../../core/utils/locale_format.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../models/caregiver_invitation.dart';
import '../../../../providers/invitation_provider.dart';
import '../../../../core/services/backend_api_service.dart';

// Caregiver home palette
const Color _teal = Color(0xFF0D3D38);
const Color _cream = Color(0xFFEDEAE1);
const Color _sage = Color(0xFF7DA68A);
const Color _sagePale = Color(0xFFD6E8DC);
const Color _sageDark = Color(0xFF4F7A61);
const Color _danger = Color(0xFFB94040);
const Color _textMuted = Color(0xFF84968F);
const Color _textPrimary = Color(0xFF162623);
const Color _textSecondary = Color(0xFF4D6360);

class CaregiverHomeScreen extends ConsumerStatefulWidget {
  const CaregiverHomeScreen({super.key});

  @override
  ConsumerState<CaregiverHomeScreen> createState() =>
      _CaregiverHomeScreenState();
}

class _CaregiverHomeScreenState extends ConsumerState<CaregiverHomeScreen> {
  List<Map<String, dynamic>> _alerts = [];
  List<Map<String, dynamic>> _connectedPatients = [];
  bool _isLoadingAlerts = true;

  TextStyle get _bodyStyle => GoogleFonts.dmSans();
  TextStyle get _displayStyle => GoogleFonts.dmSerifDisplay();

  @override
  void initState() {
    super.initState();
    _loadAlerts();
    _loadConnectedPatients();
  }

  int _pendingInvitationCount(List<CaregiverInvitation> invitations) {
    final uniquePatientIds = invitations
        .where((i) => i.status == 'pending' || i.status == 'viewed')
        .map((i) => i.patientId)
        .where((id) => id.isNotEmpty)
        .toSet();
    return uniquePatientIds.length;
  }

  int get _unreadAlertCount =>
      _alerts.where((a) => a['isRead'] != true).length;

  List<Map<String, dynamic>> get _displayAlerts {
    final sorted = List<Map<String, dynamic>>.from(_alerts);
    sorted.sort((a, b) {
      final aUnread = a['isRead'] != true;
      final bUnread = b['isRead'] != true;
      if (aUnread != bUnread) return aUnread ? -1 : 1;
      final aTime = a['timestamp'] as DateTime?;
      final bTime = b['timestamp'] as DateTime?;
      if (aTime == null && bTime == null) return 0;
      if (aTime == null) return 1;
      if (bTime == null) return -1;
      return bTime.compareTo(aTime);
    });
    return sorted.take(3).toList();
  }

  String _patientNameForUserId(String userId) {
    if (userId.isEmpty) return AppLocalizations.of(context)!.defaultPatient;
    for (final patient in _connectedPatients) {
      final patientId =
          patient['patientId']?.toString() ?? patient['id']?.toString() ?? '';
      if (patientId == userId) {
        final name = patient['name']?.toString() ??
            patient['patientName']?.toString() ??
            patient['fullName']?.toString();
        if (name != null && name.isNotEmpty) return name;
      }
    }
    return AppLocalizations.of(context)!.defaultPatient;
  }

  String _timeBasedGreeting(AppLocalizations l10n) {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) return l10n.goodMorning;
    if (hour >= 12 && hour < 17) return l10n.goodAfternoon;
    if (hour >= 17 && hour < 22) return l10n.goodEvening;
    return l10n.goodNight;
  }

  Map<String, dynamic> _normalizeAlert(Map<String, dynamic> raw) {
    final sentAt = raw['sent_at'] ?? raw['created_at'];
    DateTime? timestamp;
    if (sentAt != null) {
      timestamp = DateTime.tryParse(sentAt.toString())?.toLocal();
    }

    final userId = raw['user_id']?.toString() ?? '';
    final alertType = raw['alert_type']?.toString() ?? '';

    return {
      'id': raw['id']?.toString() ?? '',
      'message': raw['message']?.toString() ?? '',
      'userId': userId,
      'patient': _patientNameForUserId(userId),
      'timestamp': timestamp,
      'isRead':
          raw['read'] == true || raw['is_read'] == true || raw['isRead'] == true,
      'alertType': alertType,
    };
  }

  void _refreshAlertPatientNames() {
    _alerts = _alerts
        .map(
          (a) => {
            ...a,
            'patient': _patientNameForUserId(a['userId']?.toString() ?? ''),
          },
        )
        .toList();
  }

  Future<void> _loadAlerts() async {
    try {
      final authState = ref.read(authNotifierProvider);
      final uid = authState.user?.id;
      if (uid == null) return;
      final alerts = await BackendApiService().getCaregiverAlerts(uid);
      if (mounted) {
        setState(() {
          _alerts = alerts.map(_normalizeAlert).toList();
          _isLoadingAlerts = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingAlerts = false);
    }
  }

  Future<void> _loadConnectedPatients() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;
      final snap = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('connectedPatients')
          .get();
      if (!mounted) return;
      final patients = snap.docs
          .map((d) => {'id': d.id, ...d.data()})
          .toList();
      setState(() {
        _connectedPatients = patients;
        if (_alerts.isNotEmpty) {
          _refreshAlertPatientNames();
        }
      });
    } catch (_) {
      // silent fail
    }
  }


  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final l10n = AppLocalizations.of(context)!;
    final invitesAsync = ref.watch(receivedInvitationsProvider);
    final invitations = invitesAsync.value ?? [];
    final isLoadingInvitations = invitesAsync.isLoading;
    final pendingCount = _pendingInvitationCount(invitations);
    final userName = LocaleFormat.displayName(
      context,
      authState.profile?.fullName ?? '',
      fallback: l10n.defaultCaregiver,
    );
    final greeting = _timeBasedGreeting(l10n);
    final firstName = userName.split(' ').first;
    final topPadding = MediaQuery.of(context).padding.top;

    return ColoredBox(
      color: RemiCareUiColors.bodyBackground,
      child: ListView(
        padding: EdgeInsets.fromLTRB(20, topPadding + 16, 20, 32),
        children: [
          _buildSummaryCard(
            context: context,
            greeting: greeting,
            firstName: firstName,
            patientCount: _connectedPatients.length,
            alertCount: _unreadAlertCount,
            pendingCount: pendingCount,
            unreadAlerts: _unreadAlertCount,
            l10n: l10n,
          ),
          _sectionLabel(
            l10n.sectionRecentAlerts,
            trailing: l10n.viewAll,
            onTrailing: () => context.go('/caregiver/alerts'),
          ),
          _buildRecentAlertsSection(l10n),
          _sectionLabel(l10n.sectionInvitations),
          _buildInvitationsSection(l10n, pendingCount, isLoadingInvitations),
        ],
      ),
    );
  }

  Widget _buildSummaryCard({
    required BuildContext context,
    required String greeting,
    required String firstName,
    required int patientCount,
    required int alertCount,
    required int pendingCount,
    required int unreadAlerts,
    required AppLocalizations l10n,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      decoration: BoxDecoration(
        color: _teal,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(21),
                ),
                child: const Icon(Icons.favorite, color: _cream, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      greeting,
                      style: _bodyStyle.copyWith(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: _cream.withValues(alpha: 0.65),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      firstName,
                      style: _displayStyle.copyWith(
                        fontSize: 22,
                        color: _cream,
                        height: 1.1,
                      ),
                    ),
                  ],
                ),
              ),
              Stack(
                clipBehavior: Clip.none,
                children: [
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: const Icon(Icons.notifications_outlined,
                        color: _cream, size: 24),
                    onPressed: () => context.go('/caregiver/alerts'),
                  ),
                  if (unreadAlerts > 0)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        width: 9,
                        height: 9,
                        decoration: const BoxDecoration(
                          color: _danger,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Divider(
              height: 1,
              color: _cream.withValues(alpha: 0.15),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: _summaryStat(
                  context,
                  l10n.summaryPatients,
                  patientCount,
                ),
              ),
              Expanded(
                child: _summaryStat(
                  context,
                  l10n.summaryAlerts,
                  alertCount,
                ),
              ),
              Expanded(
                child: _summaryStat(
                  context,
                  l10n.summaryPending,
                  pendingCount,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryStat(BuildContext context, String label, int value) {
    return Column(
      children: [
        Text(
          LocaleFormat.number(context, value),
          style: _displayStyle.copyWith(
            fontSize: 22,
            color: _cream,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: _bodyStyle.copyWith(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.08,
            color: _cream.withValues(alpha: 0.55),
          ),
        ),
      ],
    );
  }

  Widget _sectionLabel(
    String title, {
    String? trailing,
    VoidCallback? onTrailing,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 14, 4, 2),
      child: Row(
        children: [
          Text(
            title.toUpperCase(),
            style: _bodyStyle.copyWith(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.1,
              color: _textMuted,
            ),
          ),
          if (trailing != null) ...[
            const Spacer(),
            GestureDetector(
              onTap: onTrailing,
              child: Text(
                trailing,
                style: _bodyStyle.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _sageDark,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _compactEmptyRow({
    required IconData icon,
    required String message,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return CustomPaint(
      painter: _DashedBorderPainter(
        color: const Color(0x260D3D38),
        radius: 14,
      ),
      child: Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: _sagePale,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, size: 18, color: _sageDark),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: _bodyStyle.copyWith(
                fontSize: 13.5,
                fontWeight: FontWeight.w500,
                color: _textSecondary,
              ),
            ),
          ),
          if (actionLabel != null && onAction != null)
            GestureDetector(
              onTap: onAction,
              child: Text(
                actionLabel,
                style: _bodyStyle.copyWith(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: _sageDark,
                ),
              ),
            ),
        ],
      ),
      ),
    );
  }

  Widget _buildRecentAlertsSection(AppLocalizations l10n) {
    if (_isLoadingAlerts) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2, color: _teal),
          ),
        ),
      );
    }

    if (_alerts.isEmpty) {
      return _compactEmptyRow(
        icon: Icons.notifications_none_outlined,
        message: l10n.noAlertsAtThisTime,
      );
    }

    return Column(
      children: _displayAlerts.map((a) => _buildAlertCard(a, l10n)).toList(),
    );
  }

  Widget _buildAlertCard(Map<String, dynamic> alert, AppLocalizations l10n) {
    final isRead = alert['isRead'] as bool? ?? false;
    final alertType = alert['alertType'] as String? ?? '';

    final Color priorityColor;
    switch (alertType) {
      case 'skipped':
        priorityColor = _danger;
        break;
      case 'multiple_snoozes':
        priorityColor = const Color(0xFFC98A3A);
        break;
      default:
        priorityColor = _sage;
    }

    final timestamp = alert['timestamp'];
    final timeLabel = timestamp is DateTime
        ? _formatAlertTime(timestamp, l10n)
        : '';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isRead
              ? const Color(0x1A0D3D38)
              : const Color(0x33B94040),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.only(top: 6),
            decoration: BoxDecoration(
              color: priorityColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  alert['message']?.toString() ?? '',
                  style: _bodyStyle.copyWith(
                    fontSize: 14,
                    fontWeight: isRead ? FontWeight.w400 : FontWeight.w600,
                    color: _textPrimary,
                  ),
                ),
                if (timeLabel.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    l10n.caregiverPatientTime(
                      alert['patient']?.toString() ?? l10n.defaultPatient,
                      timeLabel,
                    ),
                    style: _bodyStyle.copyWith(
                      fontSize: 12,
                      color: _textMuted,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInvitationsSection(
    AppLocalizations l10n,
    int pendingCount,
    bool isLoadingInvitations,
  ) {
    if (isLoadingInvitations) {
      return const SizedBox.shrink();
    }

    if (pendingCount == 0) {
      return _compactEmptyRow(
        icon: Icons.mail_outline,
        message: l10n.noPendingInvitations,
      );
    }

    final count = pendingCount;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A5C55), _teal],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.mail, color: _cream, size: 26),
              const SizedBox(width: 12),
              Text(
                l10n.pendingInvitationsTitle,
                style: _bodyStyle.copyWith(
                  color: _cream.withValues(alpha: 0.9),
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            LocaleFormat.localizeDigitsInText(
              context,
              l10n.invitationsWaiting(count),
            ),
            style: _displayStyle.copyWith(
              fontSize: 24,
              color: _cream,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.reviewAcceptInvitations,
            style: _bodyStyle.copyWith(
              color: _cream.withValues(alpha: 0.8),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () =>
                  context.go('/caregiver/accept-invitations?filter=pending'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _cream,
                foregroundColor: _teal,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
                elevation: 0,
              ),
              child: Text(
                l10n.viewInvitations,
                style: _bodyStyle.copyWith(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatAlertTime(DateTime timestamp, AppLocalizations l10n) {
    return LocaleFormat.reminderRelativeTime(context, timestamp, l10n);
  }
}

class _DashedBorderPainter extends CustomPainter {
  const _DashedBorderPainter({
    required this.color,
    required this.radius,
  });

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    const strokeWidth = 1.0;
    const dashWidth = 5.0;
    const dashSpace = 4.0;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            strokeWidth / 2,
            strokeWidth / 2,
            size.width - strokeWidth,
            size.height - strokeWidth,
          ),
          Radius.circular(radius),
        ),
      );

    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final end = (distance + dashWidth).clamp(0.0, metric.length);
        canvas.drawPath(metric.extractPath(distance, end), paint);
        distance += dashWidth + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.radius != radius;
}
