import 'package:flutter/material.dart';

import '../../app_scope.dart';
import '../../data/report_repository.dart';
import '../../widgets/brand_badge.dart';
import '../history/my_reports_screen.dart';
import '../report/new_report_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final campaign = scope.campaign;
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  BrandBadge(branding: campaign.branding, size: 48),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(campaign.appName,
                            style: text.titleLarge
                                ?.copyWith(fontWeight: FontWeight.w700)),
                        Text(campaign.country.name,
                            style: text.bodySmall?.copyWith(
                                color: scheme.onSurfaceVariant)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _HeroCard(),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const NewReportScreen()),
                ),
                icon: const Icon(Icons.add_a_photo_outlined),
                label: Text(campaign.locale.reportCta),
              ),
              const SizedBox(height: 10),
              _MyReportsButton(),
              const SizedBox(height: 24),
              if (campaign.safetyNotes.isNotEmpty) _SafetyCard(),
              const SizedBox(height: 16),
              _MissionCard(),
              const SizedBox(height: 24),
              Center(
                child: Text(
                  'No account needed · Reports go to ${campaign.agency.shortName}',
                  textAlign: TextAlign.center,
                  style: text.bodySmall
                      ?.copyWith(color: scheme.onSurfaceVariant),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final campaign = AppScope.of(context).campaign;
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(campaign.branding.heroIcon,
              size: 32, color: scheme.onPrimaryContainer),
          const SizedBox(height: 12),
          Text(
            campaign.tagline,
            style: text.titleMedium?.copyWith(
              color: scheme.onPrimaryContainer,
              fontWeight: FontWeight.w700,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Reports reach ${campaign.agency.name}.',
            style: text.bodyMedium?.copyWith(
              color: scheme.onPrimaryContainer.withValues(alpha: 0.85),
            ),
          ),
        ],
      ),
    );
  }
}

class _MyReportsButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ReportRepository.instance,
      builder: (context, _) {
        final reports = ReportRepository.instance.all;
        final queued = reports
            .where((r) =>
                r.status.name == 'queued' || r.status.name == 'failed')
            .length;
        return OutlinedButton.icon(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const MyReportsScreen()),
          ),
          icon: const Icon(Icons.history),
          label: Text(
            reports.isEmpty
                ? 'My reports'
                : 'My reports (${reports.length})'
                    '${queued > 0 ? ' · $queued to send' : ''}',
          ),
        );
      },
    );
  }
}

class _SafetyCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final campaign = AppScope.of(context).campaign;
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.tertiaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.health_and_safety_outlined,
                  size: 20, color: scheme.onTertiaryContainer),
              const SizedBox(width: 8),
              Text('Stay safe',
                  style: text.titleSmall?.copyWith(
                    color: scheme.onTertiaryContainer,
                    fontWeight: FontWeight.w700,
                  )),
            ],
          ),
          const SizedBox(height: 10),
          ...campaign.safetyNotes.map(
            (note) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('•  ',
                      style: TextStyle(color: scheme.onTertiaryContainer)),
                  Expanded(
                    child: Text(note,
                        style: text.bodySmall?.copyWith(
                          color: scheme.onTertiaryContainer,
                          height: 1.35,
                        )),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MissionCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final campaign = AppScope.of(context).campaign;
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Why report?',
                style: text.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(campaign.missionBlurb,
                style: text.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                  height: 1.4,
                )),
          ],
        ),
      ),
    );
  }
}
