import 'package:flutter/material.dart';

import '../models/report.dart';

/// Small coloured chip communicating a report's [ReportStatus]. Colours are
/// derived from the theme's colour scheme so they restyle with the campaign.
class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.status});

  final ReportStatus status;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (Color bg, Color fg, IconData icon) = switch (status) {
      ReportStatus.draft => (
          scheme.surfaceContainerHighest,
          scheme.onSurfaceVariant,
          Icons.edit_note,
        ),
      ReportStatus.queued => (
          scheme.tertiaryContainer,
          scheme.onTertiaryContainer,
          Icons.schedule,
        ),
      ReportStatus.submitted => (
          scheme.primaryContainer,
          scheme.onPrimaryContainer,
          Icons.check_circle_outline,
        ),
      ReportStatus.failed => (
          scheme.errorContainer,
          scheme.onErrorContainer,
          Icons.error_outline,
        ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: fg),
          const SizedBox(width: 5),
          Text(
            status.label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: fg,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}
