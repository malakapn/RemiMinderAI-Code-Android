import 'package:flutter/material.dart';
import '../../../care_team/care_team_tab.dart';
import '../../../../services/invitation_service.dart';
import '../../../../services/post_auth_navigation.dart';

/// Caregiver shell route: Care Team tab (Firestore invitations + API team).
class AcceptInvitationsScreen extends StatefulWidget {
  final String? inviteToken;
  const AcceptInvitationsScreen({super.key, this.inviteToken});

  @override
  State<AcceptInvitationsScreen> createState() => _AcceptInvitationsScreenState();
}

class _AcceptInvitationsScreenState extends State<AcceptInvitationsScreen> {
  @override
  void initState() {
    super.initState();
    if (widget.inviteToken != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _handleInviteToken(widget.inviteToken!);
      });
    }
  }

  Future<void> _handleInviteToken(String token) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Accept Invitation'),
        content: const Text('You have been invited to join a care team on RemiMinderAI. Would you like to accept?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Decline'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Accept'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await InvitationService().acceptInvitationByToken(token);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You have joined the care team!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to accept invitation: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return const CareTeamTab();
  }
}
