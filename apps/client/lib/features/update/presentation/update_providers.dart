import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/preferences/preferences.dart';
import '../../../core/time/clock.dart';
import '../../release_notes/domain/app_version.dart';
import '../data/github_update_service.dart';
import '../data/service_worker_bridge.dart';
import '../data/web_update_service.dart';
import '../domain/update_info.dart';

/// The version of the build that is running.
final installedVersionProvider = FutureProvider<AppVersion>((ref) async {
  final info = await PackageInfo.fromPlatform();
  return parseReleaseVersion(info.version) ?? const AppVersion(0, 0, 0);
});

/// Web or GitHub, picked with `kIsWeb`.
final updateServiceProvider = Provider<UpdateService>(
  (ref) => _DeferredUpdateService(() async {
    final current = await ref.read(installedVersionProvider.future);
    final client = http.Client();
    final now = ref.read(clockProvider);
    if (kIsWeb) {
      const bridge = ServiceWorkerBridge();
      return WebUpdateService(
        client: client,
        baseUri: Uri.base.removeFragment().resolve('.'),
        now: now,
        currentVersion: current,
        hasWaitingWorker: bridge.hasUpdate,
      );
    }
    return GitHubUpdateService(
      client: client,
      prefs: ref.read(sharedPreferencesProvider),
      now: now,
      currentVersion: current,
      isAndroid: defaultTargetPlatform == TargetPlatform.android,
    );
  }),
);

class _DeferredUpdateService implements UpdateService {
  _DeferredUpdateService(this._build);
  final Future<UpdateService> Function() _build;

  @override
  Future<UpdateInfo?> check() async {
    try {
      return await (await _build()).check();
    } on Object {
      return null;
    }
  }
}

/// What the banner's main action does: reload into the waiting worker on
/// the web, open the APK or release page elsewhere.
final applyUpdateProvider = Provider<Future<void> Function(UpdateInfo)>(
  (ref) => (info) async {
    if (kIsWeb) {
      await const ServiceWorkerBridge().applyUpdate();
    } else {
      await launchUrl(info.url, mode: LaunchMode.externalApplication);
    }
  },
);

/// The version whose banner the user dismissed.
final dismissedUpdateVersionProvider =
    StateNotifierProvider<StringPreference, String>(
      (ref) => StringPreference(
        ref.watch(sharedPreferencesProvider),
        'update.dismissedVersion',
        fallback: '',
      ),
    );

/// Checked at launch; invalidated when the app comes back to the foreground.
final availableUpdateProvider = FutureProvider<UpdateInfo?>(
  (ref) => ref.watch(updateServiceProvider).check(),
);
