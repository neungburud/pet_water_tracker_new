class DeviceStatus {
  final String deviceId;
  final String status;
  final int uptime;
  final int heap;
  final int wifiRssi;
  final DateTime timestamp;

  DeviceStatus({
    required this.deviceId,
    required this.status,
    required this.uptime,
    required this.heap,
    required this.wifiRssi,
    required this.timestamp,
  });

  factory DeviceStatus.fromJson(Map<String, dynamic> json) {
    return DeviceStatus(
      deviceId: json['device_id'],
      status: json['status'],
      uptime: json['uptime'] ?? 0,
      heap: json['heap'] ?? 0,
      wifiRssi: json['wifi_rssi'] ?? 0,
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'device_id': deviceId,
      'status': status,
      'uptime': uptime,
      'heap': heap,
      'wifi_rssi': wifiRssi,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  // สร้างจาก MQTT message
  factory DeviceStatus.fromMqttMessage(Map<String, dynamic> message) {
    return DeviceStatus(
      deviceId: message['device_id'],
      status: message['status'],
      uptime: message['uptime'] ?? 0,
      heap: message['heap'] ?? 0,
      wifiRssi: message['wifi_rssi'] ?? 0,
      timestamp: DateTime.now(),
    );
  }
}