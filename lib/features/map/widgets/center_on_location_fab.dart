import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:location_alarm/shared/providers/location_provider.dart';

class CenterOnLocationButton extends ConsumerWidget {
  const CenterOnLocationButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locationAsync = ref.watch(locationProvider);

    final icon = locationAsync.when(
      data: (_) => Icons.my_location,
      loading: () => Icons.location_searching,
      error: (_, _) => Icons.location_disabled,
    );

    return FloatingActionButton.small(
      heroTag: 'center_location',
      elevation: 6,
      tooltip: 'Center on my location',
      onPressed: onPressed,
      child: Icon(icon),
    );
  }
}
