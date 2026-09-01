import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/centered_content.dart';
import '../../../core/widgets/section_label.dart';
import '../../../l10n/app_localizations.dart';
import '../../backup/presentation/widgets/backup_card.dart';
import '../../release_notes/presentation/widgets/release_notes_tile.dart';
import '../../shared/support_actions.dart';
import '../domain/accent_color.dart';
import '../domain/language_preference.dart';
import '../domain/theme_preference.dart';
import 'settings_providers.dart';
import 'widgets/tutorial_dialog.dart';

/// The Ajustes tab: how the app looks, what it shows, and how to support it.
///
/// One flat column of sections, which is the layout every Zyreth app shares
/// (`STACK-APPS-DINAMICAS.md`, 2.2). Deliberately not a card per section:
/// boxing each block adds a border and an inset to every one of them, and on
/// a screen that is mostly one-line rows that reads as clutter rather than as
/// structure. The label and the page gutter carry the grouping instead.
///
/// The order of the sections is fixed by the same document, so someone who
/// uses two of these apps finds the same thing in the same place. Security is
/// absent because this app has no PIN; the visible tabs are its own section
/// and sit before support, where a domain section belongs.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: SafeArea(
        child: CenteredContent(
          child: ListView(
            // The one gutter on the page. Nothing below adds its own, which
            // is what keeps every label, row and control on one left edge.
            padding: const EdgeInsets.fromLTRB(Gap.lg, Gap.lg, Gap.lg, Gap.xxl),
            children: const [
              _AppearanceSection(),
              Gap.vSection,
              _ProfileSection(),
              Gap.vSection,
              _LanguageSection(),
              Gap.vSection,
              _TabsSection(),
              Gap.vSection,
              _DataSection(),
              Gap.vSection,
              _SupportSection(),
              Gap.vSection,
              _AboutSection(),
            ],
          ),
        ),
      ),
    );
  }
}

/// A section is its label and its controls. Nothing boxes them in.
class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [SectionLabel(title), ...children],
  );
}

class _AppearanceSection extends StatelessWidget {
  const _AppearanceSection();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return _Section(
      title: l10n.settingsAppearance,
      children: [
        const _ThemePicker(),
        const SizedBox(height: Gap.xl),
        Text(l10n.settingsAccent, style: theme.textTheme.titleSmall),
        const SizedBox(height: Gap.md),
        const _AccentPicker(),
      ],
    );
  }
}

class _ProfileSection extends StatelessWidget {
  const _ProfileSection();

  @override
  Widget build(BuildContext context) => _Section(
    title: AppLocalizations.of(context).settingsProfile,
    children: const [_ProfileNameField()],
  );
}

class _LanguageSection extends StatelessWidget {
  const _LanguageSection();

  @override
  Widget build(BuildContext context) => _Section(
    title: AppLocalizations.of(context).settingsLanguage,
    children: const [_LanguagePicker()],
  );
}

/// This app's own section: which modules the bottom bar offers.
class _TabsSection extends StatelessWidget {
  const _TabsSection();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return _Section(
      title: l10n.settingsTabs,
      children: [
        Text(l10n.settingsTabsHint, style: theme.textTheme.bodySmall),
        const SizedBox(height: Gap.md),
        const TabVisibilityPicker(),
      ],
    );
  }
}

class _DataSection extends StatelessWidget {
  const _DataSection();

  @override
  Widget build(BuildContext context) => _Section(
    title: AppLocalizations.of(context).settingsYourData,
    children: const [BackupCard()],
  );
}

class _SupportSection extends StatelessWidget {
  const _SupportSection();

  @override
  Widget build(BuildContext context) => _Section(
    title: AppLocalizations.of(context).settingsSupport,
    children: const [SupportProjectsCard()],
  );
}

class _AboutSection extends StatelessWidget {
  const _AboutSection();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return _Section(
      title: l10n.settingsAbout,
      children: [
        Text(l10n.disclaimerTitle, style: theme.textTheme.titleSmall),
        const SizedBox(height: Gap.sm),
        // Printed in full rather than hidden behind a tile that opens a
        // dialog: a notice you have to tap to read is a notice nobody reads.
        Text(
          l10n.disclaimerBody,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            height: 1.45,
          ),
        ),
        const SizedBox(height: Gap.sm),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.school_outlined),
          title: Text(l10n.settingsTutorial),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => showTutorial(context),
        ),
        const ReleaseNotesTile(),
      ],
    );
  }
}

/// Spanish, English, or whatever the device is set to.
class _LanguagePicker extends ConsumerWidget {
  const _LanguagePicker();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final current = ref.watch(languageChoiceProvider);

    String label(LanguageChoice choice) => switch (choice) {
      LanguageChoice.system => l10n.languageSystem,
      LanguageChoice.spanish => l10n.languageSpanish,
      LanguageChoice.english => l10n.languageEnglish,
    };

    return SegmentedButton<LanguageChoice>(
      showSelectedIcon: false,
      segments: [
        for (final choice in LanguageChoice.values)
          ButtonSegment(value: choice, label: Text(label(choice))),
      ],
      selected: {current},
      onSelectionChanged: (selection) =>
          ref.read(languagePreferenceProvider.notifier).set(selection.first.id),
    );
  }
}

/// Light, dark, or whatever the system is doing.
class _ThemePicker extends ConsumerWidget {
  const _ThemePicker();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final current = ref.watch(themeChoiceProvider);

    String label(ThemeChoice choice) => switch (choice) {
      ThemeChoice.system => l10n.themeSystem,
      ThemeChoice.light => l10n.themeLight,
      ThemeChoice.dark => l10n.themeDark,
    };

    IconData icon(ThemeChoice choice) => switch (choice) {
      ThemeChoice.system => Icons.brightness_auto_outlined,
      ThemeChoice.light => Icons.light_mode_outlined,
      ThemeChoice.dark => Icons.dark_mode_outlined,
    };

    return SegmentedButton<ThemeChoice>(
      showSelectedIcon: false,
      segments: [
        for (final choice in ThemeChoice.values)
          ButtonSegment(
            value: choice,
            icon: Icon(icon(choice), size: 18),
            label: Text(label(choice)),
          ),
      ],
      selected: {current},
      onSelectionChanged: (selection) =>
          ref.read(themePreferenceProvider.notifier).set(selection.first.id),
    );
  }
}

/// The accent swatches. Selecting one retints the app immediately.
class _AccentPicker extends ConsumerWidget {
  const _AccentPicker();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final current = ref.watch(accentColorProvider);
    final brightness = Theme.of(context).brightness;

    String label(AccentColor accent) => switch (accent) {
      AccentColor.forest => l10n.accentForest,
      AccentColor.gold => l10n.accentGold,
      AccentColor.clay => l10n.accentClay,
      AccentColor.indigo => l10n.accentIndigo,
      AccentColor.plum => l10n.accentPlum,
      AccentColor.slate => l10n.accentSlate,
    };

    return Wrap(
      spacing: Gap.lg,
      runSpacing: Gap.md,
      children: [
        for (final accent in AccentColor.values)
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Tooltip(
                message: label(accent),
                child: InkResponse(
                  onTap: () => ref
                      .read(accentPreferenceProvider.notifier)
                      .set(accent.id),
                  radius: 28,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: accent.resolve(brightness),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: accent == current
                            ? Theme.of(context).colorScheme.onSurface
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: accent == current
                        ? const Icon(Icons.check, size: 20, color: Colors.white)
                        : null,
                  ),
                ),
              ),
              const SizedBox(height: Gap.xs),
              Text(label(accent), style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
      ],
    );
  }
}

class _ProfileNameField extends ConsumerStatefulWidget {
  const _ProfileNameField();

  @override
  ConsumerState<_ProfileNameField> createState() => _ProfileNameFieldState();
}

class _ProfileNameFieldState extends ConsumerState<_ProfileNameField> {
  late final _controller = TextEditingController(
    text: ref.read(profileNameProvider),
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return TextField(
      controller: _controller,
      textCapitalization: TextCapitalization.words,
      decoration: InputDecoration(labelText: l10n.settingsProfileName),
      // Saved as it is typed: there is nothing to validate and nowhere for
      // the value to go wrong.
      onChanged: (value) =>
          ref.read(profileNameProvider.notifier).set(value.trim()),
    );
  }
}
