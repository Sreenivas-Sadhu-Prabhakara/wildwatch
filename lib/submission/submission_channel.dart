import '../campaign/campaign.dart';
import '../models/report.dart';

/// Outcome of a delivery attempt.
class SubmissionResult {
  SubmissionResult({
    required this.success,
    this.message,
    this.handedOff = false,
  });

  /// The report was accepted (API) or successfully handed to the mail app.
  final bool success;

  /// Human-readable detail, shown to the user or stored as `lastError`.
  final String? message;

  /// True when delivery depends on a further user action (e.g. tapping "Send"
  /// in their mail app). The app cannot confirm final receipt in this case.
  final bool handedOff;

  factory SubmissionResult.ok({String? message, bool handedOff = false}) =>
      SubmissionResult(success: true, message: message, handedOff: handedOff);

  factory SubmissionResult.error(String message) =>
      SubmissionResult(success: false, message: message);
}

/// A delivery mechanism for a finished report. New agencies plug in by adding
/// a channel; the rest of the app does not change.
abstract class SubmissionChannel {
  /// Whether the offline queue may send this automatically without the user
  /// present. Email cannot (it opens the mail app); HTTP can.
  bool get supportsAutoSubmit;

  Future<SubmissionResult> submit(Report report, Campaign campaign);
}
