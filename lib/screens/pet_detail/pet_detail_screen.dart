import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/pet_provider.dart';
//import '../../models/pet.dart';
//import '../../models/drinking_record.dart';
import '../../widgets/charts/pet_drinking_pattern_chart.dart';

class PetDetailScreen extends StatelessWidget {
  const PetDetailScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final petId = ModalRoute.of(context)!.settings.arguments as String;

    return Consumer<PetProvider>(
      builder: (context, petProvider, child) {
        final pet = petProvider.getPetById(petId);
        
        if (pet == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('ไม่พบข้อมูล')),
            body: const Center(child: Text('ไม่พบข้อมูลสัตว์เลี้ยง')),
          );
        }

        // สถิติพื้นฐาน
        final dailyRecords = petProvider.getDailyHistory(petId);
        final weeklyRecords = petProvider.getWeeklyHistory(petId);
        final totalToday = dailyRecords.length;
        final averageTimeToday = totalToday > 0
            ? dailyRecords.fold(0, (sum, record) => sum + record.duration) ~/ totalToday
            : 0;
        final totalWeek = weeklyRecords.length;
        final averageTimeWeek = totalWeek > 0
            ? weeklyRecords.fold(0, (sum, record) => sum + record.duration) ~/ totalWeek
            : 0;
        
        // ตรวจสอบสถานะล่าสุด
        final isNear = pet.lastRssi >= -60; // ใช้ RSSI_NEAR_THRESHOLD จากโค้ด ESP32
        final isDrinking = pet.isDrinking;
        
        // ช่วงเวลาที่ดื่มบ่อย (ตัวอย่าง)
        final drinkingPattern = petProvider.getDrinkingPatternByHour(petId);

        return Scaffold(
          appBar: AppBar(
            title: Text(pet.name),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ข้อมูลพื้นฐานและสถานะปัจจุบัน
                Card(
                  elevation: 3,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        // รูปและข้อมูลพื้นฐาน
                        Row(
                          children: [
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: Theme.of(context).primaryColor.withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Icon(
                                  Icons.pets,
                                  size: 40,
                                  color: Theme.of(context).primaryColor,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    pet.name,
                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Icon(
                                        isNear ? Icons.wifi : Icons.wifi_off,
                                        size: 16,
                                        color: isNear ? Colors.green : Colors.grey,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        isNear ? 'อยู่ใกล้น้ำพุ' : 'ไม่อยู่ใกล้น้ำพุ',
                                        style: TextStyle(
                                          color: isNear ? Colors.green : Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.signal_cellular_alt,
                                        size: 16,
                                        color: Theme.of(context).primaryColor,
                                      ),
                                      const SizedBox(width: 4),
                                      Text('ระดับสัญญาณ: ${pet.lastRssi} dBm'),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 16),
                        const Divider(),
                        
                        // สถานะการดื่มน้ำปัจจุบัน
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: isDrinking ? Colors.blue.shade50 : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                isDrinking ? Icons.water_drop : Icons.water_drop_outlined,
                                size: 24,
                                color: isDrinking ? Colors.blue : Colors.grey,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                isDrinking ? 'กำลังดื่มน้ำ' : 'ไม่ได้ดื่มน้ำ',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: isDrinking ? Colors.blue : Colors.grey,
                                ),
                              ),
                              if (isDrinking && pet.drinkStartTime != null)
                                Text(
                                  'เริ่มดื่มเมื่อ ${_formatTime(pet.drinkStartTime!)}',
                                  style: const TextStyle(fontSize: 12),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // สรุปสถิติ
                const Text(
                  'สรุปสถิติการดื่มน้ำ',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatItem(
                          context,
                          'วันนี้',
                          '$totalToday ครั้ง',
                          'เฉลี่ย $averageTimeToday วินาที',
                          Colors.blue,
                        ),
                        const VerticalDivider(thickness: 1),
                        _buildStatItem(
                          context,
                          '7 วันล่าสุด',
                          '$totalWeek ครั้ง',
                          'เฉลี่ย $averageTimeWeek วินาที',
                          Colors.green,
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // รูปแบบการดื่มน้ำตามช่วงเวลา
                const Text(
                  'รูปแบบการดื่มน้ำตามช่วงเวลา',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 200,
                  child: PetDrinkingPatternChart(
                    data: drinkingPattern,
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // รายการดื่มน้ำล่าสุด
                const Text(
                  'ประวัติการดื่มน้ำล่าสุด',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                
                // รายการประวัติล่าสุด
                dailyRecords.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16.0),
                      child: Center(child: Text('ยังไม่มีประวัติการดื่มน้ำวันนี้')),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: dailyRecords.length > 5 ? 5 : dailyRecords.length,
                      itemBuilder: (context, index) {
                        final record = dailyRecords[index];
                        return Card(
                          child: ListTile(
                            leading: const Icon(Icons.water_drop, color: Colors.blue),
                            title: Text('ดื่มน้ำนาน ${record.duration} วินาที'),
                            subtitle: Text(_formatDateTime(record.timestamp)),
                          ),
                        );
                      },
                    ),
                
                if (dailyRecords.length > 5)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Center(
                      child: TextButton(
                        onPressed: () {
                          Navigator.pushNamed(
                            context,
                            '/history',
                            arguments: {'initialPet': petId},
                          );
                        },
                        child: const Text('ดูประวัติทั้งหมด'),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildStatItem(
    BuildContext context,
    String title,
    String primary,
    String secondary,
    Color color,
  ) {
    return Column(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          primary,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          secondary,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }
  
  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
  
  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}