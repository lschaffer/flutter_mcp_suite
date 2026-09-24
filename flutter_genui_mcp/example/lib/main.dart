import 'package:flutter_genui_mcp/flutter_genui_mcp.dart';
import 'package:material_ui/material_ui.dart';
import 'env_loader.dart';
import 'genui_travel_example.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EnvLoader.load();
  runApp(const GenuiTravelExampleApp());
}

class GenuiTravelExampleApp extends StatelessWidget {
  const GenuiTravelExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GenUI Travel & Stay Planner',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.system,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6750A4),
          brightness: Brightness.light,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFD0BCFF),
          brightness: Brightness.dark,
        ),
      ),
      home: const GenuiTravelScreen(),
    );
  }
}

