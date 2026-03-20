import 'package:flutter/material.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('About')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SizedBox(height: 32),
          Icon(
            Icons.notifications_active,
            size: 64,
            color: colorScheme.primary,
          ),
          const SizedBox(height: 16),
          Text(
            'Location Alarm',
            style: Theme.of(context).textTheme.headlineMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Offline location-based alarm app',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('Version'),
            subtitle: Text('1.0.0'),
          ),
          const ListTile(
            leading: Icon(Icons.gavel),
            title: Text('License'),
            subtitle: Text('PolyForm Shield 1.0.0'),
          ),
          const ListTile(
            leading: Icon(Icons.map),
            title: Text('Map data'),
            subtitle: Text('OpenStreetMap contributors · CartoDB'),
          ),
          const SizedBox(height: 16),
          FilledButton.tonal(
            onPressed: () => showLicensePage(
              context: context,
              applicationName: 'Location Alarm',
              applicationVersion: '1.0.0',
            ),
            child: const Text('Open source licenses'),
          ),
        ],
      ),
    );
  }
}
