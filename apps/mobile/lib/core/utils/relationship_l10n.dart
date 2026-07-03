import '../../l10n/app_localizations.dart';

/// Maps stored English relationship labels to localized display text.
class RelationshipL10n {
  RelationshipL10n._();

  static String label(AppLocalizations l10n, String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return trimmed;

    final normalized = trimmed
        .toLowerCase()
        .replaceAll('/', ' ')
        .replaceAll(RegExp(r'\s+'), ' ');

    switch (normalized) {
      case 'son':
        return l10n.relationshipSon;
      case 'daughter':
        return l10n.relationshipDaughter;
      case 'friend':
        return l10n.relationshipFriend;
      case 'spouse':
      case 'partner':
      case 'spouse partner':
        return l10n.relationshipSpousePartner;
      case 'parent':
      case 'mother':
      case 'father':
        return l10n.relationshipParent;
      case 'child':
        return l10n.relationshipChild;
      case 'family member':
      case 'family':
        return l10n.relationshipFamilyMember;
      case 'healthcare professional':
      case 'health care professional':
      case 'nurse':
      case 'doctor':
        return l10n.relationshipHealthcareProfessional;
      case 'caregiver':
        return l10n.relationshipCaregiver;
      case 'sister':
        return l10n.relationshipSister;
      case 'brother':
        return l10n.relationshipBrother;
      case 'other':
        return l10n.relationshipOther;
      default:
        return trimmed;
    }
  }
}
