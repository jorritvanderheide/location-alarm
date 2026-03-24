import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:there_yet/l10n/app_localizations.dart';
import 'package:there_yet/shared/providers/location_provider.dart';

class CenterOnLocationButton extends ConsumerWidget {
  const CenterOnLocationButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final locationAsync = ref.watch(locationProvider);

    final icon = locationAsync.when(
      data: (_) => Icons.my_location,
      loading: () => Icons.location_searching,
      error: (_, _) => Icons.location_disabled,
    );

    return FloatingActionButton.small(
      heroTag: 'center_location',
      elevation: 6,
      tooltip: l10n.centerOnMyLocation,
      onPressed: onPressed,
      child: Icon(icon),
    );
  }
}
