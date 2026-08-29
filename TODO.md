# TODO

Pending work on Nísabit, newest concern first. Written in English to match
the commit messages and code comments; the app's own copy is Spanish and
English.

---

## 1. Finish the progress pass (in flight)

The groundwork landed in `073bc0f`. What exists:

- `core/widgets/daily_area_chart.dart` — the one area chart.
- `core/widgets/progress_layout.dart` — window picker, figures, chart.
- `core/widgets/module_scaffold.dart` — settings, health notice and the
  doing/reviewing toggle in the same place on every screen.
- `TodoTasks.completedAt` (schema v4) — so "what did I finish last week"
  can be answered at all.

What is left:

- [ ] Add `statsFor(DateRange)` to the repositories that lack it:
      nutrition, exercise, medication, journal, to-do.
- [ ] Build the progress view for each: Journal, Pomodoro, To-Do, and the
      four Salud views (Sueño, Alimentación, Ejercicio, Medicación).
- [ ] Move Habits onto `ModuleScaffold`. It has the pattern already but
      wired by hand, which is the copy the refactor exists to remove.
- [ ] Salud needs the toggle to apply to the **selected sub-tab**, not the
      section, since each of its four views has its own list and progress.
- [ ] Retire the bespoke chart code left in `habits_progress_view.dart`,
      `sleep_chart.dart` and `pomodoro_screen.dart` in favour of
      `DailyAreaChart`.

Suggested figures per module, to keep them comparable:

| Module | Tiles | Chart |
|---|---|---|
| Sueño | average, records, optimal %, range | hours per night, y pinned 0–12 |
| Alimentación | daily average kcal, days logged | calories per day, target line |
| Ejercicio | sets, reps, volume, days trained | volume per day |
| Medicación | adherence %, complete days | adherence per day |
| Journal | entries written, days written | entries per day |
| Pomodoro | focus minutes, cycles | minutes per day (already computed) |
| To-Do | completed, open, overdue | tasks completed per day |

Medication adherence is measured against the **currently** active list. The
schema does not record when something was activated, so a long window will
misread a regimen that changed inside it. Either accept and document that,
or add an `activeFrom` column.

---

## 2. Export and import

The spec's Anexo asks for one file holding every entity. The count has grown
past the original ten:

habits, habit completions, streaks, streak history, pomodoro sessions, sleep
logs, journal entries, projects, tasks, task comments, nutrition goals, food
entries, exercises, exercise sets, medications, medication intakes.

- [ ] One JSON document, versioned, with the schema version inside it.
- [ ] Import must be all-or-nothing: a partial restore is worse than none.
- [ ] Decide replace vs merge, and say which in the UI before it runs.

This is the last item of the original spec that has no implementation.

---

## 3. Typography

The reference mockups use a typeface the app does not have; it currently
runs on the system font.

- [ ] Bundle the font files as assets under `assets/fonts/` and declare
      them in `pubspec.yaml`.

**Do not use `google_fonts`.** It downloads at runtime, which breaks the
offline-first pillar the whole architecture was chosen for.

---

## 4. Continuous integration

- [ ] GitHub Actions: `flutter analyze`, `flutter test`, and a build per
      platform. The stack document asks for it and there is now enough to
      protect — 448 tests.

---

## 5. The name

The logo reads **NISABITUS**, `About Nísabit.txt` reads **Nísabit**, the
repository is `nisabitus`, and the app title, package name and manifest all
say **Nísabit**.

- [ ] Pick one and unify: `appTitle` in both ARB files, `web/manifest.json`,
      `web/index.html`, `pubspec.yaml`, and the tutorial copy.

---

## 6. Layout consistency

`CenteredContent` caps the reading measure and centres it. Only Settings
uses it.

- [ ] Apply it to Sueño, Journal, Pomodoro, Salud and the Panel. On a wide
      window they all stretch a card the full width of the screen.

---

## 7. Smaller debts

- [ ] The habit form has no description field. The spec notes the data
      exists and the UI should offer it.
- [ ] The Panel is missing the spec's **Acciones rápidas** row.
- [ ] `sqlite3_flutter_libs 0.6.0+eol` and `sqlcipher_flutter_libs
      0.7.0+eol` arrive through `drift_flutter`. They work; they are marked
      end-of-life. Watch for a replacement.
- [ ] The UI has never been checked visually from this environment. WSLg
      composites per Wayland surface, so `ffmpeg -f x11grab` on `:0` returns
      an empty root, and Xvfb with no window manager never maps the window.
      Installing Chromium would allow driving the web build headless and
      taking real screenshots.

---

## Running the app

```bash
tmux new-session -d -s nisabit -x 200 -y 50 -c apps/client \
  "DISPLAY=:0 flutter run -d linux 2>&1 | tee /tmp/run.log"
```

Hot restart with `tmux send-keys -t nisabit "R"`. It has to live inside tmux:
the harness kills the process group when a command returns, so `&`, `nohup`
and `setsid` all die with it.
