# TODO

Pending work on Nísabit, newest concern first. Written in English to match
the commit messages and code comments; the app's own copy is Spanish and
English.

---

## 1. The progress pass — done

Every module now wears `ModuleScaffold` and reviews itself through
`ProgressLayout` and the one `DailyAreaChart`. The bespoke chart code in
`habits_progress_view.dart`, `sleep_chart.dart` and `pomodoro_screen.dart` is
gone, and the repeated loading-or-error block became
`core/widgets/async_section.dart`.

`statsFor(DateRange)` now exists on every repository, each returning a domain
stats object with a dense per-day series: one point for every day of the
window, so a gap reads as a gap rather than as a straight line between two
distant days.

| Module | Tiles | Chart |
|---|---|---|
| Sueño | average, records, optimal %, range | hours per night, y pinned 0–12 |
| Alimentación | daily average kcal, days logged | calories per day, target line |
| Ejercicio | volume, days trained, sets, reps | volume per day |
| Medicación | adherence %, complete days | adherence per day, y pinned 0–100 |
| Journal | entries, coverage %, longest run | days written |
| Pomodoro | focus minutes, cycles | minutes per day |
| To-Do | completed, open, overdue | tasks completed per day |

Two decisions worth remembering:

- Journal reports coverage and the longest run rather than "days written":
  the schema allows one entry per day, so entries and days written are the
  same number and printing both twice says nothing.
- Salud keeps one flag per sub-tab, so flipping Sueño to progress leaves
  Ejercicio where the user left it.

Still open, carried over:

- [ ] Medication adherence is measured against the **currently** active list.
      The schema does not record when something was activated, so a long
      window will misread a regimen that changed inside it. Either accept and
      document that — it is documented in `MedicationStats` — or add an
      `activeFrom` column.

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
