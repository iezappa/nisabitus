import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/backup/presentation/auto_backup_providers.dart';
import '../../features/backup/presentation/widgets/backup_notice_dialog.dart';
import '../../features/release_notes/domain/release_notes.dart';
import '../../features/release_notes/presentation/release_notes_providers.dart';
import '../../features/release_notes/presentation/widgets/release_notes_dialog.dart';
import '../../features/settings/presentation/settings_providers.dart';
import '../../features/settings/presentation/widgets/tutorial_dialog.dart';

/// Decides what, if anything, greets the user once the app has a navigator —
/// and takes the week's backup while nobody is looking.
///
/// Two things can want the first moment of a launch, and they must not both
/// take it: the first-run wizard, and the announcement of what changed since
/// the user was last here. A first run wins and silences the other — someone
/// installing the app today was never around for the releases it lists.
///
/// It sits in the app builder, above the navigator, so its own context cannot
/// open a dialog: dialogs go through [navigatorKey] instead.
class LaunchGate extends ConsumerStatefulWidget {
  const LaunchGate({
    required this.navigatorKey,
    required this.child,
    super.key,
  });

  final GlobalKey<NavigatorState> navigatorKey;
  final Widget child;

  @override
  ConsumerState<LaunchGate> createState() => _LaunchGateState();
}

class _LaunchGateState extends ConsumerState<LaunchGate> {
  bool _asked = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _greet();
      _keepACopy();
    });
  }

  /// The weekly copy, if one is owed and the user asked for them.
  ///
  /// Here because a launch is the only moment this app is ever guaranteed to
  /// have: nothing runs behind it on any platform it ships to. It does not
  /// wait for the greeting and cannot interrupt it — a copy is written in
  /// the background of a dialog nobody has answered yet, which is exactly
  /// where it belongs.
  Future<void> _keepACopy() => ref.read(autoBackupActionsProvider).runIfDue();

  Future<void> _greet() async {
    if (_asked || !mounted) return;
    _asked = true;

    final language = Localizations.localeOf(context).languageCode;
    final onboarding = !ref.read(onboardingDoneProvider);

    // The changelog ships inside the app, so a failure here is a broken
    // build, not a broken device. Either way it must not stop a launch:
    // there is simply nothing to announce.
    ReleaseNotes? notes;
    try {
      notes = await ref.read(releaseNotesProvider(language).future);
    } on Exception {
      notes = null;
    }

    // The navigator is built in the same frame as this gate, so it is there
    // by now; if it is not, there is nowhere to greet anyone.
    final dialogs = widget.navigatorKey.currentContext;
    if (!mounted || dialogs == null || !dialogs.mounted) return;

    if (onboarding) {
      // Stamped before the wizard is even answered: whatever the user does
      // with it, they are starting on this version, not catching up on it.
      if (notes != null) {
        ref.read(releaseNotesActionsProvider).markSeen(notes.current);
      }
      await showTutorial(dialogs, onboarding: true);
      return;
    }

    // Someone onboarded before the backup notice existed has never been told
    // their data lives only here. Once, before anything else is announced.
    if (!ref.read(backupNoticeAcceptedProvider)) {
      await showBackupNoticeDialog(dialogs);
      if (!mounted || !dialogs.mounted) return;
    }

    if (ref.read(unseenReleasesProvider(language)).isEmpty) return;

    await showReleaseNotes(dialogs, unseenOnly: true);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
