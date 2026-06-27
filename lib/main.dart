import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:transformfit/screens/today_screen.dart';
import 'package:transformfit/theme/digital_atelier.dart';

void main() {
  runApp(
    const ProviderScope(
      child: TransformFitApp(),
    ),
  );
}

class TransformFitApp extends StatelessWidget {
  const TransformFitApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TransformFit',
      theme: buildDigitalAtelierTheme(),
      home: const TodayScreen(),
    );
  }
}
