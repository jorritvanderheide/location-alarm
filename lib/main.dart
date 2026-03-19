import 'package:flutter/material.dart';

void main() {
  runApp(const LocationAlarmApp());
}

class LocationAlarmApp extends StatelessWidget {
  const LocationAlarmApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Location Alarm',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Location Alarm'),
      ),
      body: const Center(
        child: Text('Location Alarm'),
      ),
    );
  }
}
