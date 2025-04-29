import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/pet_provider.dart';
import '../../providers/connectivity_provider.dart';
import '../../widgets/charts/pet_drink_summary_chart.dart';
import '../../widgets/cards/pet_status_card.dart';
import '../../widgets/cards/device_status_card.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ติดตามการดื่มน้ำ'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.pushNamed(context, '/settings');
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          // รีเฟรชข้อมูลจาก Provider
          await Provider.of<PetProvider>(context, listen: false).refreshData();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // สถานะการเชื่อมต่อ
              Consumer<ConnectivityProvider>(
                builder: (context, connectivity, child) {
                  return DeviceStatusCard(
                    isConnected: connectivity.isConnected,
                    lastUpdated: connectivity.lastUpdated,
                    deviceInfo: connectivity.deviceInfo,
                  );
                },
              ),
              
              const SizedBox(height: 16),
              
              // สรุปการดื่มน้ำวันนี้
              const SizedBox(height: 16),

            const Text(
              'สรุปการดื่มน้ำวันนี้',
            style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
              ),
            ),

const SizedBox(height: 8),
              SizedBox(
                height: 200,
                child: Consumer<PetProvider>(
                  builder: (context, petProvider, child) {
                    return PetDrinkSummaryChart(
                      data: petProvider.getDailySummary(),
                    );
                  },
                ),
              ),
              
              const SizedBox(height: 24),
              
              // สถานะสัตว์เลี้ยง
              const Text(
                'สถานะสัตว์เลี้ยง',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Consumer<PetProvider>(
                builder: (context, petProvider, child) {
                  return Column(
                    children: petProvider.pets.map((pet) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: PetStatusCard(
                          pet: pet,
                          onTap: () {
                            Navigator.pushNamed(
                              context,
                              '/pet-detail',
                              arguments: pet.id,
                            );
                          },
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
              
              const SizedBox(height: 16),
              
              // ดูประวัติเพิ่มเติม
              Center(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.history),
                  label: const Text('ดูประวัติการดื่มน้ำ'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                  onPressed: () {
                    Navigator.pushNamed(context, '/history');
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}