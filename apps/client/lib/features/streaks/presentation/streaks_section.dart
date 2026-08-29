import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/name_prompt_dialog.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/wheel_scroll_area.dart';
import '../../../l10n/app_localizations.dart';
import 'streak_providers.dart';
import 'widgets/streak_card.dart';
import 'widgets/streak_editor_dialog.dart';

/// The streaks band above the habit list, per the spec's layout where one
/// tab holds both modules.
class StreaksSection extends ConsumerWidget {
  const StreaksSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final streaks = ref.watch(streaksProvider);
    final actions = ref.read(streakActionsProvider);

    Future<void> createStreak() async {
      final name = await promptForName(context, title: l10n.streakNew);
      if (name != null) await actions.create(name);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          label: l10n.streaksTitle,
          trailing: IconButton(
            icon: const Icon(Icons.add, size: 20),
            tooltip: l10n.streakNew,
            onPressed: createStreak,
          ),
        ),
        streaks.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(Gap.xl),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (error, _) => Padding(
            padding: const EdgeInsets.all(Gap.lg),
            child: Text(
              '$error',
              style: TextStyle(color: theme.colorScheme.error),
            ),
          ),
          data: (items) => items.isEmpty
              ? EmptyState(
                  icon: Icons.local_fire_department_outlined,
                  title: l10n.streaksEmpty,
                  hint: l10n.streaksEmptyHint,
                )
              : SizedBox(
                  height: 124,
                  child: _StreakStrip(count: items.length, builder: (context, index) {
                      final streak = items[index];
                      return SizedBox(
                        width: 200,
                        child: StreakCard(
                          streak: streak,
                          onIncrement: () => actions.increment(streak.id),
                          onRename: () async {
                            final name = await showStreakEditor(
                              context,
                              streak: streak,
                              onReset: () => actions.reset(streak.id),
                              onDelete: () => actions.delete(streak.id),
                            );
                            if (name != null) {
                              await actions.rename(streak.id, name);
                            }
                          },
                        ),
                      );
                  }),
                ),
        ),
      ],
    );
  }
}

/// The horizontal band of streak cards.
///
/// Wrapped so a mouse wheel moves it: without that, any card past the right
/// edge of the window cannot be reached with a mouse at all.
class _StreakStrip extends StatefulWidget {
  const _StreakStrip({required this.count, required this.builder});

  final int count;
  final Widget Function(BuildContext, int) builder;

  @override
  State<_StreakStrip> createState() => _StreakStripState();
}

class _StreakStripState extends State<_StreakStrip> {
  final _controller = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => WheelScrollArea(
    controller: _controller,
    child: ListView.separated(
      controller: _controller,
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: Gap.lg),
      itemCount: widget.count,
      separatorBuilder: (_, _) => const SizedBox(width: Gap.md),
      itemBuilder: widget.builder,
    ),
  );
}
