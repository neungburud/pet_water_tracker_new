import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import '../services/notification_service.dart';
import '../services/database_service.dart';
import 'settings_provider.dart';
import 'pet_provider.dart';
import '../models/device_status.dart';
import '../models/drinking_record.dart';

class ConnectivityProvider extends ChangeNotifier {
  // MQTT Client
  MqttServerClient? _client;
  bool _isConnected = false;
  DateTime? _lastUpdated;
  DeviceStatus? _deviceStatus;
  String? _lastConnectionError;
  int _connectionAttempts = 0;
  static const int _maxReconnectAttempts = 10; // เพิ่มจำนวนครั้งสูงสุดจาก 5 เป็น 10
  
  // สำหรับการเชื่อมต่อใหม่อัตโนมัติ
  Timer? _reconnectTimer;
  
  // ผู้ให้บริการที่เกี่ยวข้อง
  final SettingsProvider _settingsProvider;
  final PetProvider _petProvider;
  final NotificationService _notificationService;
  
  // Getters
  bool get isConnected => _isConnected;
  DateTime? get lastUpdated => _lastUpdated;
  String? get lastConnectionError => _lastConnectionError;
  String get deviceInfo => _deviceStatus != null
    ? 'อุปกรณ์: ${_deviceStatus!.deviceId}, เวลาทำงาน: ${_deviceStatus!.uptime}s, WiFi: ${_deviceStatus!.wifiRssi} dBm'
    : 'ไม่มีข้อมูลอุปกรณ์';
  
  // Constructor
  ConnectivityProvider({
    required SettingsProvider settingsProvider,
    required PetProvider petProvider,
    required NotificationService notificationService,
  }) : _settingsProvider = settingsProvider,
       _petProvider = petProvider,
       _notificationService = notificationService
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
  
  // ตรวจสอบสถานะการเชื่อมต่อและลองเชื่อมต่อใหม่ถ้าไม่ได้เชื่อมต่อ
  void checkConnectionStatus() {
    if (!_isConnected) {
      debugPrint("ตรวจพบการขาดการเชื่อมต่อ MQTT กำลังพยายามเชื่อมต่อใหม่...");
      connect();
    }
  }
  
  // เริ่มต้นการทำงานของ MQTT Client
  void _initMqttClient() {
    // รับการตั้งค่า MQTT จาก SettingsProvider
    final server = _settingsProvider.mqttServer;
    final port = _settingsProvider.mqttPort;
    final clientId = _settingsProvider.mqttClientId.isNotEmpty
      ? _settingsProvider.mqttClientId
      : 'flutter_client_${DateTime.now().millisecondsSinceEpoch}';
    
    debugPrint('กำลังเริ่มต้น MQTT Client: $server:$port, ID: $clientId');
    
    _client = MqttServerClient.withPort(server, clientId, port);
    
    // ตั้งค่า MQTT Client
    _client!.logging(on: true); // เปิดการล็อกเพื่อดีบั๊ก
    _client!.keepAlivePeriod = 60;
    // ไม่มี connectionTimeout ใน MqttServerClient
    _client!.autoReconnect = true;
    _client!.onAutoReconnect = _onAutoReconnect;
    _client!.onAutoReconnected = _onConnected;
    
    // ตั้งค่า callback
    _client!.onConnected = _onConnected;
    _client!.onDisconnected = _onDisconnected;
    _client!.onSubscribed = _onSubscribed;
    _client!.onSubscribeFail = _onSubscribeFail;
    _client!.pongCallback = () => debugPrint('ได้รับ pong จาก broker');
    
    // ถ้าพอร์ตเป็น SSL/TLS (8883)
    if (port == 8883) {
      debugPrint('กำลังเปิดใช้งาน SSL/TLS');
      _client!.secure = true;
      _client!.securityContext = SecurityContext.defaultContext;
      // เพิ่มการจัดการใบรับรองที่ไม่ถูกต้อง - ใช้เฉพาะในสภาพแวดล้อมการพัฒนาเท่านั้น
      _client!.onBadCertificate = (dynamic certificate) => true;
    }
    
    // เชื่อมต่อโดยอัตโนมัติ
    connect();
  }
  
  // เชื่อมต่อกับ MQTT Broker
  Future<void> connect() async {
    if (_client == null) {
      debugPrint('MQTT client เป็น null, กำลังเริ่มต้นใหม่');
      _initMqttClient();
      return;
    }
    
    if (_isConnected) {
      debugPrint('เชื่อมต่อ MQTT อยู่แล้ว');
      return;
    }
    
    try {
      debugPrint('กำลังเชื่อมต่อกับ MQTT Broker...');
      _lastConnectionError = null;
      
      // ตั้งค่าการเชื่อมต่อ
      final username = _settingsProvider.mqttUsername;
      final password = _settingsProvider.mqttPassword;
      
      debugPrint('ใช้ข้อมูลประจำตัว - Username: $username, Password: ${password.isNotEmpty ? 'Provided' : 'Not provided'}');
      
      final connMessage = MqttConnectMessage()
        .withClientIdentifier(_client!.clientIdentifier)
        .withWillQos(MqttQos.atLeastOnce);
      
      // ตั้งค่า keep alive (ไม่มีเมธอด withKeepAlive)
      // ใช้วิธีกำหนด keepAlivePeriod ของ client แทน
      _client!.keepAlivePeriod = 60;
      
      if (username.isNotEmpty) {
        connMessage.authenticateAs(username, password);
      }
      
      _client!.connectionMessage = connMessage;
      
      // เชื่อมต่อ
      debugPrint('กำลังเริ่มการเชื่อมต่อ...');
      await _client!.connect();
      
      // ตรวจสอบสถานะการเชื่อมต่อหลังจากเชื่อมต่อ
      if (_client!.connectionStatus!.state == MqttConnectionState.connected) {
        debugPrint('เชื่อมต่อ MQTT สำเร็จ');
        _onConnected(); // เรียกฟังก์ชัน callback ด้วยตนเอง
      } else {
        final returnCode = _client!.connectionStatus!.returnCode;
        debugPrint('ไม่สามารถเชื่อมต่อได้: $returnCode');
        throw Exception('เชื่อมต่อล้มเหลว: $returnCode');
      }
    } on SocketException catch (e) {
      _lastConnectionError = 'ปัญหาการเชื่อมต่อเครือข่าย: $e';
      debugPrint('เกิด Socket Exception ในการเชื่อมต่อ MQTT: $e');
      _isConnected = false;
      _connectionAttempts++;
      notifyListeners();
      _scheduleReconnect();
    } on HandshakeException catch (e) {
      _lastConnectionError = 'ปัญหาการเขย่ามือ SSL/TLS: $e';
      debugPrint('เกิด SSL Handshake Exception ในการเชื่อมต่อ MQTT: $e');
      _isConnected = false;
      _connectionAttempts++;
      notifyListeners();
      _scheduleReconnect();
    } on NoConnectionException catch (e) {
      _lastConnectionError = 'ไม่สามารถเชื่อมต่อกับ broker: $e';
      debugPrint('เกิด NoConnectionException ในการเชื่อมต่อ MQTT: $e');
      _isConnected = false;
      _connectionAttempts++;
      notifyListeners();
      _scheduleReconnect();
    } catch (e) {
      _lastConnectionError = e.toString();
      debugPrint('เกิดข้อผิดพลาดในการเชื่อมต่อ MQTT: $e');
      _isConnected = false;
      
      // เพิ่มจำนวนครั้งที่พยายามเชื่อมต่อ
      _connectionAttempts++;
      
      // ถ้าพยายามหลายครั้งแล้ว แจ้งเตือนผู้ใช้
      if (_connectionAttempts >= 3 && _settingsProvider.notifyWhenDisconnected) {
        _notificationService.showNotification(
          'ไม่สามารถเชื่อมต่อได้',
          'ไม่สามารถเชื่อมต่อกับ MQTT Broker ได้ กรุณาตรวจสอบการตั้งค่า'
        );
      }
      
      notifyListeners();
      
      // ลองเชื่อมต่อใหม่ในอีก 10 วินาที
      _scheduleReconnect();
    }
  }
  
  // ตัดการเชื่อมต่อจาก MQTT Broker
  void disconnect() {
    _disconnect();
    // รีเซ็ตจำนวนการพยายามเชื่อมต่อเมื่อมีการตัดการเชื่อมต่อโดยตั้งใจ
    _connectionAttempts = 0;
    notifyListeners();
  }

  // ตัดการเชื่อมต่อภายใน (ไม่ปรับปรุง UI)
  void _disconnect() {
    _reconnectTimer?.cancel();
    
    if (_client != null && _isConnected) {
      debugPrint('กำลังตัดการเชื่อมต่อจาก MQTT broker');
      _client!.disconnect();
    }
    
    _isConnected = false;
  }
  
  // กำหนดการเชื่อมต่อใหม่
  void _scheduleReconnect() {
    _reconnectTimer?.cancel();
    
    // ถ้าพยายามเชื่อมต่อเกินจำนวนสูงสุดแล้ว ไม่ต้องพยายามอีก
    if (_connectionAttempts >= _maxReconnectAttempts) {
      debugPrint('เกินจำนวนครั้งสูงสุดในการพยายามเชื่อมต่อ');
      return;
    }
    
    // เพิ่มเวลารอขึ้นเรื่อยๆ หากการเชื่อมต่อล้มเหลวหลายครั้ง (exponential backoff)
    final backoffTime = _connectionAttempts < 3 ? 10 : 30 * (_connectionAttempts - 2);
    
    debugPrint('จะลองเชื่อมต่อใหม่ในอีก $backoffTime วินาที (ครั้งที่ $_connectionAttempts)');
    
    _reconnectTimer = Timer(Duration(seconds: backoffTime), () {
      if (!_isConnected) {
        debugPrint('กำลังพยายามเชื่อมต่อใหม่ (ครั้งที่ $_connectionAttempts)...');
        connect();
      }
    });
  }
  
  // callback เมื่อเชื่อมต่อสำเร็จ
  void _onConnected() {
    debugPrint('เชื่อมต่อ MQTT สำเร็จ');
    _isConnected = true;
    _connectionAttempts = 0; // รีเซ็ตจำนวนครั้งของการพยายามเชื่อมต่อ
    
    // สมัครรับข้อมูลจาก MQTT topics
    _subscribeToTopics();
    
    notifyListeners();
    
    // แจ้งเตือนเมื่อเชื่อมต่อสำเร็จหลังจากขาดการเชื่อมต่อ
    if (_settingsProvider.notifyWhenDisconnected && _lastConnectionError != null) {
      _notificationService.showNotification(
        'เชื่อมต่อสำเร็จ',
        'เชื่อมต่อกับอุปกรณ์ติดตามสัตว์เลี้ยงเรียบร้อยแล้ว',
      );
    }
  }
  
  // callback เมื่อขาดการเชื่อมต่อ
  void _onDisconnected() {
    debugPrint('ขาดการเชื่อมต่อจาก MQTT');
    _isConnected = false;
    
    // แจ้งเตือนเมื่อขาดการเชื่อมต่อ (ถ้าเปิดใช้งาน)
    if (_settingsProvider.notifyWhenDisconnected) {
      _notificationService.showNotification(
        'ขาดการเชื่อมต่อ',
        'ขาดการเชื่อมต่อจากอุปกรณ์ติดตามสัตว์เลี้ยง',
      );
    }
    
    notifyListeners();
    
    // ลองเชื่อมต่อใหม่
    _scheduleReconnect();
  }
  
  // callback เมื่อเกิดการเชื่อมต่อใหม่อัตโนมัติ
  void _onAutoReconnect() {
    debugPrint('กำลังเชื่อมต่อใหม่อัตโนมัติ...');
    // ไม่ต้องเรียก notifyListeners ที่นี่เพราะจะเรียกที่ _onConnected เมื่อเชื่อมต่อสำเร็จ
  }
  
  // callback เมื่อสมัครสมาชิก topic สำเร็จ
  void _onSubscribed(String topic) {
    debugPrint('สมัครสมาชิก topic สำเร็จ: $topic');
  }
  
  // callback เมื่อสมัครสมาชิก topic ล้มเหลว
  void _onSubscribeFail(String topic) {
    debugPrint('สมัครสมาชิก topic ล้มเหลว: $topic');
    // อาจจะลองสมัครอีกครั้งหลังจากรอสักครู่
    Future.delayed(const Duration(seconds: 5), () {
      if (_isConnected) {
        _client!.subscribe(topic, MqttQos.atLeastOnce);
      }
    });
  }
  
  // สมัครสมาชิก MQTT topics
  void _subscribeToTopics() {
    if (_client != null && _client!.connectionStatus!.state == MqttConnectionState.connected) {
      debugPrint('กำลังสมัครสมาชิก MQTT topics');
      
      // topic สำหรับสถานะอุปกรณ์
      _client!.subscribe('pet/device/status', MqttQos.atLeastOnce);
      
      // topic สำหรับสถานะสัตว์เลี้ยง
      _client!.subscribe('pet/status', MqttQos.atLeastOnce);
      
      // topic สำหรับการดื่มน้ำ
      _client!.subscribe('pet/drinking', MqttQos.atLeastOnce);
      
      // ตั้งค่า callback สำหรับรับข้อมูล
      _client!.updates!.listen(_onMqttMessage);
      
      debugPrint('สมัครสมาชิก MQTT topics เรียบร้อย');
    } else {
      debugPrint('ไม่สามารถสมัครสมาชิก topics: ไม่ได้เชื่อมต่อ');
    }
  }
  
  // รับ MQTT Message
  void _onMqttMessage(List<MqttReceivedMessage<MqttMessage>> messages) {
    for (final message in messages) {
      final topic = message.topic;
      final payload = (message.payload as MqttPublishMessage).payload.message;
      final payloadString = MqttPublishPayload.bytesToStringAsString(payload);
      
      debugPrint('ได้รับข้อมูลจาก topic: $topic, payload: $payloadString');
      
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
          default:
            debugPrint('ไม่รู้จัก topic: $topic');
        }
      } catch (e) {
        debugPrint('เกิดข้อผิดพลาดในการประมวลผลข้อมูล MQTT: $e');
      }
    }
  }
  
  // จัดการข้อมูลสถานะอุปกรณ์
  void _handleDeviceStatus(Map<String, dynamic> data) {
    try {
      debugPrint('กำลังประมวลผลสถานะอุปกรณ์: $data');
      _deviceStatus = DeviceStatus.fromMqttMessage(data);
      _lastUpdated = DateTime.now();
      
      // บันทึกข้อมูลสถานะอุปกรณ์
      DatabaseService.saveDeviceStatus(_deviceStatus!);
      
      notifyListeners();
    } catch (e) {
      debugPrint('เกิดข้อผิดพลาดในการประมวลผลสถานะอุปกรณ์: $e');
    }
  }
  
  // จัดการข้อมูลสถานะสัตว์เลี้ยง
  void _handlePetStatus(Map<String, dynamic> data) {
    try {
      debugPrint('กำลังประมวลผลสถานะสัตว์เลี้ยง: $data');
      final petId = data['pet'] != null ? 'pet${data['pet']}' : null;
      final rssi = data['rssi'] as int?;
      
      if (petId != null && rssi != null) {
        _petProvider.updatePetStatus(
          petId,
          rssi: rssi,
        );
      } else {
        debugPrint('ข้อมูลสถานะสัตว์เลี้ยงไม่ครบถ้วน: $data');
      }
    } catch (e) {
      debugPrint('เกิดข้อผิดพลาดในการประมวลผลสถานะสัตว์เลี้ยง: $e');
    }
  }
  
  // จัดการข้อมูลการดื่มน้ำ
  void _handlePetDrinking(Map<String, dynamic> data) {
    try {
      debugPrint('กำลังประมวลผลข้อมูลการดื่มน้ำ: $data');
      
      // ดึงค่า petNum จาก ESP32 (ส่งมาเป็นตัวเลข 1, 2, 3)
      final petNum = data['pet'] as int?;
      if (petNum == null) {
        debugPrint('ไม่พบหมายเลขสัตว์เลี้ยงในข้อความ MQTT');
        return;
      }
      
      // แปลง petNum เป็น petId ในรูปแบบ "pet1", "pet2", "pet3"
      final petId = 'pet$petNum';
      
      final action = data['action'] as String?;
      final timestampValue = data['timestamp'] as int?;
      
      if (action == null || timestampValue == null) {
        debugPrint('ข้อมูลการดื่มน้ำไม่ครบถ้วน: $data');
        return;
      }
      
      // แปลง timestamp เป็น DateTime (ทั้งนี้ ESP ส่ง timestamp เป็นวินาที)
      final timestamp = DateTime.fromMillisecondsSinceEpoch(timestampValue * 1000);
      
      // อัปเดตสถานะการดื่มน้ำของสัตว์เลี้ยง
      if (action == 'start_drinking') {
        debugPrint('เริ่มดื่ม: $petId ที่เวลา ${timestamp.toString()}');
        _petProvider.updatePetStatus(
          petId,
          isDrinking: true,
          drinkStartTime: timestamp,
        );
        
        // แจ้งเตือนเมื่อสัตว์เลี้ยงเริ่มดื่มน้ำ (ถ้าเปิดใช้งาน)
        if (_settingsProvider.notifyWhenDrinking) {
          final petName = data['name'] as String? ?? 'สัตว์เลี้ยง';
          _notificationService.showNotification(
            'สัตว์เลี้ยงกำลังดื่มน้ำ',
            '$petName กำลังดื่มน้ำ',
            payload: 'pet:$petId:drinking',
          );
        }
      } else if (action == 'finish_drinking') {
        debugPrint('เลิกดื่ม: $petId ที่เวลา ${timestamp.toString()}');
        
        // ดึงค่า count จากข้อมูล (ESP32 ส่งมาด้วย)
        final drinkCount = data['count'] as int? ?? 0;
        final duration = data['duration'] as int? ?? 0;
        
        _petProvider.updatePetStatus(
          petId,
          isDrinking: false,
          drinkCount: drinkCount, // อัปเดตจำนวนครั้งตามที่ ESP32 ส่งมา
        );
        
        // แจ้งเตือนเมื่อสัตว์เลี้ยงดื่มน้ำเสร็จ (ถ้าเปิดใช้งาน)
        if (_settingsProvider.notifyWhenDrinking) {
          final petName = data['name'] as String? ?? 'สัตว์เลี้ยง';
          _notificationService.showNotification(
            'สัตว์เลี้ยงดื่มน้ำเสร็จแล้ว',
            '$petName ดื่มน้ำเป็นเวลา $duration วินาที',
            payload: 'pet:$petId:finished',
          );
        }
        
        // บันทึกข้อมูลการดื่มน้ำ
        final recordId = 'drink_${petId}_${DateTime.now().millisecondsSinceEpoch}';
        final drinkingRecord = DrinkingRecord.fromMqttMessage(data, recordId);
        _petProvider.addDrinkingRecord(drinkingRecord);
      }
    } catch (e) {
      debugPrint('เกิดข้อผิดพลาดในการประมวลผลการดื่มน้ำ: $e');
    }
  }
  
  // ส่งข้อความไปยัง MQTT Broker
  Future<bool> publishMessage(String topic, String message) async {
    if (!_isConnected || _client == null) {
      debugPrint('ไม่สามารถส่งข้อความได้: ไม่ได้เชื่อมต่อ');
      return false;
    }
    
    try {
      final builder = MqttClientPayloadBuilder();
      builder.addString(message);
      
      _client!.publishMessage(
        topic,
        MqttQos.atLeastOnce,
        builder.payload!,
        retain: false,
      );
      
      debugPrint('ส่งข้อความไปยัง $topic สำเร็จ');
      return true;
    } catch (e) {
      debugPrint('เกิดข้อผิดพลาดในการส่งข้อความ: $e');
      return false;
    }
  }
}