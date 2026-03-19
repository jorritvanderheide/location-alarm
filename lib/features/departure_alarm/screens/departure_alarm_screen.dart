import 'package:flutter/material.dart';

class DepartureAlarmScreen extends StatelessWidget {
  const DepartureAlarmScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Departure Alarm')),
      body: const Center(child: Text('Alert when it\'s time to leave')),
    );
  }
}
