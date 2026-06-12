import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';

import '../../app_scope.dart';
import '../../campaign/campaign.dart';
import '../../data/report_repository.dart';
import '../../models/report.dart';
import '../../widgets/status_chip.dart';

class ReportDetailScreen extends StatelessWidget {
  const ReportDetailScreen({super.key, required this.reportId});

  final String reportId;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ReportRepository.instance,
      builder: (context, _) {
        final report = ReportRepository.instance.byId(reportId);
        if (report == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text('This report was deleted.')),
          );
        }
        return _DetailView(report: report);
      },
    );
  }
}

class _DetailView extends StatefulWidget {
  const _DetailView({required this.report});
  final Report report;

  @override
  State<_DetailView> createState() => _DetailViewState();
}

class _DetailViewState extends State<_DetailView> {
  bool _sending = false;

  Report get report => widget.report;

  Future<void> _resend() async {
    setState(() => _sending = true);
    final result =
        await AppScope.of(context).submissionManager.submitNow(report);
    if (!mounted) return;
    setState(() => _sending = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(result.message ?? 'Updated.')),
    );
  }

  Future<void> _delete() async {
    final photoService = AppScope.of(context).photoService;
    final navigator = Navigator.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete report?'),
        content: const Text('This removes the report from your device.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    await photoService.deleteIfManaged(report.photoPath);
    await ReportRepository.instance.delete(report.id);
    navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final campaign = AppScope.of(context).campaign;
    final scheme = Theme.of(context).colorScheme;
    final canResend = report.status != ReportStatus.submitted;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Report details'),
        actions: [
          IconButton(
            onPressed: _delete,
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Delete',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          Row(
            children: [
              StatusChip(status: report.status),
              const Spacer(),
              if (report.submittedAt != null)
                Text(
                  'Sent ${DateFormat('d MMM, h:mm a').format(report.submittedAt!)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
            ],
          ),
          if (report.lastError != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: scheme.errorContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.warning_amber_rounded,
                      size: 18, color: scheme.onErrorContainer),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(report.lastError!,
                        style: TextStyle(color: scheme.onErrorContainer)),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          if (report.photoPath != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: AspectRatio(
                aspectRatio: 4 / 3,
                child: kIsWeb
                    ? Image.network(report.photoPath!, fit: BoxFit.cover)
                    : Image.file(File(report.photoPath!), fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => const _MissingPhoto()),
              ),
            ),
            const SizedBox(height: 16),
          ],
          _InfoRow(
              icon: Icons.pets, label: 'Species', value: report.speciesName),
          _InfoRow(
            icon: Icons.event,
            label: 'Observed',
            value: DateFormat('EEE, d MMM yyyy · h:mm a')
                .format(report.observedAt),
          ),
          _InfoRow(
            icon: Icons.place_outlined,
            label: 'Location',
            value: report.localityLabel,
          ),
          if (report.location != null) ...[
            const SizedBox(height: 8),
            _MiniMap(report: report),
          ],
          for (final f in campaign.fields)
            if (report.fieldValues[f.key] != null &&
                report.fieldValues[f.key]!.isNotEmpty)
              _InfoRow(
                icon: f.icon ?? Icons.notes,
                label: f.label,
                value: _fieldDisplay(f, report.fieldValues[f.key]!),
              ),
          if (report.notes != null && report.notes!.isNotEmpty)
            _InfoRow(
                icon: Icons.sticky_note_2_outlined,
                label: 'Notes',
                value: report.notes),
          _InfoRow(
            icon: Icons.person_outline,
            label: 'Reporter',
            value: report.contact.isEmpty
                ? 'Anonymous'
                : [
                    report.contact.name,
                    report.contact.phone,
                    report.contact.email,
                  ].where((e) => e != null && e.isNotEmpty).join(' · '),
          ),
          const SizedBox(height: 24),
          if (canResend)
            FilledButton.icon(
              onPressed: _sending ? null : _resend,
              icon: _sending
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send),
              label: Text(
                _sending ? 'Sending…' : campaign.locale.submitLabel,
              ),
            ),
          if (canResend)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Center(
                child: Text('Sends to ${campaign.agency.name}',
                    style: Theme.of(context).textTheme.bodySmall),
              ),
            ),
        ],
      ),
    );
  }

  String _fieldDisplay(ReportField field, String raw) {
    if (field.type == ReportFieldType.boolean) {
      return raw == 'true' ? 'Yes' : 'No';
    }
    return raw;
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.label, this.value});

  final IconData icon;
  final String label;
  final String? value;

  @override
  Widget build(BuildContext context) {
    if (value == null || value!.isEmpty) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: scheme.onSurfaceVariant),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        )),
                const SizedBox(height: 2),
                Text(value!,
                    style: Theme.of(context).textTheme.bodyLarge),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniMap extends StatelessWidget {
  const _MiniMap({required this.report});
  final Report report;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final point = LatLng(report.location!.latitude, report.location!.longitude);
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        height: 160,
        child: FlutterMap(
          options: MapOptions(
            initialCenter: point,
            initialZoom: 15,
            interactionOptions:
                const InteractionOptions(flags: InteractiveFlag.none),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'ph.wildwatch',
            ),
            MarkerLayer(
              markers: [
                Marker(
                  point: point,
                  width: 40,
                  height: 40,
                  alignment: Alignment.topCenter,
                  child: Icon(Icons.location_on, size: 40, color: scheme.error),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MissingPhoto extends StatelessWidget {
  const _MissingPhoto();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      color: scheme.surfaceContainerHighest,
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.broken_image_outlined, color: scheme.onSurfaceVariant),
          const SizedBox(height: 8),
          Text('Photo unavailable',
              style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}
