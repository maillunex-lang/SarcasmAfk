import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import 'screens/menu_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // ignore: deprecated_member_use
  WidgetsBinding.instance.ensureSemantics();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const AfkApp());
}

class AfkApp extends StatelessWidget {
  const AfkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AFK MMORPG · Flame',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF07060A),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFC45C26),
          secondary: Color(0xFF6EC8FF),
          surface: Color(0xFF1A1520),
        ),
        useMaterial3: true,
      ),
      home: const MenuScreen(),
    );
  }
}
