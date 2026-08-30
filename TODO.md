# TODO

Pending work on Nísabit, most worth doing first. Written in English to match
the commit messages and code comments; the app's own copy is Spanish and
English.

Every module of `HABITS_SECTOR_SPEC.md` is implemented, and so is its Anexo.
What is left is polish, infrastructure and a handful of debts — see
[Done](#done) at the bottom for what landed and why it was decided that way.

---

## 1. Typography

The reference mockups use a typeface the app does not have; it currently
runs on the system font.

- [ ] Bundle the font files as assets under `assets/fonts/` and declare
      them in `pubspec.yaml`.

**Do not use `google_fonts`.** It downloads at runtime, which breaks the
offline-first pillar the whole architecture was chosen for.

---

## 2. Continuous integration

- [ ] GitHub Actions: `flutter analyze`, `flutter test`, and a build per
      platform. The stack document asks for it and there is now plenty to
      protect — 545 tests.

---

## 3. The name

The logo reads **NISABITUS**, `About Nísabit.txt` reads **Nísabit**, the
repository is `nisabitus`, and the app title, package name and manifest all
say **Nísabit**.

- [ ] Pick one and unify: `appTitle` in both ARB files, `web/manifest.json`,
      `web/index.html`, `pubspec.yaml`, the tutorial copy, and the backup
      file's `app` field (`BackupDocument.appId`, currently `nisabit`).

Note the last one: changing that id makes every backup written so far
unreadable. If the name changes, the parser has to accept the old id too.

---

## 4. Layout consistency

`CenteredContent` caps the reading measure and centres it. Only Settings
uses it.

- [ ] Apply it to Journal, Pomodoro, Salud, To-Do and the Panel. On a wide
      window they all stretch a card the full width of the screen.

---

## 5. Medication adherence over a changed regimen

`MedicationStats` measures adherence against the entries that are active
**now**. The schema does not record when one was activated, so a long window
counts a medication started yesterday as missed for every earlier day.

- [ ] Either accept it — it is documented in `MedicationStats` — or add an
      `activeFrom` column and measure each day against what was active on
      that day.

---

## 6. Smaller debts

- [ ] The habit form has no description field. The spec notes the data
      exists and the UI should offer it.
- [ ] The Panel is missing the spec's **Acciones rápidas** row.
- [ ] The older progress views (habits, streaks, sleep, pomodoro) still hand
      the chart a **sparse** series, one point per day that has data. The
      five newer ones build a dense one, a point for every day of the
      window. The chart's x axis is positional, so a sparse series draws a
      straight line across a gap and misreads the shape.
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

---

## Done

Kept short on purpose: the reasoning lives in the commit messages and in the
doc comments of the code itself. What is here is only what a later reader
would otherwise have to rediscover.

### The progress pass

Every module wears `ModuleScaffold` and reviews itself through
`ProgressLayout` and the one `DailyAreaChart`. `statsFor(DateRange)` exists
on every repository, each returning a domain stats object.

- Journal reports coverage and the longest run, not "days written": the
  schema allows one entry per day, so entries and days written are the same
  number said twice.
- Nutrition averages over the days actually logged, not over the window — a
  day never written down is missing data, not a fast.
- To-Do counts completions inside the window but open and overdue as they
  stand today.
- Salud keeps one toggle flag per sub-tab, so flipping Sueño leaves
  Ejercicio where the user left it.

### Export and import

One JSON document holding all sixteen tables, in `features/backup/`,
reachable from Ajustes. Carries its own `format` version separately from the
database `schemaVersion`.

- **Replace, not merge.** Merging sixteen tables that reference each other by
  id means renumbering half of them and hoping every reference was found.
- Rows travel as Drift's own JSON **with their ids**, so a restore is a copy
  rather than a reconstruction.
- All-or-nothing from one transaction: clear children first, write parents
  first, let anything that will not go back in roll the whole thing back.
- An **older** schema is accepted, a **newer** one refused: restoring a newer
  backup would drop whatever that version added.
- Projects are ordered by the tree before writing, not by id — a project
  created first can be moved under one created later.
- The table list in `DriftBackupRepository` is written by hand, because
  `allTables` has no foreign key order. A test compares the two, so a table
  added to the database and forgotten there fails loudly rather than leaving
  a hole in every backup.
