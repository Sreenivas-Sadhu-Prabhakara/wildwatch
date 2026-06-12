import 'package:flutter/foundation.dart';

import '../campaign/campaign.dart';
import '../data/report_repository.dart';
import '../models/report.dart';
import '../services/connectivity_service.dart';
import 'email_channel.dart';
import 'http_api_channel.dart';
import 'submission_channel.dart';

/// Coordinates delivery: picks the right channel for the active campaign,
/// updates report status in the repository, and flushes the offline queue when
/// connectivity returns.
class SubmissionManager {
  SubmissionManager({
    required this.campaign,
    ReportRepository? repository,
    ConnectivityService? connectivity,
  })  : _repo = repository ?? ReportRepository.instance,
        _connectivity = connectivity ?? ConnectivityService(),
        _channel = _channelFor(campaign);

  final Campaign campaign;
  final ReportRepository _repo;
  final ConnectivityService _connectivity;
  final SubmissionChannel _channel;

  static SubmissionChannel _channelFor(Campaign campaign) =>
      switch (campaign.submission.method) {
        SubmissionMethod.email => EmailChannel(),
        SubmissionMethod.httpApi => HttpApiChannel(),
      };

  /// Whether queued reports for this campaign can be sent without the user.
  bool get supportsAutoSubmit => _channel.supportsAutoSubmit;

  /// Start watching connectivity to auto-flush the queue. Safe to call once at
  /// startup.
  void startQueueWatcher() {
    if (!_channel.supportsAutoSubmit) return;
    _connectivity.onStatusChange.listen((online) {
      if (online) flushQueue();
    });
  }

  /// Attempt to deliver [report] now. Updates and persists its status.
  Future<SubmissionResult> submitNow(Report report) async {
    final result = await _channel.submit(report, campaign);
    if (result.success) {
      report.status = ReportStatus.submitted;
      report.submittedAt = DateTime.now();
      report.lastError = null;
    } else {
      // For auto-submit channels a failure is usually transient (offline) — keep
      // it queued so the watcher retries. For email the user must act, so mark
      // it failed and surface the reason.
      report.status =
          _channel.supportsAutoSubmit ? ReportStatus.queued : ReportStatus.failed;
      report.lastError = result.message;
    }
    await _repo.save(report);
    return result;
  }

  /// Explicitly hold a report for later sending (e.g. user is offline).
  Future<void> queueForLater(Report report) async {
    report.status = ReportStatus.queued;
    await _repo.save(report);
  }

  /// Try to send everything currently queued (auto-submit channels only).
  Future<void> flushQueue() async {
    if (!_channel.supportsAutoSubmit) return;
    if (!await _connectivity.isOnline()) return;
    for (final report in _repo.queued) {
      try {
        await submitNow(report);
      } catch (e) {
        debugPrint('WildWatch: queue flush error for ${report.id}: $e');
      }
    }
  }
}
