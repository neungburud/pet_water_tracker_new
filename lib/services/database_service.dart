import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/pet.dart';
import '../models/drinking_record.dart';
import '../models/device_status.dart';

class DatabaseService {
  static const String _petKey = 'pets';
  static const String _drinkingRecordsKey = 'drinking_records';
  static const String _deviceStatusKey = 'device_status';

  // บันทึกข้อมูลสัตว์เลี้ยง
  static Future<void> savePets(List<Pet> pets) async {
    final prefs = await SharedPreferences.getInstance();
    final petsJson = pets.map((pet) => jsonEncode(pet.toJson())).toList();
    await prefs.setStringList(_petKey, petsJson);
  }

  // โหลดข้อมูลสัตว์เลี้ยง
  static Future<List<Pet>> loadPets() async {
    final prefs = await SharedPreferences.getInstance();
    final petsJson = prefs.getStringList(_petKey) ?? [];
    if (petsJson.isEmpty) {
      // สร้างข้อมูลตัวอย่างถ้าไม่มีข้อมูล
      return [
        Pet(
          id: 'pet1',
          name: 'กะเพรา',
          macAddress: '51:00:24:03:02:01',
        ),
        Pet(
          id: 'pet2',
          name: 'ลัคกี้',
          macAddress: 'A4:C1:38:6A:8F:DB',
        ),
      ];
    }
    return petsJson.map((json) => Pet.fromJson(jsonDecode(json))).toList();
  }

  // บันทึกประวัติการดื่มน้ำ
  static Future<void> saveDrinkingRecords(List<DrinkingRecord> records) async {
    final prefs = await SharedPreferences.getInstance();
    final recordsJson = records.map((record) => jsonEncode(record.toJson())).toList();
    await prefs.setStringList(_drinkingRecordsKey, recordsJson);
  }

  // โหลดประวัติการดื่มน้ำ
  static Future<List<DrinkingRecord>> loadDrinkingRecords() async {
    final prefs = await SharedPreferences.getInstance();
    final recordsJson = prefs.getStringList(_drinkingRecordsKey) ?? [];
    return recordsJson.map((json) => DrinkingRecord.fromJson(jsonDecode(json))).toList();
  }

  // บันทึกสถานะอุปกรณ์
  static Future<void> saveDeviceStatus(DeviceStatus status) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_deviceStatusKey, jsonEncode(status.toJson()));
  }

  // โหลดสถานะอุปกรณ์
  static Future<DeviceStatus?> loadDeviceStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final statusJson = prefs.getString(_deviceStatusKey);
    if (statusJson == null) return null;
    return DeviceStatus.fromJson(jsonDecode(statusJson));
  }

  // ลบประวัติการดื่มน้ำที่เก่ากว่า n วัน
  static Future<void> pruneOldRecords(int days) async {
    final records = await loadDrinkingRecords();
    final cutoffDate = DateTime.now().subtract(Duration(days: days));
    
    final filteredRecords = records.where(
      (record) => record.timestamp.isAfter(cutoffDate)
    ).toList();
    
    if (filteredRecords.length < records.length) {
      await saveDrinkingRecords(filteredRecords);
    }
  }

  // ล้างข้อมูลทั้งหมด (ประวัติการดื่มน้ำ)
  static Future<void> clearDrinkingRecords() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_drinkingRecordsKey);
  }
}