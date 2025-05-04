import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/pet_provider.dart';
import '../../providers/connectivity_provider.dart';
import '../../widgets/charts/pet_drink_summary_chart.dart';
import '../../widgets/cards/pet_status_card.dart';
import '../../widgets/cards/device_status_card.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    
    // เช็คและลองเชื่อมต่อ MQTT เมื่อเปิดหน้าจอ
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Provider.of<ConnectivityProvider>(context, listen: false).checkConnectionStatus();
      }
    });
  }

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
          setState(() {
            _isRefreshing = true;
          });
          
          try {
            // รีเฟรชข้อมูลจาก Provider
            await Provider.of<PetProvider>(context, listen: false).refreshData();
            
            // ลองเชื่อมต่อ MQTT ใหม่ถ้ายังไม่ได้เชื่อมต่อ
            final connectivity = Provider.of<ConnectivityProvider>(context, listen: false);
            if (!connectivity.isConnected) {
              await connectivity.connect();
            }
          } catch (e) {
            // แสดงข้อความผิดพลาด
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('เกิดข้อผิดพลาดในการรีเฟรชข้อมูล: $e'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          } finally {
            if (mounted) {
              setState(() {
                _isRefreshing = false;
              });
            }
          }
        },
        child: Consumer2<PetProvider, ConnectivityProvider>(
          builder: (context, petProvider, connectivity, child) {
            if (petProvider.isLoading) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }
            
            if (petProvider.error != null) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Colors.red,
                      size: 48,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'เกิดข้อผิดพลาด',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      petProvider.error!,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        petProvider.refreshData();
                      },
                      child: const Text('ลองอีกครั้ง'),
                    ),
                  ],
                ),
              );
            }
            
            if (petProvider.pets.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.pets,
                      color: Colors.grey,
                      size: 48,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'ไม่พบข้อมูลสัตว์เลี้ยง',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        // ไปที่หน้าตั้งค่าเพื่อเพิ่มสัตว์เลี้ยง
                        Navigator.pushNamed(context, '/settings');
                      },
                      child: const Text('เพิ่มสัตว์เลี้ยง'),
                    ),
                  ],
                ),
              );
            }
            
            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // สถานะการเชื่อมต่อ
                  DeviceStatusCard(
                    isConnected: connectivity.isConnected,
                    lastUpdated: connectivity.lastUpdated,
                    deviceInfo: connectivity.deviceInfo,
                    onTap: () {
                      // พยายามเชื่อมต่อใหม่ถ้าไม่ได้เชื่อมต่ออยู่
                      if (!connectivity.isConnected) {
                        connectivity.connect();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('กำลังพยายามเชื่อมต่อ...'),
                          ),
                        );
                      }
                    },
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // สรุปการดื่มน้ำวันนี้
                  const SizedBox(height: 16),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'สรุปการดื่มน้ำวันนี้',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (_isRefreshing)
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: 8),
                  SizedBox(
                    height: 200,
                    child: petProvider.getDailySummary().isEmpty
                        ? const Center(
                            child: Text('ยังไม่มีการดื่มน้ำวันนี้'),
                          )
                        : PetDrinkSummaryChart(
                            data: petProvider.getDailySummary(),
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
                  Column(
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
            );
          },
        ),
      ),
    );
  }
}