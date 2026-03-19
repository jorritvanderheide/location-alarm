import 'package:flutter/material.dart';

class ProximityAlarmScreen extends StatelessWidget {
  const ProximityAlarmScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Proximity Alarm')),
      body: const Center(child: Text('Alert when within range of a location')),
    );
  }
}
