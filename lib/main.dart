import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
//import 'package:flutter_local_notifications/flutter_local_notifications.dart';

//import 'services/notification_service.dart';
import 'providers/pet_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/connectivity_provider.dart';
import 'screens/dashboard/dashboard_screen.dart';
import 'screens/history/history_screen.dart';
import 'screens/pet_detail/pet_detail_screen.dart';
import 'screens/settings/settings_screen.dart';
import 'config/theme_config.dart';

void main() async {
  // ต้อง ensure initialized ก่อนเรียก native code
  WidgetsFlutterBinding.ensureInitialized();
  
  // เริ่มต้นบริการแจ้งเตือน
  //final notificationService = NotificationService();
  //await notificationService.init();
  
  // runApp(MyApp(notificationService: notificationService));
  runApp(const MyApp());  // เพิ่มบรรทัดนี้
}

class MyApp extends StatelessWidget {
  //final NotificationService notificationService;
  
  const MyApp({
    Key? key,
    //required this.notificationService,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Provider จัดการการตั้งค่า
        ChangeNotifierProvider(
          create: (_) => SettingsProvider(),
        ),
        
        // Provider จัดการข้อมูลสัตว์เลี้ยง
        ChangeNotifierProvider(
          create: (_) => PetProvider(),
        ),
        
        // Provider จัดการการเชื่อมต่อ MQTT (ขึ้นกับ settings และ pet)
        ChangeNotifierProxyProvider2<SettingsProvider, PetProvider, ConnectivityProvider>(
          create: (context) => ConnectivityProvider(
            settingsProvider: Provider.of<SettingsProvider>(context, listen: false),
            petProvider: Provider.of<PetProvider>(context, listen: false),
            // notificationService: notificationService,  // แก้ไขบรรทัดนี้
          ),
          update: (context, settings, pets, previous) => previous!,
        ),
      ],
      child: MaterialApp(
        title: 'ติดตามการดื่มน้ำของสัตว์เลี้ยง',
        theme: ThemeConfig.lightTheme,
        darkTheme: ThemeConfig.darkTheme,
        themeMode: ThemeMode.system,
        initialRoute: '/',
        routes: {
          '/': (context) => const DashboardScreen(),
          '/history': (context) => const HistoryScreen(),
          '/pet-detail': (context) => const PetDetailScreen(),
          '/settings': (context) => const SettingsScreen(),
        },
      ),
    );
  }
}