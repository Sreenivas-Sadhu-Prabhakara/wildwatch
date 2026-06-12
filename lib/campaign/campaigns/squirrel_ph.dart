import 'package:flutter/material.dart';

import '../campaign.dart';

/// First flavor: invasive Finlayson's squirrel reporting in the Philippines,
/// delivered to DENR's Biodiversity Management Bureau.
///
/// Context (2026): DENR-BMB asked the public to report sightings of the
/// invasive Finlayson's squirrel spreading through Metro Manila. The bureau's
/// public inbox is bmb@bmb.gov.ph.
const Campaign squirrelPhCampaign = Campaign(
  id: 'squirrel-ph',
  appName: 'Squirrel Watch PH',
  tagline: 'Spotted a squirrel? Help DENR track an invasive species.',
  missionBlurb:
      'Finlayson’s squirrels are an invasive species not native to the '
      'Philippines. Reporting where you see them helps the DENR Biodiversity '
      'Management Bureau map their spread and protect native wildlife.',
  country: CampaignCountry(
    code: 'PH',
    name: 'Philippines',
    // Roughly Metro Manila, where current sightings are concentrated.
    defaultCenter: MapLatLng(14.5995, 120.9842),
    defaultZoom: 11,
  ),
  branding: CampaignBranding(
    seedColor: Color(0xFF2E7D32), // forest green
    accentColor: Color(0xFFF9A825), // amber
    emojiBadge: '\u{1F43F}\u{FE0F}', // 🐿️
    heroIcon: Icons.forest,
  ),
  species: [
    SpeciesOption(
      id: 'finlaysons-squirrel',
      commonName: "Finlayson's squirrel",
      scientificName: 'Callosciurus finlaysonii',
      idHint:
          'Slender, long bushy tail. Colour varies widely — cream, grey, '
          'reddish or near-white. Often seen on trees, fences and power lines.',
      isPrimaryTarget: true,
    ),
    SpeciesOption(
      id: 'other-squirrel',
      commonName: 'Other / unsure squirrel',
      idHint: 'Pick this if it looks like a squirrel but you are not certain.',
    ),
  ],
  fields: [
    ReportField(
      key: 'count',
      label: 'How many did you see?',
      type: ReportFieldType.integer,
      hint: 'e.g. 1',
      icon: Icons.tag,
    ),
    ReportField(
      key: 'behavior',
      label: 'What was it doing?',
      type: ReportFieldType.choice,
      choices: [
        'On a tree',
        'On power lines / cables',
        'On the ground',
        'On a fence or wall',
        'Inside / on a building',
        'Feeding',
        'Other',
      ],
      icon: Icons.directions_run,
    ),
    ReportField(
      key: 'habitat',
      label: 'Where did you see it?',
      type: ReportFieldType.choice,
      choices: [
        'Residential area',
        'Park or garden',
        'Forest / wooded area',
        'Roadside',
        'Commercial area',
        'Other',
      ],
      icon: Icons.place_outlined,
    ),
    ReportField(
      key: 'still_present',
      label: 'Is it still there now?',
      type: ReportFieldType.boolean,
      icon: Icons.visibility_outlined,
    ),
  ],
  agency: AgencyConfig(
    name: 'DENR – Biodiversity Management Bureau',
    shortName: 'DENR-BMB',
    website: 'https://www.bmb.gov.ph',
    phone: '09690412467',
  ),
  submission: SubmissionConfig(
    method: SubmissionMethod.email,
    email: EmailSubmission(
      recipients: ['bmb@bmb.gov.ph'],
      subjectTemplate: 'Squirrel sighting report — {species} @ {locality}',
    ),
  ),
  locale: CampaignLocale(
    languageTag: 'en',
    reportCta: 'Report a sighting',
    reportTitle: 'Report a squirrel sighting',
    speciesPrompt: 'Which squirrel did you see?',
    photoPrompt: 'Add a photo (helps DENR confirm the species)',
    locationPrompt: 'Where did you see it?',
    submitLabel: 'Send report to DENR',
    thanksMessage:
        'Thank you for helping DENR protect Philippine biodiversity.',
  ),
  safetyNotes: [
    'Do not touch, catch or feed the squirrel — wild animals can carry '
        'disease (including rabies).',
    'Keep a safe distance and keep pets and children away.',
    'A clear photo from a distance is more useful than getting close.',
  ],
  requirePhoto: false,
);
