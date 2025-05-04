import 'dart:async';
//import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

class MqttService {
  // MQTT Client
  MqttServerClient? _client;

  // สถานะการเชื่อมต่อ
  bool _isConnected = false;
  String _connectionStatus = 'กำลังเริ่มต้น...';

  // Callbacks
  final void Function(String topic, String message)? onMessage;
  final void Function(bool isConnected)? onConnectionChange;
  final void Function(String status)? onStatusChange;

  // Getters
  bool get isConnected => _isConnected;
  String get connectionStatus => _connectionStatus;

  MqttService({
    this.onMessage,
    this.onConnectionChange,
    this.onStatusChange,
  });

  // เชื่อมต่อกับ MQTT Broker
  Future<bool> connect({
    required String server,
    required int port,
    required String clientId,
    String? username,
    String? password,
    bool useSSL = true,
  }) async {
    if (_isConnected) {
      return true;
    }

    _updateConnectionStatus('กำลังเชื่อมต่อกับ $server...');

    // สร้าง MQTT Client
    _client = MqttServerClient.withPort(server, clientId, port);
    _client!.logging(on: true);
    _client!.keepAlivePeriod = 60;
    _client!.onConnected = _onConnected;
    _client!.onDisconnected = _onDisconnected;
    _client!.pongCallback = _onPong;

    // ตั้งค่า SSL ถ้าจำเป็น
    if (useSSL) {
      _client!.secure = true;
      _client!.securityContext = SecurityContext.defaultContext;
    }

    // ตั้งค่าข้อความการเชื่อมต่อ
    final connMessage = MqttConnectMessage()
        .withClientIdentifier(clientId)
        .withWillQos(MqttQos.atLeastOnce);

    // เพิ่มข้อมูลการยืนยันตัวตนถ้ามี
    if (username != null && username.isNotEmpty) {
      connMessage.authenticateAs(username, password ?? '');
    }

    _client!.connectionMessage = connMessage;

    try {
      // เชื่อมต่อกับ MQTT Broker
      await _client!.connect();
      return true;
    } catch (e) {
      _updateConnectionStatus('เกิดข้อผิดพลาดในการเชื่อมต่อ: $e');
      _isConnected = false;
      if (onConnectionChange != null) {
        onConnectionChange!(_isConnected);
      }
      return false;
    }
  }

  // ตัดการเชื่อมต่อ
  void disconnect() {
    if (_client != null && _isConnected) {
      _client!.disconnect();
      _updateConnectionStatus('ตัดการเชื่อมต่อแล้ว');
    }
  }

  // สมัครรับข้อมูลจาก Topic
  void subscribe(String topic, {MqttQos qos = MqttQos.atLeastOnce}) {
    if (_client != null && _isConnected) {
      _client!.subscribe(topic, qos);
      debugPrint('สมัครสมาชิก topic: $topic');
    }
  }

  // ยกเลิกการสมัครรับข้อมูลจาก Topic
  void unsubscribe(String topic) {
    if (_client != null && _isConnected) {
      _client!.unsubscribe(topic);
      debugPrint('ยกเลิกการสมัครสมาชิก topic: $topic');
    }
  }

  // ส่งข้อมูลไปยัง Topic
  bool publish(String topic, String message, {MqttQos qos = MqttQos.atLeastOnce}) {
    if (_client != null && _isConnected) {
      final builder = MqttClientPayloadBuilder();
      builder.addString(message);
      _client!.publishMessage(topic, qos, builder.payload!);
      return true;
    }
    return false;
  }

  // อัปเดตสถานะการเชื่อมต่อ
  void _updateConnectionStatus(String status) {
    _connectionStatus = status;
    if (onStatusChange != null) {
      onStatusChange!(status);
    }
    debugPrint(status);
  }

  // Callback เมื่อเชื่อมต่อสำเร็จ
  void _onConnected() {
    _isConnected = true;
    _updateConnectionStatus('เชื่อมต่อสำเร็จ');
    
    if (onConnectionChange != null) {
      onConnectionChange!(_isConnected);
    }
    
    // ตั้งค่า callback สำหรับรับข้อมูล
    _client!.updates!.listen(_onMessage);
  }

  // Callback เมื่อขาดการเชื่อมต่อ
  void _onDisconnected() {
    _isConnected = false;
    _updateConnectionStatus('ขาดการเชื่อมต่อ');
    
    if (onConnectionChange != null) {
      onConnectionChange!(_isConnected);
    }
  }

  // Callback เมื่อได้รับการตอบกลับ ping
  void _onPong() {
    debugPrint('ได้รับการตอบกลับ ping จาก MQTT Broker');
  }

  // Callback เมื่อได้รับข้อความ
  void _onMessage(List<MqttReceivedMessage<MqttMessage>> messages) {
    for (final message in messages) {
      final topic = message.topic;
      final payload = (message.payload as MqttPublishMessage).payload.message;
      final payloadString = MqttPublishPayload.bytesToStringAsString(payload);
      
      debugPrint('ได้รับข้อมูลจาก topic: $topic');
      
      if (onMessage != null) {
        onMessage!(topic, payloadString);
      }
    }
  }
}