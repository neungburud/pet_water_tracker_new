import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/pet_provider.dart';
import '../../widgets/charts/history_chart.dart';
import '../../models/drinking_record.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({Key? key}) : super(key: key);

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedPetIndex = 0;
  String _selectedPeriod = 'day'; // day, week, month

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {
          switch (_tabController.index) {
            case 0:
              _selectedPeriod = 'day';
              break;
            case 1:
              _selectedPeriod = 'week';
              break;
            case 2:
              _selectedPeriod = 'month';
              break;
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ประวัติการดื่มน้ำ'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'รายวัน'),
            Tab(text: 'รายสัปดาห์'),
            Tab(text: 'รายเดือน'),
          ],
        ),
      ),
      body: Consumer<PetProvider>(
        builder: (context, petProvider, child) {
          final pets = petProvider.pets;
          
          if (pets.isEmpty) {
            return const Center(
              child: Text('ไม่พบข้อมูลสัตว์เลี้ยง'),
            );
          }

          // สร้างตัวเลือกสัตว์เลี้ยง
          final petSelectionWidget = Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('เลือกสัตว์เลี้ยง: '),
                const SizedBox(width: 8),
                DropdownButton<int>(
                  value: _selectedPetIndex,
                  items: List.generate(pets.length, (index) {
                    return DropdownMenuItem<int>(
                      value: index,
                      child: Text(pets[index].name),
                    );
                  }),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedPetIndex = value;
                      });
                    }
                  },
                ),
              ],
            ),
          );

          // ดึงข้อมูลประวัติการดื่มน้ำตามช่วงเวลาที่เลือก
          final selectedPet = pets[_selectedPetIndex];
          List<DrinkingRecord> records;
          String periodLabel;
          
          switch (_selectedPeriod) {
            case 'day':
              records = petProvider.getDailyHistory(selectedPet.id);
              periodLabel = 'วันนี้';
              break;
            case 'week':
              records = petProvider.getWeeklyHistory(selectedPet.id);
              periodLabel = '7 วันล่าสุด';
              break;
            case 'month':
              records = petProvider.getMonthlyHistory(selectedPet.id);
              periodLabel = '30 วันล่าสุด';
              break;
            default:
              records = petProvider.getDailyHistory(selectedPet.id);
              periodLabel = 'วันนี้';
          }

          // สร้างสรุปข้อมูล
          final totalDrinks = records.length;
          final totalDuration = records.fold(0, (sum, record) => sum + record.duration);
          final avgDuration = totalDrinks > 0 ? totalDuration ~/ totalDrinks : 0;

          return Column(
            children: [
              petSelectionWidget,
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // รายวัน
                    _buildHistoryContent(context, records, periodLabel, totalDrinks, avgDuration, petProvider, selectedPet.id, 'day'),
                    // รายสัปดาห์
                    _buildHistoryContent(context, records, periodLabel, totalDrinks, avgDuration, petProvider, selectedPet.id, 'week'),
                    // รายเดือน
                    _buildHistoryContent(context, records, periodLabel, totalDrinks, avgDuration, petProvider, selectedPet.id, 'month'),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHistoryContent(
    BuildContext context,
    List<DrinkingRecord> records,
    String periodLabel,
    int totalDrinks,
    int avgDuration,
    PetProvider petProvider,
    String petId,
    String period,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // สรุปข้อมูล
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Text(
                    'สรุปการดื่มน้ำ ($periodLabel)',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildSummaryItem(
                        context,
                        'จำนวนครั้ง',
                        '$totalDrinks ครั้ง',
                        Icons.local_drink,
                      ),
                      _buildSummaryItem(
                        context,
                        'เวลาเฉลี่ย',
                        '$avgDuration วินาที',
                        Icons.timer,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // กราฟแสดงข้อมูล
          const Text(
            'กราฟการดื่มน้ำ',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 250,
            child: HistoryChart(
              petId: petId,
              period: period,
              data: petProvider.getChartData(petId, period),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // รายการประวัติ
          const Text(
            'รายการล่าสุด',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          records.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text('ไม่พบรายการดื่มน้ำในช่วงเวลานี้'),
                  ),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: records.length,
                  itemBuilder: (context, index) {
                    final record = records[index];
                    return Card(
                      child: ListTile(
                        leading: const Icon(Icons.water_drop),
                        title: Text('ดื่มน้ำนาน ${record.duration} วินาที'),
                        subtitle: Text(
                          _formatDateTime(record.timestamp),
                        ),
                      ),
                    );
                  },
                ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    return Column(
      children: [
        Icon(icon, size: 30, color: Theme.of(context).primaryColor),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}