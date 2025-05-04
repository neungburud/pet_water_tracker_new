import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math' as Math;
import '../models/pet.dart';
import '../models/drinking_record.dart';
import '../models/device_status.dart';

class DatabaseService {
  static const String _petKey = 'pets';
  static const String _drinkingRecordsKey = 'drinking_records';
  static const String _deviceStatusKey = 'device_status';

  // บันทึกข้อมูลสัตว์เลี้ยง
  static Future<void> savePets(List<Pet> pets) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final petsJson = pets.map((pet) => jsonEncode(pet.toJson())).toList();
      await prefs.setStringList(_petKey, petsJson);
      debugPrint('DatabaseService: Saved ${pets.length} pets.');
    } catch (e) {
      debugPrint('DatabaseService Error saving pets: $e');
      throw Exception('ไม่สามารถบันทึกข้อมูลสัตว์เลี้ยงได้: $e');
    }
  }

  // โหลดข้อมูลสัตว์เลี้ยง
  static Future<List<Pet>> loadPets() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final petsJson = prefs.getStringList(_petKey) ?? [];

      // ไม่มีข้อมูลเริ่มต้นแล้ว จะคืนค่า list ว่างถ้าไม่มีข้อมูลบันทึกไว้
      if (petsJson.isNotEmpty) {
        debugPrint("DatabaseService: Loading ${petsJson.length} saved pets.");
        return petsJson
            .map((jsonString) {
                try {
                  if (jsonString.startsWith('{') && jsonString.endsWith('}')) {
                      return Pet.fromJson(jsonDecode(jsonString));
                  } else {
                      debugPrint("DatabaseService: Invalid JSON format for pet: $jsonString");
                      return null;
                  }
                } catch (e) {
                    debugPrint("DatabaseService Error decoding pet JSON: $jsonString, Error: $e");
                    return null;
                }
            })
            .whereType<Pet>()
            .toList();
      } else {
        debugPrint("DatabaseService: No saved pets found, returning empty list.");
        return []; // คืนค่า list ว่าง
      }
    } catch (e) {
      debugPrint('DatabaseService Error loading pets: $e');
      throw Exception('ไม่สามารถโหลดข้อมูลสัตว์เลี้ยงได้: $e');
    }
  }

  // บันทึกประวัติการดื่มน้ำ
  static Future<void> saveDrinkingRecords(List<DrinkingRecord> records) async {
      try {
        final prefs = await SharedPreferences.getInstance();
        final recordsJson = records.map((record) => jsonEncode(record.toJson())).toList();
        await prefs.setStringList(_drinkingRecordsKey, recordsJson);
         debugPrint('DatabaseService: Saved ${records.length} drinking records.');
      } catch (e) {
         debugPrint('DatabaseService Error saving drinking records: $e');
        throw Exception('ไม่สามารถบันทึกประวัติการดื่มน้ำได้: $e');
      }
    }

  // โหลดประวัติการดื่มน้ำ
  static Future<List<DrinkingRecord>> loadDrinkingRecords() async {
     try {
        final prefs = await SharedPreferences.getInstance();
        final recordsJson = prefs.getStringList(_drinkingRecordsKey) ?? [];
        if (recordsJson.isNotEmpty) {
           debugPrint("DatabaseService: Loading ${recordsJson.length} saved drinking records.");
           return recordsJson
               .map((jsonString) {
                  try {
                    if (jsonString.startsWith('{') && jsonString.endsWith('}')) {
                        // เพิ่มการตรวจสอบ key ที่จำเป็นก่อนแปลง
                        final Map<String, dynamic> decoded = jsonDecode(jsonString);
                        if (decoded.containsKey('id') && decoded.containsKey('petId') && decoded.containsKey('timestamp') && decoded.containsKey('action')) {
                             return DrinkingRecord.fromJson(decoded);
                        } else {
                             debugPrint("DatabaseService: Missing required keys in drinking record JSON: $jsonString");
                             return null;
                        }
                    } else {
                       debugPrint("DatabaseService: Invalid JSON format for drinking record: $jsonString");
                       return null;
                     }
                  } catch (e) {
                     debugPrint("DatabaseService Error decoding drinking record JSON: $jsonString, Error: $e");
                     return null;
                  }
               })
               .whereType<DrinkingRecord>()
               .toList();
        } else {
          debugPrint("DatabaseService: No saved drinking records found.");
          return [];
        }
     } catch (e) {
        debugPrint('DatabaseService Error loading drinking records: $e');
       throw Exception('ไม่สามารถโหลดประวัติการดื่มน้ำได้: $e');
     }
   }

   // บันทึกสถานะอุปกรณ์
   static Future<void> saveDeviceStatus(DeviceStatus status) async {
     try {
       final prefs = await SharedPreferences.getInstance();
       await prefs.setString(_deviceStatusKey, jsonEncode(status.toJson()));
       debugPrint('DatabaseService: Saved device status.');
     } catch (e) {
       debugPrint('DatabaseService Error saving device status: $e');
       throw Exception('ไม่สามารถบันทึกสถานะอุปกรณ์ได้: $e');
     }
   }

   // โหลดสถานะอุปกรณ์
   static Future<DeviceStatus?> loadDeviceStatus() async {
     try {
       final prefs = await SharedPreferences.getInstance();
       final statusJson = prefs.getString(_deviceStatusKey);
       if (statusJson == null) {
         debugPrint("DatabaseService: No saved device status found.");
         return null;
       }
       debugPrint("DatabaseService: Loading saved device status.");
       // เพิ่ม try-catch รอบ decode เฉพาะ
       try {
          return DeviceStatus.fromJson(jsonDecode(statusJson));
       } catch (e) {
          debugPrint("DatabaseService Error decoding device status JSON: $statusJson, Error: $e");
          return null; // คืนค่า null ถ้า decode ไม่ได้
       }
     } catch (e) {
       debugPrint('DatabaseService Error loading device status: $e');
       throw Exception('ไม่สามารถโหลดสถานะอุปกรณ์ได้: $e');
     }
   }

  // ลบประวัติการดื่มน้ำที่เก่ากว่า n วัน
  static Future<void> pruneOldRecords(int days) async {
    if (days <= 0) {
        debugPrint('DatabaseService: Pruning skipped (retention days <= 0).');
        return;
    }
    try {
      final records = await loadDrinkingRecords();
      final cutoffDate = DateTime.now().subtract(Duration(days: days));
      final initialLength = records.length;

      final filteredRecords = records.where(
        (record) => record.timestamp.isAfter(cutoffDate)
      ).toList();

      if (filteredRecords.length < initialLength) {
        await saveDrinkingRecords(filteredRecords);
        debugPrint('DatabaseService: Pruned ${initialLength - filteredRecords.length} old drinking records (older than $days days).');
      } else {
        debugPrint('DatabaseService: No old drinking records to prune.');
      }
    } catch (e) {
      debugPrint('DatabaseService Error pruning old records: $e');
      // ไม่ควร throw Exception ที่นี่ เพราะอาจจะทำให้การทำงานอื่นหยุดชะงัก
      // throw Exception('ไม่สามารถลบประวัติการดื่มน้ำที่เก่าได้: $e');
    }
  }

  // ล้างข้อมูลประวัติการดื่มน้ำ
  static Future<void> clearDrinkingRecords() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_drinkingRecordsKey);
      debugPrint('DatabaseService: Cleared all drinking records.');
    } catch (e) {
      debugPrint('DatabaseService Error clearing drinking records: $e');
      throw Exception('ไม่สามารถล้างประวัติการดื่มน้ำได้: $e');
    }
  }
  
  // เพิ่มฟังก์ชันสำหรับแสดงข้อมูลบันทึกไว้ในคอนโซล (ดีบั๊ก)
  static Future<void> debugPrintRecords() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final recordsJson = prefs.getStringList(_drinkingRecordsKey) ?? [];
      
      debugPrint("=== Debug Drinking Records ===");
      debugPrint("พบประวัติการดื่มน้ำทั้งหมด ${recordsJson.length} รายการ");
      
      if (recordsJson.isNotEmpty) {
        for (int i = 0; i < Math.min(recordsJson.length, 5); i++) { // แสดงแค่ 5 รายการแรก
          debugPrint("Record $i: ${recordsJson[i]}");
        }
      }
      debugPrint("==============================");
    } catch (e) {
      debugPrint('เกิดข้อผิดพลาดในการดีบั๊กข้อมูล: $e');
    }
  }

  // ฟังก์ชันสำรองข้อมูล
  static Future<Map<String, dynamic>> exportAllData() async {
     try {
       final pets = await loadPets();
       final drinkingRecords = await loadDrinkingRecords();
       final deviceStatus = await loadDeviceStatus();
        debugPrint('DatabaseService: Exporting data...');
       return {
         'pets': pets.map((pet) => pet.toJson()).toList(),
         'drinking_records': drinkingRecords.map((record) => record.toJson()).toList(),
         'device_status': deviceStatus?.toJson(),
         'export_date': DateTime.now().toIso8601String(),
       };
     } catch (e) {
        debugPrint('DatabaseService Error exporting data: $e');
       throw Exception('ไม่สามารถสำรองข้อมูลได้: $e');
     }
  }

  // ฟังก์ชันนำเข้าข้อมูล
  static Future<void> importAllData(Map<String, dynamic> data) async {
      try {
        debugPrint('DatabaseService: Importing data...');
       // นำเข้าข้อมูลสัตว์เลี้ยง
       if (data.containsKey('pets') && data['pets'] is List) {
         final List<dynamic> petsJson = data['pets'];
         final List<Pet> pets = petsJson
             .map((json) => Pet.fromJson(json))
             .toList();
         await savePets(pets);
         debugPrint('DatabaseService: Imported ${pets.length} pets.');
       }

       // นำเข้าประวัติการดื่มน้ำ
       if (data.containsKey('drinking_records') && data['drinking_records'] is List) {
         final List<dynamic> recordsJson = data['drinking_records'];
         final List<DrinkingRecord> records = recordsJson
             .map((json) => DrinkingRecord.fromJson(json))
             .toList();
         await saveDrinkingRecords(records);
         debugPrint('DatabaseService: Imported ${records.length} drinking records.');
       }

       // นำเข้าสถานะอุปกรณ์
       if (data.containsKey('device_status') && data['device_status'] != null) {
         final deviceStatus = DeviceStatus.fromJson(data['device_status']);
         await saveDeviceStatus(deviceStatus);
         debugPrint('DatabaseService: Imported device status.');
       }
     } catch (e) {
        debugPrint('DatabaseService Error importing data: $e');
       throw Exception('ไม่สามารถนำเข้าข้อมูลได้: $e');
     }
   }
}