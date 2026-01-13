import 'package:flutter/material.dart';
import 'package:weather_app/ui/weather_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  /*
  it makes sure Flutter’s engine + framework bindings are ready.
  runApp does it automatically, but if you need to do async work or plugin calls before runApp,
  you must call it explicitly.
   */
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {

  bool isDarkMode = true;

  void toggleTheme(){
    setState(() {
      isDarkMode = !isDarkMode;
    });
  }
  @override
  Widget build(BuildContext context) {
    final theme = isDarkMode
        ? ThemeData.dark(useMaterial3: true)
        : ThemeData.light(useMaterial3: true);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      // Use AnimatedTheme here
      home: AnimatedTheme(
        data: theme,
        duration: const Duration(milliseconds: 1000),
        curve: Curves.easeInOut,
        child: WeatherScreen(
          onToggleTheme: toggleTheme,
          isDarkMode: isDarkMode,
        ),
      ),
      theme: theme, // Still needed for base theming
    );
  }
}
//15:00:00 -> 15:41:18 -> 16:05:05
// always check if app opens and permission is not allowed then ask for permission
// create an own flutter package and publish it
// search feature to enter city name and fetch the weather details on the search basis.