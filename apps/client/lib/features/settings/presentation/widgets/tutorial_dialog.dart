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

  void _move(int delta) => _controller.animateToPage(
    _page + delta,
    duration: const Duration(milliseconds: 240),
    curve: Curves.easeOut,
  );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    final slides = <Widget>[
      _Slide(
        art: Image.asset('assets/branding/logo.png', height: 88),
        title: l10n.onboardingWelcome,
        lead: l10n.onboardingWelcomeBody,
        detail: l10n.onboardingWelcomeDetail,
        extra: const SupportProjectsCard(compact: true),
      ),
      _Slide(
        art: const _Glyph(icon: Icons.checklist),
        title: l10n.tutorialHabitsTitle,
        lead: l10n.tutorialHabitsBody,
        detail: l10n.tutorialHabitsDetail,
      ),
      _Slide(
        art: const _Glyph(icon: Icons.bedtime_outlined),
        title: l10n.tutorialTrackTitle,
        lead: l10n.tutorialTrackBody,
        detail: l10n.tutorialTrackDetail,
      ),
      _Slide(
        art: const _Glyph(icon: Icons.timer_outlined),
        title: l10n.tutorialFocusTitle,
        lead: l10n.tutorialFocusBody,
        detail: l10n.tutorialFocusDetail,
      ),
      if (widget.onboarding) ...[
        _Slide(
          art: const _Glyph(icon: Icons.person_outline),
          title: l10n.onboardingNameTitle,
          lead: l10n.onboardingNameBody,
          detail: l10n.onboardingNameDetail,
          extra: TextField(
            controller: _name,
            textAlign: TextAlign.center,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(labelText: l10n.settingsProfileName),
          ),
        ),
        _Slide(
          art: const _Glyph(icon: Icons.tune),
          title: l10n.onboardingTabsTitle,
          lead: l10n.onboardingTabsBody,
          detail: l10n.onboardingTabsDetail,
          extra: const TabVisibilityPicker(),
        ),
      ],
    ];

    final isLast = _page == slides.length - 1;

    return AlertDialog(
      contentPadding: const EdgeInsets.fromLTRB(Gap.xl, Gap.xl, Gap.xl, 0),
      content: SizedBox(
        width: 460,
        height: 520,
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _controller,
                onPageChanged: (index) => setState(() => _page = index),
                children: slides,
              ),
            ),
            const SizedBox(height: Gap.lg),
            _PageIndicator(page: _page, total: slides.length),
          ],
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(Gap.xl, Gap.md, Gap.xl, Gap.lg),
      actions: [
        if (_page > 0)
          TextButton(onPressed: () => _move(-1), child: Text(l10n.tutorialBack))
        else if (!widget.onboarding)
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.tutorialSkip),
          )
        else
          const SizedBox.shrink(),
        FilledButton(
          onPressed: isLast ? _finish : () => _move(1),
          child: Text(isLast ? l10n.tutorialDone : l10n.tutorialNext),
        ),
      ],
    );
  }
}

/// Dots plus a spelled-out count.
///
/// The dots alone read as decoration; the number is what actually answers
/// "how much of this is left".
class _PageIndicator extends StatelessWidget {
  const _PageIndicator({required this.page, required this.total});

  final int page;
  final int total;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < total; i++)
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: i == page ? 20 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: i == page
                      ? theme.colorScheme.primary
                      : theme.colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
          ],
        ),
        const SizedBox(height: Gap.sm),
        Text(
          l10n.tutorialPageOf(page + 1, total),
          style: theme.textTheme.labelSmall,
        ),
      ],
    );
  }
}

class _Slide extends StatelessWidget {
  const _Slide({
    required this.art,
    required this.title,
    required this.lead,
    required this.detail,
    this.extra,
  });

  final Widget art;
  final String title;

  /// One short line that says what this screen is for.
  final String lead;

  /// The paragraph under it.
  final String detail;

  final Widget? extra;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          art,
          const SizedBox(height: Gap.xl),
          Text(
            title,
            style: theme.textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: Gap.sm),
          Text(
            lead,
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: Gap.md),
          Text(
            detail,
            style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
            textAlign: TextAlign.center,
          ),
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
      width: 88,
      height: 88,
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.10),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: 38, color: theme.colorScheme.primary),
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
      alignment: WrapAlignment.center,
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
