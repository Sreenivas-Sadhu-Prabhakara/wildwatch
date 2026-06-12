import 'package:flutter/widgets.dart';

import 'campaign/campaign.dart';
import 'data/report_repository.dart';
import 'services/location_service.dart';
import 'services/photo_service.dart';
import 'submission/submission_manager.dart';

/// Dependency holder shared down the widget tree. Avoids a state-management
/// package: screens read what they need from `AppScope.of(context)`.
class AppScope extends InheritedWidget {
  AppScope({
    super.key,
    required this.campaign,
    required super.child,
    SubmissionManager? submissionManager,
    LocationService? locationService,
    PhotoService? photoService,
  })  : submissionManager =
            submissionManager ?? SubmissionManager(campaign: campaign),
        locationService = locationService ?? LocationService(),
        photoService = photoService ?? PhotoService();

  final Campaign campaign;
  final SubmissionManager submissionManager;
  final LocationService locationService;
  final PhotoService photoService;

  ReportRepository get repository => ReportRepository.instance;

  static AppScope of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'No AppScope found in context');
    return scope!;
  }

  @override
  bool updateShouldNotify(AppScope oldWidget) =>
      campaign.id != oldWidget.campaign.id;
}
