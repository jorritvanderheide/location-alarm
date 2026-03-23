import 'package:flutter/material.dart';
import 'package:location_alarm/l10n/app_localizations.dart';

Future<bool> showBackgroundRationaleDialog(BuildContext context) async {
  final l10n = AppLocalizations.of(context)!;
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(l10n.backgroundLocationNeeded),
      content: Text(l10n.backgroundLocationBody),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(l10n.cancel),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text(l10n.continueButton),
        ),
      ],
    ),
  );
  return result ?? false;
}

Future<bool> showBatteryRationaleDialog(BuildContext context) async {
  final l10n = AppLocalizations.of(context)!;
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(l10n.disableBatteryOptimization),
      content: Text(l10n.batteryOptimizationBody),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(l10n.skip),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text(l10n.disableOptimization),
        ),
      ],
    ),
  );
  return result ?? false;
}
