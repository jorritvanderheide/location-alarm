import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:location_alarm/shared/providers/location_permission_provider.dart';
import 'package:location_alarm/shared/providers/onboarding_provider.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  bool _locationGranted = false;
  bool _backgroundGranted = false;
  bool _notificationGranted = false;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    final location = await Permission.locationWhenInUse.status;
    final background = await Permission.locationAlways.status;
    final notification = await Permission.notification.status;
    if (!mounted) return;
    setState(() {
      _locationGranted = location.isGranted;
      _backgroundGranted = background.isGranted;
      _notificationGranted = notification.isGranted;
    });
  }

  Future<void> _requestLocation() async {
    final result = await Permission.locationWhenInUse.request();
    if (!mounted) return;
    setState(() => _locationGranted = result.isGranted);
    if (result.isGranted) {
      await ref.read(locationPermissionProvider.notifier).request();
    }
  }

  Future<void> _requestBackground() async {
    if (!_locationGranted) {
      await _requestLocation();
      if (!_locationGranted) return;
    }
    final result = await Permission.locationAlways.request();
    if (!mounted) return;
    setState(() => _backgroundGranted = result.isGranted);
    if (result.isGranted) {
      ref.read(backgroundPermissionProvider.notifier).set(true);
    }
  }

  Future<void> _requestNotification() async {
    final result = await Permission.notification.request();
    if (!mounted) return;
    setState(() => _notificationGranted = result.isGranted);
  }

  void _finish() {
    ref.read(onboardingCompleteProvider.notifier).complete();
    context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(flex: 2),
              Icon(
                Icons.notifications_active,
                size: 64,
                color: colorScheme.primary,
              ),
              const SizedBox(height: 24),
              Text(
                'Location Alarm',
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'Get alerted when you arrive at a location. '
                'The app needs a few permissions to work.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const Spacer(),
              _PermissionTile(
                icon: Icons.location_on,
                title: 'Location access',
                subtitle: 'Required to detect when you arrive',
                granted: _locationGranted,
                onRequest: _requestLocation,
              ),
              const SizedBox(height: 12),
              _PermissionTile(
                icon: Icons.location_on_outlined,
                title: 'Background location',
                subtitle: 'Needed to monitor while the app is closed',
                granted: _backgroundGranted,
                onRequest: _requestBackground,
              ),
              const SizedBox(height: 12),
              _PermissionTile(
                icon: Icons.notifications,
                title: 'Notifications',
                subtitle: 'To alert you when an alarm triggers',
                granted: _notificationGranted,
                onRequest: _requestNotification,
              ),
              const Spacer(flex: 2),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _finish,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(56),
                  ),
                  child: Text(
                    _locationGranted &&
                            _backgroundGranted &&
                            _notificationGranted
                        ? 'Get started'
                        : 'Continue without permissions',
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

class _PermissionTile extends StatelessWidget {
  const _PermissionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.granted,
    required this.onRequest,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool granted;
  final VoidCallback onRequest;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card.outlined(
      margin: EdgeInsets.zero,
      child: ListTile(
        leading: Icon(
          icon,
          color: granted ? colorScheme.primary : colorScheme.onSurfaceVariant,
        ),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: granted
            ? Icon(Icons.check_circle, color: colorScheme.primary)
            : FilledButton.tonal(
                onPressed: onRequest,
                child: const Text('Grant'),
              ),
      ),
    );
  }
}
