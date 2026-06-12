import 'package:flutter/material.dart';

import '../campaign/campaign.dart';

/// Rounded badge showing the campaign's emoji over a tinted surface. Stands in
/// for a real logo and recolours automatically with the theme.
class BrandBadge extends StatelessWidget {
  const BrandBadge({super.key, required this.branding, this.size = 56});

  final CampaignBranding branding;
  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(size * 0.28),
      ),
      alignment: Alignment.center,
      child: Text(
        branding.emojiBadge,
        style: TextStyle(fontSize: size * 0.5),
      ),
    );
  }
}
