// lib/models/hourly_pattern.dart

class HourlyPattern {
  final int hour;
  final int count;

  HourlyPattern({
    required this.hour,
    required this.count,
  });

  factory HourlyPattern.fromJson(Map<String, dynamic> json) {
    return HourlyPattern(
      hour: json['hour'],
      count: json['count'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'hour': hour,
      'count': count,
    };
  }
}