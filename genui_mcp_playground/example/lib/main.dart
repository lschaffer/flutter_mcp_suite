import 'package:flutter/material.dart';
import 'env_loader.dart';
import 'genui_travel_example.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EnvLoader.load();
  runApp(const GenuiPlaygroundExampleApp());
}

class GenuiPlaygroundExampleApp extends StatelessWidget {
  const GenuiPlaygroundExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GenUI Travel & Stay Planner Example',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.system,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0078D4),
          brightness: Brightness.light,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2B88D8),
          brightness: Brightness.dark,
        ),
      ),
      home: const GenuiTravelScreen(),
    );
  }
}
