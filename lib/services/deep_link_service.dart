import 'package:app_links/app_links.dart';

/// Surfaces incoming deep links (custom URL schemes) so the app can be launched
/// into a specific flow — used to drive testing from an iOS/Android Shortcut.
class DeepLinkService {
  final AppLinks _appLinks = AppLinks();

  /// The link that cold-started the app, if any.
  Future<Uri?> getInitialLink() => _appLinks.getInitialLink();

  /// Links delivered while the app is already running.
  Stream<Uri> get uriStream => _appLinks.uriLinkStream;
}
