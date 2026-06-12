import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../app_scope.dart';
import '../../../campaign/campaign.dart';
import '../../../models/report.dart';

/// Map-based location picker built on OpenStreetMap tiles (no API key needed).
/// Tap the map to drop/move the pin, or use the device GPS. Works with raw
/// coordinates so it is usable offline once tiles are cached.
class LocationPicker extends StatefulWidget {
  const LocationPicker({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final GeoPoint? value;
  final ValueChanged<GeoPoint> onChanged;

  @override
  State<LocationPicker> createState() => _LocationPickerState();
}

class _LocationPickerState extends State<LocationPicker> {
  final MapController _map = MapController();
  bool _locating = false;
  String? _error;

  LatLng get _initialCenter {
    if (widget.value != null) {
      return LatLng(widget.value!.latitude, widget.value!.longitude);
    }
    final c = AppScope.of(context).campaign.country.defaultCenter;
    return LatLng(c.latitude, c.longitude);
  }

  Future<void> _useMyLocation() async {
    setState(() {
      _locating = true;
      _error = null;
    });
    final result = await AppScope.of(context).locationService.getCurrentLocation();
    if (!mounted) return;
    setState(() => _locating = false);
    if (result.ok) {
      final p = result.point!;
      widget.onChanged(p);
      _map.move(LatLng(p.latitude, p.longitude), 16);
    } else {
      setState(() => _error = result.error);
    }
  }

  void _onTap(LatLng latlng) {
    widget.onChanged(
      GeoPoint(latitude: latlng.latitude, longitude: latlng.longitude),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final value = widget.value;
    final CampaignCountry country = AppScope.of(context).campaign.country;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            height: 200,
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _map,
                  options: MapOptions(
                    initialCenter: _initialCenter,
                    initialZoom:
                        value != null ? 16 : country.defaultZoom.toDouble(),
                    onTap: (_, latlng) => _onTap(latlng),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'ph.wildwatch',
                    ),
                    if (value != null)
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: LatLng(value.latitude, value.longitude),
                            width: 44,
                            height: 44,
                            alignment: Alignment.topCenter,
                            child: Icon(Icons.location_on,
                                size: 44, color: scheme.error),
                          ),
                        ],
                      ),
                    const _OsmAttribution(),
                  ],
                ),
                if (value == null)
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: scheme.surface.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text('Tap the map to set the spot',
                          style: Theme.of(context).textTheme.bodySmall),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _locating ? null : _useMyLocation,
                icon: _locating
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.my_location, size: 18),
                label: Text(_locating ? 'Locating…' : 'Use my location'),
              ),
            ),
          ],
        ),
        if (value != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              'Pin: ${value.latitude.toStringAsFixed(5)}, '
              '${value.longitude.toStringAsFixed(5)}'
              '${value.accuracy != null ? '  (±${value.accuracy!.toStringAsFixed(0)} m)' : ''}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
            ),
          ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(_error!,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: scheme.error)),
          ),
      ],
    );
  }
}

class _OsmAttribution extends StatelessWidget {
  const _OsmAttribution();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomRight,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.7),
        child: Text(
          '© OpenStreetMap',
          style: Theme.of(context).textTheme.labelSmall,
        ),
      ),
    );
  }
}
