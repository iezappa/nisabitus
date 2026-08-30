import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/centered_content.dart';
import '../../../core/widgets/disclaimer.dart';
import '../../../core/widgets/section_header.dart';
import '../../../l10n/app_localizations.dart';
import '../../backup/presentation/widgets/backup_card.dart';
import '../../shared/support_actions.dart';
import '../domain/accent_color.dart';
import '../domain/language_preference.dart';
import '../domain/theme_preference.dart';
import 'settings_providers.dart';
import 'widgets/tutorial_dialog.dart';

/// The Ajustes tab: how the app looks, what it shows, and how to support it.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: CenteredContent(
        child: ListView(
          padding: const EdgeInsets.only(bottom: Gap.xxl),
          children: [
            SectionHeader(label: l10n.settingsAppearance),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Gap.lg),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(Gap.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.settingsTheme,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: Gap.md),
                      const _ThemePicker(),
                      const SizedBox(height: Gap.xl),
                      Text(
                        l10n.settingsAccent,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: Gap.md),
                      const _AccentPicker(),
                      const SizedBox(height: Gap.xl),
                      Text(
                        l10n.settingsLanguage,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: Gap.md),
                      const _LanguagePicker(),
                    ],
                  ),
                ),
              ),
            ),
            SectionHeader(label: l10n.settingsTabs),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Gap.lg),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(Gap.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.settingsTabsHint,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: Gap.md),
                      const TabVisibilityPicker(),
                    ],
                  ),
                ),
              ),
            ),
            SectionHeader(label: l10n.settingsProfile),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Gap.lg),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(Gap.lg),
                  child: const _ProfileNameField(),
                ),
              ),
            ),
            SectionHeader(label: l10n.settingsBackup),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: Gap.lg),
              child: BackupCard(),
            ),
            SectionHeader(label: l10n.settingsDisclaimer),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: Gap.lg),
              child: DisclaimerCard(),
            ),
            SectionHeader(label: l10n.settingsAbout),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Gap.lg),
              child: Card(
                child: ListTile(
                  leading: const Icon(Icons.school_outlined),
                  title: Text(l10n.settingsTutorial),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => showTutorial(context),
                ),
              ),
            ),
            const SizedBox(height: Gap.lg),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: Gap.lg),
              child: SupportProjectsCard(),
            ),
          ],
        ),
      ),
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
