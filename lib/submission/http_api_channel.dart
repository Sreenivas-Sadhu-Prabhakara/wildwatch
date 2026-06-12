import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../campaign/campaign.dart';
import '../data/device_id.dart';
import '../models/report.dart';
import 'report_formatter.dart';
import 'submission_channel.dart';

/// Delivers a report by POSTing it to an agency HTTP API as multipart form
/// data: a JSON `report` part plus the photo file. Because it completes without
/// user interaction, the offline queue can flush these automatically.
class HttpApiChannel extends SubmissionChannel {
  @override
  bool get supportsAutoSubmit => true;

  @override
  Future<SubmissionResult> submit(Report report, Campaign campaign) async {
    final cfg = campaign.submission.api;
    if (cfg == null) {
      return SubmissionResult.error('This campaign has no API configuration.');
    }

    final formatter = ReportFormatter(campaign);
    final deviceId = await DeviceId.get();

    try {
      final request = http.MultipartRequest(cfg.method, Uri.parse(cfg.url));
      request.headers.addAll(cfg.headers);
      request.fields[cfg.payloadFieldName] =
          formatter.jsonBody(report, deviceId: deviceId);

      if (!kIsWeb &&
          report.photoPath != null &&
          await File(report.photoPath!).exists()) {
        request.files.add(
          await http.MultipartFile.fromPath(cfg.photoFieldName, report.photoPath!),
        );
      }

      final streamed = await request.send().timeout(const Duration(seconds: 30));
      final status = streamed.statusCode;
      if (status >= 200 && status < 300) {
        return SubmissionResult.ok(message: 'Report accepted by the agency API.');
      }
      final body = await streamed.stream.bytesToString();
      return SubmissionResult.error(
        'Agency API returned HTTP $status. ${body.isEmpty ? '' : body}'.trim(),
      );
    } on SocketException {
      return SubmissionResult.error(
        'No connection. The report is queued and will retry automatically.',
      );
    } catch (e) {
      return SubmissionResult.error('Submission failed: $e');
    }
  }
}
