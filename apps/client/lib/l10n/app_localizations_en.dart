// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Nisabitus';

  @override
  String get appTagline => 'The effort that lifts you up';

  @override
  String get tabDashboard => 'Panel';

  @override
  String get tabHabits => 'Habits';

  @override
  String get tabJournal => 'Journal';

  @override
  String get tabSleep => 'Sleep';

  @override
  String get tabPomodoro => 'Pomodoro';

  @override
  String get tabTodo => 'To-Do';

  @override
  String get habitsTitle => 'Habits';

  @override
  String get habitsList => 'List';

  @override
  String get habitsProgress => 'Progress';

  @override
  String get frequencyDaily => 'Daily';

  @override
  String get frequencyWeekly => 'Weekly';

  @override
  String get frequencyMonthly => 'Monthly';

  @override
  String get frequencyYearly => 'Yearly';

  @override
  String get habitsEmpty => 'No habits here yet';

  @override
  String get habitsEmptyHint => 'Create your first one and start keeping it';

  @override
  String get habitNew => 'New habit';

  @override
  String get habitDone => 'Done';

  @override
  String get habitCancel => 'Cancel';

  @override
  String get habitCompleted => 'Completed';

  @override
  String get habitCancelled => 'Cancelled';

  @override
  String habitFinishedOn(String date) {
    return 'Ended on $date';
  }

  @override
  String habitTargetBadge(int count) {
    return '${count}x';
  }

  @override
  String get streaksTitle => 'Streaks';

  @override
  String get streaksEmpty => 'No streaks yet';

  @override
  String get streaksEmptyHint =>
      'A streak counts the days in a row you keep something up';

  @override
  String get streakNew => 'New streak';

  @override
  String get streakDays => 'days';

  @override
  String streakRecord(int count) {
    return 'Record: $count';
  }

  @override
  String get streakIncrement => '+1';

  @override
  String get streakReset => 'Reset';

  @override
  String get streakMissedDay => 'Mark a day I forgot';

  @override
  String get actionSave => 'Save';

  @override
  String get actionCancel => 'Cancel';

  @override
  String get actionDelete => 'Delete';

  @override
  String get actionExpand => 'Show';

  @override
  String get actionCollapse => 'Hide';

  @override
  String get actionEdit => 'Edit';

  @override
  String get fieldName => 'Name';

  @override
  String get fieldDescription => 'Description';

  @override
  String get fieldCategory => 'Category';

  @override
  String get fieldFrequency => 'Frequency';

  @override
  String get fieldTarget => 'Target per period';

  @override
  String get validationNameRequired => 'The name is required';

  @override
  String deleteConfirmTitle(String name) {
    return 'Delete $name?';
  }

  @override
  String get deleteConfirmBody => 'This cannot be undone.';

  @override
  String get comingSoon => 'Under construction';

  @override
  String get comingSoonHint => 'This module is not implemented yet.';

  @override
  String get weekdayShortMonday => 'M';

  @override
  String get weekdayShortTuesday => 'T';

  @override
  String get weekdayShortWednesday => 'W';

  @override
  String get weekdayShortThursday => 'T';

  @override
  String get weekdayShortFriday => 'F';

  @override
  String get weekdayShortSaturday => 'S';

  @override
  String get weekdayShortSunday => 'S';

  @override
  String get habitRepeatForever => 'Repeat forever';

  @override
  String get habitEndDate => 'End date';

  @override
  String get habitRepeatDays => 'Repeat on';

  @override
  String get habitEdit => 'Edit habit';

  @override
  String habitScheduledOn(String days) {
    return 'Scheduled: $days';
  }

  @override
  String get habitRevert => 'Back to pending';

  @override
  String get habitsToday => 'Today\'s progress';

  @override
  String habitsTodayCount(int done, int total) {
    return '$done of $total';
  }

  @override
  String get streakCurrent => 'Current streak';

  @override
  String get streakLongest => 'Record';

  @override
  String get rangeDay => 'Day';

  @override
  String get rangeWeek => 'Week';

  @override
  String get rangeMonth => 'Month';

  @override
  String get rangeYear => 'Year';

  @override
  String get statsCompleted => 'Completed';

  @override
  String get statsSuccessRate => 'Success rate';

  @override
  String statsPercent(int value) {
    return '$value%';
  }

  @override
  String statsRangeCaption(int days) {
    return 'Last $days days';
  }

  @override
  String get chartEmpty => 'No data in this range';

  @override
  String get chartEmptyHint =>
      'Tick off a habit and your progress shows up here';

  @override
  String get chartStreaksEmptyHint =>
      'Add to a streak and its evolution shows up here';

  @override
  String get habitsCompletionsPerDay => 'Completions per day';

  @override
  String get streaksEvolution => 'Evolution';

  @override
  String get weekPrevious => 'Previous week';

  @override
  String get weekNext => 'Next week';

  @override
  String get sleepTitle => 'Sleep';

  @override
  String get sleepLastNight => 'That night';

  @override
  String sleepHours(String hours) {
    return '$hours h';
  }

  @override
  String get sleepNoRecord => 'No record';

  @override
  String get sleepNoRecordHint => 'Note how many hours you slept that day';

  @override
  String get sleepQualityOptimal => 'Optimal';

  @override
  String get sleepQualityAcceptable => 'Acceptable';

  @override
  String get sleepQualityPoor => 'Could be better';

  @override
  String get sleepLog => 'Log sleep';

  @override
  String get sleepFieldHours => 'Hours slept';

  @override
  String get sleepSave => 'Log';

  @override
  String get sleepUpdate => 'Update';

  @override
  String get sleepHistory => 'History';

  @override
  String get sleepAverage => 'Average';

  @override
  String get sleepRecords => 'Records';

  @override
  String get sleepOptimalNights => 'Optimal nights';

  @override
  String get sleepRange => 'Range';

  @override
  String sleepRangeValue(String min, String max) {
    return '$min – $max h';
  }

  @override
  String get sleepInsights => 'Wellbeing';

  @override
  String get sleepInsightAverageGood =>
      'Your average sits in the recommended band. Keep it up.';

  @override
  String get sleepInsightAverageLow =>
      'You are sleeping below what is recommended.';

  @override
  String get sleepInsightAverageHigh => 'You are sleeping more than usual.';

  @override
  String get sleepInsightConsistency => 'Consistency';

  @override
  String get sleepInsightConsistencySteady => 'Your nights are steady.';

  @override
  String get sleepInsightConsistencyErratic =>
      'Your hours swing quite a bit from night to night.';

  @override
  String get sleepValidationHours => 'Enter a number between 0 and 24';

  @override
  String get journalTitle => 'Journal';

  @override
  String get journalMood => 'Mood';

  @override
  String get journalMoodHint => 'How did you feel?';

  @override
  String get journalEnergy => 'Energy';

  @override
  String get journalEnergyLow => 'Low';

  @override
  String get journalEnergyMedium => 'Medium';

  @override
  String get journalEnergyHigh => 'High';

  @override
  String get journalGratitude => 'Gratitude';

  @override
  String get journalGratitudeHint => 'What are you grateful for today?';

  @override
  String get journalFocus => 'Focus of the day';

  @override
  String get journalFocusHint => 'Where did you put your attention?';

  @override
  String get journalReflection => 'Reflection';

  @override
  String get journalReflectionHint => 'Write whatever you like. No rush.';

  @override
  String get journalIntention => 'Intention for tomorrow';

  @override
  String get journalIntentionHint => 'What do you want to start with tomorrow?';

  @override
  String get journalSave => 'Save';

  @override
  String get journalUpdate => 'Update';

  @override
  String get journalSaved => 'Saved';

  @override
  String get journalEntry => 'Today\'s entry';

  @override
  String get journalHistory => 'Earlier entries';

  @override
  String get journalHistoryEmpty => 'No entries yet';

  @override
  String get journalHistoryEmptyHint => 'What you write will show up here';

  @override
  String get journalNoPreview => 'No content';

  @override
  String journalPage(int page, int total) {
    return '$page of $total';
  }

  @override
  String get journalDeleteTitle => 'Delete the entry?';

  @override
  String get supportTitle => 'Support the project';

  @override
  String get supportBody =>
      'Nisabitus is free, account-free and ad-free. If it helps you, you can chip in to keep it that way.';

  @override
  String get supportCafecito => 'Cafecito';

  @override
  String get supportPatreon => 'Patreon';

  @override
  String get supportLinkFailed => 'Could not open the link';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsAppearance => 'Appearance';

  @override
  String get settingsAccent => 'Accent colour';

  @override
  String get settingsTabs => 'Visible tabs';

  @override
  String get settingsTabsHint =>
      'Pick the sections you want to see. At least one always stays.';

  @override
  String get settingsProfile => 'Profile';

  @override
  String get settingsProfileName => 'Your name';

  @override
  String get settingsTutorial => 'See the tutorial';

  @override
  String get settingsAbout => 'About';

  @override
  String get accentForest => 'Forest';

  @override
  String get accentGold => 'Gold';

  @override
  String get accentClay => 'Clay';

  @override
  String get accentIndigo => 'Indigo';

  @override
  String get accentPlum => 'Plum';

  @override
  String get accentSlate => 'Slate';

  @override
  String get tabSettings => 'Settings';

  @override
  String get tutorialSkip => 'Skip';

  @override
  String get tutorialNext => 'Next';

  @override
  String get tutorialDone => 'Get started';

  @override
  String get tutorialBack => 'Back';

  @override
  String get onboardingWelcome => 'Welcome to Nisabitus';

  @override
  String get onboardingWelcomeBody => 'The effort that lifts you up.';

  @override
  String get onboardingNameTitle => 'What should we call you?';

  @override
  String get onboardingNameBody => 'What should we call you?';

  @override
  String get onboardingTabsTitle => 'What do you want to see?';

  @override
  String get onboardingTabsBody => 'What do you want to see?';

  @override
  String get tutorialHabitsTitle => 'Habits and streaks';

  @override
  String get tutorialHabitsBody => 'Keeping up, not starting over.';

  @override
  String get tutorialTrackTitle => 'Sleep and journal';

  @override
  String get tutorialTrackBody => 'Tracking is understanding yourself.';

  @override
  String get tutorialFocusTitle => 'Focus and tasks';

  @override
  String get tutorialFocusBody => 'One thing at a time.';

  @override
  String get pomodoroTitle => 'Pomodoro';

  @override
  String get pomodoroSessions => 'Sessions';

  @override
  String get pomodoroNew => 'New session';

  @override
  String get pomodoroEdit => 'Edit session';

  @override
  String get pomodoroEmpty => 'No sessions yet';

  @override
  String get pomodoroEmptyHint => 'Create one and go into focus mode';

  @override
  String get pomodoroStatePending => 'Pending';

  @override
  String get pomodoroStateInProgress => 'In progress';

  @override
  String get pomodoroStateCompleted => 'Completed';

  @override
  String get pomodoroStateCancelled => 'Cancelled';

  @override
  String get pomodoroCycles => 'Cycles';

  @override
  String get pomodoroFocusMinutes => 'Focus minutes';

  @override
  String get pomodoroBreakMinutes => 'Break minutes';

  @override
  String get pomodoroPurpose => 'Purpose';

  @override
  String get pomodoroCurrentSession => 'Current session';

  @override
  String get pomodoroPhaseFocus => 'Focus';

  @override
  String get pomodoroPhaseRest => 'Break';

  @override
  String pomodoroCycleOf(int done, int total) {
    return 'Cycle $done of $total';
  }

  @override
  String get pomodoroStart => 'Start';

  @override
  String get pomodoroPause => 'Pause';

  @override
  String get pomodoroSkip => 'Next phase';

  @override
  String get pomodoroFinish => 'Finish';

  @override
  String get pomodoroCancel => 'Cancel session';

  @override
  String get pomodoroClose => 'Close without saving';

  @override
  String get pomodoroStats => 'Statistics';

  @override
  String get pomodoroTotalFocus => 'Total focus';

  @override
  String get pomodoroTotalCycles => 'Cycles completed';

  @override
  String get pomodoroByCategory => 'By category';

  @override
  String get pomodoroMinutesPerDay => 'Minutes per day';

  @override
  String pomodoroMinutes(int minutes) {
    return '$minutes min';
  }

  @override
  String pomodoroHoursMinutes(int hours, int minutes) {
    return '$hours h $minutes min';
  }

  @override
  String pomodoroValidationRange(int min, int max) {
    return 'Between $min and $max';
  }

  @override
  String get todoTitle => 'To-Do';

  @override
  String get todoProjects => 'Projects';

  @override
  String get todoNewProject => 'New project';

  @override
  String get todoNewSubproject => 'New subproject';

  @override
  String get todoNoProjects => 'No projects yet';

  @override
  String get todoNoProjectsHint => 'Create one to start organising your tasks';

  @override
  String get todoPickProject => 'Pick a project';

  @override
  String get todoPickProjectHint => 'Its tasks will show up here';

  @override
  String get todoIncludeSubprojects => 'Include subprojects';

  @override
  String get todoViewKanban => 'Board';

  @override
  String get todoViewList => 'List';

  @override
  String get todoNewTask => 'New task';

  @override
  String get todoEditTask => 'Edit task';

  @override
  String get todoNoTasks => 'No tasks';

  @override
  String get todoNoTasksHint => 'Add the first one with the button below';

  @override
  String get todoStatusTodo => 'To do';

  @override
  String get todoStatusInProgress => 'In progress';

  @override
  String get todoStatusDone => 'Done';

  @override
  String get todoPriorityLow => 'Low';

  @override
  String get todoPriorityMedium => 'Medium';

  @override
  String get todoPriorityHigh => 'High';

  @override
  String get todoPriorityUrgent => 'Urgent';

  @override
  String get todoDueOverdue => 'Overdue';

  @override
  String get todoDueToday => 'Due today';

  @override
  String get todoDueUpcoming => 'Upcoming';

  @override
  String get todoFieldTitle => 'Title';

  @override
  String get todoFieldDescription => 'Description';

  @override
  String get todoFieldDue => 'Due date';

  @override
  String get todoFieldPriority => 'Priority';

  @override
  String get todoFieldStatus => 'Status';

  @override
  String get todoComments => 'Progress notes';

  @override
  String get todoCommentHint => 'Note some progress';

  @override
  String get todoNoComments => 'No notes yet';

  @override
  String get todoFilters => 'Filters';

  @override
  String get todoFilterCategory => 'Category contains';

  @override
  String get todoFilterClear => 'Clear';

  @override
  String todoTaskCount(int count) {
    return '$count tasks';
  }

  @override
  String get todoMoveNotAllowed => 'That move would break the project tree';

  @override
  String dashboardGreeting(String name) {
    return 'Hello, $name';
  }

  @override
  String get dashboardGreetingAnonymous => 'Hello';

  @override
  String get dashboardSubtitle => 'Here is today.';

  @override
  String get dashboardRefresh => 'Refresh';

  @override
  String get dashboardPendingTasks => 'Open tasks';

  @override
  String dashboardOverdue(int count) {
    return '$count overdue';
  }

  @override
  String get dashboardNoOverdue => 'None overdue';

  @override
  String get dashboardHabitsToday => 'Today\'s habits';

  @override
  String dashboardHabitsRatio(int done, int total) {
    return '$done of $total';
  }

  @override
  String get dashboardFocus => 'Focus';

  @override
  String get dashboardFocusEmpty => 'Nothing pending. Enjoy it.';

  @override
  String get dashboardHealth => 'Health and journal';

  @override
  String get dashboardSleepToday => 'Sleep today';

  @override
  String get dashboardJournalReady => 'Done';

  @override
  String get dashboardJournalPending => 'Pending';

  @override
  String get dashboardNoJournal => 'No entry';

  @override
  String get dashboardQuickActions => 'Quick actions';

  @override
  String get dashboardNoDue => 'No date';

  @override
  String tutorialPageOf(int page, int total) {
    return '$page of $total';
  }

  @override
  String get onboardingWelcomeDetail =>
      'Nisabitus brings habits, streaks, sleep, journal and tasks together in one place that lives on your device. No accounts, no cloud, no telemetry: your data never leaves your machine, and the app works just the same offline.';

  @override
  String get tutorialHabitsDetail =>
      'Define what you want to repeat and settle it each day with one tap. Choose whether it is daily, weekly, monthly or yearly, and which days you expect to keep it.\n\nStreaks count separately: they track the days in a row of something and hold on to your record, even after you go back to zero.';

  @override
  String get tutorialTrackDetail =>
      'Note how many hours you slept and the app tells you how the night went, works out your average and shows you the trend.\n\nThe journal offers six short fields to close the day: how you were, what you are grateful for, where you put your focus and what you want to start with tomorrow.\n\nThe week strip lets you fill in days you skipped.';

  @override
  String get tutorialFocusDetail =>
      'The pomodoro splits your work into focus and break cycles, and keeps count of the minutes you actually concentrated.\n\nTo-Do organises your tasks into projects up to three levels deep, and you move them between To do, In progress and Done by dragging them across the board.';

  @override
  String get onboardingNameDetail =>
      'We only use it to greet you on the panel. It never leaves this device, and you can change or clear it whenever you like.';

  @override
  String get onboardingTabsDetail =>
      'Pick the sections that serve you and leave out the ones that do not. You can change this any time from Settings, which is always within reach at the top left.';

  @override
  String get settingsTheme => 'Theme';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get languageSpanish => 'Español';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageSystem => 'System';

  @override
  String get tabHealth => 'Health';

  @override
  String get healthSleep => 'Sleep';

  @override
  String get healthNutrition => 'Nutrition';

  @override
  String get healthExercise => 'Exercise';

  @override
  String get nutritionGoals => 'Daily targets';

  @override
  String get nutritionEditGoals => 'Edit targets';

  @override
  String get nutritionCalories => 'Calories';

  @override
  String get nutritionProtein => 'Protein';

  @override
  String get nutritionCarbs => 'Carbs';

  @override
  String get nutritionFat => 'Fat';

  @override
  String nutritionGrams(int value) {
    return '$value g';
  }

  @override
  String nutritionKcal(int value) {
    return '$value kcal';
  }

  @override
  String nutritionOfTarget(int value, int target) {
    return '$value of $target';
  }

  @override
  String nutritionRemaining(int value) {
    return '$value kcal left';
  }

  @override
  String nutritionOver(int value) {
    return '$value kcal over';
  }

  @override
  String get nutritionToday => 'What you ate';

  @override
  String get nutritionEmpty => 'Nothing logged that day';

  @override
  String get nutritionEmptyHint => 'Note what you ate and it adds itself up';

  @override
  String get nutritionAdd => 'Add food';

  @override
  String get nutritionEditEntry => 'Edit food';

  @override
  String get nutritionPortion => 'Portion';

  @override
  String get nutritionPortionHint => '150 g, 1 plate, 2 units';

  @override
  String get meditationTitle => 'Meditation';

  @override
  String get meditationToday => 'What you sat';

  @override
  String get meditationEmpty => 'Nothing logged that day';

  @override
  String get meditationEmptyHint => 'Log how long you sat and how it went';

  @override
  String get meditationAdd => 'Log a session';

  @override
  String get meditationEdit => 'Edit session';

  @override
  String meditationMinutes(Object value) {
    return '$value min';
  }

  @override
  String meditationDayTotal(Object value) {
    return '$value min that day';
  }

  @override
  String get meditationDuration => 'Duration';

  @override
  String get meditationNote => 'How it went';

  @override
  String get meditationNoteHint => 'Hard to start, fell asleep, came out calm…';

  @override
  String meditationValidationMinutes(Object max) {
    return 'Enter a number between 1 and $max';
  }

  @override
  String get meditationMinutesPerDay => 'Minutes per day';

  @override
  String get meditationAverageDaily => 'Daily average';

  @override
  String get meditationDaysPractised => 'Days practised';

  @override
  String get meditationLongestStreak => 'Longest streak';

  @override
  String get hydration => 'Hydration';

  @override
  String get hydrationTarget => 'Daily target';

  @override
  String get hydrationEditTarget => 'Edit target';

  @override
  String hydrationMillilitres(Object value) {
    return '$value ml';
  }

  @override
  String hydrationRemaining(Object value) {
    return '$value ml to go';
  }

  @override
  String get hydrationReached => 'Target reached';

  @override
  String get hydrationToday => 'What you drank';

  @override
  String get hydrationEmpty => 'Nothing logged that day';

  @override
  String get hydrationEmptyHint => 'Log each glass and it adds itself up';

  @override
  String get hydrationAdd => 'Add';

  @override
  String get hydrationCustom => 'Another amount';

  @override
  String get hydrationAmount => 'Amount';

  @override
  String hydrationValidationAmount(Object max) {
    return 'Enter a number between 1 and $max';
  }

  @override
  String get hydrationPerDay => 'Millilitres per day';

  @override
  String get hydrationAverageDaily => 'Daily average';

  @override
  String get hydrationDaysOnTarget => 'Days on target';

  @override
  String get nutritionMeal => 'Meal';

  @override
  String get nutritionMealBreakfast => 'Breakfast';

  @override
  String get nutritionMealLunch => 'Lunch';

  @override
  String get nutritionMealSnack => 'Snack';

  @override
  String get nutritionMealDinner => 'Dinner';

  @override
  String get nutritionMealNone => 'No meal';

  @override
  String get nutritionUnassigned => 'Unassigned';

  @override
  String get nutritionFoodDatabase => 'Food database';

  @override
  String get nutritionFoodDatabaseHint => 'Pick a food and say what it weighed';

  @override
  String get nutritionFoodSearch => 'Search a food';

  @override
  String get nutritionFoodNone => 'Nothing matches that';

  @override
  String get nutritionFoodNew => 'New food';

  @override
  String get nutritionFoodEdit => 'Edit food';

  @override
  String get nutritionFoodMine => 'Yours';

  @override
  String get nutritionFoodDeleteBody =>
      'It only leaves the food database. What you already ate stays exactly as it was logged.';

  @override
  String nutritionPer100g(int value) {
    return '$value kcal per 100 g';
  }

  @override
  String get nutritionPer100gLabel => 'Per 100 g';

  @override
  String get nutritionWeight => 'Weight';

  @override
  String get nutritionWeightHint => 'The figures scale to what you weighed';

  @override
  String nutritionValidationGrams(int max) {
    return 'Enter a weight between 0 and $max g';
  }

  @override
  String nutritionValidationNumber(int max) {
    return 'Enter a number between 0 and $max';
  }

  @override
  String get discipline => 'Disciplines';

  @override
  String get disciplineHint =>
      'Swimming, running, cycling — what is measured in time, not sets';

  @override
  String get disciplineEmpty => 'Nothing practised that day';

  @override
  String get disciplineAdd => 'Log a discipline';

  @override
  String get disciplineEdit => 'Edit discipline';

  @override
  String get disciplineName => 'What you practised';

  @override
  String get disciplineNameHint => 'Swimming, Running, Cycling, Yoga…';

  @override
  String get disciplineDuration => 'Duration';

  @override
  String get disciplineDistance => 'Distance';

  @override
  String disciplineMinutes(int value) {
    return '$value min';
  }

  @override
  String disciplineKm(String value) {
    return '$value km';
  }

  @override
  String get disciplineNotes => 'Notes';

  @override
  String get disciplineCompleteTitle => 'How did it go?';

  @override
  String get disciplineCompleteHint =>
      'Record the time and distance you actually did. Anything left blank stays as planned.';

  @override
  String disciplineValidationMinutes(int max) {
    return 'Enter a number between 1 and $max';
  }

  @override
  String disciplineValidationDistance(int max) {
    return 'Enter a number between 0 and $max';
  }

  @override
  String get plan => 'Plan';

  @override
  String get planToday => 'Gym Routine';

  @override
  String get planEmpty => 'Nothing logged for that day';

  @override
  String get planEmptyHint =>
      'Write an exercise down and, if it repeats, say on which days';

  @override
  String get planAdd => 'Log an exercise';

  @override
  String get planEdit => 'Edit exercise';

  @override
  String planSetsReps(int sets, int reps) {
    return '${sets}x$reps';
  }

  @override
  String planWeight(String weight) {
    return '$weight kg';
  }

  @override
  String planRpe(int value) {
    return 'RPE $value';
  }

  @override
  String get planComments => 'Cues';

  @override
  String get planCommentsHint => 'Down to parallel, no bounce…';

  @override
  String get planFeedback => 'How it went';

  @override
  String get planFeedbackHint =>
      'Last rep was ugly, felt heavier than expected…';

  @override
  String get planDone => 'Done';

  @override
  String get planReopen => 'Back to pending';

  @override
  String get planComplete => 'Mark as done';

  @override
  String get planCompleteTitle => 'How did it go?';

  @override
  String get planCompleteHint =>
      'Record the weight and effort you actually hit. Anything left blank stays as planned.';

  @override
  String get planRepeat => 'Repeat';

  @override
  String get planRepeatDays => 'Days';

  @override
  String get planRepeatUntilLabel => 'How long for';

  @override
  String get planRepeatWeeks => 'For weeks';

  @override
  String get planRepeatUntil => 'Until a date';

  @override
  String get planRepeatForever => 'Always';

  @override
  String get planRepeatWeeksValue => 'Number of weeks';

  @override
  String get planRepeatUntilValue => 'Ends on';

  @override
  String planRepeatSummary(String days) {
    return 'Repeats $days';
  }

  @override
  String get planStopRepeat => 'Stop repeating';

  @override
  String get planStopRepeatTitle => 'Stop repeating?';

  @override
  String get planStopRepeatBody =>
      'The later days you have not done yet are removed. What you already trained stays as it is.';

  @override
  String get planValidationDays => 'Pick at least one day';

  @override
  String planValidationNumber(int max) {
    return 'Enter a number between 1 and $max';
  }

  @override
  String get planValidationRpe => 'RPE runs from 1 to 10';

  @override
  String get planValidationEndDate =>
      'A repetition cannot end before it starts';

  @override
  String get exerciseVideo => 'Reference video';

  @override
  String get exerciseVideoHint => 'Link to a video showing the movement';

  @override
  String get exerciseOpenVideo => 'Watch the video';

  @override
  String get exerciseNew => 'New exercise';

  @override
  String get exerciseEdit => 'Edit exercise';

  @override
  String get exerciseDeleteBody =>
      'Deleting an exercise also deletes every day it was written down on, past ones included. This cannot be undone.';

  @override
  String get exerciseMuscleGroup => 'Muscle group';

  @override
  String get exerciseDescription => 'Description';

  @override
  String get exerciseSets => 'Sets';

  @override
  String get exerciseReps => 'Reps';

  @override
  String get exerciseWeight => 'Weight (kg)';

  @override
  String get exerciseBodyweight => 'Bodyweight';

  @override
  String get exerciseTotalSets => 'Sets';

  @override
  String get exerciseTotalReps => 'Reps';

  @override
  String get exerciseVolume => 'Volume';

  @override
  String exerciseVolumeValue(String value) {
    return '$value kg';
  }

  @override
  String get exercisePickOne => 'Pick an exercise';

  @override
  String get disclaimerTitle => 'This is a log, not medical advice';

  @override
  String get disclaimerBody =>
      'Nisabitus is not a medical or nutritional application. It is a log: it keeps what you write down and hands it back to you in order.\n\nIt does not diagnose, interpret symptoms, calculate doses, or recommend treatments, diets or routines. The targets you set are your own, not a professional instruction.\n\nBefore starting, changing or stopping a medication, a supplement, a diet or a training plan, talk to a health professional. If any symptom worries you, seek advice without delay.';

  @override
  String get disclaimerAction => 'Understood';

  @override
  String get disclaimerTooltip => 'About this data';

  @override
  String get healthMeds => 'Medication';

  @override
  String get medsTitle => 'Medication and supplements';

  @override
  String get medsToday => 'For that day';

  @override
  String get medsCatalogue => 'What you take';

  @override
  String get medsNew => 'Add';

  @override
  String get medsEdit => 'Edit';

  @override
  String get medsEmpty => 'Nothing added yet';

  @override
  String get medsEmptyHint => 'Add what you take and tick it off each day';

  @override
  String get medsKind => 'Kind';

  @override
  String get medsKindMedication => 'Medication';

  @override
  String get medsKindSupplement => 'Supplement';

  @override
  String get medsDose => 'Dose';

  @override
  String get medsDoseHint => '500 mg, 2 capsules, 10 drops';

  @override
  String get medsSchedule => 'When';

  @override
  String get medsScheduleHint => 'Morning, every 8 h, with dinner';

  @override
  String get medsNotes => 'Notes';

  @override
  String get medsActive => 'Active';

  @override
  String get medsInactiveHint => 'Anything paused stays out of the day';

  @override
  String medsTakenCount(int done, int total) {
    return '$done of $total';
  }

  @override
  String get medsNoneActive => 'Nothing active to tick off';

  @override
  String get medsNoneActiveHint => 'Activate something from the list below';

  @override
  String get progressEntries => 'Records';

  @override
  String get progressPerDay => 'Per day';

  @override
  String get nutritionCaloriesPerDay => 'Calories per day';

  @override
  String get nutritionAverageDaily => 'Daily average';

  @override
  String get nutritionDaysLogged => 'Days logged';

  @override
  String get exerciseVolumePerDay => 'Volume per day';

  @override
  String get exerciseDaysTrained => 'Days trained';

  @override
  String get medsAdherence => 'Adherence';

  @override
  String get medsAdherencePerDay => 'Adherence per day';

  @override
  String get medsDaysComplete => 'Complete days';

  @override
  String get journalEntriesWritten => 'Entries written';

  @override
  String get journalCoverage => 'Coverage';

  @override
  String get journalLongestRun => 'Longest run';

  @override
  String get journalPerDay => 'Entries per day';

  @override
  String get todoProgress => 'Progress';

  @override
  String get todoCompletedPerDay => 'Tasks completed per day';

  @override
  String get todoCompleted => 'Completed';

  @override
  String get todoOpen => 'Open';

  @override
  String get todoOverdue => 'Overdue';

  @override
  String get sleepHoursPerNight => 'Hours per night';

  @override
  String progressDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days',
      one: '1 day',
    );
    return '$_temp0';
  }

  @override
  String get todoProgressEmptyHint => 'Finish a task and it shows up here';

  @override
  String get settingsBackup => 'Backup';

  @override
  String get settingsYourData => 'Your data';

  @override
  String get settingsSupport => 'Support';

  @override
  String get backupExport => 'Export';

  @override
  String get backupImport => 'Import';

  @override
  String get backupReplaceWarning =>
      'Importing replaces everything you have now.';

  @override
  String get backupConfirmTitle => 'Replace everything you have?';

  @override
  String get backupConfirmBody =>
      'What is stored now is deleted and replaced by whatever the file holds. It cannot be undone, so export first if you are unsure.';

  @override
  String get backupConfirmAction => 'Replace';

  @override
  String backupExported(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Backup saved: $count records',
      one: 'Backup saved: 1 record',
    );
    return '$_temp0';
  }

  @override
  String backupImported(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Data restored: $count records',
      one: 'Data restored: 1 record',
    );
    return '$_temp0';
  }

  @override
  String get backupSomeIgnored =>
      'Part of the file comes from an older version and could not be restored.';

  @override
  String get backupNotABackup => 'That file is not a Nisabitus backup';

  @override
  String get backupNewerVersion =>
      'The backup comes from a newer version of Nisabitus';

  @override
  String get backupCorrupt => 'The backup is damaged and cannot be read';

  @override
  String get backupFailed => 'It could not be completed';

  @override
  String get settingsReleaseNotes => 'What\'s new';

  @override
  String get releaseNotesWhatsNew => 'What\'s new';

  @override
  String get releaseNotesHistory => 'Release history';

  @override
  String releaseNotesVersion(String version) {
    return 'Version $version';
  }

  @override
  String get releaseNotesClose => 'Got it';

  @override
  String get storageDegradedWarning =>
      'This browser keeps your data in storage that may be lost on a reload or when browser data is cleared. Export a backup now.';

  @override
  String get storageVolatileWarning =>
      'This browser cannot store your data: everything you record will be lost when you close this tab. Export a backup before you leave.';

  @override
  String get storageExportNow => 'Export now';

  @override
  String get storageWarningDismiss => 'Dismiss';

  @override
  String get recoveryTitle => 'The local database could not be opened';

  @override
  String get recoveryBody =>
      'The data stored on this device could not be read, so the app cannot start normally. You can restore a backup file, or start over with an empty database.';

  @override
  String get recoveryImport => 'Import a backup';

  @override
  String get recoveryReset => 'Reset local database';

  @override
  String get recoveryImportConfirmTitle => 'Import a backup?';

  @override
  String get recoveryImportConfirmBody =>
      'The unreadable database on this device will be permanently deleted and replaced by what the backup file holds. It cannot be undone.';

  @override
  String get recoveryResetConfirmTitle => 'Reset the local database?';

  @override
  String get recoveryResetConfirmBody =>
      'Everything stored on this device will be permanently deleted and the app will start empty. It cannot be undone.';

  @override
  String get recoveryResetConfirmAction => 'Reset';

  @override
  String get backupNoticeTitle => 'Your data lives only on this device';

  @override
  String get backupNoticeLead => 'No server keeps a copy.';

  @override
  String get backupNoticeOnboarding =>
      'We don\'t store your data on our servers. If you uninstall the app, lose or reset your device, or clear your browser data, it will be lost. Export regularly from Settings → Your data → Export and keep the file somewhere safe.';

  @override
  String get backupNoticeAccept => 'Got it, I\'ll back up';

  @override
  String get backupNoticeSettings =>
      'Your data isn\'t stored on our servers. Export regularly and keep the file off this device.';

  @override
  String get backupReminderNever => 'You haven\'t backed up your data yet.';

  @override
  String backupReminderOverdue(int days) {
    return 'Your last backup was $days days ago.';
  }

  @override
  String get backupReminderAction => 'Export';

  @override
  String get backupReminderDismiss => 'Not now';

  @override
  String get eraseAllData => 'Delete all my data';

  @override
  String get eraseAllTitle => 'Delete all your data?';

  @override
  String get eraseAllBody =>
      'Every record on this device is deleted, along with your profile and settings; only the language and the appearance are kept. The app then starts over from the welcome screens. It cannot be undone, and no copy exists anywhere else: export first if you might want any of it back.';

  @override
  String get eraseAllConfirmWord => 'DELETE';

  @override
  String eraseAllTypeToConfirm(String word) {
    return 'Type $word to confirm';
  }

  @override
  String get eraseAllExportFirst => 'Export first';

  @override
  String get eraseAllAction => 'Delete everything';

  @override
  String get privacyPolicy => 'Privacy policy';

  @override
  String get termsOfUse => 'Terms of use';

  @override
  String get developerContact => 'Contact';

  @override
  String developerContactBody(String developer) {
    return '$developer · reports and questions on GitHub';
  }

  @override
  String get openSourceLicenses => 'Licenses';

  @override
  String get backupExportCsv => 'Export CSV';

  @override
  String get backupCsvHint =>
      'The CSV is for reading your data in a spreadsheet; it cannot be imported. To back up, use Export.';

  @override
  String backupCsvExported(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'CSV saved: $count records',
      one: 'CSV saved: 1 record',
    );
    return '$_temp0';
  }

  @override
  String get updateAvailableTitle => 'A new version is available';

  @override
  String updateAvailableBody(String version) {
    return 'Version $version is available.';
  }

  @override
  String get updateAvailableBackupHint =>
      'This version changes how your data is stored. Export a backup before updating.';

  @override
  String get updateUnsupportedPath =>
      'Your version is too old to update directly. Export a backup and check the instructions.';

  @override
  String get updateActionReload => 'Update';

  @override
  String get updateActionDownload => 'Download';

  @override
  String get updateActionExport => 'Export';

  @override
  String get updateActionDismiss => 'Not now';

  @override
  String get saveFailed => 'Couldn\'t save. Please try again.';

  @override
  String get deleteFailed => 'Couldn\'t delete. Please try again.';

  @override
  String get staleStoreTitle => 'Another tab is running an older version';

  @override
  String get staleStoreBody =>
      'Nisabitus is open in another tab or window with an older version, and while it stays open this one cannot save anything. Your data is intact. Close every other Nisabitus tab, then reload this page.';

  @override
  String get todoColumns => 'Columns';

  @override
  String get todoEditColumns => 'Edit columns';

  @override
  String get todoNewColumn => 'New column';

  @override
  String get todoColumnName => 'Column name';

  @override
  String get todoColumnCountsAsDone => 'Counts as finished';

  @override
  String get todoColumnCountsAsDoneHint =>
      'Tasks landing here stop being overdue and count as completed in the progress figures.';

  @override
  String todoColumnHoldsTasks(int count) {
    return 'This column still holds $count task(s). Move them before deleting it.';
  }

  @override
  String get todoColumnLastOne => 'The board needs at least one column.';

  @override
  String get todoColumnMoveLeft => 'Move left';

  @override
  String get todoColumnMoveRight => 'Move right';

  @override
  String get todoTaskDetail => 'Task detail';

  @override
  String get todoNoDescription => 'No description';

  @override
  String get todoFieldColumn => 'Column';

  @override
  String get todoUpdates => 'Updates';

  @override
  String get todoAddUpdate => 'Add an update';

  @override
  String get todoProjectAllDone => 'All done';

  @override
  String get todoProjectOverdue => 'Has overdue tasks';

  @override
  String get todoProjectDueToday => 'Has tasks due today';

  @override
  String get todoProjectOpen => 'Has open tasks';

  @override
  String get todoProjectEmpty => 'No tasks';

  @override
  String todoProjectProgress(int done, int total) {
    return '$done of $total finished';
  }

  @override
  String get actionClose => 'Close';

  @override
  String get todoChecklist => 'Checklist';

  @override
  String get todoAddChecklistItem => 'Add an item';

  @override
  String todoChecklistProgress(int done, int total) {
    return '$done of $total';
  }

  @override
  String get todoInColumn => 'in list';

  @override
  String get todoDetails => 'Details';

  @override
  String get todoNoUpdates => 'No updates yet';

  @override
  String todoBoardOf(String project) {
    return '$project board';
  }

  @override
  String get nutritionComposition => 'What it is made of';

  @override
  String get nutritionComposedHint =>
      'Add foods with their weight and the macros work themselves out. You can still correct them by hand.';

  @override
  String get nutritionSaveAsDish => 'Keep this combination as a dish';

  @override
  String get nutritionSaveAsDishHint =>
      'It joins your food database, so you can pick it next time.';

  @override
  String get nutritionDishSaved => 'Dish saved to your database';

  @override
  String get nutritionTotal => 'Total';

  @override
  String get nutritionRemoveFood => 'Remove';

  @override
  String get nutritionHowMuch => 'How much does it weigh?';

  @override
  String nutritionPartOf(String name, int grams) {
    return '$name, $grams g';
  }

  @override
  String get habitsAllCategories => 'All';

  @override
  String get habitsFilterByCategory => 'Filter by category';

  @override
  String get habitsNoCategory => 'No category';

  @override
  String get habitsNewCategory => 'New category…';

  @override
  String get planVideo => 'Watch the video';

  @override
  String get planVideoTitle => 'Exercise video';

  @override
  String get planVideoOpen => 'Open outside';

  @override
  String get planVideoExternalOnly =>
      'This link cannot be shown in here. It opens in your browser.';

  @override
  String get planVideoNotice =>
      'The video loads from its own site; that is the one thing here that leaves the device.';

  @override
  String get steps => 'Steps';

  @override
  String get stepsToday => 'Steps for the day';

  @override
  String get stepsNone => 'No steps written down for this day yet.';

  @override
  String get stepsRecord => 'Write down steps';

  @override
  String get stepsEdit => 'Correct';

  @override
  String get stepsClear => 'Remove the entry';

  @override
  String stepsCount(String steps) {
    return '$steps steps';
  }

  @override
  String get stepsGoal => 'Daily target';

  @override
  String get stepsGoalEdit => 'Change the target';

  @override
  String get stepsGoalReached => 'Target reached';

  @override
  String stepsOfGoal(String walked, String goal) {
    return '$walked of $goal';
  }

  @override
  String get stepsAverage => 'Average per day';

  @override
  String get stepsBest => 'Best day';

  @override
  String get stepsDaysLogged => 'Days written down';

  @override
  String get stepsGoalDays => 'Days on target';

  @override
  String get stepsPerDay => 'Steps per day';

  @override
  String get stepsEmptyHint =>
      'Write down a day\'s steps and the week shows up here.';

  @override
  String stepsValidation(String max) {
    return 'Enter a number between 0 and $max.';
  }

  @override
  String stepsAveragedOverLogged(int days) {
    return 'Averaged over the days you wrote down, not over the $days in the window.';
  }

  @override
  String get dashboardActivity => 'Activity';

  @override
  String dashboardActivityCaption(int weeks) {
    return 'Last $weeks weeks';
  }

  @override
  String get dashboardActivityEmpty =>
      'Nothing written down yet. Everything you record fills in a square.';

  @override
  String get dashboardActivityLess => 'Less';

  @override
  String get dashboardActivityMore => 'More';

  @override
  String dashboardActivityDays(int days) {
    return '$days days with activity';
  }

  @override
  String dashboardActivityRun(int days) {
    return 'Longest run: $days days';
  }

  @override
  String dashboardActivityTotal(int count) {
    return '$count records';
  }

  @override
  String dashboardActivityCell(String date, int count) {
    return '$date: $count records';
  }

  @override
  String dashboardActivityCellEmpty(String date) {
    return '$date: nothing written down';
  }

  @override
  String get settingsVacation => 'Holiday mode';

  @override
  String get settingsVacationHint =>
      'Pause habits and streaks while you are away. A paused day neither breaks a streak nor counts against you.';

  @override
  String get vacationSwitch => 'I am on holiday';

  @override
  String get vacationSwitchHint => 'Paused from today until you switch it off.';

  @override
  String vacationActiveSince(String date) {
    return 'Paused since $date';
  }

  @override
  String get vacationEnd => 'End';

  @override
  String get vacationAdd => 'Add a period';

  @override
  String get vacationEditTitle => 'Paused period';

  @override
  String get vacationEmpty => 'No periods written down yet.';

  @override
  String vacationRange(String start, String end) {
    return '$start to $end';
  }

  @override
  String vacationOpenRange(String date) {
    return 'From $date, still open';
  }

  @override
  String vacationLength(int days) {
    return '$days days';
  }

  @override
  String get vacationFrom => 'From';

  @override
  String get vacationUntil => 'Until';

  @override
  String get vacationUntilOpen => 'Open';

  @override
  String get vacationNote => 'Note (optional)';

  @override
  String get vacationNoteHint => 'Trip, flu, moving house…';

  @override
  String get vacationDelete => 'Delete period';

  @override
  String get vacationBackwards => 'The end cannot come before the start.';

  @override
  String get vacationPausedToday =>
      'Today is paused: habits and streaks will not break.';

  @override
  String get dashboardHabitsPaused => 'Paused';
}
