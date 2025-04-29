import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/connectivity_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // สำหรับการตั้งค่า MQTT
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _serverController;
  late TextEditingController _portController;
  late TextEditingController _usernameController;
  late TextEditingController _passwordController;
  late TextEditingController _clientIdController;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    // ดึงการตั้งค่าปัจจุบัน
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    
    _serverController = TextEditingController(text: settings.mqttServer);
    _portController = TextEditingController(text: settings.mqttPort.toString());
    _usernameController = TextEditingController(text: settings.mqttUsername);
    _passwordController = TextEditingController(text: settings.mqttPassword);
    _clientIdController = TextEditingController(text: settings.mqttClientId);
  }

  @override
  void dispose() {
    _serverController.dispose();
    _portController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _clientIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('การตั้งค่า'),
      ),
      body: Consumer2<SettingsProvider, ConnectivityProvider>(
        builder: (context, settings, connectivity, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ส่วนการตั้งค่า MQTT
                const Text(
                  'การตั้งค่า MQTT',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _serverController,
                            decoration: const InputDecoration(
                              labelText: 'MQTT Server',
                              helperText: 'เช่น broker.hivemq.com',
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'กรุณาระบุ MQTT Server';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _portController,
                            decoration: const InputDecoration(
                              labelText: 'Port',
                              helperText: 'เช่น 1883 หรือ 8883 (SSL)',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'กรุณาระบุพอร์ต';
                              }
                              if (int.tryParse(value) == null) {
                                return 'กรุณาระบุเป็นตัวเลขเท่านั้น';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _usernameController,
                            decoration: const InputDecoration(
                              labelText: 'Username',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            decoration: InputDecoration(
                              labelText: 'Password',
                              border: const OutlineInputBorder(),
                              suffixIcon: IconButton(
                                icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _clientIdController,
                            decoration: const InputDecoration(
                              labelText: 'Client ID',
                              helperText: 'เว้นว่างเพื่อใช้ค่าอัตโนมัติ',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () async {
                                    if (_formKey.currentState!.validate()) {
                                      // บันทึกการตั้งค่า
                                      await settings.saveMqttSettings(
                                        server: _serverController.text,
                                        port: int.parse(_portController.text),
                                        username: _usernameController.text,
                                        password: _passwordController.text,
                                        clientId: _clientIdController.text,
                                      );
                                      
                                      // แสดงข้อความยืนยัน
                                      if (mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('บันทึกการตั้งค่าเรียบร้อย'),
                                          ),
                                        );
                                      }
                                    }
                                  },
                                  child: const Text('บันทึก'),
                                ),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton(
                                onPressed: connectivity.isConnected
                                    ? () {
                                        // ตัดการเชื่อมต่อเดิม
                                        connectivity.disconnect();
                                      }
                                    : () {
                                        // เชื่อมต่อใหม่
                                        connectivity.connect();
                                      },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: connectivity.isConnected
                                      ? Colors.red
                                      : Colors.green,
                                ),
                                child: Text(
                                  connectivity.isConnected ? 'ตัดการเชื่อมต่อ' : 'เชื่อมต่อ',
                                ),
                              ),
                            ],
                          ),
                          if (connectivity.isConnected)
                            Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                'เชื่อมต่อแล้ว: ${settings.mqttServer}',
                                style: const TextStyle(
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // การตั้งค่าการแจ้งเตือน
                const Text(
                  'การแจ้งเตือน',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Card(
                  child: Column(
                    children: [
                      SwitchListTile(
                        title: const Text('แจ้งเตือนเมื่อสัตว์เลี้ยงดื่มน้ำ'),
                        subtitle: const Text('แจ้งเตือนทุกครั้งที่สัตว์เลี้ยงเริ่มดื่มน้ำ'),
                        value: settings.notifyWhenDrinking,
                        onChanged: (value) {
                          settings.setNotifyWhenDrinking(value);
                        },
                      ),
                      const Divider(height: 1),
                      SwitchListTile(
                        title: const Text('แจ้งเตือนเมื่อไม่ดื่มน้ำเป็นเวลานาน'),
                        subtitle: const Text('แจ้งเตือนหากสัตว์เลี้ยงไม่ดื่มน้ำเกิน 8 ชั่วโมง'),
                        value: settings.notifyWhenNotDrinking,
                        onChanged: (value) {
                          settings.setNotifyWhenNotDrinking(value);
                        },
                      ),
                      const Divider(height: 1),
                      SwitchListTile(
                        title: const Text('แจ้งเตือนเมื่อขาดการเชื่อมต่อ'),
                        subtitle: const Text('แจ้งเตือนเมื่ออุปกรณ์ ESP32 ขาดการเชื่อมต่อนานเกิน 5 นาที'),
                        value: settings.notifyWhenDisconnected,
                        onChanged: (value) {
                          settings.setNotifyWhenDisconnected(value);
                        },
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // การบันทึกข้อมูล
                const Text(
                  'การบันทึกข้อมูล',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Card(
                  child: Column(
                    children: [
                      ListTile(
                        title: const Text('ระยะเวลาการเก็บข้อมูล'),
                        subtitle: Text('${settings.dataRetentionDays} วัน'),
                        trailing: PopupMenuButton<int>(
                          onSelected: (value) {
                            settings.setDataRetentionDays(value);
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 7,
                              child: Text('7 วัน'),
                            ),
                            const PopupMenuItem(
                              value: 30,
                              child: Text('30 วัน'),
                            ),
                            const PopupMenuItem(
                              value: 90,
                              child: Text('90 วัน'),
                            ),
                            const PopupMenuItem(
                              value: 365,
                              child: Text('1 ปี'),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        title: const Text('ล้างข้อมูลทั้งหมด'),
                        subtitle: const Text('ลบประวัติการดื่มน้ำทั้งหมด'),
                        trailing: ElevatedButton(
                          onPressed: () {
                            // แสดงกล่องยืนยันก่อนลบข้อมูล
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('ยืนยันการลบข้อมูล'),
                                content: const Text('คุณแน่ใจหรือไม่ว่าต้องการลบข้อมูลทั้งหมด? การกระทำนี้ไม่สามารถเรียกคืนได้'),
                                actions: [
                                  TextButton(
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                    },
                                    child: const Text('ยกเลิก'),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      settings.clearAllData();
                                      Navigator.of(context).pop();
                                      // แสดงข้อความยืนยัน
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('ลบข้อมูลทั้งหมดเรียบร้อย'),
                                        ),
                                      );
                                    },
                                    style: TextButton.styleFrom(
                                      foregroundColor: Colors.red,
                                    ),
                                    child: const Text('ลบข้อมูล'),
                                  ),
                                ],
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                          ),
                          child: const Text('ล้างข้อมูล'),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // เกี่ยวกับแอป
                const Text(
                  'เกี่ยวกับแอป',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Card(
                  child: Column(
                    children: [
                      const ListTile(
                        title: Text('เวอร์ชัน'),
                        subtitle: Text('1.0.0'),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        title: const Text('ผู้พัฒนา'),
                        subtitle: const Text('ระบบติดตามการดื่มน้ำของสัตว์เลี้ยง'),
                        onTap: () {
                          // เพิ่มการเปิดเว็บไซต์หรือข้อมูลเพิ่มเติมได้ที่นี่
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}