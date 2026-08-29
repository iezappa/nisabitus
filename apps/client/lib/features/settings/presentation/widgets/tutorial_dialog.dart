import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/router/app_tab.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../shared/support_actions.dart';
import '../settings_providers.dart';

/// The short walkthrough.
///
/// Run as [onboarding] on first launch it also collects the profile name and
/// which tabs to show; opened later from settings it is just the tour.
Future<void> showTutorial(
  BuildContext context, {
  bool onboarding = false,
}) => showDialog<void>(
  context: context,
  // The first run has to be completed, not dismissed: the app needs a
  // visible tab set before it can show anything.
  barrierDismissible: !onboarding,
  builder: (context) => _TutorialDialog(onboarding: onboarding),
);

class _TutorialDialog extends ConsumerStatefulWidget {
  const _TutorialDialog({required this.onboarding});

  final bool onboarding;

  @override
  ConsumerState<_TutorialDialog> createState() => _TutorialDialogState();
}

class _TutorialDialogState extends ConsumerState<_TutorialDialog> {
  final _controller = PageController();
  final _name = TextEditingController();
  int _page = 0;

  @override
  void initState() {
    super.initState();
    _name.text = ref.read(profileNameProvider);
  }

  @override
  void dispose() {
    _controller.dispose();
    _name.dispose();
    super.dispose();
  }

  void _finish() {
    if (widget.onboarding) {
      ref.read(profileNameProvider.notifier).set(_name.text.trim());
      ref.read(onboardingDoneProvider.notifier).set(true);
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    final slides = <Widget>[
      _Slide(
        title: l10n.onboardingWelcome,
        body: l10n.onboardingWelcomeBody,
        art: Image.asset('assets/branding/logo.png', height: 96),
        extra: const SupportProjectsCard(compact: true),
      ),
      _Slide(
        title: l10n.tutorialHabitsTitle,
        body: l10n.tutorialHabitsBody,
        art: _Glyph(icon: Icons.checklist),
      ),
      _Slide(
        title: l10n.tutorialTrackTitle,
        body: l10n.tutorialTrackBody,
        art: _Glyph(icon: Icons.bedtime_outlined),
      ),
      _Slide(
        title: l10n.tutorialFocusTitle,
        body: l10n.tutorialFocusBody,
        art: _Glyph(icon: Icons.timer_outlined),
      ),
      if (widget.onboarding) ...[
        _Slide(
          title: l10n.onboardingNameTitle,
          body: l10n.onboardingNameBody,
          art: _Glyph(icon: Icons.person_outline),
          extra: TextField(
            controller: _name,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(labelText: l10n.settingsProfileName),
          ),
        ),
        _Slide(
          title: l10n.onboardingTabsTitle,
          body: l10n.onboardingTabsBody,
          art: _Glyph(icon: Icons.tune),
          extra: const TabVisibilityPicker(),
        ),
      ],
    ];

    final isLast = _page == slides.length - 1;

    return AlertDialog(
      contentPadding: const EdgeInsets.fromLTRB(Gap.lg, Gap.xl, Gap.lg, 0),
      content: SizedBox(
        width: 420,
        height: 420,
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _controller,
                onPageChanged: (index) => setState(() => _page = index),
                children: slides,
              ),
            ),
            const SizedBox(height: Gap.md),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < slides.length; i++)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: i == _page ? 18 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: i == _page
                          ? theme.colorScheme.primary
                          : theme.colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        if (_page > 0)
          TextButton(
            onPressed: () => _controller.previousPage(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOut,
            ),
            child: Text(l10n.tutorialBack),
          )
        else if (!widget.onboarding)
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.tutorialSkip),
          ),
        FilledButton(
          onPressed: isLast
              ? _finish
              : () => _controller.nextPage(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOut,
                ),
          child: Text(isLast ? l10n.tutorialDone : l10n.tutorialNext),
        ),
      ],
    );
  }
}

class _Slide extends StatelessWidget {
  const _Slide({
    required this.title,
    required this.body,
    required this.art,
    this.extra,
  });

  final String title;
  final String body;
  final Widget art;
  final Widget? extra;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(child: art),
          const SizedBox(height: Gap.xl),
          Text(title, style: theme.textTheme.titleLarge),
          const SizedBox(height: Gap.sm),
          Text(body, style: theme.textTheme.bodyMedium),
          if (extra != null) ...[const SizedBox(height: Gap.xl), extra!],
        ],
      ),
    );
  }
}

class _Glyph extends StatelessWidget {
  const _Glyph({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: 84,
      height: 84,
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.10),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: 36, color: theme.colorScheme.primary),
    );
  }
}

/// The tab checklist, shared by onboarding and settings.
class TabVisibilityPicker extends ConsumerWidget {
  const TabVisibilityPicker({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final visible = ref.watch(visibleTabsProvider);
    final actions = ref.read(tabVisibilityActionsProvider);

    return Wrap(
      spacing: Gap.sm,
      runSpacing: Gap.sm,
      children: [
        for (final tab in AppTab.values)
          FilterChip(
            avatar: Icon(tab.icon, size: 18),
            label: Text(tab.label(l10n)),
            selected: visible.contains(tab),
            onSelected: (value) => actions.setVisible(tab, visible: value),
          ),
      ],
    );
  }
}
