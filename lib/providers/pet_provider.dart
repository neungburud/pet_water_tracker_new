// lib/providers/pet_provider.dart

import 'package:flutter/material.dart';
import '../models/pet.dart';
import '../models/drinking_record.dart';
import '../models/chart_data.dart';

import '../services/database_service.dart';

class PetProvider extends ChangeNotifier {
  List<Pet> _pets = [];
  List<DrinkingRecord> _drinkingRecords = [];
  bool _isLoading = true;

  // Getters
  List<Pet> get pets => _pets;
  List<DrinkingRecord> get drinkingRecords => _drinkingRecords;
  bool get isLoading => _isLoading;

  // Constructor
  PetProvider() {
    _loadData();
  }

  // โหลดข้อมูลจาก SharedPreferences
  Future<void> _loadData() async {
    _isLoading = true;
    notifyListeners();

    try {
      // โหลดข้อมูลสัตว์เลี้ยง
      _pets = await DatabaseService.loadPets();

      // โหลดประวัติการดื่มน้ำ
      _drinkingRecords = await DatabaseService.loadDrinkingRecords();
      
      // เรียงลำดับตามเวลาล่าสุด
      _drinkingRecords.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    } catch (e) {
      debugPrint('เกิดข้อผิดพลาดในการโหลดข้อมูล: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // รีเฟรชข้อมูล
  Future<void> refreshData() async {
    await _loadData();
  }

  // อัปเดตข้อมูลสัตว์เลี้ยงจาก MQTT
  Future<void> updatePetStatus(String petId, {
    int? rssi,
    bool? isDrinking,
    DateTime? drinkStartTime,
  }) async {
    final petIndex = _pets.indexWhere((pet) => pet.id == petId);
    if (petIndex != -1) {
      final pet = _pets[petIndex];
      _pets[petIndex] = pet.copyWith(
        lastRssi: rssi ?? pet.lastRssi,
        isDrinking: isDrinking ?? pet.isDrinking,
        drinkStartTime: drinkStartTime ?? pet.drinkStartTime,
        lastSeen: DateTime.now(),
      );
      
      await DatabaseService.savePets(_pets);
      notifyListeners();
    }
  }

  // เพิ่มบันทึกการดื่มน้ำจาก MQTT
  Future<void> addDrinkingRecord(DrinkingRecord record) async {
    // ตรวจสอบว่ามีบันทึกซ้ำหรือไม่
    final isDuplicate = _drinkingRecords.any((r) => r.id == record.id);
    if (isDuplicate) return;

    // อัปเดตจำนวนการดื่มน้ำสำหรับสัตว์เลี้ยง (เฉพาะ finish_drinking)
    if (record.action == 'finish_drinking') {
      final petIndex = _pets.indexWhere((pet) => pet.id == record.petId);
      if (petIndex != -1) {
        final pet = _pets[petIndex];
        _pets[petIndex] = pet.copyWith(
          drinkCount: pet.drinkCount + 1,
          isDrinking: false,
        );
      }
    } else if (record.action == 'start_drinking') {
      final petIndex = _pets.indexWhere((pet) => pet.id == record.petId);
      if (petIndex != -1) {
        final pet = _pets[petIndex];
        _pets[petIndex] = pet.copyWith(
          isDrinking: true,
          drinkStartTime: record.timestamp,
        );
      }
    }

    // เพิ่มบันทึกใหม่
    _drinkingRecords.add(record);
    
    // เรียงลำดับตามเวลาล่าสุด
    _drinkingRecords.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    
    // ลบข้อมูลเก่าเกินกว่า n วัน (ตามการตั้งค่า)
    _pruneOldRecords(90); // ค่าเริ่มต้น 90 วัน
    
    await DatabaseService.savePets(_pets);
    await DatabaseService.saveDrinkingRecords(_drinkingRecords);
    notifyListeners();
  }
  
  // ลบบันทึกที่เก่าเกินกว่า n วัน
  void _pruneOldRecords(int days) {
    final cutoffDate = DateTime.now().subtract(Duration(days: days));
    _drinkingRecords.removeWhere((record) => record.timestamp.isBefore(cutoffDate));
  }

  // ดึงข้อมูลสัตว์เลี้ยงตาม ID
  Pet? getPetById(String id) {
    try {
      return _pets.firstWhere((pet) => pet.id == id);
    } catch (e) {
      return null;
    }
  }

  // ดึงประวัติการดื่มน้ำรายวันของสัตว์เลี้ยง
  List<DrinkingRecord> getDailyHistory(String petId) {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    
    return _drinkingRecords.where((record) => 
      record.petId == petId && 
      record.timestamp.isAfter(startOfDay) &&
      record.action == 'finish_drinking'
    ).toList();
  }

  // ดึงประวัติการดื่มน้ำรายสัปดาห์ของสัตว์เลี้ยง
  List<DrinkingRecord> getWeeklyHistory(String petId) {
    final today = DateTime.now();
    final startOfWeek = today.subtract(Duration(days: 7));
    
    return _drinkingRecords.where((record) => 
      record.petId == petId && 
      record.timestamp.isAfter(startOfWeek) &&
      record.action == 'finish_drinking'
    ).toList();
  }

  // ดึงประวัติการดื่มน้ำรายเดือนของสัตว์เลี้ยง
  List<DrinkingRecord> getMonthlyHistory(String petId) {
    final today = DateTime.now();
    final startOfMonth = today.subtract(Duration(days: 30));
    
    return _drinkingRecords.where((record) => 
      record.petId == petId && 
      record.timestamp.isAfter(startOfMonth) &&
      record.action == 'finish_drinking'
    ).toList();
  }

  // ดึงข้อมูลสรุปรายวันสำหรับกราฟ
  List<ChartPoint> getDailySummary() {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    
    final Map<String, int> petCounts = {};
    
    for (final pet in _pets) {
      final count = _drinkingRecords.where((record) => 
        record.petId == pet.id && 
        record.timestamp.isAfter(startOfDay) &&
        record.action == 'finish_drinking'
      ).length;
      
      petCounts[pet.name] = count;
    }
    
    return petCounts.entries.map((entry) => 
      ChartPoint(
        x: entry.key,
        y: entry.value,
      )
    ).toList();
  }

  // ดึงข้อมูลกราฟตามช่วงเวลา
  List<ChartPoint> getChartData(String petId, String period) {
    switch (period) {
      case 'day':
        return _getDailyChartData(petId);
      case 'week':
        return _getWeeklyChartData(petId);
      case 'month':
        return _getMonthlyChartData(petId);
      default:
        return [];
    }
  }

  // ดึงข้อมูลกราฟรายวัน (แบ่งตามชั่วโมง)
  List<ChartPoint> _getDailyChartData(String petId) {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    
    // สร้างข้อมูลเริ่มต้นสำหรับทุกชั่วโมง
    final Map<int, int> hourData = {};
    for (int i = 0; i < 24; i++) {
      hourData[i] = 0;
    }
    
    // นับจำนวนครั้งการดื่มน้ำในแต่ละชั่วโมง
    for (final record in _drinkingRecords) {
      if (record.petId == petId && 
          record.timestamp.isAfter(startOfDay) &&
          record.action == 'finish_drinking') {
        final hour = record.timestamp.hour;
        hourData[hour] = (hourData[hour] ?? 0) + 1;
      }
    }
    
    // แปลงเป็น ChartPoint
    return hourData.entries.map((entry) => 
      ChartPoint(
        x: entry.key,
        y: entry.value,
        label: '${entry.key}:00',
      )
    ).toList()
      ..sort((a, b) => (a.x as int).compareTo(b.x as int));
  }

  // ดึงข้อมูลกราฟรายสัปดาห์ (แบ่งตามวัน)
  List<ChartPoint> _getWeeklyChartData(String petId) {
    final today = DateTime.now();
    
    // สร้างข้อมูลเริ่มต้นสำหรับทุกวันในสัปดาห์
    final Map<int, int> dayData = {};
    final List<String> dayNames = ['จ.', 'อ.', 'พ.', 'พฤ.', 'ศ.', 'ส.', 'อา.'];
    
    for (int i = 6; i >= 0; i--) {
      final day = today.subtract(Duration(days: i));
      dayData[day.day] = 0;
    }
    
    // นับจำนวนครั้งการดื่มน้ำในแต่ละวัน
    for (final record in _drinkingRecords) {
      if (record.petId == petId && 
          record.timestamp.isAfter(today.subtract(Duration(days: 7))) &&
          record.action == 'finish_drinking') {
        final day = record.timestamp.day;
        if (dayData.containsKey(day)) {
          dayData[day] = (dayData[day] ?? 0) + 1;
        }
      }
    }
    
    // แปลงเป็น ChartPoint โดยใช้ชื่อวัน
    final List<ChartPoint> result = [];
    int i = 0;
    
    for (int day in dayData.keys.toList()..sort()) {
      result.add(ChartPoint(
        x: dayNames[i % 7],
        y: dayData[day] ?? 0,
        label: '$day',
      ));
      i++;
    }
    
    return result;
  }

  // ดึงข้อมูลกราฟรายเดือน (แบ่งตามสัปดาห์)
  List<ChartPoint> _getMonthlyChartData(String petId) {
    final today = DateTime.now();
    
    // สร้างข้อมูลสำหรับ 4 สัปดาห์ย้อนหลัง
    final List<ChartPoint> result = [];
    
    for (int i = 0; i < 4; i++) {
      final endWeek = today.subtract(Duration(days: i * 7));
      final startWeek = endWeek.subtract(Duration(days: 6));
      
      final count = _drinkingRecords.where((record) => 
        record.petId == petId && 
        record.timestamp.isAfter(startWeek) &&
        record.timestamp.isBefore(endWeek.add(Duration(days: 1))) &&
        record.action == 'finish_drinking'
      ).length;
      
      result.add(ChartPoint(
        x: 'W${4 - i}',
        y: count,
        label: '${startWeek.day}/${startWeek.month} - ${endWeek.day}/${endWeek.month}',
      ));
    }
    
    return result.reversed.toList();
  }

// ดึงรูปแบบการดื่มน้ำแบ่งตามช่วงเวลา (ชั่วโมง)
List<dynamic> getDrinkingPatternByHour(String petId) {
  // สร้างข้อมูลเริ่มต้นสำหรับทุกชั่วโมง
  final Map<int, int> hourData = {};
  for (int i = 0; i < 24; i++) {
    hourData[i] = 0;
  }
  
  // นับจำนวนครั้งการดื่มน้ำในแต่ละชั่วโมง (ทั้งหมดไม่จำกัดวัน)
  for (final record in _drinkingRecords) {
    if (record.petId == petId && record.action == 'finish_drinking') {
      final hour = record.timestamp.hour;
      hourData[hour] = (hourData[hour] ?? 0) + 1;
    }
  }
  
  // แปลงเป็นรูปแบบข้อมูลที่ต้องการ
  return hourData.entries.map((entry) => {
    'hour': entry.key,
    'count': entry.value,
  }).toList()
    ..sort((a, b) => (a['hour'] as int).compareTo(b['hour'] as int));
}

  // ล้างข้อมูลทั้งหมด
  Future<void> clearAllData() async {
    await DatabaseService.clearDrinkingRecords();
    
    // เก็บข้อมูลสัตว์เลี้ยงไว้ แต่รีเซ็ตค่าตัวแปรบางตัว
    for (int i = 0; i < _pets.length; i++) {
      _pets[i] = _pets[i].copyWith(
        drinkCount: 0,
        isDrinking: false,
        drinkStartTime: null,
      );
    }
    
    await DatabaseService.savePets(_pets);
    
    _drinkingRecords = [];
    notifyListeners();
  }
}