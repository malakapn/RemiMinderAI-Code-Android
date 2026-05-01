import 'package:equatable/equatable.dart';

class Overview extends Equatable {
  final int total;
  final int activeToday;
  final int upcoming;
  final int past;

  const Overview({
    required this.total,
    required this.activeToday,
    required this.upcoming,
    required this.past,
  });

  factory Overview.fromJson(Map<String, dynamic> json) {
    return Overview(
      total: json['total'] as int? ?? 0,
      activeToday: json['active_today'] as int? ?? 0,
      upcoming: json['upcoming'] as int? ?? 0,
      past: json['past'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total': total,
      'active_today': activeToday,
      'upcoming': upcoming,
      'past': past,
    };
  }

  @override
  List<Object?> get props => [total, activeToday, upcoming, past];
}
