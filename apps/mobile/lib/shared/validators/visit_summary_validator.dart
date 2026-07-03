/// Validates persisted [VisitSummary] JSON maps.
class VisitSummaryValidator {
  static const _topLevelKeys = [
    'summarization',
    'decision',
    'medication',
    'action',
  ];

  static const _listSectionKeys = ['decision', 'medication', 'action'];

  /// Returns an error message when invalid, or `null` when valid.
  static String? validate(Map<String, dynamic> json) {
    for (final key in _topLevelKeys) {
      if (!json.containsKey(key)) {
        return 'Missing required key: $key';
      }
      if (json[key] == null) {
        return 'Key must not be null: $key';
      }
    }

    final summarization = json['summarization'];
    if (summarization is! Map) {
      return 'summarization must be a map';
    }
    if (!summarization.containsKey('text')) {
      return 'summarization missing required key: text';
    }
    if (summarization['text'] == null) {
      return 'summarization.text must not be null';
    }

    for (final key in _listSectionKeys) {
      final section = json[key];
      if (section is! Map) {
        return '$key must be a map';
      }
      if (!section.containsKey('items')) {
        return '$key missing required key: items';
      }
      final items = section['items'];
      if (items == null) {
        return '$key.items must not be null';
      }
      if (items is! List) {
        return '$key.items must be a list';
      }
    }

    return null;
  }
}
