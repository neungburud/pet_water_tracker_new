class Pet {
  final String id;
  final String name;
  final String macAddress;
  int lastRssi;
  bool isDrinking;
  int drinkCount;
  DateTime? drinkStartTime;
  DateTime? lastSeen;

  Pet({
    required this.id,
    required this.name,
    required this.macAddress,
    this.lastRssi = -100,
    this.isDrinking = false,
    this.drinkCount = 0,
    this.drinkStartTime,
    this.lastSeen,
  });

  factory Pet.fromJson(Map<String, dynamic> json) {
    return Pet(
      id: json['id'],
      name: json['name'],
      macAddress: json['macAddress'],
      lastRssi: json['lastRssi'] ?? -100,
      isDrinking: json['isDrinking'] ?? false,
      drinkCount: json['drinkCount'] ?? 0,
      drinkStartTime: json['drinkStartTime'] != null
          ? DateTime.parse(json['drinkStartTime'])
          : null,
      lastSeen: json['lastSeen'] != null
          ? DateTime.parse(json['lastSeen'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'macAddress': macAddress,
      'lastRssi': lastRssi,
      'isDrinking': isDrinking,
      'drinkCount': drinkCount,
      'drinkStartTime': drinkStartTime?.toIso8601String(),
      'lastSeen': lastSeen?.toIso8601String(),
    };
  }

  Pet copyWith({
    String? id,
    String? name,
    String? macAddress,
    int? lastRssi,
    bool? isDrinking,
    int? drinkCount,
    DateTime? drinkStartTime,
    DateTime? lastSeen,
  }) {
    return Pet(
      id: id ?? this.id,
      name: name ?? this.name,
      macAddress: macAddress ?? this.macAddress,
      lastRssi: lastRssi ?? this.lastRssi,
      isDrinking: isDrinking ?? this.isDrinking,
      drinkCount: drinkCount ?? this.drinkCount,
      drinkStartTime: drinkStartTime ?? this.drinkStartTime,
      lastSeen: lastSeen ?? this.lastSeen,
    );
  }
}