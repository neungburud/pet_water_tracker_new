import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DeviceStatusCard extends StatelessWidget {
  final bool isConnected;
  final DateTime? lastUpdated;
  final String deviceInfo;
  final VoidCallback? onTap;

  const DeviceStatusCard({
    Key? key,
    required this.isConnected,
    required this.lastUpdated,
    required this.deviceInfo,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              // ไอคอนสถานะ
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: isConnected
                      ? Colors.green.withOpacity(0.2)
                      : Colors.red.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(
                    isConnected ? Icons.check_circle : Icons.error,
                    size: 30,
                    color: isConnected ? Colors.green : Colors.red,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              
              // ข้อมูลสถานะ
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isConnected ? 'อุปกรณ์ทำงานปกติ' : 'ไม่สามารถเชื่อมต่อได้',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (lastUpdated != null)
                      Text(
                        'อัปเดตล่าสุด: ${_formatDateTime(lastUpdated!)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    if (isConnected && deviceInfo.isNotEmpty)
                      Text(
                        deviceInfo,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    if (!isConnected)
                      Text(
                        'แตะเพื่อลองเชื่อมต่อใหม่',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue.shade700,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                  ],
                ),
              ),
              
              // ปุ่มรีเฟรช
              if (onTap != null && !isConnected)
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: onTap,
                  tooltip: 'ลองเชื่อมต่อใหม่',
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final formattedDate = DateFormat('dd/MM/yyyy HH:mm').format(dateTime);
    final diff = DateTime.now().difference(dateTime);
    
    if (diff.inMinutes < 1) {
      return 'เมื่อไม่กี่วินาทีที่แล้ว';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes} นาทีที่แล้ว';
    } else if (diff.inHours < 24) {
      return '${diff.inHours} ชั่วโมงที่แล้ว';
    } else {
      return formattedDate;
    }
  }
}