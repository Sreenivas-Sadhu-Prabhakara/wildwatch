import 'package:flutter_test/flutter_test.dart';
import 'package:wildwatch/campaign/active_campaign.dart';
import 'package:wildwatch/models/report.dart';
import 'package:wildwatch/models/report_prefill.dart';
import 'package:wildwatch/submission/report_formatter.dart';

void main() {
  group('Report serialization', () {
    test('round-trips through JSON', () {
      final original = Report(
        id: 'abc-123',
        campaignId: 'squirrel-ph',
        createdAt: DateTime.parse('2026-06-12T09:00:00Z'),
        observedAt: DateTime.parse('2026-06-12T08:30:00Z'),
        speciesId: 'finlaysons-squirrel',
        speciesName: "Finlayson's squirrel",
        location: GeoPoint(latitude: 14.55, longitude: 121.02, accuracy: 8),
        localityText: 'Makati',
        notes: 'On a power line',
        fieldValues: {'count': '2', 'still_present': 'true'},
        contact: ContactInfo(name: 'Ana', email: 'ana@example.com'),
        status: ReportStatus.queued,
      );

      final restored = Report.fromJson(original.toJson());

      expect(restored.id, original.id);
      expect(restored.campaignId, original.campaignId);
      expect(restored.speciesName, original.speciesName);
      expect(restored.location!.latitude, 14.55);
      expect(restored.location!.accuracy, 8);
      expect(restored.fieldValues['count'], '2');
      expect(restored.contact.email, 'ana@example.com');
      expect(restored.status, ReportStatus.queued);
    });

    test('localityLabel falls back to coordinates then unknown', () {
      final withText = Report(
        id: '1',
        campaignId: 'x',
        createdAt: DateTime.now(),
        observedAt: DateTime.now(),
        localityText: 'Quezon City',
      );
      expect(withText.localityLabel, 'Quezon City');

      final withCoords = Report(
        id: '2',
        campaignId: 'x',
        createdAt: DateTime.now(),
        observedAt: DateTime.now(),
        location: GeoPoint(latitude: 1.23456, longitude: 2.34567),
      );
      expect(withCoords.localityLabel, '1.2346, 2.3457');

      final empty = Report(
        id: '3',
        campaignId: 'x',
        createdAt: DateTime.now(),
        observedAt: DateTime.now(),
      );
      expect(empty.localityLabel, 'Unknown location');
    });
  });

  group('ReportFormatter', () {
    final campaign = campaignRegistry['squirrel-ph']!;

    test('email subject fills species and locality placeholders', () {
      final report = Report(
        id: '1',
        campaignId: campaign.id,
        createdAt: DateTime.now(),
        observedAt: DateTime.now(),
        speciesName: "Finlayson's squirrel",
        localityText: 'Makati',
      );
      final subject = ReportFormatter(campaign).subject(report);
      expect(subject, contains("Finlayson's squirrel"));
      expect(subject, contains('Makati'));
    });

    test('email body marks anonymous reporters', () {
      final report = Report(
        id: '1',
        campaignId: campaign.id,
        createdAt: DateTime.now(),
        observedAt: DateTime.now(),
      );
      final body = ReportFormatter(campaign).emailBody(report);
      expect(body, contains('Anonymous'));
    });
  });

  group('ReportPrefill.fromUri (deep link / Shortcut)', () {
    test('parses species, location, locality, fields, notes and contact', () {
      final uri = Uri.parse(
        'squirrelwatch://report?species=finlaysons-squirrel'
        '&lat=14.5547&lng=121.0244'
        '&locality=Ayala%20Triangle%2C%20Makati'
        '&count=2&behavior=On%20power%20lines%20%2F%20cables'
        '&still_present=true'
        '&notes=Seen%20from%20the%20office%20window'
        '&name=Ana%20Cruz&email=ana@example.com',
      );
      final p = ReportPrefill.fromUri(uri);

      expect(p.speciesId, 'finlaysons-squirrel');
      expect(p.location!.latitude, 14.5547);
      expect(p.location!.longitude, 121.0244);
      expect(p.localityText, 'Ayala Triangle, Makati');
      expect(p.fieldValues['count'], '2');
      expect(p.fieldValues['behavior'], 'On power lines / cables');
      expect(p.fieldValues['still_present'], 'true');
      expect(p.notes, 'Seen from the office window');
      expect(p.contact!.name, 'Ana Cruz');
      expect(p.contact!.email, 'ana@example.com');
      expect(p.isEmpty, isFalse);
    });

    test('accepts latitude/longitude aliases and is anonymous without contact', () {
      final p = ReportPrefill.fromUri(
        Uri.parse('wildwatch://report?latitude=1.5&longitude=2.5'),
      );
      expect(p.location!.latitude, 1.5);
      expect(p.location!.longitude, 2.5);
      expect(p.contact, isNull);
    });

    test('a bare link yields an empty prefill', () {
      final p = ReportPrefill.fromUri(Uri.parse('squirrelwatch://report'));
      expect(p.isEmpty, isTrue);
    });

    test('ignores invalid coordinates', () {
      final p = ReportPrefill.fromUri(
        Uri.parse('squirrelwatch://report?lat=abc&lng=121.0'),
      );
      expect(p.location, isNull);
    });
  });
}
