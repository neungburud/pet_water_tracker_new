//import 'package:flutter/foundation.dart'; // สำหรับ kDebugMode (ถ้าใช้)

class Pet {
  final String id;
  final String name;
  final String macAddress;
  final int lastRssi;
  final bool isDrinking;
  final int drinkCount;
  final DateTime? drinkStartTime;
  final DateTime? lastSeen;

  // Constructor
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

  // Factory constructor from JSON
  factory Pet.fromJson(Map<String, dynamic> json) {
    // ใส่ default value หรือ validation เพิ่มเติมได้
    return Pet(
      id: json['id'] ?? '', // ควรมี ID เสมอ
      name: json['name'] ?? 'Unknown Pet',
      macAddress: json['macAddress'] ?? '',
      lastRssi: json['lastRssi'] as int? ?? -100,
      isDrinking: json['isDrinking'] as bool? ?? false,
      drinkCount: json['drinkCount'] as int? ?? 0,
      drinkStartTime: json['drinkStartTime'] != null
          ? DateTime.tryParse(json['drinkStartTime'])
          : null,
      lastSeen: json['lastSeen'] != null
          ? DateTime.tryParse(json['lastSeen'])
          : null,
    );
  }

  // Method to convert to JSON
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

  // --- copyWith Method ---
  Pet copyWith({
    String? id,
    String? name,
    String? macAddress,
    int? lastRssi,
    bool? isDrinking,
    int? drinkCount,
    // ใช้ ValueGetter<DateTime?> เพื่อให้สามารถตั้งค่าเป็น null ได้
    DateTime? Function()? drinkStartTime,
    DateTime? Function()? lastSeen,
  }) {
    return Pet(
      id: id ?? this.id,
      name: name ?? this.name,
      macAddress: macAddress ?? this.macAddress,
      lastRssi: lastRssi ?? this.lastRssi,
      isDrinking: isDrinking ?? this.isDrinking,
      drinkCount: drinkCount ?? this.drinkCount,
      // เรียกใช้ function ถ้ามี, ถ้าไม่มีใช้ค่าเดิม
      drinkStartTime: drinkStartTime != null ? drinkStartTime() : this.drinkStartTime,
      lastSeen: lastSeen != null ? lastSeen() : this.lastSeen,
    );
  }
  // --- End copyWith Method ---

  // --- Equality and HashCode ---
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Pet &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          macAddress == other.macAddress &&
          lastRssi == other.lastRssi &&
          isDrinking == other.isDrinking &&
          drinkCount == other.drinkCount &&
          drinkStartTime == other.drinkStartTime &&
          lastSeen == other.lastSeen;

  @override
  int get hashCode => Object.hash(
        id,
        name,
        macAddress,
        lastRssi,
        isDrinking,
        drinkCount,
        drinkStartTime,
        lastSeen,
      );
  // --- End Equality and HashCode ---

  // Optional: toString for debugging
  @override
  String toString() {
    return 'Pet(id: $id, name: $name, mac: $macAddress, rssi: $lastRssi, drinking: $isDrinking, count: $drinkCount, start: $drinkStartTime, seen: $lastSeen)';
  }
}