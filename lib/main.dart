import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart'; // Import สำหรับ format ภาษาไทย
import 'package:provider/provider.dart';

import 'services/notification_service.dart';
import 'providers/pet_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/connectivity_provider.dart';
import 'screens/dashboard/dashboard_screen.dart';
import 'screens/history/history_screen.dart';
import 'screens/pet_detail/pet_detail_screen.dart';
import 'screens/settings/settings_screen.dart';
import 'config/theme_config.dart';

// สร้าง Key สำหรับเก็บอ้างอิงถึง GlobalScaffold
final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
// GlobalKey สำหรับ Navigator (ถ้าต้องการเข้าถึง context จากนอก Widget tree)
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  // ต้อง ensure initialized ก่อนเรียก native code หรือ plugin
  WidgetsFlutterBinding.ensureInitialized();

  // เริ่มต้นข้อมูล locale สำหรับ intl package (สำคัญสำหรับ DateFormat ภาษาไทย)
  await initializeDateFormatting('th', null);

  // เริ่มต้นบริการแจ้งเตือน
  final notificationService = NotificationService();
  await notificationService.init();

  runApp(MyApp(notificationService: notificationService));
}

class MyApp extends StatelessWidget {
  final NotificationService notificationService;

  const MyApp({
    Key? key,
    required this.notificationService,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Provider จัดการการตั้งค่า
        ChangeNotifierProvider(
          create: (_) => SettingsProvider(),
        ),

        // Provider จัดการข้อมูลสัตว์เลี้ยง (ขึ้นกับ SettingsProvider)
        // ใช้ ChangeNotifierProxyProvider เพื่อให้ PetProvider เข้าถึง SettingsProvider ได้
        ChangeNotifierProxyProvider<SettingsProvider, PetProvider>(
           create: (_) => PetProvider(), // สร้าง PetProvider เปล่าๆ ก่อน
           update: (context, settings, previousPetProvider) {
             // เมื่อ SettingsProvider เปลี่ยน หรือ PetProvider ถูกสร้างครั้งแรก
             // ส่ง reference ของ settings ไปให้ PetProvider
             previousPetProvider?.updateSettingsProvider(settings);
             return previousPetProvider!; // คืนค่า PetProvider เดิมที่อัปเดตแล้ว
           } ,
        ),

        // Provider จัดการการเชื่อมต่อ MQTT (ขึ้นกับ settings และ pet)
        ChangeNotifierProxyProvider2<SettingsProvider, PetProvider, ConnectivityProvider>(
          create: (context) => ConnectivityProvider(
            // อ่านค่า provider ตอนสร้าง โดย listen: false
            settingsProvider: Provider.of<SettingsProvider>(context, listen: false),
            petProvider: Provider.of<PetProvider>(context, listen: false),
            notificationService: notificationService,
          ),
          // update ไม่จำเป็นต้องทำอะไร เพราะเราส่ง reference ตอน create แล้ว
          // แต่ถ้า ConnectivityProvider ต้อง react ต่อการเปลี่ยนแปลงของ Settings/Pet ก็ใส่ logic ที่นี่
          update: (context, settings, pets, previousConnectivity) => previousConnectivity!,
        ),
      ],
      child: Consumer<SettingsProvider>(
        builder: (context, settings, _) {
          return MaterialApp(
            navigatorKey: navigatorKey, // ตั้งค่า key สำหรับ navigator
            scaffoldMessengerKey: _scaffoldMessengerKey, // เพิ่ม key สำหรับแสดง SnackBar ได้จากทั่วแอป
            title: 'Pet Drinking Monitor', // เปลี่ยนชื่อ Title
            theme: ThemeConfig.lightTheme,
            darkTheme: ThemeConfig.darkTheme,
            themeMode: settings.themeMode, // ใช้ ThemeMode จาก settings
            initialRoute: '/',
            routes: {
              '/': (context) => const DashboardScreen(),
              '/history': (context) => const HistoryScreen(),
              '/pet-detail': (context) => const PetDetailScreen(),
              '/settings': (context) => const SettingsScreen(),
            },
            // ตั้งค่า locale เริ่มต้น (ถ้าต้องการ)
            // locale: Locale('th', 'TH'),
            // supportedLocales: [ Locale('th', 'TH'), Locale('en', 'US'), ],
            debugShowCheckedModeBanner: false, // ปิด Banner Debug
          );
        }
      ),
    );
  }
}