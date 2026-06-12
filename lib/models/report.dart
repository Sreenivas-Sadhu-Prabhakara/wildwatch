/// Lifecycle of a report on the device.
enum ReportStatus {
  /// Saved locally, not yet sent (work in progress or kept for later).
  draft,

  /// Ready to send but waiting — typically offline, will retry.
  queued,

  /// Handed off to the delivery channel (mail app opened, or API accepted).
  submitted,

  /// A submission attempt failed; see [Report.lastError].
  failed,
}

extension ReportStatusLabel on ReportStatus {
  String get label => switch (this) {
        ReportStatus.draft => 'Draft',
        ReportStatus.queued => 'Queued',
        ReportStatus.submitted => 'Submitted',
        ReportStatus.failed => 'Failed',
      };
}

/// A geographic coordinate with optional accuracy in metres.
class GeoPoint {
  GeoPoint({required this.latitude, required this.longitude, this.accuracy});

  final double latitude;
  final double longitude;
  final double? accuracy;

  Map<String, dynamic> toJson() => {
        'latitude': latitude,
        'longitude': longitude,
        if (accuracy != null) 'accuracy': accuracy,
      };

  factory GeoPoint.fromJson(Map<String, dynamic> json) => GeoPoint(
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
        accuracy: (json['accuracy'] as num?)?.toDouble(),
      );
}

/// Optional reporter contact details so the agency can follow up. Reporting is
/// anonymous; all of these may be blank.
class ContactInfo {
  ContactInfo({this.name, this.phone, this.email});

  String? name;
  String? phone;
  String? email;

  bool get isEmpty =>
      (name == null || name!.trim().isEmpty) &&
      (phone == null || phone!.trim().isEmpty) &&
      (email == null || email!.trim().isEmpty);

  Map<String, dynamic> toJson() => {
        if (name != null) 'name': name,
        if (phone != null) 'phone': phone,
        if (email != null) 'email': email,
      };

  factory ContactInfo.fromJson(Map<String, dynamic> json) => ContactInfo(
        name: json['name'] as String?,
        phone: json['phone'] as String?,
        email: json['email'] as String?,
      );
}

/// A single sighting report. Core fields are common to every campaign; the
/// campaign-specific answers live in [fieldValues], keyed by [ReportField.key].
class Report {
  Report({
    required this.id,
    required this.campaignId,
    required this.createdAt,
    required this.observedAt,
    this.speciesId,
    this.speciesName,
    this.location,
    this.localityText,
    this.photoPath,
    this.notes,
    Map<String, String>? fieldValues,
    ContactInfo? contact,
    this.status = ReportStatus.draft,
    this.submittedAt,
    this.lastError,
  })  : fieldValues = fieldValues ?? {},
        contact = contact ?? ContactInfo();

  final String id;
  final String campaignId;
  final DateTime createdAt;

  /// When the sighting happened (defaults to creation time).
  DateTime observedAt;

  String? speciesId;

  /// Human-readable species snapshot, kept so history reads well even if the
  /// campaign's species list later changes.
  String? speciesName;

  GeoPoint? location;

  /// Free-text landmark/address the reporter typed.
  String? localityText;

  /// Absolute path to the attached photo in app storage, if any.
  String? photoPath;

  String? notes;

  /// Answers to campaign-defined [ReportField]s, stored as strings.
  final Map<String, String> fieldValues;

  ContactInfo contact;

  ReportStatus status;
  DateTime? submittedAt;
  String? lastError;

  bool get hasLocation => location != null;

  /// A short locality label for subjects/lists.
  String get localityLabel {
    if (localityText != null && localityText!.trim().isNotEmpty) {
      return localityText!.trim();
    }
    if (location != null) {
      return '${location!.latitude.toStringAsFixed(4)}, '
          '${location!.longitude.toStringAsFixed(4)}';
    }
    return 'Unknown location';
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'campaignId': campaignId,
        'createdAt': createdAt.toIso8601String(),
        'observedAt': observedAt.toIso8601String(),
        'speciesId': speciesId,
        'speciesName': speciesName,
        'location': location?.toJson(),
        'localityText': localityText,
        'photoPath': photoPath,
        'notes': notes,
        'fieldValues': fieldValues,
        'contact': contact.toJson(),
        'status': status.name,
        'submittedAt': submittedAt?.toIso8601String(),
        'lastError': lastError,
      };

  factory Report.fromJson(Map<String, dynamic> json) => Report(
        id: json['id'] as String,
        campaignId: json['campaignId'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
        observedAt: DateTime.parse(json['observedAt'] as String),
        speciesId: json['speciesId'] as String?,
        speciesName: json['speciesName'] as String?,
        location: json['location'] == null
            ? null
            : GeoPoint.fromJson(json['location'] as Map<String, dynamic>),
        localityText: json['localityText'] as String?,
        photoPath: json['photoPath'] as String?,
        notes: json['notes'] as String?,
        fieldValues: (json['fieldValues'] as Map?)?.map(
              (k, v) => MapEntry(k as String, v as String),
            ) ??
            {},
        contact: json['contact'] == null
            ? ContactInfo()
            : ContactInfo.fromJson(json['contact'] as Map<String, dynamic>),
        status: ReportStatus.values.firstWhere(
          (s) => s.name == json['status'],
          orElse: () => ReportStatus.draft,
        ),
        submittedAt: json['submittedAt'] == null
            ? null
            : DateTime.parse(json['submittedAt'] as String),
        lastError: json['lastError'] as String?,
      );
}
