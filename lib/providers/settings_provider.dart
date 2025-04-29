import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider extends ChangeNotifier {
  // การตั้งค่า MQTT
  String _mqttServer = '8da9745f81c3401480e29580cdde0773.s1.eu.hivemq.cloud';
  int _mqttPort = 8883;
  String _mqttUsername = 'neungburud';
  String _mqttPassword = '@Top140635';
  String _mqttClientId = '';

  // การตั้งค่าการแจ้งเตือน
  bool _notifyWhenDrinking = true;
  bool _notifyWhenNotDrinking = true;
  bool _notifyWhenDisconnected = true;

  // การตั้งค่าการเก็บข้อมูล
  int _dataRetentionDays = 90;

  // Getters
  String get mqttServer => _mqttServer;
  int get mqttPort => _mqttPort;
  String get mqttUsername => _mqttUsername;
  String get mqttPassword => _mqttPassword;
  String get mqttClientId => _mqttClientId;
  bool get notifyWhenDrinking => _notifyWhenDrinking;
  bool get notifyWhenNotDrinking => _notifyWhenNotDrinking;
  bool get notifyWhenDisconnected => _notifyWhenDisconnected;
  int get dataRetentionDays => _dataRetentionDays;

  // Constructor
  SettingsProvider() {
    _loadSettings();
  }

  // โหลดการตั้งค่าจาก SharedPreferences
  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // การตั้งค่า MQTT
      _mqttServer = prefs.getString('mqtt_server') ?? _mqttServer;
      _mqttPort = prefs.getInt('mqtt_port') ?? _mqttPort;
      _mqttUsername = prefs.getString('mqtt_username') ?? _mqttUsername;
      _mqttPassword = prefs.getString('mqtt_password') ?? _mqttPassword;
      _mqttClientId = prefs.getString('mqtt_client_id') ?? _mqttClientId;
      
      // การตั้งค่าการแจ้งเตือน
      _notifyWhenDrinking = prefs.getBool('notify_when_drinking') ?? _notifyWhenDrinking;
      _notifyWhenNotDrinking = prefs.getBool('notify_when_not_drinking') ?? _notifyWhenNotDrinking;
      _notifyWhenDisconnected = prefs.getBool('notify_when_disconnected') ?? _notifyWhenDisconnected;
      
      // การตั้งค่าการเก็บข้อมูล
      _dataRetentionDays = prefs.getInt('data_retention_days') ?? _dataRetentionDays;
      
      notifyListeners();
    } catch (e) {
      debugPrint('เกิดข้อผิดพลาดในการโหลดการตั้งค่า: $e');
    }
  }

  // บันทึกการตั้งค่า MQTT
  Future<void> saveMqttSettings({
    required String server,
    required int port,
    required String username,
    required String password,
    required String clientId,
  }) async {
    _mqttServer = server;
    _mqttPort = port;
    _mqttUsername = username;
    _mqttPassword = password;
    _mqttClientId = clientId;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('mqtt_server', server);
      await prefs.setInt('mqtt_port', port);
      await prefs.setString('mqtt_username', username);
      await prefs.setString('mqtt_password', password);
      await prefs.setString('mqtt_client_id', clientId);
      
      notifyListeners();
    } catch (e) {
      debugPrint('เกิดข้อผิดพลาดในการบันทึกการตั้งค่า MQTT: $e');
    }
  }

  // ตั้งค่าการแจ้งเตือนเมื่อสัตว์เลี้ยงดื่มน้ำ
  Future<void> setNotifyWhenDrinking(bool value) async {
    _notifyWhenDrinking = value;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('notify_when_drinking', value);
      
      notifyListeners();
    } catch (e) {
      debugPrint('เกิดข้อผิดพลาดในการบันทึกการตั้งค่าการแจ้งเตือน: $e');
    }
  }

  // ตั้งค่าการแจ้งเตือนเมื่อสัตว์เลี้ยงไม่ดื่มน้ำเป็นเวลานาน
  Future<void> setNotifyWhenNotDrinking(bool value) async {
    _notifyWhenNotDrinking = value;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('notify_when_not_drinking', value);
      
      notifyListeners();
    } catch (e) {
      debugPrint('เกิดข้อผิดพลาดในการบันทึกการตั้งค่าการแจ้งเตือน: $e');
    }
  }

  // ตั้งค่าการแจ้งเตือนเมื่อขาดการเชื่อมต่อ
  Future<void> setNotifyWhenDisconnected(bool value) async {
    _notifyWhenDisconnected = value;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('notify_when_disconnected', value);
      
      notifyListeners();
    } catch (e) {
      debugPrint('เกิดข้อผิดพลาดในการบันทึกการตั้งค่าการแจ้งเตือน: $e');
    }
  }

  // ตั้งค่าระยะเวลาการเก็บข้อมูล
  Future<void> setDataRetentionDays(int days) async {
    _dataRetentionDays = days;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('data_retention_days', days);
      
      notifyListeners();
    } catch (e) {
      debugPrint('เกิดข้อผิดพลาดในการบันทึกการตั้งค่าการเก็บข้อมูล: $e');
    }
  }

  // ล้างการตั้งค่าทั้งหมด
  Future<void> clearAllData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // ลบเฉพาะบางค่า แต่คงค่าการเชื่อมต่อ MQTT ไว้
      await prefs.remove('data_retention_days');
      await prefs.remove('notify_when_drinking');
      await prefs.remove('notify_when_not_drinking');
      await prefs.remove('notify_when_disconnected');
      
      _dataRetentionDays = 90;
      _notifyWhenDrinking = true;
      _notifyWhenNotDrinking = true;
      _notifyWhenDisconnected = true;
      
      notifyListeners();
    } catch (e) {
      debugPrint('เกิดข้อผิดพลาดในการล้างการตั้งค่า: $e');
    }
  }
}