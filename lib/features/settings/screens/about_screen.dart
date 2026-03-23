import 'package:flutter/material.dart';
import 'package:location_alarm/l10n/app_localizations.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.aboutTitle)),
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
            l10n.locationAlarmDefault,
            style: Theme.of(context).textTheme.headlineMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            l10n.appTagline,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: Text(l10n.version),
            subtitle: const Text('1.0.0'),
          ),
          ListTile(
            leading: const Icon(Icons.gavel),
            title: Text(l10n.license),
            subtitle: Text(l10n.licenseValue),
          ),
          ListTile(
            leading: const Icon(Icons.map),
            title: Text(l10n.mapData),
            subtitle: Text(l10n.mapDataValue),
          ),
          ListTile(
            leading: const Icon(Icons.search),
            title: Text(l10n.geocoding),
            subtitle: Text(l10n.geocodingValue),
          ),
          const SizedBox(height: 16),
          FilledButton.tonal(
            onPressed: () => showLicensePage(
              context: context,
              applicationName: l10n.locationAlarmDefault,
              applicationVersion: '1.0.0',
            ),
            child: Text(l10n.openSourceLicenses),
          ),
        ],
      ),
    );
  }
}
