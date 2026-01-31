import 'package:flutter/material.dart';
import 'package:netlyra_ui/pages/dashboard_page.dart';
import 'package:netlyra_ui/theme/colors.dart';

void main() {
  runApp(const NetLyraApp());
}

class NetLyraApp extends StatelessWidget {
  const NetLyraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NetLyra',
      debugShowCheckedModeBanner: false,
      theme: buildNetLyraTheme(),
      home: const DashboardPage(),
    );
  }
}
