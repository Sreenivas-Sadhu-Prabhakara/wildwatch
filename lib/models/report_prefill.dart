import 'report.dart';

/// Values used to pre-populate the report form when the app is opened via a
/// deep link (e.g. from an iOS/Android Shortcut). Everything is optional —
/// a deep link can fill as much or as little as it likes.
///
/// URL contract (any registered scheme works, e.g. `squirrelwatch://`):
///
///   squirrelwatch://report
///       ?species=finlaysons-squirrel
///       &lat=14.5547&lng=121.0244
///       &locality=Ayala%20Triangle%2C%20Makati
///       &count=2
///       &behavior=On%20power%20lines%20%2F%20cables
///       &notes=Seen%20from%20office%20window
///       &name=Ana&email=ana@example.com
///
/// `species`, `lat`/`lng` (or `latitude`/`longitude`), `locality`/`address`,
/// `notes`, and `name`/`phone`/`email` are recognised. Any other query
/// parameter is treated as a campaign field value, keyed by the field's `key`
/// (e.g. `count`, `behavior`, `habitat`, `still_present`).
class ReportPrefill {
  const ReportPrefill({
    this.speciesId,
    this.location,
    this.localityText,
    this.notes,
    this.fieldValues = const {},
    this.contact,
  });

  final String? speciesId;
  final GeoPoint? location;
  final String? localityText;
  final String? notes;
  final Map<String, String> fieldValues;
  final ContactInfo? contact;

  static const _coreKeys = {
    'species',
    'lat',
    'lng',
    'latitude',
    'longitude',
    'locality',
    'address',
    'notes',
    'name',
    'phone',
    'email',
  };

  factory ReportPrefill.fromUri(Uri uri) {
    final q = uri.queryParameters;

    final lat = double.tryParse(q['lat'] ?? q['latitude'] ?? '');
    final lng = double.tryParse(q['lng'] ?? q['longitude'] ?? '');
    GeoPoint? location;
    if (lat != null && lng != null) {
      location = GeoPoint(latitude: lat, longitude: lng);
    }

    final fields = <String, String>{};
    q.forEach((key, value) {
      if (!_coreKeys.contains(key) && value.isNotEmpty) {
        fields[key] = value;
      }
    });

    ContactInfo? contact;
    final name = q['name'], phone = q['phone'], email = q['email'];
    if ((name?.isNotEmpty ?? false) ||
        (phone?.isNotEmpty ?? false) ||
        (email?.isNotEmpty ?? false)) {
      contact = ContactInfo(name: name, phone: phone, email: email);
    }

    final locality = (q['locality'] ?? q['address'])?.trim();

    return ReportPrefill(
      speciesId: q['species'],
      location: location,
      localityText: (locality?.isEmpty ?? true) ? null : locality,
      notes: q['notes'],
      fieldValues: fields,
      contact: contact,
    );
  }

  bool get isEmpty =>
      speciesId == null &&
      location == null &&
      localityText == null &&
      notes == null &&
      fieldValues.isEmpty &&
      contact == null;
}
