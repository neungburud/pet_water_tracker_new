class AppConfig {
  // การตั้งค่า MQTT เริ่มต้น (จากโค้ด ESP32)
  static const String defaultMqttServer = '8da9745f81c3401480e29580cdde0773.s1.eu.hivemq.cloud';
  static const int defaultMqttPort = 8883;
  static const String defaultMqttUsername = 'neungburud';
  static const String defaultMqttPassword = '@Top140635';
  
  // MQTT topics
  static const String topicDeviceStatus = 'pet/device/status';
  static const String topicPetStatus = 'pet/status';
  static const String topicPetDrinking = 'pet/drinking';
  
  // ค่า RSSI สำหรับตรวจจับระยะ (จากโค้ด ESP32)
  static const int rssiNearThreshold = -60;
  static const int rssiFarThreshold = -70;
  static const int minDrinkingTime = 5000; // 5 วินาที
  
  // การตั้งค่าแอป
  static const int defaultDataRetentionDays = 90;
}