import 'package:flutter/material.dart';
import 'screens/webview_screen.dart';

void main() {
  runApp(const ShopPulseApp());
}

class ShopPulseApp extends StatelessWidget {
  const ShopPulseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ShopPulse',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true, brightness: Brightness.dark),
      home: const WebViewScreen(),
    );
  }
}
