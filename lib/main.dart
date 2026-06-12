import 'package:flutter/material.dart';

import 'app_scope.dart';
import 'campaign/active_campaign.dart';
import 'data/report_repository.dart';
import 'features/home/home_screen.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ReportRepository.instance.load();
  runApp(const WildWatchApp());
}

class WildWatchApp extends StatefulWidget {
  const WildWatchApp({super.key});

  @override
  State<WildWatchApp> createState() => _WildWatchAppState();
}

class _WildWatchAppState extends State<WildWatchApp> {
  late final AppScope _scope;

  @override
  void initState() {
    super.initState();
    // Built once so the submission manager / queue watcher persist for the app
    // lifetime.
    _scope = AppScope(
      campaign: activeCampaign,
      child: const _Root(),
    );
    _scope.submissionManager.startQueueWatcher();
    // Try to flush anything left queued from a previous session.
    _scope.submissionManager.flushQueue();
  }

  @override
  Widget build(BuildContext context) => _scope;
}

class _Root extends StatelessWidget {
  const _Root();

  @override
  Widget build(BuildContext context) {
    final campaign = AppScope.of(context).campaign;
    return MaterialApp(
      title: campaign.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(campaign.branding),
      darkTheme: AppTheme.dark(campaign.branding),
      home: const HomeScreen(),
    );
  }
}
