import 'package:flutter/material.dart';
import '../../models/pet.dart';

class PetStatusCard extends StatelessWidget {
  final Pet pet;
  final VoidCallback? onTap;

  const PetStatusCard({
    Key? key,
    required this.pet,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // ตรวจสอบสถานะล่าสุด
    final isNear = pet.lastRssi >= -60; // ใช้ RSSI_NEAR_THRESHOLD จากโค้ด ESP32
    final isDrinking = pet.isDrinking;
    
    // ตรวจสอบการออฟไลน์
    final isOffline = pet.lastSeen == null || 
        DateTime.now().difference(pet.lastSeen!).inMinutes > 5;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isDrinking
              ? Colors.blue
              : isOffline
                  ? Colors.grey.shade300
                  : Colors.transparent,
          width: isDrinking ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              // ไอคอนสัตว์เลี้ยง
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: isOffline
                      ? Colors.grey.withOpacity(0.2)
                      : Theme.of(context).primaryColor.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(
                    Icons.pets,
                    size: 30,
                    color: isOffline
                        ? Colors.grey
                        : Theme.of(context).primaryColor,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              
              // ข้อมูลสัตว์เลี้ยง
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          pet.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (isDrinking)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'กำลังดื่มน้ำ',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          isOffline
                              ? Icons.wifi_off
                              : isNear
                                  ? Icons.wifi
                                  : Icons.wifi_1_bar,
                          size: 16,
                          color: isOffline
                              ? Colors.grey
                              : isNear
                                  ? Colors.green
                                  : Colors.orange,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isOffline
                              ? 'ออฟไลน์'
                              : isNear
                                  ? 'อยู่ใกล้น้ำพุ'
                                  : 'ไม่อยู่ใกล้น้ำพุ',
                          style: TextStyle(
                            color: isOffline
                                ? Colors.grey
                                : isNear
                                    ? Colors.green
                                    : Colors.orange,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.water_drop,
                          size: 16,
                          color: Colors.blue,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'วันนี้: ${pet.drinkCount} ครั้ง',
                          style: TextStyle(
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // ข้อมูลสัญญาณ
              if (!isOffline)
                Column(
                  children: [
                    Text(
                      '${pet.lastRssi} dBm',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: _getRssiColor(pet.lastRssi),
                      ),
                    ),
                    const SizedBox(height: 4),
                    _buildSignalIndicator(pet.lastRssi),
                  ],
                ),
              
              // ปุ่มดูรายละเอียด
              const Icon(
                Icons.chevron_right,
                color: Colors.grey,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSignalIndicator(int rssi) {
    const double width = 4;
    const double spacing = 2;
    const double height = 16;
    
    // คำนวณจำนวนขีด (1-4) ตามความแรงของสัญญาณ
    int bars = 0;
    if (rssi >= -60) {
      bars = 4;
    } else if (rssi >= -70) {
      bars = 3;
    } else if (rssi >= -80) {
      bars = 2;
    } else if (rssi >= -90) {
      bars = 1;
    }
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(4, (index) {
        final barHeight = (index + 1) * height / 4;
        final color = index < bars ? _getRssiColor(rssi) : Colors.grey.shade300;
        
        return Container(
          margin: EdgeInsets.only(right: index < 3 ? spacing : 0),
          width: width,
          height: barHeight,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(1),
          ),
        );
      }),
    );
  }

  Color _getRssiColor(int rssi) {
    if (rssi >= -60) {
      return Colors.green;
    } else if (rssi >= -70) {
      return Colors.lightGreen;
    } else if (rssi >= -80) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }
}