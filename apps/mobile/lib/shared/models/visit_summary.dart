import 'package:equatable/equatable.dart';

/// Structured visit summary with four sections (V2 schema).
class VisitSummary extends Equatable {
  final Summarization summarization;
  final Decision decision;
  final Medication medication;
  final Action action;

  const VisitSummary({
    required this.summarization,
    required this.decision,
    required this.medication,
    required this.action,
  });

  factory VisitSummary.fromMap(Map<String, dynamic> map) {
    return VisitSummary(
      summarization: Summarization.fromMap(
        Map<String, dynamic>.from(map['summarization'] as Map),
      ),
      decision: Decision.fromMap(
        Map<String, dynamic>.from(map['decision'] as Map),
      ),
      medication: Medication.fromMap(
        Map<String, dynamic>.from(map['medication'] as Map),
      ),
      action: Action.fromMap(
        Map<String, dynamic>.from(map['action'] as Map),
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'summarization': summarization.toMap(),
      'decision': decision.toMap(),
      'medication': medication.toMap(),
      'action': action.toMap(),
    };
  }

  VisitSummary copyWith({
    Summarization? summarization,
    Decision? decision,
    Medication? medication,
    Action? action,
  }) {
    return VisitSummary(
      summarization: summarization ?? this.summarization,
      decision: decision ?? this.decision,
      medication: medication ?? this.medication,
      action: action ?? this.action,
    );
  }

  @override
  List<Object?> get props => [summarization, decision, medication, action];
}

/// Narrative overview of the visit.
class Summarization extends Equatable {
  final String text;

  const Summarization({required this.text});

  factory Summarization.fromMap(Map<String, dynamic> map) {
    return Summarization(text: map['text']?.toString() ?? '');
  }

  Map<String, dynamic> toMap() => {'text': text};

  Summarization copyWith({String? text}) {
    return Summarization(text: text ?? this.text);
  }

  @override
  List<Object?> get props => [text];
}

/// Clinical decisions discussed during the visit.
class Decision extends Equatable {
  final List<String> items;

  const Decision({required this.items});

  factory Decision.fromMap(Map<String, dynamic> map) {
    return Decision(items: _stringList(map['items']));
  }

  Map<String, dynamic> toMap() => {'items': items};

  Decision copyWith({List<String>? items}) {
    return Decision(items: items ?? this.items);
  }

  @override
  List<Object?> get props => [items];
}

/// Medications mentioned or changed during the visit.
class Medication extends Equatable {
  final List<String> items;

  const Medication({required this.items});

  factory Medication.fromMap(Map<String, dynamic> map) {
    return Medication(items: _stringList(map['items']));
  }

  Map<String, dynamic> toMap() => {'items': items};

  Medication copyWith({List<String>? items}) {
    return Medication(items: items ?? this.items);
  }

  @override
  List<Object?> get props => [items];
}

/// Follow-up tasks and next steps from the visit.
class Action extends Equatable {
  final List<String> items;

  const Action({required this.items});

  factory Action.fromMap(Map<String, dynamic> map) {
    return Action(items: _stringList(map['items']));
  }

  Map<String, dynamic> toMap() => {'items': items};

  Action copyWith({List<String>? items}) {
    return Action(items: items ?? this.items);
  }

  @override
  List<Object?> get props => [items];
}

List<String> _stringList(dynamic value) {
  if (value == null) return [];
  if (value is List) {
    return value.map((e) => e.toString()).toList();
  }
  if (value is String && value.isNotEmpty) {
    return [value];
  }
  return [];
}
