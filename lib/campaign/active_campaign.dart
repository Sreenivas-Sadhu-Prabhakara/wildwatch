import 'campaign.dart';
import 'campaigns/cane_toad_au.dart';
import 'campaigns/squirrel_ph.dart';

/// Registry of every campaign this codebase can ship as.
/// Keys must match each campaign's `id`.
const Map<String, Campaign> campaignRegistry = {
  'squirrel-ph': squirrelPhCampaign,
  'cane-toad-au': caneToadAuCampaign,
};

/// Which campaign this build is. Override at build/run time, e.g.
///   flutter run --dart-define=CAMPAIGN=cane-toad-au
const String _selectedCampaignId =
    String.fromEnvironment('CAMPAIGN', defaultValue: 'squirrel-ph');

/// The single active campaign for this build. The whole app reads from this.
final Campaign activeCampaign =
    campaignRegistry[_selectedCampaignId] ?? squirrelPhCampaign;
