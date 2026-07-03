class SummaryItem {
  static const unknownDoctor = 'Unknown Doctor';
  static const unknownSpecialty = 'Unknown Specialty';

  final String summaryId;
  final String visitId;
  final String doctorName;
  final String specialty;
  final String? title;
  final String? visitDate;
  final String summaryCreatedAt;
  final String summaryPreview;
  final String modelName;

  SummaryItem({
    required this.summaryId,
    required this.visitId,
    required this.doctorName,
    required this.specialty,
    this.title,
    this.visitDate,
    required this.summaryCreatedAt,
    required this.summaryPreview,
    required this.modelName,
  });

  factory SummaryItem.fromJson(Map<String, dynamic> json) {
    var doctorName = _cleanMeta(json['doctor_name'] as String?);
    var specialty = _cleanMeta(json['specialty'] as String?);
    final title = _cleanMeta(json['title'] as String?);

    if ((doctorName == null || specialty == null) &&
        title != null &&
        title.isNotEmpty) {
      final parsed = _parseTitle(title);
      doctorName ??= parsed.$1;
      specialty ??= parsed.$2;
    }

    return SummaryItem(
      summaryId: json['summary_id']?.toString() ?? '',
      visitId: json['visit_id']?.toString() ?? '',
      doctorName: doctorName ?? '',
      specialty: specialty ?? '',
      title: title,
      visitDate: json['visit_date']?.toString(),
      summaryCreatedAt:
          json['summary_created_at']?.toString() ?? DateTime.now().toIso8601String(),
      summaryPreview: json['summary_preview'] as String? ?? '',
      modelName: json['model_name'] as String? ?? '',
    );
  }

  /// User-facing visit label; empty means caller should use [fallbackVisitLabel].
  String visitDisplayLabel(String fallbackVisitLabel) {
    if (doctorName.isNotEmpty && specialty.isNotEmpty) {
      return '$doctorName - $specialty';
    }
    if (doctorName.isNotEmpty) return doctorName;
    if (specialty.isNotEmpty) return specialty;
    if (title != null && title!.isNotEmpty) return title!;
    return fallbackVisitLabel;
  }

  static String? _cleanMeta(String? value) {
    if (value == null) return null;
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;
    if (trimmed == unknownDoctor || trimmed == unknownSpecialty) return null;
    return trimmed;
  }

  static (String?, String?) _parseTitle(String title) {
    for (final sep in [' — ', ' - ', '—', '-']) {
      final idx = title.indexOf(sep);
      if (idx > 0) {
        final left = title.substring(0, idx).trim();
        final right = title.substring(idx + sep.length).trim();
        if (left.isNotEmpty && right.isNotEmpty) {
          return (left, right);
        }
      }
    }
    return (title.trim().isEmpty ? null : title.trim(), null);
  }

  Map<String, dynamic> toJson() {
    return {
      'visit_id': visitId,
      'doctor_name': doctorName,
      'specialty': specialty,
      'title': title,
      'visit_date': visitDate,
      'summary_created_at': summaryCreatedAt,
      'summary_preview': summaryPreview,
      'model_name': modelName,
    };
  }
}
