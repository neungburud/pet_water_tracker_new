import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
//import '../services/notification_service.dart';
import '../services/database_service.dart';
import 'settings_provider.dart';
import 'pet_provider.dart';
import '../models/device_status.dart';
import '../models/drinking_record.dart';
import 'dart:io' show SecurityContext;

class ConnectivityProvider extends ChangeNotifier {
  // MQTT Client
  MqttServerClient? _client;
  bool _isConnected = false;
  DateTime? _lastUpdated;
  DeviceStatus? _deviceStatus;
  
  // สำหรับการเชื่อมต่อใหม่อัตโนมัติ
  Timer? _reconnectTimer;
  
  // ผู้ให้บริการที่เกี่ยวข้อง
  final SettingsProvider _settingsProvider;
  final PetProvider _petProvider;
  //final NotificationService _notificationService;
  
  // Getters
  bool get isConnected => _isConnected;
  DateTime? get lastUpdated => _lastUpdated;
  String get deviceInfo => _deviceStatus != null
    ? 'อุปกรณ์: ${_deviceStatus!.deviceId}, เวลาทำงาน: ${_deviceStatus!.uptime}s, WiFi: ${_deviceStatus!.wifiRssi} dBm'
    : 'ไม่มีข้อมูลอุปกรณ์';
  
  // Constructor
  ConnectivityProvider({
    required SettingsProvider settingsProvider,
    required PetProvider petProvider,
    //required NotificationService notificationService,
  }) : _settingsProvider = settingsProvider,
       _petProvider = petProvider
       //_notificationService = notificationService
  {
    // เริ่มการเชื่อมต่ออัตโนมัติเมื่อสร้าง Provider
    _initMqttClient();
  }
  
  @override
  void dispose() {
    _disconnect();
    _reconnectTimer?.cancel();
    super.dispose();
  }
  
  // เริ่มต้นการทำงานของ MQTT Client
  void _initMqttClient() {
    // รับการตั้งค่า MQTT จาก SettingsProvider
    final server = _settingsProvider.mqttServer;
    final port = _settingsProvider.mqttPort;
    final clientId = _settingsProvider.mqttClientId.isNotEmpty
      ? _settingsProvider.mqttClientId
      : 'flutter_client_${DateTime.now().millisecondsSinceEpoch}';
    
    _client = MqttServerClient.withPort(server, clientId, port);
    
    // ตั้งค่า MQTT Client
    _client!.logging(on: false);
    _client!.keepAlivePeriod = 60;
    _client!.autoReconnect = true;
    
    // ตั้งค่า callback
    _client!.onConnected = _onConnected;
    _client!.onDisconnected = _onDisconnected;
    _client!.onSubscribed = _onSubscribed;
    
    // ถ้าพอร์ตเป็น SSL
    if (port == 8883) {
      _client!.secure = true;
      _client!.securityContext = SecurityContext.defaultContext;
    }
    
    // เชื่อมต่อโดยอัตโนมัติ
    connect();
  }
  
  // เชื่อมต่อกับ MQTT Broker
  Future<void> connect() async {
    if (_client == null) {
      _initMqttClient();
      return;
    }
    
    if (_isConnected) {
      debugPrint('เชื่อมต่อ MQTT อยู่แล้ว');
      return;
    }
    
    try {
      debugPrint('กำลังเชื่อมต่อกับ MQTT Broker...');
      
      // ตั้งค่าการเชื่อมต่อ
      final username = _settingsProvider.mqttUsername;
      final password = _settingsProvider.mqttPassword;
      
      final connMessage = MqttConnectMessage()
        .withClientIdentifier(_client!.clientIdentifier)
        .withWillQos(MqttQos.atLeastOnce);
      
      if (username.isNotEmpty) {
        connMessage.authenticateAs(username, password);
      }
      
      _client!.connectionMessage = connMessage;
      
      // เชื่อมต่อ
      await _client!.connect();
    } catch (e) {
      debugPrint('เกิดข้อผิดพลาดในการเชื่อมต่อ MQTT: $e');
      _isConnected = false;
      notifyListeners();
      
      // ลองเชื่อมต่อใหม่ในอีก 10 วินาที
      _scheduleReconnect();
    }
  }
  
  // ตัดการเชื่อมต่อจาก MQTT Broker
  void disconnect() {
    _disconnect();
    notifyListeners();
  }

  // ตัดการเชื่อมต่อภายใน (ไม่ปรับปรุง UI)
  void _disconnect() {
    _reconnectTimer?.cancel();
    
    if (_client != null && _isConnected) {
      _client!.disconnect();
    }
    
    _isConnected = false;
  }
  
  // กำหนดการเชื่อมต่อใหม่
  void _scheduleReconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 10), () {
      if (!_isConnected) {
        connect();
      }
    });
  }
  
  // callback เมื่อเชื่อมต่อสำเร็จ
  void _onConnected() {
    debugPrint('เชื่อมต่อ MQTT สำเร็จ');
    _isConnected = true;
    
    // สมัครรับข้อมูลจาก MQTT topics
    _subscribeToTopics();
    
    notifyListeners();
  }
  
  // callback เมื่อขาดการเชื่อมต่อ
  void _onDisconnected() {
    debugPrint('ขาดการเชื่อมต่อจาก MQTT');
    _isConnected = false;
    
    // แจ้งเตือนเมื่อขาดการเชื่อมต่อ (ถ้าเปิดใช้งาน)
    if (_settingsProvider.notifyWhenDisconnected) {
      // _notificationService.showNotification(
      //   'ขาดการเชื่อมต่อ',
      //   'ขาดการเชื่อมต่อจากอุปกรณ์ติดตามสัตว์เลี้ยง',
      // );
      debugPrint('ขาดการเชื่อมต่อจากอุปกรณ์ติดตามสัตว์เลี้ยง');
    }
    
    notifyListeners();
    
    // ลองเชื่อมต่อใหม่
    _scheduleReconnect();
  }
  
  // callback เมื่อสมัครสมาชิก topic สำเร็จ
  void _onSubscribed(String topic) {
    debugPrint('สมัครสมาชิก topic สำเร็จ: $topic');
  }
  
  // สมัครสมาชิก MQTT topics
  void _subscribeToTopics() {
    if (_client != null && _client!.connectionStatus!.state == MqttConnectionState.connected) {
      // topic สำหรับสถานะอุปกรณ์
      _client!.subscribe('pet/device/status', MqttQos.atLeastOnce);
      
      // topic สำหรับสถานะสัตว์เลี้ยง
      _client!.subscribe('pet/status', MqttQos.atLeastOnce);
      
      // topic สำหรับการดื่มน้ำ
      _client!.subscribe('pet/drinking', MqttQos.atLeastOnce);
      
      // ตั้งค่า callback สำหรับรับข้อมูล
      _client!.updates!.listen(_onMqttMessage);
      
      debugPrint('สมัครสมาชิก MQTT topics เรียบร้อย');
    }
  }
  
  // รับ MQTT Message
  void _onMqttMessage(List<MqttReceivedMessage<MqttMessage>> messages) {
    for (final message in messages) {
      final topic = message.topic;
      final payload = (message.payload as MqttPublishMessage).payload.message;
      final payloadString = MqttPublishPayload.bytesToStringAsString(payload);
      
      debugPrint('ได้รับข้อมูลจาก topic: $topic');
      
      try {
        // แปลงข้อมูล JSON
        final data = jsonDecode(payloadString);
        
        // จัดการข้อมูลตาม topic
        switch (topic) {
          case 'pet/device/status':
            _handleDeviceStatus(data);
            break;
          case 'pet/status':
            _handlePetStatus(data);
            break;
          case 'pet/drinking':
            _handlePetDrinking(data);
            break;
        }
      } catch (e) {
        debugPrint('เกิดข้อผิดพลาดในการประมวลผลข้อมูล MQTT: $e');
      }
    }
  }
  
  // จัดการข้อมูลสถานะอุปกรณ์
  void _handleDeviceStatus(Map<String, dynamic> data) {
    _deviceStatus = DeviceStatus.fromMqttMessage(data);
    _lastUpdated = DateTime.now();
    
    // บันทึกข้อมูลสถานะอุปกรณ์
    DatabaseService.saveDeviceStatus(_deviceStatus!);
    
    notifyListeners();
  }
  
  // จัดการข้อมูลสถานะสัตว์เลี้ยง
  void _handlePetStatus(Map<String, dynamic> data) {
    final petId = 'pet${data['pet']}';
    final rssi = data['rssi'] as int?;
    
    if (rssi != null) {
      _petProvider.updatePetStatus(
        petId,
        rssi: rssi,
      );
    }
  }
  
  // จัดการข้อมูลการดื่มน้ำ
  void _handlePetDrinking(Map<String, dynamic> data) {
    final petId = 'pet${data['pet']}';
    final action = data['action'] as String;
    final timestamp = DateTime.fromMillisecondsSinceEpoch(
        (data['timestamp'] as int) * 1000);
    
    // อัปเดตสถานะการดื่มน้ำของสัตว์เลี้ยง
    if (action == 'start_drinking') {
      _petProvider.updatePetStatus(
        petId,
        isDrinking: true,
        drinkStartTime: timestamp,
      );
      
      // แจ้งเตือนเมื่อสัตว์เลี้ยงเริ่มดื่มน้ำ (ถ้าเปิดใช้งาน)
      if (_settingsProvider.notifyWhenDrinking) {
        final petName = data['name'] as String;
        // _notificationService.showNotification(
        //   'สัตว์เลี้ยงกำลังดื่มน้ำ',
        //   '$petName กำลังดื่มน้ำ',
        // );
        debugPrint('สัตว์เลี้ยงกำลังดื่มน้ำ: $petName กำลังดื่มน้ำ');
      }
    } else if (action == 'finish_drinking') {
      _petProvider.updatePetStatus(
        petId,
        isDrinking: false,
      );
    }
    
    // บันทึกข้อมูลการดื่มน้ำ
    final recordId = 'drink_${petId}_${DateTime.now().millisecondsSinceEpoch}';
    final drinkingRecord = DrinkingRecord.fromMqttMessage(data, recordId);
    _petProvider.addDrinkingRecord(drinkingRecord);
  }
}