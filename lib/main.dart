import 'dart:async';

import 'package:flutter/material.dart';

import 'app_scope.dart';
import 'campaign/active_campaign.dart';
import 'data/report_repository.dart';
import 'features/history/my_reports_screen.dart';
import 'features/home/home_screen.dart';
import 'features/report/new_report_screen.dart';
import 'models/report_prefill.dart';
import 'services/deep_link_service.dart';
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
  final GlobalKey<NavigatorState> _navKey = GlobalKey<NavigatorState>();
  final DeepLinkService _deepLinks = DeepLinkService();
  StreamSubscription<Uri>? _linkSub;
  late final AppScope _scope;

  @override
  void initState() {
    super.initState();
    // Built once so the submission manager / queue watcher persist for the app
    // lifetime.
    _scope = AppScope(
      campaign: activeCampaign,
      child: _Root(navigatorKey: _navKey),
    );
    _scope.submissionManager.startQueueWatcher();
    // Try to flush anything left queued from a previous session.
    _scope.submissionManager.flushQueue();
    _initDeepLinks();
  }

  Future<void> _initDeepLinks() async {
    try {
      final initial = await _deepLinks.getInitialLink();
      if (initial != null) {
        // Defer until the navigator exists (cold-start links arrive early).
        WidgetsBinding.instance
            .addPostFrameCallback((_) => _handleUri(initial));
      }
    } catch (_) {
      // No initial link / platform without deep links — ignore.
    }
    _linkSub = _deepLinks.uriStream.listen(_handleUri, onError: (_) {});
  }

  /// Routes a deep link such as `squirrelwatch://report?species=...`.
  /// The target is taken from the URI host (or first path segment).
  void _handleUri(Uri uri) {
    final nav = _navKey.currentState;
    if (nav == null) return;
    final target = (uri.host.isNotEmpty
            ? uri.host
            : (uri.pathSegments.isNotEmpty ? uri.pathSegments.first : 'home'))
        .toLowerCase();

    switch (target) {
      case 'report':
      case 'new':
      case 'sighting':
        nav.push(MaterialPageRoute(
          builder: (_) => NewReportScreen(prefill: ReportPrefill.fromUri(uri)),
        ));
      case 'reports':
      case 'history':
        nav.push(MaterialPageRoute(builder: (_) => const MyReportsScreen()));
      default:
        nav.popUntil((r) => r.isFirst);
    }
  }

  @override
  void dispose() {
    _linkSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _scope;
}

class _Root extends StatelessWidget {
  const _Root({required this.navigatorKey});

  final GlobalKey<NavigatorState> navigatorKey;

  @override
  Widget build(BuildContext context) {
    final campaign = AppScope.of(context).campaign;
    return MaterialApp(
      title: campaign.appName,
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(campaign.branding),
      darkTheme: AppTheme.dark(campaign.branding),
      home: const HomeScreen(),
    );
  }
}
