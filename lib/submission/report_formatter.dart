import 'dart:convert';

import '../campaign/campaign.dart';
import '../models/report.dart';

/// Turns a [Report] into the text/data an agency receives. Used by every
/// channel so email bodies and API payloads describe a report consistently.
class ReportFormatter {
  ReportFormatter(this.campaign);

  final Campaign campaign;

  String subject(Report report) {
    final species = report.speciesName ?? 'Wildlife sighting';
    return (campaign.submission.email?.subjectTemplate ??
            '${campaign.appName} report — {species} @ {locality}')
        .replaceAll('{species}', species)
        .replaceAll('{locality}', report.localityLabel);
  }

  /// A human-readable plain-text body for email delivery.
  String emailBody(Report report, {String? deviceId}) {
    final b = StringBuffer();
    b.writeln('${campaign.appName} — wildlife sighting report');
    b.writeln('For: ${campaign.agency.name} (${campaign.country.name})');
    b.writeln('');
    b.writeln('SPECIES');
    b.writeln('  ${report.speciesName ?? 'Not specified'}');
    b.writeln('');
    b.writeln('WHEN');
    b.writeln('  Observed: ${report.observedAt.toLocal()}');
    b.writeln('  Reported: ${report.createdAt.toLocal()}');
    b.writeln('');
    b.writeln('WHERE');
    if (report.location != null) {
      final loc = report.location!;
      b.writeln('  Coordinates: ${loc.latitude}, ${loc.longitude}');
      if (loc.accuracy != null) {
        b.writeln('  Accuracy: ±${loc.accuracy!.toStringAsFixed(0)} m');
      }
      b.writeln(
        '  Map: https://www.google.com/maps/search/?api=1&query='
        '${loc.latitude},${loc.longitude}',
      );
    }
    if (report.localityText != null && report.localityText!.isNotEmpty) {
      b.writeln('  Landmark / address: ${report.localityText}');
    }
    if (report.location == null &&
        (report.localityText == null || report.localityText!.isEmpty)) {
      b.writeln('  Not provided');
    }
    b.writeln('');

    if (campaign.fields.isNotEmpty) {
      b.writeln('DETAILS');
      for (final f in campaign.fields) {
        final v = report.fieldValues[f.key];
        if (v != null && v.isNotEmpty) {
          b.writeln('  ${f.label}: ${_displayValue(f, v)}');
        }
      }
      b.writeln('');
    }

    if (report.notes != null && report.notes!.trim().isNotEmpty) {
      b.writeln('NOTES');
      b.writeln('  ${report.notes}');
      b.writeln('');
    }

    b.writeln('REPORTER');
    if (report.contact.isEmpty) {
      b.writeln('  Anonymous (no contact details provided)');
    } else {
      if (report.contact.name != null && report.contact.name!.isNotEmpty) {
        b.writeln('  Name: ${report.contact.name}');
      }
      if (report.contact.phone != null && report.contact.phone!.isNotEmpty) {
        b.writeln('  Phone: ${report.contact.phone}');
      }
      if (report.contact.email != null && report.contact.email!.isNotEmpty) {
        b.writeln('  Email: ${report.contact.email}');
      }
    }
    b.writeln('');
    if (report.photoPath != null) {
      b.writeln('A photo is attached to this email.');
    } else {
      b.writeln('No photo was attached.');
    }
    b.writeln('');
    b.writeln('Report ID: ${report.id}');
    if (deviceId != null) b.writeln('Device ID: $deviceId');
    b.writeln('Sent via ${campaign.appName} (WildWatch).');
    return b.toString();
  }

  /// A structured JSON body for HTTP API delivery.
  String jsonBody(Report report, {String? deviceId}) {
    final map = {
      'campaignId': campaign.id,
      'agency': campaign.agency.shortName,
      'country': campaign.country.code,
      'reportId': report.id,
      'deviceId': ?deviceId,
      'species': {
        'id': report.speciesId,
        'name': report.speciesName,
      },
      'observedAt': report.observedAt.toUtc().toIso8601String(),
      'reportedAt': report.createdAt.toUtc().toIso8601String(),
      'location': report.location?.toJson(),
      'localityText': report.localityText,
      'fields': report.fieldValues,
      'notes': report.notes,
      'contact': report.contact.isEmpty ? null : report.contact.toJson(),
      'hasPhoto': report.photoPath != null,
    };
    return jsonEncode(map);
  }

  String _displayValue(ReportField field, String raw) {
    if (field.type == ReportFieldType.boolean) {
      return raw == 'true' ? 'Yes' : 'No';
    }
    return raw;
  }
}
