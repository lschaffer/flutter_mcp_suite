import 'package:flutter/material.dart';
import 'env_loader.dart';
import 'genui_weather_example.dart';

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
      title: 'GenUI MCP Playground Example',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.system,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color.fromARGB(255, 22, 75, 179),
          brightness: Brightness.light,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color.fromARGB(255, 14, 30, 50),
          brightness: Brightness.dark,
        ),
      ),
      home: const GenuiWeatherScreen(),
    );
  }
}
