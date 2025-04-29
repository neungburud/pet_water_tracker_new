class DrinkingRecord {
  final String id;
  final String petId;
  final DateTime timestamp;
  final int duration; // เวลาที่ใช้ในการดื่มน้ำ (วินาที)
  final String action; // 'start_drinking' หรือ 'finish_drinking'

  DrinkingRecord({
    required this.id,
    required this.petId,
    required this.timestamp,
    required this.duration,
    required this.action,
  });

  factory DrinkingRecord.fromJson(Map<String, dynamic> json) {
    return DrinkingRecord(
      id: json['id'],
      petId: json['petId'],
      timestamp: DateTime.parse(json['timestamp']),
      duration: json['duration'] ?? 0,
      action: json['action'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'petId': petId,
      'timestamp': timestamp.toIso8601String(),
      'duration': duration,
      'action': action,
    };
  }

  // สร้างจาก MQTT message
  factory DrinkingRecord.fromMqttMessage(
      Map<String, dynamic> message, String recordId) {
    final petId = 'pet${message['pet']}';
    final timestamp = DateTime.fromMillisecondsSinceEpoch(
        (message['timestamp'] as int) * 1000);
    
    return DrinkingRecord(
      id: recordId,
      petId: petId,
      timestamp: timestamp,
      duration: message['duration'] ?? 0,
      action: message['action'],
    );
  }
}