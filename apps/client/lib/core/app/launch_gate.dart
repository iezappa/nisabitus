import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/release_notes/domain/release_notes.dart';
import '../../features/release_notes/presentation/release_notes_providers.dart';
import '../../features/release_notes/presentation/widgets/release_notes_dialog.dart';
import '../../features/settings/presentation/settings_providers.dart';
import '../../features/settings/presentation/widgets/tutorial_dialog.dart';

/// Decides what, if anything, greets the user once the app has a navigator.
///
/// Two things can want the first moment of a launch, and they must not both
/// take it: the first-run wizard, and the announcement of what changed since
/// the user was last here. A first run wins and silences the other — someone
/// installing the app today was never around for the releases it lists.
class LaunchGate extends ConsumerStatefulWidget {
  const LaunchGate({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<LaunchGate> createState() => _LaunchGateState();
}

class _LaunchGateState extends ConsumerState<LaunchGate> {
  bool _asked = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _greet());
  }

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

    if (!mounted) return;

    if (onboarding) {
      // Stamped before the wizard is even answered: whatever the user does
      // with it, they are starting on this version, not catching up on it.
      if (notes != null) {
        ref.read(releaseNotesActionsProvider).markSeen(notes.current);
      }
      await showTutorial(context, onboarding: true);
      return;
    }

    if (ref.read(unseenReleasesProvider(language)).isEmpty) return;

    await showReleaseNotes(context, unseenOnly: true);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
