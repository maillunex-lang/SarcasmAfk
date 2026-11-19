import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import 'screens/menu_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Help headless / a11y tooling find buttons on Flutter web.
  // ignore: deprecated_member_use
  WidgetsBinding.instance.ensureSemantics();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);
  runApp(const BashLegendsApp());
}

class BashLegendsApp extends StatelessWidget {
  const BashLegendsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'БашЛегенды · Flame',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF070A12),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFC9A227),
          secondary: Color(0xFF4ECDC4),
          surface: Color(0xFF1A2238),
        ),
        useMaterial3: true,
      ),
      home: const MenuScreen(),
    );
  }
}
