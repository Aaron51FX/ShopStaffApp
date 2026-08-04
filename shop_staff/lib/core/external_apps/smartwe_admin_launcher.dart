import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

typedef ExternalUriOpener = Future<bool> Function(Uri uri);

class SmartWeAdminLauncher {
  SmartWeAdminLauncher({ExternalUriOpener? openUri})
    : _openUri = openUri ?? _openExternalApplication;

  static final Uri appUri = Uri.parse('smartwe-admin://open');

  final ExternalUriOpener _openUri;

  Future<bool> open() => _openUri(appUri);

  static Future<bool> _openExternalApplication(Uri uri) {
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

final smartWeAdminLauncherProvider = Provider<SmartWeAdminLauncher>(
  (_) => SmartWeAdminLauncher(),
);
