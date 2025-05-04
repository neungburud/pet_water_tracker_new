// lib/screens/settings/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/connectivity_provider.dart';
import '../../providers/pet_provider.dart';
import '../../models/pet.dart'; // Import Pet model

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // MQTT Form Key and Controllers
  final _mqttFormKey = GlobalKey<FormState>();
  late TextEditingController _serverController;
  late TextEditingController _portController;
  late TextEditingController _usernameController;
  late TextEditingController _passwordController;
  late TextEditingController _clientIdController;
  bool _obscurePassword = true;
  bool _isMqttSubmitting = false;

  // Pet Add/Edit Dialog Form Key and Controllers
  final _petFormKey = GlobalKey<FormState>();
  final _petNameController = TextEditingController();
  final _petMacController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // ดึงค่าเริ่มต้นจาก Provider (ต้องทำใน initState)
    // ใช้ read เพราะไม่ต้องการ listen การเปลี่ยนแปลงใน initState
    final settings = context.read<SettingsProvider>();
    _serverController = TextEditingController(text: settings.mqttServer);
    _portController = TextEditingController(text: settings.mqttPort.toString());
    _usernameController = TextEditingController(text: settings.mqttUsername);
    _passwordController = TextEditingController(text: settings.mqttPassword);
    _clientIdController = TextEditingController(text: settings.mqttClientId);
  }

  @override
  void dispose() {
    // Dispose controllers ทั้งหมด
    _serverController.dispose();
    _portController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _clientIdController.dispose();
    _petNameController.dispose();
    _petMacController.dispose();
    super.dispose();
  }

  // --- Dialog สำหรับ เพิ่ม/แก้ไข สัตว์เลี้ยง ---
  Future<void> _showPetDialog({Pet? editingPet}) async {
    final bool isEditing = editingPet != null;
    _petNameController.text = isEditing ? editingPet.name : '';
    _petMacController.text = isEditing ? editingPet.macAddress : '';
    // ไม่ควรรีเซ็ต key ตรงนี้ เพราะอาจจะยังอยู่ในระหว่างการ build
    // _petFormKey.currentState?.reset();

    await showDialog<void>( // ใส่ await
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) { // ใช้ dialogContext แยกต่างหาก
        // อ่าน Provider โดยใช้ context ของ dialog
        final petProvider = Provider.of<PetProvider>(dialogContext, listen: false);
        bool isDialogSubmitting = false; // State เฉพาะใน Dialog

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(isEditing ? 'แก้ไขข้อมูลสัตว์เลี้ยง' : 'เพิ่มสัตว์เลี้ยงใหม่'),
              content: SingleChildScrollView(
                child: Form(
                  key: _petFormKey, // ใช้ key ที่ประกาศไว้
                  child: ListBody(
                    children: <Widget>[
                      TextFormField(
                        controller: _petNameController,
                        decoration: const InputDecoration(
                          labelText: 'ชื่อสัตว์เลี้ยง *',
                          icon: Icon(Icons.pets),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'กรุณาใส่ชื่อสัตว์เลี้ยง';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _petMacController,
                        decoration: const InputDecoration(
                          labelText: 'MAC Address (BLE Beacon) *',
                          hintText: 'XX:XX:XX:XX:XX:XX',
                          icon: Icon(Icons.bluetooth),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'กรุณาใส่ MAC Address';
                          }
                          final macRegex = RegExp(r'^([0-9A-Fa-f]{2}[:-]){5}([0-9A-Fa-f]{2})$');
                          if (!macRegex.hasMatch(value.trim())) {
                            return 'รูปแบบ MAC ไม่ถูกต้อง (เช่น aa:bb:cc:11:22:33)';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text('ยกเลิก'),
                  onPressed: () => Navigator.of(dialogContext).pop(), // ใช้ dialogContext
                ),
                ElevatedButton(
                  child: isDialogSubmitting
                      ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white,))
                      : Text(isEditing ? 'บันทึกการแก้ไข' : 'เพิ่ม'),
                  onPressed: isDialogSubmitting ? null : () async {
                    // Validate form ก่อน
                    if (_petFormKey.currentState?.validate() ?? false) {
                      setDialogState(() => isDialogSubmitting = true);

                      bool success = false;
                      final name = _petNameController.text.trim();
                      final mac = _petMacController.text.trim();

                      if (isEditing) {
                        success = await petProvider.updatePet(editingPet.id, name: name, macAddress: mac);
                      } else {
                        success = await petProvider.addPet(name, mac);
                      }

                      // ไม่ต้อง setState isDialogSubmitting = false ที่นี่ เพราะจะ pop dialog อยู่แล้ว

                      // ใช้ mounted ของ State หลัก (_SettingsScreenState) ในการเช็ค
                      if (mounted) {
                        Navigator.of(dialogContext).pop(); // ปิด Dialog ก่อนแสดง SnackBar
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(success
                                ? (isEditing ? 'แก้ไขข้อมูลสำเร็จ' : 'เพิ่มสัตว์เลี้ยงสำเร็จ')
                                : (petProvider.error ?? 'เกิดข้อผิดพลาดบางอย่าง')),
                            backgroundColor: success ? Colors.green : Colors.red,
                          ),
                        );
                      }
                    }
                  },
                ),
              ],
            );
          }
        );
      },
    );
     // เคลียร์ controller หลังจาก dialog ปิด (อาจจะไม่จำเป็นถ้าตั้งค่าใน initState)
     // _petNameController.clear();
     // _petMacController.clear();
  }

  // --- Dialog ยืนยันการลบ ---
  Future<void> _showDeleteConfirmationDialog(BuildContext context, Pet petToDelete) async {
     await showDialog<void>( // ใส่ await
       context: context,
       barrierDismissible: false,
       builder: (BuildContext dialogContext) { // ใช้ dialogContext
          final petProvider = Provider.of<PetProvider>(dialogContext, listen: false);
          bool isDialogDeleting = false; // State เฉพาะใน Dialog

         return StatefulBuilder(
           builder: (context, setDialogState) {
             return AlertDialog(
               title: const Text('ยืนยันการลบ'),
               content: SingleChildScrollView(
                 child: ListBody(
                   children: <Widget>[
                     Text('คุณแน่ใจหรือไม่ว่าต้องการลบ "${petToDelete.name}"?'),
                     const SizedBox(height: 8),
                     const Text('ประวัติการดื่มน้ำของสัตว์เลี้ยงตัวนี้จะถูกลบไปด้วย และไม่สามารถกู้คืนได้', style: TextStyle(color: Colors.red, fontSize: 12)),
                   ],
                 ),
               ),
               actions: <Widget>[
                 TextButton(
                   child: const Text('ยกเลิก'),
                   onPressed: isDialogDeleting ? null : () => Navigator.of(dialogContext).pop(), // ใช้ dialogContext
                 ),
                 ElevatedButton(
                   style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                   child: isDialogDeleting
                       ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                       : const Text('ลบ'),
                   onPressed: isDialogDeleting ? null : () async {
                      setDialogState(() => isDialogDeleting = true);
                      bool success = await petProvider.deletePet(petToDelete.id);
                      // ไม่ต้อง setState isDialogDeleting = false

                      if (mounted) { // เช็ค mounted ของ State หลัก
                          Navigator.of(dialogContext).pop(); // ปิด Dialog
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text(success ? 'ลบ ${petToDelete.name} สำเร็จ' : (petProvider.error ?? 'เกิดข้อผิดพลาดในการลบ')),
                                backgroundColor: success ? Colors.green : Colors.red,
                            ),
                          );
                      }
                   },
                 ),
               ],
             );
           }
         );
       },
     );
   }

  // --- Build Method ---
  @override
  Widget build(BuildContext context) {
    // ใช้ Watch เพื่อให้ rebuild เมื่อ Provider มีการเปลี่ยนแปลง
    final settings = context.watch<SettingsProvider>();
    final connectivity = context.watch<ConnectivityProvider>();
    final petProvider = context.watch<PetProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('การตั้งค่า'),
      ),
      body: SingleChildScrollView( // ใช้ SingleChildScrollView ครอบเพื่อให้เลื่อนได้ทั้งหมด
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch, // ทำให้ Card เต็มความกว้าง
          children: [
            // --- ส่วนจัดการสัตว์เลี้ยง ---
            _buildSectionTitle(context, 'จัดการสัตว์เลี้ยง'),
            _buildPetManagementSection(context, petProvider),
            const SizedBox(height: 24),

            // --- ส่วนการตั้งค่า MQTT ---
            _buildSectionTitle(context, 'การตั้งค่า MQTT'),
            _buildMqttSection(context, settings, connectivity),
            const SizedBox(height: 24),

            // --- ส่วนการแจ้งเตือน ---
            _buildSectionTitle(context, 'การแจ้งเตือน'),
            _buildNotificationSection(context, settings),
            const SizedBox(height: 24),

            // --- ส่วน Theme ---
            _buildSectionTitle(context, 'ธีมแอปพลิเคชัน'),
            _buildThemeSection(context, settings),
            const SizedBox(height: 24),

            // --- ส่วน Data ---
            _buildSectionTitle(context, 'การบันทึกข้อมูล'),
            _buildDataSection(context, settings, petProvider),
            const SizedBox(height: 24),

            // --- ส่วน About ---
            _buildSectionTitle(context, 'เกี่ยวกับแอป'),
            _buildAboutSection(context),
          ],
        ),
      ),
    );
  }

  // --- Helper Widget: Section Title ---
  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }


  // --- Widget ใหม่: ส่วนจัดการสัตว์เลี้ยง ---
  Widget _buildPetManagementSection(BuildContext context, PetProvider petProvider) {
    final pets = petProvider.pets;
    final isLoading = petProvider.isLoading;

    return Card(
       margin: EdgeInsets.zero, // เอา margin ของ Card ออก
       elevation: 2,
      child: Column(
        children: [
           Padding(
             padding: const EdgeInsets.only(left: 16.0, right: 8.0, top: 8.0, bottom: 0), // ปรับ padding
             child: Row(
               mainAxisAlignment: MainAxisAlignment.spaceBetween,
               children: [
                 Text('รายการสัตว์เลี้ยง (${pets.length})', style: Theme.of(context).textTheme.titleMedium),
                  // ใช้ SizedBox เพื่อคุมขนาด loading indicator
                  SizedBox(
                    height: 30,
                    width: 30,
                    child: isLoading
                        ? const Padding(padding: EdgeInsets.all(5.0), child: CircularProgressIndicator(strokeWidth: 2))
                        : IconButton(
                            icon: const Icon(Icons.add_circle),
                            color: Colors.green,
                            tooltip: 'เพิ่มสัตว์เลี้ยง',
                            onPressed: () => _showPetDialog(),
                            padding: EdgeInsets.zero, // ลด padding ของ IconButton
                            iconSize: 28, // ปรับขนาดไอคอน
                          ),
                  ),
               ],
             ),
           ),
           const Divider(height: 1), // เส้นคั่น
          if (pets.isEmpty && !isLoading)
            const ListTile(
              title: Center(child: Text('ไม่มีสัตว์เลี้ยง\nกด + เพื่อเพิ่ม', textAlign: TextAlign.center)),
              contentPadding: EdgeInsets.symmetric(vertical: 20),
            )
          else if (!isLoading) // แสดง ListView เฉพาะตอนไม่โหลด
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: pets.length,
              itemBuilder: (context, index) {
                final pet = pets[index];
                return ListTile(
                  leading: CircleAvatar(child: Text('${index + 1}')), // แสดงลำดับ
                  title: Text(pet.name),
                  subtitle: Text(pet.macAddress, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_note, color: Colors.orange),
                        tooltip: 'แก้ไข',
                        onPressed: isLoading ? null : () => _showPetDialog(editingPet: pet),
                        splashRadius: 20, // ลดขนาด splash
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                        tooltip: 'ลบ',
                        onPressed: isLoading ? null : () => _showDeleteConfirmationDialog(context, pet),
                        splashRadius: 20,
                      ),
                    ],
                  ),
                  dense: true, // ทำให้ ListTile แน่นขึ้น
                );
              },
               separatorBuilder: (context, index) => const Divider(height: 1, indent: 70), // เส้นคั่นเยื้องเข้ามา
            ),
            // แสดง Loading indicator ตรงกลาง Card ถ้ากำลังโหลด
            if (isLoading && pets.isEmpty)
               const Padding(
                 padding: EdgeInsets.symmetric(vertical: 30.0),
                 child: Center(child: CircularProgressIndicator()),
               ),
           // แสดงข้อความ Error ด้านล่าง Card
           if (petProvider.error != null && !isLoading)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Text(
                  'ข้อผิดพลาด: ${petProvider.error}',
                  style: const TextStyle(color: Colors.red, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ),
        ],
      ),
    );
  }

  // --- Widget: ส่วน MQTT ---
  Widget _buildMqttSection( BuildContext context, SettingsProvider settings, ConnectivityProvider connectivity) {
    return Card(
       margin: EdgeInsets.zero,
       elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _mqttFormKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch, // ทำให้ปุ่มเต็มความกว้าง
            children: [
               TextFormField(
                 controller: _serverController,
                 enabled: !_isMqttSubmitting && !connectivity.isConnected, // Disable ถ้ากำลัง submit หรือต่ออยู่
                 decoration: const InputDecoration(labelText: 'MQTT Server *', helperText: 'เช่น broker.hivemq.com', border: OutlineInputBorder()),
                 validator: (value) => (value == null || value.trim().isEmpty) ? 'กรุณาระบุ MQTT Server' : null,
               ),
               const SizedBox(height: 16),
               TextFormField(
                 controller: _portController,
                 enabled: !_isMqttSubmitting && !connectivity.isConnected,
                 decoration: const InputDecoration(labelText: 'Port *', helperText: 'เช่น 1883 หรือ 8883 (SSL)', border: OutlineInputBorder()),
                 keyboardType: TextInputType.number,
                 validator: (value) {
                   if (value == null || value.trim().isEmpty) return 'กรุณาระบุพอร์ต';
                   if (int.tryParse(value.trim()) == null) return 'กรุณาระบุเป็นตัวเลขเท่านั้น';
                   return null;
                 },
               ),
               const SizedBox(height: 16),
               TextFormField(
                 controller: _usernameController,
                 enabled: !_isMqttSubmitting && !connectivity.isConnected,
                 decoration: const InputDecoration(labelText: 'Username', border: OutlineInputBorder()),
               ),
               const SizedBox(height: 16),
               TextFormField(
                 controller: _passwordController,
                 enabled: !_isMqttSubmitting && !connectivity.isConnected,
                 obscureText: _obscurePassword,
                 decoration: InputDecoration(
                   labelText: 'Password',
                   border: const OutlineInputBorder(),
                   suffixIcon: IconButton(
                     icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                     onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                   ),
                 ),
               ),
               const SizedBox(height: 16),
               TextFormField(
                 controller: _clientIdController,
                 enabled: !_isMqttSubmitting && !connectivity.isConnected,
                 decoration: const InputDecoration(labelText: 'Client ID', helperText: 'เว้นว่างเพื่อใช้ค่าอัตโนมัติ', border: OutlineInputBorder()),
               ),
              const SizedBox(height: 24),
              // --- ส่วนปุ่มและสถานะ ---
               Column( // ใช้ Column ให้ปุ่มอยู่คนละบรรทัดกับสถานะ
                 crossAxisAlignment: CrossAxisAlignment.stretch,
                 children: [
                   ElevatedButton(
                      onPressed: _isMqttSubmitting || connectivity.isConnected ? null : () async { // ปิดปุ่มถ้าต่ออยู่
                        if (_mqttFormKey.currentState?.validate() ?? false) {
                          setState(() => _isMqttSubmitting = true);
                          try {
                            await settings.saveMqttSettings(
                              server: _serverController.text.trim(),
                              port: int.parse(_portController.text.trim()),
                              username: _usernameController.text.trim(),
                              password: _passwordController.text,
                              clientId: _clientIdController.text.trim(),
                            );
                             if (mounted) {
                                 ScaffoldMessenger.of(context).showSnackBar(
                                   const SnackBar(content: Text('บันทึกการตั้งค่า MQTT เรียบร้อย')),
                                 );
                                 // ลองเชื่อมต่อใหม่หลังบันทึก
                                 if (!connectivity.isConnected) {
                                      connectivity.connect();
                                 }
                             }
                          } catch (e) {
                             if (mounted) {
                                 ScaffoldMessenger.of(context).showSnackBar(
                                   SnackBar(content: Text('เกิดข้อผิดพลาด: $e'), backgroundColor: Colors.red),
                                 );
                             }
                          } finally {
                               if (mounted) setState(() => _isMqttSubmitting = false);
                          }
                        }
                      },
                      child: _isMqttSubmitting
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text('บันทึกและเชื่อมต่อ'),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                       onPressed: _isMqttSubmitting ? null : (connectivity.isConnected ? connectivity.disconnect : null), // ปุ่มนี้ใช้ตัดการเชื่อมต่อเท่านั้น
                       style: ElevatedButton.styleFrom(
                         backgroundColor: connectivity.isConnected ? Colors.red : Colors.grey, // สีแดงเมื่อต่อ, เทาเมื่อไม่ต่อ
                         foregroundColor: Colors.white,
                       ),
                       child: Text(connectivity.isConnected ? 'ตัดการเชื่อมต่อ' : 'ไม่ได้เชื่อมต่อ'),
                     ),
                 ],
               ),
              // --- สถานะการเชื่อมต่อ ---
               if (connectivity.isConnected)
                 Padding(
                   padding: const EdgeInsets.only(top: 12.0),
                   child: Center(child: Text('สถานะ: เชื่อมต่อแล้ว (${settings.mqttServer})', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold))),
                 ),
               if (connectivity.lastConnectionError != null && !connectivity.isConnected)
                 Padding(
                   padding: const EdgeInsets.only(top: 12.0),
                   child: Center(child: Text('ข้อผิดพลาด: ${connectivity.lastConnectionError}', style: const TextStyle(color: Colors.red, fontSize: 12))),
                 ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Widget: ส่วน Notification ---
   Widget _buildNotificationSection(BuildContext context, SettingsProvider settings) {
      return Card(
         margin: EdgeInsets.zero,
         elevation: 2,
        child: Column(
          children: [
            SwitchListTile(
              title: const Text('แจ้งเตือนเมื่อดื่มน้ำ'),
              subtitle: const Text('เมื่อเริ่มหรือเลิกดื่มน้ำ'),
              value: settings.notifyWhenDrinking,
              onChanged: (value) => settings.setNotifyWhenDrinking(value),
              dense: true,
            ),
            const Divider(height: 1, indent: 16, endIndent: 16),
            SwitchListTile(
              title: const Text('แจ้งเตือนเมื่อไม่ดื่มน้ำ'),
              subtitle: const Text('หากไม่ดื่มนานเกินไป (ยังไม่実装)'),
              value: settings.notifyWhenNotDrinking,
              onChanged: (value) => settings.setNotifyWhenNotDrinking(value),
              dense: true,
            ),
             const Divider(height: 1, indent: 16, endIndent: 16),
            SwitchListTile(
              title: const Text('แจ้งเตือนเมื่อเชื่อมต่อ'),
              subtitle: const Text('เมื่ออุปกรณ์เชื่อมต่อ/ขาดการเชื่อมต่อ'),
              value: settings.notifyWhenDisconnected,
              onChanged: (value) => settings.setNotifyWhenDisconnected(value),
               dense: true,
            ),
          ],
        ),
      );
    }

  // --- Widget: ส่วน Theme ---
   Widget _buildThemeSection(BuildContext context, SettingsProvider settings) {
      return Card(
         margin: EdgeInsets.zero,
         elevation: 2,
        child: Column(
          children: [
            RadioListTile<ThemeMode>(
              title: const Text('ธีมตามระบบ'),
              value: ThemeMode.system,
              groupValue: settings.themeMode,
              onChanged: (value) => settings.setThemeMode(value ?? ThemeMode.system),
               dense: true,
            ),
             const Divider(height: 1, indent: 16, endIndent: 16),
            RadioListTile<ThemeMode>(
              title: const Text('ธีมสว่าง'),
              value: ThemeMode.light,
              groupValue: settings.themeMode,
              onChanged: (value) => settings.setThemeMode(value ?? ThemeMode.light),
               dense: true,
            ),
             const Divider(height: 1, indent: 16, endIndent: 16),
            RadioListTile<ThemeMode>(
              title: const Text('ธีมมืด'),
              value: ThemeMode.dark,
              groupValue: settings.themeMode,
              onChanged: (value) => settings.setThemeMode(value ?? ThemeMode.dark),
               dense: true,
            ),
          ],
        ),
      );
    }

  // --- Widget: ส่วน Data ---
   Widget _buildDataSection(BuildContext context, SettingsProvider settings, PetProvider petProvider) {
       bool isProcessingData = petProvider.isLoading;

      return Card(
         margin: EdgeInsets.zero,
         elevation: 2,
        child: Column(
          children: [
            ListTile(
              title: const Text('ระยะเวลาเก็บประวัติ'),
              trailing: DropdownButton<int>(
                value: settings.dataRetentionDays,
                underline: Container(), // เอาเส้นใต้ของ Dropdown ออก
                items: [7, 30, 90, 180, 365].map((days) => DropdownMenuItem(
                    value: days,
                    child: Text('$days วัน'),
                )).toList(),
                onChanged: isProcessingData ? null : (value) {
                  if (value != null) settings.setDataRetentionDays(value);
                },
              ),
               dense: true,
            ),
             const Divider(height: 1, indent: 16, endIndent: 16),
            ListTile(
              leading: Icon(Icons.delete_sweep_outlined, color: Colors.red[700]),
              title: Text('ล้างประวัติการดื่มน้ำ', style: TextStyle(color: Colors.red[700])),
              subtitle: const Text('ลบข้อมูลการดื่มน้ำทั้งหมด', style: TextStyle(fontSize: 12)),
              onTap: isProcessingData ? null : () {
                  showDialog(
                    context: context,
                    builder: (dialogContext) => AlertDialog(
                      title: const Text('ยืนยันการล้างประวัติ'),
                      content: const Text('ข้อมูลประวัติการดื่มน้ำทั้งหมดจะถูกลบ และไม่สามารถกู้คืนได้'),
                      actions: [
                        TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('ยกเลิก')),
                        TextButton(
                          onPressed: () async {
                            Navigator.of(dialogContext).pop();
                            await petProvider.clearAllData();
                            if(mounted){
                                 ScaffoldMessenger.of(context).showSnackBar(
                                     SnackBar(
                                         content: Text(petProvider.error == null ? 'ล้างประวัติสำเร็จ' : 'เกิดข้อผิดพลาด'),
                                         backgroundColor: petProvider.error == null ? Colors.green : Colors.red,
                                     ),
                                 );
                            }
                          },
                          style: TextButton.styleFrom(foregroundColor: Colors.red),
                          child: const Text('ยืนยัน'),
                        ),
                      ],
                    ),
                  );
                },
               dense: true,
            ),
          ],
        ),
      );
    }

  // --- Widget: ส่วน About ---
   Widget _buildAboutSection(BuildContext context) {
     return Card(
        margin: EdgeInsets.zero,
        elevation: 2,
       child: Column(
         children: [
           const ListTile(
             leading: Icon(Icons.info_outline),
             title: Text('เวอร์ชัน'),
             subtitle: Text('1.0.1'), // อาจจะดึงจาก package_info_plus
             dense: true,
           ),
           const Divider(height: 1, indent: 70),
           ListTile(
             leading: Icon(Icons.code),
             title: Text('ผู้พัฒนา'),
             subtitle: Text('Pet Drinking Monitor'),
              dense: true,
              onTap: () { /* Maybe link somewhere */ },
           ),
         ],
       ),
     );
   }

} // End of _SettingsScreenState