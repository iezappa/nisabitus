# TODO

Pending work on Nisabitus, most worth doing first. Written in English to match
the commit messages and code comments; the app's own copy is Spanish and
English.

Every module of `HABITS_SECTOR_SPEC.md` is implemented, and so is its Anexo.
What is left is polish, infrastructure and a handful of debts — see
[Done](#done) at the bottom for what landed and why it was decided that way.

---

## 1. Smaller debts

- [ ] `sqlite3_flutter_libs 0.6.0+eol` and `sqlcipher_flutter_libs
      0.7.0+eol` arrive through `drift_flutter`. They work; they are marked
      end-of-life. Watch for a replacement.
- [ ] The UI has never been checked visually from this environment. WSLg
      composites per Wayland surface, so `ffmpeg -f x11grab` on `:0` returns
      an empty root, and Xvfb with no window manager never maps the window.
      Installing Chromium would allow driving the web build headless and
      taking real screenshots.

---

## Publishing a release

The changelog is what the app calls its own version, so a release is three
edits, and a test fails if any is missed:

1. Bump `version:` in `apps/client/pubspec.yaml`.
2. Add the release at the top of **both** `assets/release_notes/es.json` and
   `assets/release_notes/en.json` — same version, same date, one highlight per
   line, written for a user rather than for a reviewer.
3. Run `flutter test test/features/release_notes/data/`.

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

### The dense progress series

Every progress view hands the chart one point for every day of its window,
zero where nothing was recorded. `dailySeries` in `core/time/` builds it.

- The chart's x axis is **positional**, not temporal. A series that skipped
  its empty days drew a straight line across the gap and reported a shape
  that never happened.
- Emptiness is read off a total (`completions == 0`, `count == 0`), never off
  the series: the series is never empty any more. `ProgressLayout` still
  decides by `points.isEmpty`, so a view passes `const []` when its window
  holds nothing.
- A missed day now **breaks a streak**: `Streak.increment` restarts the count
  at one when a whole calendar day went by unrecorded, instead of resuming.
  The record survives. Without this the chart would draw a fall to zero
  while the counter on the card kept climbing.
- Journal and medication keep building their series inside their own loop,
  which also computes the longest run and the adherence. Calling the helper
  there would mean a second pass over the window for nothing.
- Sleep reads an unrecorded night as zero hours, the same reading every other
  module gives an unlogged day. It is not a claim that nothing was slept —
  `count` says how many nights were written down.

### Release notes

`features/release_notes/` announces what changed. A dialog on the first launch
after an update, and a **Novedades** row in Ajustes carrying a dot while
something is unread.

- **The app has no backend**, so nothing can be pushed: the notes ship as an
  asset inside the binary and a user learns about a change by installing the
  version that carries it. Announcing to installed users without an update
  would need a server and would break the offline-first pillar.
- One JSON file per language under `assets/release_notes/`, not ARB keys. A
  changelog only grows, and the ARBs would gain a key per line per release
  forever. A test parses both files and fails on a typo, a missing
  translation, or two languages that disagree on the history.
- **The changelog declares the app version**, so no `package_info_plus` and no
  reading of package metadata. A test compares it against `pubspec.yaml` so
  the two cannot drift.
- `AppVersion` exists because these arrive as strings and `'1.10.0'` sorts
  before `'1.9.0'` as text, which would hide a release from anyone who
  skipped one.
- Dismissing counts as read. Showing it again every launch would be nagging.
- `LaunchGate` in `core/app/` decides what greets the user, because two things
  want that moment. A first run opens the tutorial and stamps the current
  version as seen: someone installing today was never around for the history.
  A broken changelog is skipped, never a failed launch.

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

### The name

Everything the app calls itself is **Nisabitus**, down to the native shells:
the Dart package, the `appTitle` in both ARB files, the web manifest and
title, the README, the window titles, the Android `applicationId` and Kotlin
package, the iOS and macOS bundle identifiers and product name, the Linux and
Windows binaries, and the SQLite file.

- `BackupDocument.legacyAppId` still reads `nisabit`. It is never written.
  Dropping it would turn every backup taken before the rename into a file
  the app refuses to open. It is the one deliberate survivor.
- Renaming `driftDatabase(name:)` **does not migrate anything**: the app
  opens a new empty file and the old one stays on disk under its old name.
  It was safe here only because the app was unpublished and the only copy
  was a development database, moved by hand.
- Changing the store identifiers was free for the same reason. On a
  published app it is not: the store treats a new id as a different app and
  installed copies stop receiving updates.

### One reading measure everywhere

`CenteredContent.readingMeasure` (640) is the cap, and `ModuleScaffold`
applies it, so Habits, Streaks, Journal, Pomodoro and To-Do got it at once.
Salud and the Panel build their own frame and wrap their own body.

- To-Do passes `listMaxWidth: double.infinity`: its tree and board are two
  panes, not a column of cards. Its progress side is capped like everyone
  else's — reviewing is always a column of figures.
- The cap wraps the whole body, header included, so a week strip does not
  stretch past the content it belongs to.

### Medication adherence over a changed regimen

`Medications.activeFrom` records the day an entry started counting, and
`MedicationStats` measures each day against what was active **on that day**.

- The v5 migration leaves existing rows **null**, meaning "for as long as the
  record goes back". Stamping them with the migration's own day would turn
  every regimen already being followed into one that began the moment the
  user updated the app.
- Bringing a paused entry back moves `activeFrom` to that day: the days it
  sat inactive were never missed. Editing an active entry leaves it alone.
- A day nothing had started yet plots flat and is left out of the total. It
  is outside the regimen, not a day it was skipped.
- Pausing is still undated, so a paused entry drops out of the figures
  entirely, its genuinely taken days included. Documented in
  `MedicationStats`.
- `create` and `update` take `today`, like `TodoRepository.statsFor`, so the
  app's idea of today stays in one place.

### The last of the smaller debts

- The habit form offers **description**, the field the schema always had.
- The Panel carries the spec's **Acciones rápidas** row: one chip per visible
  tab, the Panel itself excluded. It is built from the tabs the user kept, so
  a hidden tab does not come back through the side door.
- A streak can be raised on **a day that was forgotten**, from the editor, up
  to a year back and never past today. Recording the missed day is what
  rescues the run — but only until the next midnight, after which the day
  after the gap has broken it too.
- `Streak.increment` no longer drags `lastUpdated` backwards when the day
  given is earlier than it. It used to, which would have turned the days
  already recorded after the correction into a gap and broken the very run
  the correction was meant to rescue.
