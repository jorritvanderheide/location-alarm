import 'package:flutter/material.dart';

Future<bool> showBackgroundRationaleDialog(BuildContext context) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Background location needed'),
      content: const Text(
        'Location Alarm needs to monitor your location in the background '
        'to trigger alarms when you arrive.\n\n'
        'On the next screen, select "Allow all the time".',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Continue'),
        ),
      ],
    ),
  );
  return result ?? false;
}

Future<bool> showBatteryRationaleDialog(BuildContext context) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Disable battery optimization'),
      content: const Text(
        'To reliably monitor your location in the background, '
        'Location Alarm needs to be excluded from battery optimization.\n\n'
        'Without this, Android may stop the alarm service to save battery.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Skip'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Disable optimization'),
        ),
      ],
    ),
  );
  return result ?? false;
}
