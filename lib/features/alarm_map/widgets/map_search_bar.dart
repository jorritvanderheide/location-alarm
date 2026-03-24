import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:there_yet/l10n/app_localizations.dart';
import 'package:there_yet/shared/data/models/geocoding_result.dart';
import 'package:there_yet/shared/providers/connectivity_provider.dart';
import 'package:there_yet/shared/providers/geocoding_provider.dart';

class MapSearchBar extends ConsumerStatefulWidget {
  const MapSearchBar({
    super.key,
    required this.onBack,
    required this.onLocationSelected,
    this.near,
  });

  final VoidCallback onBack;
  final ValueChanged<LatLng> onLocationSelected;
  final LatLng? near;

  @override
  ConsumerState<MapSearchBar> createState() => _MapSearchBarState();
}

class _MapSearchBarState extends ConsumerState<MapSearchBar> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() => setState(() {}));
    _controller.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onChanged(String query) {
    ref.read(geocodingProvider.notifier).search(query, near: widget.near);
  }

  void _onSelected(GeocodingResult result) {
    _controller.text = result.displayName;
    _focusNode.unfocus();
    ref.read(geocodingProvider.notifier).clear();
    widget.onLocationSelected(result.location);
  }

  void _onClear() {
    _controller.clear();
    ref.read(geocodingProvider.notifier).clear();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final isOnline = ref.watch(connectivityProvider);
    final geocodingState = ref.watch(geocodingProvider);
    final showResults = _focusNode.hasFocus && geocodingState is! GeocodingIdle;

    return Positioned(
      left: 16,
      right: 16,
      top: MediaQuery.of(context).viewPadding.top + 8,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Material(
            elevation: 2,
            borderRadius: BorderRadius.circular(28),
            color: colorScheme.surface,
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              onChanged: _onChanged,
              readOnly: !isOnline,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                hintText: isOnline
                    ? l10n.searchLocation
                    : l10n.searchLocationOffline,
                prefixIcon: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: widget.onBack,
                ),
                suffixIcon: _controller.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: _onClear,
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          if (showResults)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Material(
                elevation: 2,
                borderRadius: BorderRadius.circular(12),
                color: colorScheme.surface,
                child: switch (geocodingState) {
                  GeocodingLoading() => const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  ),
                  GeocodingResults(:final results) =>
                    results.isEmpty
                        ? Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text(l10n.noResultsFound),
                          )
                        : ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxHeight: 280),
                              child: SingleChildScrollView(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    for (final result in results)
                                      _ResultTile(
                                        result: result,
                                        onTap: () => _onSelected(result),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                  GeocodingError(:final message) => Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      message,
                      style: TextStyle(color: colorScheme.error),
                    ),
                  ),
                  GeocodingIdle() => const SizedBox.shrink(),
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _ResultTile extends StatelessWidget {
  const _ResultTile({required this.result, required this.onTap});

  final GeocodingResult result;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      leading: const Icon(Icons.location_on_outlined, size: 20),
      title: Text(
        result.displayName,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.bodyMedium,
      ),
      onTap: onTap,
    );
  }
}
