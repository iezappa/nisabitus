# TODO

Pending work on Nisabitus, most worth doing first. Written in English to match
the commit messages and code comments; the app's own copy is Spanish and
English.

Every module of `HABITS_SECTOR_SPEC.md` is implemented, and so is its Anexo.
What is left is polish, infrastructure and a handful of debts — see
[Done](#done) at the bottom for what landed and why it was decided that way.

---

## 1. Smaller debts

All three closed on 2026-09-02. Kept here, struck through, because what each
one turned out to be is worth more than the line that described it.

- [x] ~~`sqlite3_flutter_libs 0.6.0+eol` and `sqlcipher_flutter_libs
      0.7.0+eol`~~ — **nothing to wait for on this side.** `+eol` is the last
      version those packages will ever have, and their own description says
      what replaces them: *"Not used anymore, update to version 3.x of
      package:sqlite3 instead"*. `sqlite3 3.5.2` is already in the lock file,
      so the code is on the replacement; what is left is `drift_flutter`
      dropping the two shims from its own pubspec. Re-check when
      `drift_flutter` moves past 0.3.1 — there is no action before that.
- [x] ~~Nothing tests the web build.~~ `tool/test_web.sh` drives the app end
      to end in a real browser, and the `web` job in `ci.yml` runs it on every
      push. Two things it does not cover, both known:
      - `flutter drive` cannot set response headers, so the page is served
        without cross-origin isolation and drift takes the IndexedDB path.
        That is the storage GitHub Pages gives, so it is the path worth
        guarding — but **OPFS stays untested**.
      - On the web drift answers from a worker over a message channel, so the
        screen goes quiet before the row exists. `pumpAndSettle` returning is
        not the write landing: assertions after a save go through
        `pumpUntilFound`, or they pass on Linux and flake in a browser.
- [x] ~~The screen captures cover seven screens in Spanish, light theme.~~
      Twenty-six now: dark theme, English, a phone-sized window (390x844) and
      all eight dialogs. Note for whoever adds another dialog — `rootBundle`
      has nothing behind it in a widget test, so a screen that loads an asset
      is photographed as a spinner, and a spinner is an animation:
      `pumpAndSettle` times out rather than failing on the picture. The
      screenshot test reads the shipped assets off the disk, synchronously,
      because a widget test drives fake async and a real disk read never
      completes inside a pump either.

---

## 2. Features asked for

Not debts — work that was decided and is not written yet.

- [x] ~~A database of recorded meals.~~ `Foods` (schema v6) filled itself
      from what was saved, and the food form offered it back. **Replaced in
      v13** — see below. An entry holds **no reference** to the food it came
      from, on purpose, and that has survived both shapes: correcting a food
      today must not rewrite what last week says was eaten.
- [x] ~~A real food database, scaled by weight.~~ v13 reshapes `Foods` into a
      reference table quoted **per 100 g** (`caloriesPer100g` and friends —
      the unit is in every column name because a figure silently quoted for
      the wrong weight is wrong by a factor nobody notices). Picking a food
      and typing what it weighed computes the entry as `per100 * grams / 100`,
      in `domain/food_portion.dart` rather than inline in a widget, and the
      result is written into the visible macro fields: scaling the user cannot
      see is scaling the user cannot check. Rounded, not truncated — the
      entry's columns are integers and truncating loses a fraction on nearly
      every entry, always downwards, so a day would add up to less than it was.
      It ships seeded with ~80 foods actually eaten here (`data/
      argentine_food_seed.dart`, Dart source rather than a bundled asset so
      the picker does not photograph as a spinner). **Those figures are not
      sourced yet** — see the open item below. `isBuiltIn` separates what the app shipped from what the
      user wrote, so the seed can be re-run — `insertOrIgnore` on the unique
      folded name — without ever merging over someone's own row.

      **The old `Foods` rows are dropped by the migration, deliberately.**
      They quoted macros against a free-text portion — "1 plato" — so their
      figures are for a weight nobody recorded. Reading those as per-100 g
      values would multiply a user's numbers by an arbitrary factor and say
      nothing about having done it, and a wrong figure that looks right is
      worse than a missing one. There is no honest conversion, so there is no
      conversion. The cost is bounded: those rows were a convenience cache the
      app filled by itself, and what is lost is the typing that filled them.
      `FoodEntries` is **not touched** — the record of what was actually eaten
      survives intact, and a migration test asserts exactly that.

      What went with the reshape, and why: `Foods.portion`, because there is
      only one weight now and a second one could only contradict it; and
      `lastUsedAt`, because a reference table of eighty foods is read by
      searching for a name, not by browsing what was eaten this morning — so
      the list is alphabetical and has a search box, and "recently used" would
      only bury the seed. The consequence worth knowing: the catalogue no
      longer fills itself from saved entries, because it cannot. It is seeded
      and added to on purpose instead.

      Open on this:

- [ ] **The seed figures are not sourced.** They were written from commonly
      published composition values, not transcribed from any table that was
      opened, and the file said "ARGENFOODS with USDA as the fallback" before
      anybody had read either. That citation is gone; the header now says what
      the numbers actually are. Walking the list against ARGENFOODS
      (Universidad Nacional de Luján) and USDA FoodData Central is a pass of
      its own. Start at the loose end — milanesa, empanada, locro, pastel de
      papa, choripán are estimates by construction — and leave the staples for
      last, because an apple, an egg and a litre of oil are measured objects
      and already agree with every table. A wrong figure that looks right is
      the same failure the dropped `Foods` rows were about, one layer up.
- [x] ~~A meal log.~~ `FoodEntries.meal` (v6), nullable — every entry written
      before the app asked keeps a null meal and shows under "Sin asignar",
      because stamping them would put food on the record at an hour nobody
      ate it. The day reads as one heading per meal, each with its own total.
- [x] ~~A hydration log.~~ `features/hydration/` (v7), a fifth tab under
      Salud. A row per drink rather than one editable daily total: water is
      drunk in glasses, and a single number typed at midnight is a guess.
- [x] ~~A dialog for exercises~~ — it already existed. `showExerciseForm`,
      called from `exercise_view.dart`, plus `showSetForm` for the sets. The
      item was written before they landed and nobody struck it out.
- [x] ~~A dialog for medication~~ — same: `showMedicationForm`, called from
      `medication_view.dart`.
- [x] ~~Meditation.~~ Asked for alongside these. `features/meditation/` (v8)
      is a first-level tab of its own. It records a sitting, it does not run
      one: a timer would make the app something to look at while meditating,
      and would leave anyone who sat without it unable to write it down.
- [x] ~~Change the logo in the nav bar.~~ Painted white through `BrandLogo`
      (`color` + `BlendMode.srcIn`) rather than shipped as a second image, so
      the artwork keeps one source of truth. **It is invisible in the light
      theme** and that is not a bug in the code: the navigation rail's
      background is `_card`, pure white, and `brand_logo_light.png` in the
      goldens is a photograph of the mark disappearing into it. Either the
      rail gets a surface to sit on or the mark takes its ink from the theme.
      Left as asked, on the record here.

### Training, the way Serenio does it

Rewritten on 2026-09-03, after the first attempt was tried and rejected.

**What was built first (v9), and why it went.** A `Routines` table with a start
and a length in weeks, `RoutineExercises` prescribing days and targets, and the
day read by comparing the two. It works. It is the wrong shape for this: you
have to create a plan before you can write anything down, the day is read-only
against it, and nothing can be ticked off.

**What replaced it (v10)** is the shape Serenio uses, which is also the shape
habits in this same app already use: **one row per exercise per day, and that
row is both the plan and the record.**

| Field | What it holds |
|---|---|
| `sets`, `reps`, `weightKg`, `comments` | What to do |
| `completed`, `rpe`, `feedback` | What happened |
| `recurrenceGroupId`, `repeatDays`, `repeatForever` | What it is part of |

A repetition is **materialised**: creating one writes a row for every day it
lands on, up to a number of weeks, a date, or a ten-year horizon for "siempre".
Nothing is computed at read time, and that is the point — a day that owns its
row can be corrected, ticked and commented on without any of it reaching the
days around it. It answers the objection the v9 design existed to answer, and
answers it for free.

Stopping a repetition removes the **later days that are still pending** and
leaves the ones already trained. Stopping a repetition is not undoing the
training that happened under it.

The reference video stays on `Exercises` — that is the one thing kept from v9.
A squat is performed the same way whoever prescribed it, so the link is right
once instead of copied onto every day it comes round.

**Disciplines (v11)** came from the same place, and are the second half of
Serenio's fitness page. A swim is not four sets of ten at eighty kilos: it is
forty-five minutes and two kilometres. Its own table, because one table for
both shapes is one table with half its columns null on every row — and no
catalogue behind it, because "Natación" does not need a definition somewhere
else before it can be written down.

The recurrence is shared rather than copied: `ExerciseRecurrence` describes
repeating a swim and repeating a squat, because it is the same question and
two answers to it would drift.

Two smaller things landed with it:

- The exercise catalogue folds away, shut by default, showing how many it
  holds. It is a reference list, not a day's work — which is the reasoning
  v12 followed all the way, and took the section off the screen entirely.
- The scheduling form can write down a movement the catalogue does not have
  yet and carry on with it. Finding that out mid-form used to mean cancelling
  and starting somewhere else.

Open on this:

- [x] ~~Two ways to record gym work still sit on the same screen.~~ **One of
      them went.** `ExerciseSets` is dropped in a schema v12 migration — a
      real `DROP TABLE`, so the sets stored under it are gone. That is data
      loss and it was chosen: two records of the same session drift apart, and
      when they do neither of them is the answer to "what did I train". The
      scheduled row survives because it is the one the screen ticks off.

      `Exercises` stays. It is the catalogue the routine points at, and
      without it `ScheduledExercises.exerciseId` references nothing. What went
      is its **section on the screen** — a reference list, not a day's work,
      and the three things it was ever used for now live in the form that
      schedules a movement: writing down one the catalogue does not have,
      correcting one whose name, muscle group or video is wrong, and deleting
      one that should never have been written down. Removing the section
      without those paths would have quietly taken away the only way to fix a
      typo that shows on every day the movement was scheduled on, and the
      only way to get rid of a movement at all. Deleting one still cascades
      into every day it was ever scheduled on, past days included, so the
      confirmation says that rather than the generic "cannot be undone".

      The progress view was rebuilt on the surviving rows, and reads
      differently for it: sets, reps, volume and days trained are now counted
      **only off rows that were ticked off**. A routine written down on Sunday
      used to be work the figures would have claimed happened; now a day
      nobody trained is not a day trained. Bodyweight work still contributes
      no volume and still counts as a day.

      The screen is two sections now — the gym routine, renamed from "Due that
      day", and disciplines.
- [ ] Disciplines have no progress view. Exercises, hydration, meditation and
      the rest all review themselves over a window; minutes and kilometres per
      day would say more than most of them.

Four things found while doing the above, all fixed:

- **The day chips were a second design for a question already answered.** The
  habit form has a weekday picker — round `ChoiceChip`, no tick — and the
  scheduling form grew its own square ticked one instead of reusing it. It is
  now `WeekdayPicker` in `core/widgets/`, the third thing this pass moved out
  of `features/habits/` after the enum and its labels. All three were calendar
  concepts wearing a feature's name.
- **A `Row` centres its children.** The weight field carries a helper line and
  the RPE field does not, so the two were different heights and RPE floated —
  with the helper reading as a label for the wrong field. `CrossAxisAlignment
  .start` fixes it, and the same trap hit the `Divider` tried between the two
  halves of that form: a divider with no width in a start-aligned column
  collapses to nothing. It was removed rather than propped up — no other
  dialog in this app draws one.Three things found while doing the above, all fixed:

- **`gen-l10n` orders placeholders alphabetically** when the ARB does not
  declare them, so `"Semana {week} de {total}"` rendered as "Semana 8 de 2" and
  `"{sets}x{reps}"` as "6x4" — a different session entirely. Declaring
  `@key.placeholders` pins the order. Found by looking at a screenshot; nothing
  else would have caught it, because both strings are perfectly well-formed.
- **The Linux integration test writes to the real database.** After six runs
  the habits list had grown past the window, and a `ListView` does not build
  what is off screen, so the habit it had just saved could not be found — the
  test failed while the app was working. It scrolls to it now.

- **Nutrition had no way to add anything.** `NutritionActions.add` existed
  and nothing called it, so the only food entries that could ever appear were
  the ones a test seeded. `nutrition_view_test.dart` now asserts the way in
  exists, which is the test that would have caught it.
- **The tutorial's logo was never in its own screenshot.** An asset image
  decodes asynchronously and a widget test drives fake async, so the frame was
  photographed before the picture existed. `mount()` now precaches it for
  every shot — for every shot, and not only the ones that show the mark,
  because the image cache is shared and precaching in one test would make a
  later golden depend on which test happened to run first.
- **A new tab used to arrive hidden for everyone.** Tab visibility stored the
  set of *visible* tabs, and such a set cannot tell "I hid this" apart from
  "this did not exist when I last chose" — so every module added afterwards
  shipped switched off, blamed on the user's own settings. The stored set is
  now the *hidden* one, migrated once from the old key against a frozen list
  of the tabs that existed when it was written.

---

## 3. Publishing the web build

The build is published to GitHub Pages by `deploy-pages.yml` on every push to
`main`. One thing about it is not a detail:

- [ ] **Pages cannot send the cross-origin isolation headers**
      (`Cross-Origin-Opener-Policy` / `Cross-Origin-Embedder-Policy`), so the
      browser withholds `SharedArrayBuffer`, drift falls back from OPFS to
      IndexedDB, and IndexedDB persists lazily. A reload at the wrong moment
      leaves a database whose tables exist but which is not marked as
      created; the next launch tries to create them again and dies on every
      screen at once. That is exactly how it was found locally.

      Good enough to let someone try the app. Not good enough to keep a
      journal in. Three ways out, none of them free:

      1. Host where headers can be set (Cloudflare Pages, Netlify: a
         `_headers` file) and point the domain there.
      2. Keep Pages and register a service worker that re-injects the headers
         client-side — the known trick, and it collides with the service
         worker Flutter already registers.
      3. Keep Pages as a demo and **say so in the app**: drift reports the
         implementation it chose, and today `driftDatabase` ignores it. For
         an app whose whole pillar is "your data lives on your device",
         silently running on storage that can lose writes is the wrong
         default. This one is worth doing regardless of 1 and 2.

`tool/serve_web.py` sends the headers locally, and is what a correct host
looks like.

---

## 4. Conformance with the shared standard

The standard is
[standardizer_multiplatform](https://github.com/iezappa/standardizer_multiplatform).
It is the canonical copy: `Estandarización/` here is a working copy, ignored
by git, and loses to that repository on any disagreement.

Last checked against it: **2026-09-02**.

- [ ] **Sentry is a decision, not a debt.** §5 lists it under observability,
      and this app is offline-first with no account and no server: shipping
      crash reports to a third party contradicts the pillar the whole stack
      was chosen for. Decide it and write the answer down — as a deliberate
      exception carried back to the canonical repository, not as an oversight.

CI and `integration_test/` used to be listed here. Both landed in `47ae205`:
`.github/workflows/ci.yml` runs format, analyse, test, integration and build on
every push, and `integration_test/habit_flow_test.dart` starts the app for real.

Walk this when the standard changes, or before a release:

- [ ] **§2.1 Product patterns.** i18n through ARB files, onboarding shown
      once, local PIN (absent here on purpose), disclaimer visible in
      settings, JSON import/export.

### §2.2 Settings layout — conformance indicator

The standard's own indicator, kept here so a drift is visible without opening
the other repository. Walk it when §2.2 changes or before a release; the date
is half the indicator, because "conformant" with no date only says somebody
looked once.

**§2.2 Settings** — Conformant: yes · Last walked: 2026-09-02 ·
Asserted by: `test/features/settings/settings_layout_test.dart`

- [x] Body inside the shared page widget, with a capped measure
      (`CenteredContent`, 640)
- [x] One flat column — no section wrapped in a `Card`
- [x] Every section opened by `SectionLabel`, uppercase
- [x] Sections in the fixed order, with the app's own before SUPPORT
- [x] Separated by `Gap.vSection` — no loose `SizedBox(height: 28)`
- [x] Every `ListTile` with `contentPadding: EdgeInsets.zero`
- [x] Short fixed sets in `SegmentedButton`, not `DropdownButton`
- [x] Support block: the only `Card`, and with no title of its own inside
- [x] Disclaimer printed in full, outside any `ListTile`
- [x] Layout test present and green

Declared deviations, carried back to the canonical repository:

- **SECURITY is omitted** — the app has no PIN, on purpose. §2.1 lists it as
  optional, and an app with no account and no server has nothing to lock.
- **`BackupCard` keeps its name and is not a card.** The name is left over
  from before the migration; renaming it is a rename across the backup slice
  and its tests, not a layout fix.

A change decided here and not carried back to the canonical repository is not
a standard — it is an exception the next project will never hear about.

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

## Looking at the UI

`test/screenshots/` renders the screens to PNG files that can actually be
opened and looked at:

```bash
flutter test test/screenshots --update-goldens
```

Without the flag they are a regression test, so a layout that shifts fails.
`flutter test -x screenshots` leaves them out.

- Running the app on this machine shows nothing: WSLg composites per Wayland
  surface, so `ffmpeg -f x11grab` on `:0` returns an empty root and Xvfb with
  no window manager never maps the window. These captures are how the UI gets
  looked at instead, and they found two real defects the first time they ran.
- Text and icons need the SDK's own Roboto and MaterialIcons: the test binding
  ships Ahem, which draws every glyph as a filled box. A golden that fails
  right after an SDK upgrade is worth looking at before it is regenerated.
- Size the window through `tester.view`, never `setSurfaceSize`: the latter
  resizes the surface but leaves MediaQuery reporting 800x600, so a screen
  that lays itself out by width — To-Do's sidebar — is photographed in a
  shape no user will ever see.

---

## Changing the database schema

Every migration is tested against a real database upgraded the way an
installed copy would be, so a schema change is four steps:

1. Change the tables, bump `schemaVersion`, and write the step in
   `AppDatabase.migration`.
2. `dart run drift_dev schema dump lib/core/database/app_database.dart
   drift_schemas/`
3. `dart run drift_dev schema generate --data-classes --companions
   drift_schemas/ test/core/database/generated/`
4. `flutter test test/core/database/migration_test.dart`

The snapshots under `drift_schemas/` are the record of what shipped; the
ones for v1 to v4 were dumped from worktrees of the commits where each
version lived, because they predate this test. v6 added the food catalogue
and the meal column, v7 the water log, v8 the meditation log, v13 the reshape
of that catalogue into a per-100 g food database — the one migration so far
that throws rows away on purpose rather than as a side effect.

Two traps the tests exist to catch, both already found this way:

- `createTable` builds a table from **today's** definition, columns and
  all. A later `addColumn` on a table an earlier step created fails on a
  duplicate — hence `from >= 3 && from < 5` for `medications.activeFrom`.
- `createTable` writes the table and **nothing else**: indices declared
  with `@TableIndex` have to go up by hand with `m.create(...)`. Missing
  ones do not merely slow a query down — `intake_by_day` is unique, and
  without it the same medication could be ticked twice on one day.

---

## Running the app

```bash
tmux new-session -d -s nisabit -x 200 -y 50 -c apps/client \
  "DISPLAY=:0 flutter run -d linux 2>&1 | tee /tmp/run.log"
```

Hot restart with `tmux send-keys -t nisabit "R"`. It has to live inside tmux:
the harness kills the process group when a command returns, so `&`, `nohup`
and `setsid` all die with it.

In a browser, which is the only way to see the web build:

```bash
flutter build web --release
python3 tool/serve_web.py 8080   # then open http://localhost:8080
```

`serve_web.py` and not `python3 -m http.server`: without the two cross-origin
isolation headers the browser withholds `SharedArrayBuffer` and drift drops to
IndexedDB, which is the storage that loses writes.

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
