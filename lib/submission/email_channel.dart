import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_email_sender/flutter_email_sender.dart';

import '../campaign/campaign.dart';
import '../data/device_id.dart';
import '../models/report.dart';
import 'report_formatter.dart';
import 'submission_channel.dart';

/// Delivers a report by opening the device's email app, pre-filled with the
/// agency recipient, subject, body and the photo attached. The reporter taps
/// "Send" in their mail client — there is no backend and no SMTP credentials in
/// the app, which keeps delivery trustworthy and credential-free.
class EmailChannel extends SubmissionChannel {
  @override
  bool get supportsAutoSubmit => false;

  @override
  Future<SubmissionResult> submit(Report report, Campaign campaign) async {
    final cfg = campaign.submission.email;
    if (cfg == null) {
      return SubmissionResult.error('This campaign has no email configuration.');
    }
    if (kIsWeb) {
      return SubmissionResult.error(
        'Email submission needs the mobile app. Please use Squirrel Watch on '
        'your phone to send to ${cfg.recipients.join(', ')}.',
      );
    }

    final formatter = ReportFormatter(campaign);
    final deviceId = await DeviceId.get();

    final attachments = <String>[];
    if (report.photoPath != null && await File(report.photoPath!).exists()) {
      attachments.add(report.photoPath!);
    }

    final email = Email(
      subject: formatter.subject(report),
      body: formatter.emailBody(report, deviceId: deviceId),
      recipients: cfg.recipients,
      cc: cfg.cc,
      attachmentPaths: attachments,
    );

    try {
      await FlutterEmailSender.send(email);
      // The mail composer opened and returned; we treat this as handed off. We
      // cannot confirm the user actually pressed Send.
      return SubmissionResult.ok(
        message: 'Opened your email app addressed to ${cfg.recipients.first}.',
        handedOff: true,
      );
    } on PlatformException catch (e) {
      if (e.code == 'not_available') {
        return SubmissionResult.error(
          'No email app is set up on this device. Add an email account, or '
          'send the details manually to ${cfg.recipients.first}.',
        );
      }
      return SubmissionResult.error('Could not open email app: ${e.message}');
    } catch (e) {
      return SubmissionResult.error('Could not open email app: $e');
    }
  }
}
