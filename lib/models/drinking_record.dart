class DrinkingRecord {
  final String id;
  final String petId;
  final DateTime timestamp;
  final int duration; // เวลาที่ใช้ในการดื่มน้ำ (วินาที)
  final String action; // 'start_drinking' หรือ 'finish_drinking'
  final int? count;    // จำนวนครั้งการดื่ม ณ เวลานั้น (สำหรับ finish_drinking)

  DrinkingRecord({
    required this.id,
    required this.petId,
    required this.timestamp,
    required this.duration,
    required this.action,
    this.count,
  });

  factory DrinkingRecord.fromJson(Map<String, dynamic> json) {
    return DrinkingRecord(
      id: json['id'] ?? '',
      petId: json['petId'] ?? '',
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp']) ?? DateTime.now()
          : DateTime.now(),
      duration: json['duration'] as int? ?? 0,
      action: json['action'] ?? '',
      count: json['count'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'petId': petId,
      'timestamp': timestamp.toIso8601String(),
      'duration': duration,
      'action': action,
      if (count != null) 'count': count,
    };
  }

  // สร้างจาก MQTT message
  factory DrinkingRecord.fromMqttMessage(Map<String, dynamic> message, String recordId) {
    // ถอดแบบตรงๆ จาก format ที่ ESP32 ส่งมา
    final petNum = message['pet'] as int? ?? 0;
    final petId = 'pet$petNum';
    
    // ESP32 ส่ง timestamp เป็นวินาที (unix timestamp) ต้องแปลงเป็น milliseconds
    final timestampValue = message['timestamp'] as int? ?? 0;
    final timestamp = DateTime.fromMillisecondsSinceEpoch(timestampValue * 1000, isUtc: false); // ใช้ Local Time

    return DrinkingRecord(
      id: recordId,
      petId: petId,
      timestamp: timestamp,
      duration: message['duration'] as int? ?? 0,
      action: message['action'] as String? ?? '',
      count: message['count'] as int?, // รับค่า count จาก message
    );
  }

  @override
  String toString() {
    return 'DrinkingRecord(id: $id, petId: $petId, time: $timestamp, action: $action, duration: $duration, count: $count)';
  }
}