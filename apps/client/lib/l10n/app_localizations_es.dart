// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'Nísabit';

  @override
  String get appTagline => 'El esfuerzo que te eleva';

  @override
  String get tabDashboard => 'Panel';

  @override
  String get tabHabits => 'Hábitos';

  @override
  String get tabJournal => 'Journal';

  @override
  String get tabSleep => 'Sueño';

  @override
  String get tabPomodoro => 'Pomodoro';

  @override
  String get tabTodo => 'To-Do';

  @override
  String get habitsTitle => 'Hábitos';

  @override
  String get habitsList => 'Lista';

  @override
  String get habitsProgress => 'Progreso';

  @override
  String get frequencyDaily => 'Diario';

  @override
  String get frequencyWeekly => 'Semanal';

  @override
  String get frequencyMonthly => 'Mensual';

  @override
  String get frequencyYearly => 'Anual';

  @override
  String get habitsEmpty => 'Todavía no hay hábitos acá';

  @override
  String get habitsEmptyHint => 'Creá el primero y empezá a sostenerlo';

  @override
  String get habitNew => 'Nuevo hábito';

  @override
  String get habitDone => 'Hecho';

  @override
  String get habitCancel => 'Cancelar';

  @override
  String get habitCompleted => 'Completado';

  @override
  String get habitCancelled => 'Cancelado';

  @override
  String habitFinishedOn(String date) {
    return 'Finalizado el $date';
  }

  @override
  String habitTargetBadge(int count) {
    return '${count}x';
  }

  @override
  String get streaksTitle => 'Rachas';

  @override
  String get streaksEmpty => 'Todavía no hay rachas';

  @override
  String get streaksEmptyHint =>
      'Una racha cuenta los días seguidos que sostenés algo';

  @override
  String get streakNew => 'Nueva racha';

  @override
  String get streakDays => 'días';

  @override
  String streakRecord(int count) {
    return 'Récord: $count';
  }

  @override
  String get streakIncrement => '+1';

  @override
  String get streakReset => 'Reiniciar';

  @override
  String get actionSave => 'Guardar';

  @override
  String get actionCancel => 'Cancelar';

  @override
  String get actionDelete => 'Borrar';

  @override
  String get actionEdit => 'Editar';

  @override
  String get fieldName => 'Nombre';

  @override
  String get fieldCategory => 'Categoría';

  @override
  String get fieldFrequency => 'Frecuencia';

  @override
  String get fieldTarget => 'Objetivo por período';

  @override
  String get validationNameRequired => 'El nombre es obligatorio';

  @override
  String deleteConfirmTitle(String name) {
    return '¿Borrar $name?';
  }

  @override
  String get deleteConfirmBody => 'Esta acción no se puede deshacer.';

  @override
  String get comingSoon => 'En construcción';

  @override
  String get comingSoonHint => 'Este módulo todavía no está implementado.';

  @override
  String get weekdayShortMonday => 'L';

  @override
  String get weekdayShortTuesday => 'M';

  @override
  String get weekdayShortWednesday => 'X';

  @override
  String get weekdayShortThursday => 'J';

  @override
  String get weekdayShortFriday => 'V';

  @override
  String get weekdayShortSaturday => 'S';

  @override
  String get weekdayShortSunday => 'D';

  @override
  String get habitRepeatForever => 'Repetir por siempre';

  @override
  String get habitEndDate => 'Fecha de fin';

  @override
  String get habitRepeatDays => 'Días de repetición';

  @override
  String get habitEdit => 'Editar hábito';

  @override
  String habitScheduledOn(String days) {
    return 'Programado: $days';
  }

  @override
  String get habitRevert => 'Volver a pendiente';

  @override
  String get habitsToday => 'Progreso de hoy';

  @override
  String habitsTodayCount(int done, int total) {
    return '$done de $total';
  }

  @override
  String get streakCurrent => 'Racha actual';

  @override
  String get streakLongest => 'Récord';

  @override
  String get rangeDay => 'Día';

  @override
  String get rangeWeek => 'Semana';

  @override
  String get rangeMonth => 'Mes';

  @override
  String get rangeYear => 'Año';

  @override
  String get statsCompleted => 'Completados';

  @override
  String get statsSuccessRate => 'Tasa de éxito';

  @override
  String statsPercent(int value) {
    return '$value%';
  }

  @override
  String statsRangeCaption(int days) {
    return 'Últimos $days días';
  }

  @override
  String get chartEmpty => 'Sin datos en este rango';

  @override
  String get chartEmptyHint => 'Resolvé algún hábito y el progreso aparece acá';

  @override
  String get chartStreaksEmptyHint =>
      'Sumá a una racha y su evolución aparece acá';

  @override
  String get habitsCompletionsPerDay => 'Cumplimientos por día';

  @override
  String get streaksEvolution => 'Evolución';

  @override
  String get weekPrevious => 'Semana anterior';

  @override
  String get weekNext => 'Semana siguiente';

  @override
  String get sleepTitle => 'Sueño';

  @override
  String get sleepLastNight => 'Esa noche';

  @override
  String sleepHours(String hours) {
    return '$hours h';
  }

  @override
  String get sleepNoRecord => 'Sin registro';

  @override
  String get sleepNoRecordHint => 'Anotá cuántas horas dormiste ese día';

  @override
  String get sleepQualityOptimal => 'Óptimo';

  @override
  String get sleepQualityAcceptable => 'Aceptable';

  @override
  String get sleepQualityPoor => 'A mejorar';

  @override
  String get sleepLog => 'Registrar sueño';

  @override
  String get sleepFieldHours => 'Horas dormidas';

  @override
  String get sleepSave => 'Registrar';

  @override
  String get sleepUpdate => 'Actualizar';

  @override
  String get sleepHistory => 'Historial';

  @override
  String get sleepAverage => 'Promedio';

  @override
  String get sleepRecords => 'Registros';

  @override
  String get sleepOptimalNights => 'Noches óptimas';

  @override
  String get sleepRange => 'Rango';

  @override
  String sleepRangeValue(String min, String max) {
    return '$min – $max h';
  }

  @override
  String get sleepInsights => 'Bienestar';

  @override
  String get sleepInsightAverageGood =>
      'Tu promedio está en la franja recomendada. Sostenelo.';

  @override
  String get sleepInsightAverageLow =>
      'Estás durmiendo por debajo de lo recomendado.';

  @override
  String get sleepInsightAverageHigh =>
      'Estás durmiendo por encima de lo habitual.';

  @override
  String get sleepInsightConsistency => 'Consistencia';

  @override
  String get sleepInsightConsistencySteady => 'Tus noches son parejas.';

  @override
  String get sleepInsightConsistencyErratic =>
      'Tus horas varían bastante de una noche a otra.';

  @override
  String get sleepValidationHours => 'Ingresá un número entre 0 y 24';

  @override
  String get journalTitle => 'Journal';

  @override
  String get journalMood => 'Estado emocional';

  @override
  String get journalMoodHint => '¿Cómo te sentiste?';

  @override
  String get journalEnergy => 'Energía';

  @override
  String get journalEnergyLow => 'Baja';

  @override
  String get journalEnergyMedium => 'Media';

  @override
  String get journalEnergyHigh => 'Alta';

  @override
  String get journalGratitude => 'Gratitud';

  @override
  String get journalGratitudeHint => '¿Qué agradecés de hoy?';

  @override
  String get journalFocus => 'Foco del día';

  @override
  String get journalFocusHint => '¿En qué pusiste tu atención?';

  @override
  String get journalReflection => 'Reflexión';

  @override
  String get journalReflectionHint => 'Escribí lo que quieras. Sin apuro.';

  @override
  String get journalIntention => 'Intención para mañana';

  @override
  String get journalIntentionHint => '¿Con qué querés empezar mañana?';

  @override
  String get journalSave => 'Guardar';

  @override
  String get journalUpdate => 'Actualizar';

  @override
  String get journalSaved => 'Guardado';

  @override
  String get journalEntry => 'Entrada del día';

  @override
  String get journalHistory => 'Entradas anteriores';

  @override
  String get journalHistoryEmpty => 'Todavía no hay entradas';

  @override
  String get journalHistoryEmptyHint => 'Lo que escribas va a aparecer acá';

  @override
  String get journalNoPreview => 'Sin contenido';

  @override
  String journalPage(int page, int total) {
    return '$page de $total';
  }

  @override
  String get journalDeleteTitle => '¿Borrar la entrada?';

  @override
  String get supportTitle => 'Apoyar el proyecto';

  @override
  String get supportBody =>
      'Nísabit es gratis, sin cuentas y sin publicidad. Si te sirve, podés colaborar para que siga así.';

  @override
  String get supportCafecito => 'Cafecito';

  @override
  String get supportPatreon => 'Patreon';

  @override
  String get supportLinkFailed => 'No se pudo abrir el enlace';

  @override
  String get settingsTitle => 'Configuración';

  @override
  String get settingsAppearance => 'Apariencia';

  @override
  String get settingsAccent => 'Color de acento';

  @override
  String get settingsTabs => 'Pestañas visibles';

  @override
  String get settingsTabsHint =>
      'Elegí qué secciones querés ver. Siempre queda al menos una.';

  @override
  String get settingsProfile => 'Perfil';

  @override
  String get settingsProfileName => 'Tu nombre';

  @override
  String get settingsTutorial => 'Ver el tutorial';

  @override
  String get settingsAbout => 'Acerca de';

  @override
  String get accentForest => 'Bosque';

  @override
  String get accentGold => 'Dorado';

  @override
  String get accentClay => 'Arcilla';

  @override
  String get accentIndigo => 'Índigo';

  @override
  String get accentPlum => 'Ciruela';

  @override
  String get accentSlate => 'Pizarra';

  @override
  String get tabSettings => 'Ajustes';

  @override
  String get tutorialSkip => 'Saltar';

  @override
  String get tutorialNext => 'Siguiente';

  @override
  String get tutorialDone => 'Empezar';

  @override
  String get tutorialBack => 'Atrás';

  @override
  String get onboardingWelcome => 'Bienvenido a Nísabit';

  @override
  String get onboardingWelcomeBody =>
      'El esfuerzo que te eleva. Tus datos viven en tu equipo: sin cuentas, sin nube, sin telemetría.';

  @override
  String get onboardingNameTitle => '¿Cómo te llamamos?';

  @override
  String get onboardingNameBody =>
      'Solo para saludarte. No sale de este dispositivo.';

  @override
  String get onboardingTabsTitle => '¿Qué querés ver?';

  @override
  String get onboardingTabsBody =>
      'Podés cambiarlo cuando quieras desde Configuración.';

  @override
  String get tutorialHabitsTitle => 'Hábitos y rachas';

  @override
  String get tutorialHabitsBody =>
      'Definí lo que querés sostener y resolvelo cada día. Las rachas cuentan los días seguidos.';

  @override
  String get tutorialTrackTitle => 'Sueño y journal';

  @override
  String get tutorialTrackBody =>
      'Anotá cuánto dormiste y cómo estuvo tu día. La tira semanal te deja completar días que te salteaste.';

  @override
  String get tutorialFocusTitle => 'Foco y tareas';

  @override
  String get tutorialFocusBody =>
      'Sesiones de pomodoro para concentrarte, y proyectos con tareas para no perder el hilo.';
}
