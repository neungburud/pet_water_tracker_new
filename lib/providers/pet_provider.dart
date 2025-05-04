// lib/providers/pet_provider.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../models/pet.dart';
import '../models/drinking_record.dart';
import '../models/chart_data.dart';
import '../services/database_service.dart';
import 'settings_provider.dart';

class PetProvider extends ChangeNotifier {
  List<Pet> _pets = [];
  List<DrinkingRecord> _drinkingRecords = [];
  bool _isLoading = true;
  String? _error;
  final _uuid = const Uuid();

  SettingsProvider? _settingsProvider;

  void updateSettingsProvider(SettingsProvider sp) {
    _settingsProvider = sp;
    debugPrint("PetProvider: SettingsProvider updated.");
  }

  List<Pet> get pets => List.unmodifiable(_pets);
  List<DrinkingRecord> get drinkingRecords => List.unmodifiable(_drinkingRecords);
  bool get isLoading => _isLoading;
  String? get error => _error;

  PetProvider() {
    _loadData();
  }

  Future<void> _loadData() async {
    _error = null;
    _isLoading = true;

    try {
      _pets = await DatabaseService.loadPets();
      _drinkingRecords = await DatabaseService.loadDrinkingRecords();
      _drinkingRecords.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      
      // สร้างสัตว์เลี้ยงเริ่มต้นถ้าไม่มีข้อมูล
      _ensureDefaultPets();
      
      debugPrint("PetProvider: Initial data loaded. Pets: ${_pets.length}, Records: ${_drinkingRecords.length}");
    } catch (e) {
      _error = 'เกิดข้อผิดพลาดในการโหลดข้อมูลเริ่มต้น: $e';
      debugPrint(_error);
      _pets = [];
      _drinkingRecords = [];
      
      // ถ้ามีข้อผิดพลาด ลองสร้างข้อมูลเริ่มต้นอีกครั้ง
      _ensureDefaultPets();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // เพิ่มฟังก์ชันสร้างสัตว์เลี้ยงเริ่มต้น
  void _ensureDefaultPets() {
    // ถ้าไม่มีสัตว์เลี้ยงเลย ให้สร้างเริ่มต้น 3 ตัวตาม ESP32
    if (_pets.isEmpty) {
      debugPrint("ไม่พบข้อมูลสัตว์เลี้ยง กำลังสร้างข้อมูลเริ่มต้น");
      
      // ค่า MAC Address เดียวกับที่ใช้ใน ESP32
      final petsList = [
        Pet(
          id: 'pet1',
          name: 'กะเพรา',
          macAddress: '51:00:24:03:02:01',
        ),
        Pet(
          id: 'pet2',
          name: 'ลัคกี้',
          macAddress: 'a4:c1:38:6a:8f:db',
        ),
        Pet(
          id: 'pet3',
          name: 'งับบี้',
          macAddress: '51:00:24:12:00:c8',
        ),
      ];
      
      _pets = petsList;
      DatabaseService.savePets(_pets);
      debugPrint("สร้างข้อมูลสัตว์เลี้ยงเริ่มต้นสำเร็จ");
    }
  }

  Future<void> refreshData() async {
    _isLoading = true;
    notifyListeners();
    await _loadData();
  }

  Future<bool> addPet(String name, String macAddress) async {
    final lowerMac = macAddress.toLowerCase().trim();
    if (_pets.any((pet) => pet.macAddress.toLowerCase() == lowerMac)) {
      _error = 'MAC Address "$macAddress" นี้ถูกใช้แล้ว';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final newId = _uuid.v4();
      final newPet = Pet(
        id: newId,
        name: name.trim(),
        macAddress: macAddress.trim(),
      );
      _pets = [..._pets, newPet];
      await DatabaseService.savePets(_pets);
      _isLoading = false;
      notifyListeners();
      debugPrint("PetProvider: Added pet '${newPet.name}' (ID: ${newPet.id})");
      return true;
    } catch (e) {
      _error = 'เกิดข้อผิดพลาดในการเพิ่มสัตว์เลี้ยง: $e';
      debugPrint(_error);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updatePet(String id, {required String name, required String macAddress}) async {
    final index = _pets.indexWhere((pet) => pet.id == id);
    if (index == -1) {
      _error = 'ไม่พบสัตว์เลี้ยง ID: $id ที่ต้องการแก้ไข';
      notifyListeners();
      return false;
    }

    final lowerMac = macAddress.toLowerCase().trim();
    if (_pets.any((pet) => pet.id != id && pet.macAddress.toLowerCase() == lowerMac)) {
      _error = 'MAC Address "$macAddress" นี้ถูกใช้แล้ว';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final currentPet = _pets[index];
      final updatedPet = currentPet.copyWith(
        name: name.trim(),
        macAddress: macAddress.trim(),
      );
      _pets = List<Pet>.from(_pets);
      _pets[index] = updatedPet;

      await DatabaseService.savePets(_pets);
      _isLoading = false;
      notifyListeners();
      debugPrint("PetProvider: Updated pet '${updatedPet.name}' (ID: ${updatedPet.id})");
      return true;
    } catch (e) {
      _error = 'เกิดข้อผิดพลาดในการแก้ไขสัตว์เลี้ยง: $e';
      debugPrint(_error);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deletePet(String id) async {
    final index = _pets.indexWhere((pet) => pet.id == id);
    if (index == -1) {
      _error = 'ไม่พบสัตว์เลี้ยง ID: $id ที่ต้องการลบ';
      notifyListeners();
      return false;
    }
    final petName = _pets[index].name;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _pets = _pets.where((pet) => pet.id != id).toList();
      _drinkingRecords = _drinkingRecords.where((record) => record.petId != id).toList();

      await DatabaseService.savePets(_pets);
      await DatabaseService.saveDrinkingRecords(_drinkingRecords);

      _isLoading = false;
      notifyListeners();
      debugPrint("PetProvider: Deleted pet '$petName' (ID: $id) and associated records.");
      return true;
    } catch (e) {
      _error = 'เกิดข้อผิดพลาดในการลบสัตว์เลี้ยง: $e';
      debugPrint(_error);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> updatePetStatus(String petId, {
    int? rssi,
    bool? isDrinking,
    DateTime? drinkStartTime,
    int? drinkCount,
    int? duration,
  }) async {
    final petIndex = _pets.indexWhere((pet) => pet.id == petId);
    if (petIndex == -1) {
      debugPrint('ไม่พบสัตว์เลี้ยง ID: $petId ที่จะอัปเดตสถานะ');
      return;
    }

    final currentPet = _pets[petIndex];
    bool needsUiUpdate = false;
    bool needsSave = false;

    Pet updatedPet = currentPet.copyWith(lastSeen: () => DateTime.now());

    if (rssi != null && currentPet.lastRssi != rssi) {
      updatedPet = updatedPet.copyWith(lastRssi: rssi);
      needsUiUpdate = true;
    }
    
    if (isDrinking != null && currentPet.isDrinking != isDrinking) {
      updatedPet = updatedPet.copyWith(
        isDrinking: isDrinking,
        drinkStartTime: !isDrinking ? () => null : (drinkStartTime != null ? () => drinkStartTime : null),
      );
      needsUiUpdate = true;
      needsSave = true;
    }
    
    if (isDrinking == true && drinkStartTime != null && currentPet.drinkStartTime != drinkStartTime) {
       updatedPet = updatedPet.copyWith(drinkStartTime: () => drinkStartTime);
       needsUiUpdate = true;
       needsSave = true;
    }
    
    // อัปเดตจำนวนครั้งการดื่มเมื่อได้รับข้อมูลจาก ESP32
    if (drinkCount != null && currentPet.drinkCount != drinkCount) {
       updatedPet = updatedPet.copyWith(drinkCount: drinkCount);
       needsUiUpdate = true;
       needsSave = true;
       debugPrint('อัปเดต drinkCount สำหรับ $petId เป็น $drinkCount');
    }

    _pets[petIndex] = updatedPet;

    if (needsSave) {
       await DatabaseService.savePets(_pets);
       debugPrint('บันทึกข้อมูลสัตว์เลี้ยงเรียบร้อย (สถานะ: isDrinking=$isDrinking, count=$drinkCount)');
    }
    
    if (needsUiUpdate) {
       notifyListeners();
    }
  }

  Future<void> addDrinkingRecord(DrinkingRecord record) async {
    final petExists = _pets.any((pet) => pet.id == record.petId);
    if (!petExists) {
      debugPrint('PetProvider: Pet ID ${record.petId} not found. Ignoring drinking record.');
      return;
    }

    // ดีบั๊กข้อมูลที่ได้รับ
    debugPrint('กำลังเพิ่มประวัติการดื่มน้ำ: ${record.toString()}');

    _drinkingRecords.insert(0, record);
    _pruneOldRecords();

    try {
      await DatabaseService.saveDrinkingRecords(_drinkingRecords);
      notifyListeners();
      debugPrint('บันทึกประวัติการดื่มน้ำเรียบร้อย (ID: ${record.id})');
    } catch (e) {
      _error = 'เกิดข้อผิดพลาดในการบันทึกประวัติการดื่มน้ำ: $e';
      debugPrint(_error);
      notifyListeners();
    }
  }

  void _pruneOldRecords() {
    final int days = _settingsProvider?.dataRetentionDays ?? 90;
    if (days <= 0) return;

    final cutoffDate = DateTime.now().subtract(Duration(days: days));
    final originalLength = _drinkingRecords.length;
    _drinkingRecords = _drinkingRecords.where((record) => record.timestamp.isAfter(cutoffDate)).toList();

    if (_drinkingRecords.length < originalLength) {
        debugPrint('PetProvider: Pruned ${originalLength - _drinkingRecords.length} old drinking records (older than $days days).');
    }
  }

  Pet? getPetById(String id) {
    try {
      return _pets.firstWhere((pet) => pet.id == id);
    } catch (e) {
      return null;
    }
  }

  List<DrinkingRecord> getDailyHistory(String petId) {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    return _drinkingRecords.whereType<DrinkingRecord>().where((record) =>
      record.petId == petId &&
      record.timestamp.isAfter(startOfDay) &&
      record.action == 'finish_drinking'
    ).toList();
  }

  List<DrinkingRecord> getWeeklyHistory(String petId) {
     final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
     return _drinkingRecords.whereType<DrinkingRecord>().where((record) =>
      record.petId == petId &&
      record.timestamp.isAfter(sevenDaysAgo) &&
      record.action == 'finish_drinking'
    ).toList();
  }

  List<DrinkingRecord> getMonthlyHistory(String petId) {
     final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
     return _drinkingRecords.whereType<DrinkingRecord>().where((record) =>
      record.petId == petId &&
      record.timestamp.isAfter(thirtyDaysAgo) &&
      record.action == 'finish_drinking'
    ).toList();
  }

  List<ChartPoint> getDailySummary() {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final Map<String, int> petCountsByName = {};

    final dailyFinishRecords = _drinkingRecords.where((record) =>
        record.timestamp.isAfter(startOfDay) &&
        record.action == 'finish_drinking');

    final Map<String, int> countsById = {};
     for (final record in dailyFinishRecords) {
       countsById[record.petId] = (countsById[record.petId] ?? 0) + 1;
     }

    for (final pet in _pets) {
        petCountsByName[pet.name] = countsById[pet.id] ?? 0;
    }

    return petCountsByName.entries.map((entry) =>
      ChartPoint(x: entry.key, y: entry.value)
    ).toList();
  }

  List<ChartPoint> getChartData(String petId, String period) {
     if (getPetById(petId) == null) return [];
     switch (period) {
       case 'day': return _getDailyChartData(petId);
       case 'week': return _getWeeklyChartData(petId);
       case 'month': return _getMonthlyChartData(petId);
       default: return [];
     }
   }

   List<ChartPoint> _getDailyChartData(String petId) {
     final today = DateTime.now();
     final startOfDay = DateTime(today.year, today.month, today.day);
     final Map<int, int> hourData = { for (var i = 0; i < 24; i++) i: 0 };

     final dailyFinishRecords = _drinkingRecords.where((record) =>
         record.petId == petId &&
         record.timestamp.isAfter(startOfDay) &&
         record.action == 'finish_drinking');

     for (final record in dailyFinishRecords) {
       final hour = record.timestamp.hour;
       hourData[hour] = (hourData[hour] ?? 0) + 1;
     }

     return hourData.entries.map((entry) =>
       ChartPoint(x: entry.key, y: entry.value, label: '${entry.key}:00')
     ).toList();
   }

   List<ChartPoint> _getWeeklyChartData(String petId) {
     final today = DateTime.now();
     final List<ChartPoint> result = [];
     final List<String> dayLabels = ['อา', 'จ', 'อ', 'พ', 'พฤ', 'ศ', 'ส'];

     for (int i = 6; i >= 0; i--) {
       final day = today.subtract(Duration(days: i));
       final startOfDay = DateTime(day.year, day.month, day.day);
       final endOfDay = startOfDay.add(const Duration(days: 1));

       final count = _drinkingRecords.where((record) =>
           record.petId == petId &&
           record.timestamp.isAfter(startOfDay) &&
           record.timestamp.isBefore(endOfDay) &&
           record.action == 'finish_drinking').length;

       final label = '${dayLabels[day.weekday % 7]}\n${day.day}';
       result.add(ChartPoint(x: label, y: count));
     }
     return result;
   }

   List<ChartPoint> _getMonthlyChartData(String petId) {
       final today = DateTime.now();
       final List<ChartPoint> result = [];
       const weeksToShow = 4;

       for (int i = 0; i < weeksToShow; i++) {
         final endOfWeek = today.subtract(Duration(days: i * 7));
         final startOfWeek = endOfWeek.subtract(Duration(days: endOfWeek.weekday - DateTime.monday));
         final startOfDay = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
         final endOfDay = startOfDay.add(const Duration(days: 7));

         final count = _drinkingRecords.where((record) =>
             record.petId == petId &&
             record.timestamp.isAfter(startOfDay) &&
             record.timestamp.isBefore(endOfDay) &&
             record.action == 'finish_drinking').length;

         final weekNumber = weeksToShow - i;
         final label = 'W$weekNumber\n(${startOfDay.day}/${startOfDay.month})';

         result.add(ChartPoint(x: label, y: count));
       }
       return result.reversed.toList();
     }

   List<dynamic> getDrinkingPatternByHour(String petId) {
      final Map<int, int> hourData = { for (var i = 0; i < 24; i++) i: 0 };
      final allFinishRecords = _drinkingRecords.where((record) =>
          record.petId == petId &&
          record.action == 'finish_drinking');

      for (final record in allFinishRecords) {
        hourData[record.timestamp.hour] = (hourData[record.timestamp.hour] ?? 0) + 1;
      }
      return hourData.entries.map((entry) => {'hour': entry.key, 'count': entry.value}).toList();
    }

  Future<void> clearAllData() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await DatabaseService.clearDrinkingRecords();

      _drinkingRecords = [];
      List<Pet> petsToSave = [];
      for (Pet pet in _pets) {
         petsToSave.add(pet.copyWith(
           drinkCount: 0,
           isDrinking: false,
           drinkStartTime: () => null,
         ));
      }
      _pets = petsToSave;

      await DatabaseService.savePets(_pets);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'เกิดข้อผิดพลาดในการล้างข้อมูล: $e';
      debugPrint(_error);
      _isLoading = false;
      notifyListeners();
    }
  }
}