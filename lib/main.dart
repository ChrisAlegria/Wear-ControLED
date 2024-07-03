import 'package:flutter/material.dart';
import 'package:wear_controled/pages/WatchScreen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Wear ControLED',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home:
          const WatchScreen(), // Aquí estableces WatchScreen como la pantalla de inicio
    );
  }
}
