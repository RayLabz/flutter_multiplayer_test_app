import 'package:flutter/material.dart';
import 'package:flutter_multiplayer_test_app/screen_tcp.dart';
import 'package:flutter_multiplayer_test_app/screen_udp.dart';

class TestApp extends StatelessWidget {
  const TestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Multiplayer test",
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const TCPScreen(),
    );
  }
}
