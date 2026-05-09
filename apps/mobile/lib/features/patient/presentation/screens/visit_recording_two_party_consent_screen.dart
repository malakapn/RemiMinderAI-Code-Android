import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Full-screen two-party consent gate before starting visit audio capture.
/// Shown after legacy [ConsentService] / audio product consent on each record start.
class VisitRecordingTwoPartyConsentScreen extends StatefulWidget {
  const VisitRecordingTwoPartyConsentScreen({super.key});

  @override
  State<VisitRecordingTwoPartyConsentScreen> createState() =>
      _VisitRecordingTwoPartyConsentScreenState();
}

class _VisitRecordingTwoPartyConsentScreenState
    extends State<VisitRecordingTwoPartyConsentScreen> {
  bool _accepted = false;

  Future<void> _logConsentBestEffort() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
      final locale = Localizations.localeOf(context).toLanguageTag();
      await FirebaseFirestore.instance.collection('recording_consents').add({
        'userId': uid,
        'timestamp': FieldValue.serverTimestamp(),
        'consentVersion': 'v1.0',
        'locale': locale,
      });
    } catch (e, st) {
      debugPrint('recording_consents Firestore write failed: $e\n$st');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight -
                      MediaQuery.paddingOf(context).vertical,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Before you record',
                      style: textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Recording a medical visit requires your doctor\'s permission in California and several other states.',
                      style: textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Please:',
                      style: textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Let your doctor know you\'d like to record the visit for your personal care notes.',
                      style: textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Wait for them to agree before you start recording.',
                      style: textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Keep your phone visible during the visit so it\'s clear recording is happening.',
                      style: textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'RemiMinder uses this recording only to create your visit summary. You control who sees it.',
                      style: textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 24),
                    MergeSemantics(
                      child: CheckboxListTile(
                        value: _accepted,
                        contentPadding: EdgeInsets.zero,
                        controlAffinity: ListTileControlAffinity.leading,
                        onChanged: (v) {
                          setState(() => _accepted = v ?? false);
                        },
                        title: Text(
                          'I have informed my doctor and they have agreed to be recorded.',
                          style: textTheme.bodyLarge,
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: Text(
                        'Cancel',
                        style: textTheme.labelLarge,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: _accepted
                          ? () async {
                              await _logConsentBestEffort();
                              if (!context.mounted) return;
                              Navigator.of(context).pop(true);
                            }
                          : null,
                      child: Text(
                        'Start Recording',
                        style: textTheme.labelLarge?.copyWith(
                          color: theme.colorScheme.onPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
