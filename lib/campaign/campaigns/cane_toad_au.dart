import 'package:flutter/material.dart';

import '../campaign.dart';

/// Second flavor — exists to prove the reuse model: a different animal, a
/// different country, and an HTTP API delivery channel instead of email.
///
/// The endpoint below is a placeholder; point it at the real agency API when
/// onboarding this campaign for real.
const Campaign caneToadAuCampaign = Campaign(
  id: 'cane-toad-au',
  appName: 'Cane Toad Watch AU',
  tagline: 'Report invasive cane toads to help protect native species.',
  missionBlurb:
      'Cane toads are a major invasive pest across northern and eastern '
      'Australia. Reporting sightings helps authorities track their spread '
      'into new areas.',
  country: CampaignCountry(
    code: 'AU',
    name: 'Australia',
    defaultCenter: MapLatLng(-25.2744, 133.7751),
    defaultZoom: 4,
  ),
  branding: CampaignBranding(
    seedColor: Color(0xFF6D4C41), // earthy brown
    accentColor: Color(0xFF8D6E63),
    emojiBadge: '\u{1F438}', // 🐸
    heroIcon: Icons.pest_control,
  ),
  species: [
    SpeciesOption(
      id: 'cane-toad',
      commonName: 'Cane toad',
      scientificName: 'Rhinella marina',
      idHint:
          'Large, warty, dry skin; bony ridges over the eyes; sits upright. '
          'Native frogs are usually smaller and smooth/moist.',
      isPrimaryTarget: true,
    ),
    SpeciesOption(
      id: 'unsure-amphibian',
      commonName: 'Unsure — frog or toad',
      idHint: 'Pick this if you cannot tell a cane toad from a native frog.',
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
      key: 'life_stage',
      label: 'Life stage',
      type: ReportFieldType.choice,
      choices: ['Adult', 'Juvenile / metamorph', 'Tadpoles', 'Eggs', 'Unsure'],
      icon: Icons.timeline,
    ),
  ],
  agency: AgencyConfig(
    name: 'Invasive species reporting line',
    shortName: 'Agency',
    website: 'https://www.example.gov.au',
  ),
  submission: SubmissionConfig(
    method: SubmissionMethod.httpApi,
    api: HttpApiSubmission(
      url: 'https://example.gov.au/api/sightings',
      headers: {'Accept': 'application/json'},
    ),
  ),
  locale: CampaignLocale(
    reportCta: 'Report a sighting',
    reportTitle: 'Report a cane toad sighting',
    speciesPrompt: 'What did you see?',
    photoPrompt: 'Add a photo (helps confirm the species)',
    locationPrompt: 'Where did you see it?',
    submitLabel: 'Submit report',
  ),
  safetyNotes: [
    'Cane toads are toxic — do not let pets mouth or eat them.',
    'Wash hands after any contact; their toxin irritates eyes and skin.',
  ],
  requirePhoto: false,
);
