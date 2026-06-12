import 'package:flutter/material.dart';

/// A [Campaign] is the single unit of reuse in WildWatch.
///
/// Everything that makes the app "about squirrels in the Philippines reporting
/// to DENR" lives in a Campaign instance — branding, the species people can
/// report, the extra questions asked, the agency it reaches, and how the report
/// is delivered. A new animal/country/agency is a new [Campaign], not new code.
///
/// Campaigns are selected at build time (see active_campaign.dart) so the same
/// codebase ships as "Squirrel Watch PH", "Cane Toad Watch AU", etc.
@immutable
class Campaign {
  const Campaign({
    required this.id,
    required this.appName,
    required this.tagline,
    required this.missionBlurb,
    required this.country,
    required this.branding,
    required this.species,
    required this.fields,
    required this.agency,
    required this.submission,
    required this.locale,
    this.safetyNotes = const [],
    this.requirePhoto = false,
    this.allowUnknownSpecies = true,
    this.urlScheme = 'wildwatch',
  });

  /// Stable machine id, e.g. `squirrel-ph`. Stored on every report.
  final String id;

  /// User-facing app/campaign name, e.g. "Squirrel Watch PH".
  final String appName;

  /// One-line hook shown under the app name on the home screen.
  final String tagline;

  /// A short paragraph explaining why reporting matters.
  final String missionBlurb;

  final CampaignCountry country;
  final CampaignBranding branding;

  /// The species a reporter can choose from. Order matters (first = default-ish).
  final List<SpeciesOption> species;

  /// Extra, campaign-specific questions appended to the report form.
  final List<ReportField> fields;

  final AgencyConfig agency;
  final SubmissionConfig submission;
  final CampaignLocale locale;

  /// Short safety / handling guidance shown prominently (e.g. "do not touch").
  final List<String> safetyNotes;

  /// Whether a photo is mandatory before a report can be submitted.
  final bool requirePhoto;

  /// Whether the reporter may submit without picking an exact species.
  final bool allowUnknownSpecies;

  /// Custom URL scheme this flavor responds to (e.g. `squirrelwatch`). Used for
  /// deep links so the app can be driven from an iOS/Android Shortcut, e.g.
  /// `squirrelwatch://report?species=...`. The universal `wildwatch` scheme is
  /// always handled too. Per-flavor schemes must also be registered natively
  /// (iOS Info.plist `CFBundleURLTypes`, Android `intent-filter`).
  final String urlScheme;

  SpeciesOption? speciesById(String? id) {
    if (id == null) return null;
    for (final s in species) {
      if (s.id == id) return s;
    }
    return null;
  }
}

@immutable
class CampaignCountry {
  const CampaignCountry({
    required this.code,
    required this.name,
    required this.defaultCenter,
    this.defaultZoom = 5,
  });

  /// ISO-3166 alpha-2, e.g. `PH`.
  final String code;
  final String name;

  /// Map center used before a precise location is captured.
  final MapLatLng defaultCenter;
  final double defaultZoom;
}

/// A tiny lat/lng pair so campaign configs don't depend on the map package.
@immutable
class MapLatLng {
  const MapLatLng(this.latitude, this.longitude);
  final double latitude;
  final double longitude;
}

/// Theming is a swappable token layer. Components must read colours from the
/// generated [ThemeData]/[ColorScheme] — never hard-code colours — so a new
/// campaign restyles the whole app by changing these tokens alone.
@immutable
class CampaignBranding {
  const CampaignBranding({
    required this.seedColor,
    this.accentColor,
    this.emojiBadge = '🐾',
    this.heroIcon = Icons.pets,
  });

  /// Seed for [ColorScheme.fromSeed] — drives the entire palette.
  final Color seedColor;

  /// Optional explicit accent; falls back to the scheme's secondary.
  final Color? accentColor;

  /// Lightweight logo stand-in until real artwork is supplied.
  final String emojiBadge;
  final IconData heroIcon;
}

@immutable
class SpeciesOption {
  const SpeciesOption({
    required this.id,
    required this.commonName,
    this.scientificName,
    this.idHint,
    this.isPrimaryTarget = false,
  });

  final String id;
  final String commonName;
  final String? scientificName;

  /// A short identification tip shown under the option.
  final String? idHint;

  /// Marks the invasive/priority species the campaign is mainly hunting.
  final bool isPrimaryTarget;

  String get displayName =>
      scientificName == null ? commonName : '$commonName ($scientificName)';
}

enum ReportFieldType { text, multiline, integer, choice, boolean }

/// A campaign-defined question appended to the standard report form.
@immutable
class ReportField {
  const ReportField({
    required this.key,
    required this.label,
    required this.type,
    this.hint,
    this.helpText,
    this.required = false,
    this.choices = const [],
    this.icon,
  });

  final String key;
  final String label;
  final ReportFieldType type;
  final String? hint;
  final String? helpText;
  final bool required;

  /// Allowed values for [ReportFieldType.choice].
  final List<String> choices;
  final IconData? icon;
}

@immutable
class AgencyConfig {
  const AgencyConfig({
    required this.name,
    required this.shortName,
    this.website,
    this.phone,
  });

  /// Full agency name, e.g. "DENR – Biodiversity Management Bureau".
  final String name;
  final String shortName;
  final String? website;
  final String? phone;
}

enum SubmissionMethod { email, httpApi }

/// How a finished report leaves the device. There is no WildWatch backend:
/// each campaign delivers directly to its agency, by email or by an HTTP API.
@immutable
class SubmissionConfig {
  const SubmissionConfig({
    required this.method,
    this.email,
    this.api,
  }) : assert(
          (method == SubmissionMethod.email && email != null) ||
              (method == SubmissionMethod.httpApi && api != null),
          'Submission config must include settings for its method',
        );

  final SubmissionMethod method;
  final EmailSubmission? email;
  final HttpApiSubmission? api;

  /// Email hands off to the user's mail app (a tap is required), so it cannot
  /// be flushed silently from the offline queue. HTTP can.
  bool get supportsAutoSubmit => method == SubmissionMethod.httpApi;
}

@immutable
class EmailSubmission {
  const EmailSubmission({
    required this.recipients,
    this.cc = const [],
    required this.subjectTemplate,
  });

  /// Agency inbox(es), e.g. `['bmb@bmb.gov.ph']`.
  final List<String> recipients;
  final List<String> cc;

  /// Subject line with `{species}` and `{locality}` placeholders.
  final String subjectTemplate;
}

@immutable
class HttpApiSubmission {
  const HttpApiSubmission({
    required this.url,
    this.method = 'POST',
    this.headers = const {},
    this.photoFieldName = 'photo',
    this.payloadFieldName = 'report',
  });

  final String url;
  final String method;
  final Map<String, String> headers;

  /// Multipart field name for the attached photo.
  final String photoFieldName;

  /// Multipart field name carrying the JSON report body.
  final String payloadFieldName;
}

/// Campaign-specific user-facing copy. Generic UI chrome stays in widgets and
/// can move to full i18n later; this holds the strings most worth translating
/// (Tagalog-ready) and rebranding per campaign.
@immutable
class CampaignLocale {
  const CampaignLocale({
    this.languageTag = 'en',
    required this.reportCta,
    required this.reportTitle,
    required this.speciesPrompt,
    required this.photoPrompt,
    required this.locationPrompt,
    required this.submitLabel,
    this.thanksMessage = 'Thank you for helping protect local wildlife.',
  });

  final String languageTag;
  final String reportCta;
  final String reportTitle;
  final String speciesPrompt;
  final String photoPrompt;
  final String locationPrompt;
  final String submitLabel;
  final String thanksMessage;
}
