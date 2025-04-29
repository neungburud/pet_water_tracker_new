class ChartPoint {
  final dynamic x; // อาจเป็น DateTime, String, int, ฯลฯ
  final dynamic y;
  final String? label;

  ChartPoint({
    required this.x,
    required this.y,
    this.label,
  });

  factory ChartPoint.fromJson(Map<String, dynamic> json) {
    return ChartPoint(
      x: json['x'],
      y: json['y'],
      label: json['label'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'x': x is DateTime ? x.toIso8601String() : x,
      'y': y,
      'label': label,
    };
  }
}

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