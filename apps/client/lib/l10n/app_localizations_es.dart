// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'Nisabitus';

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
  String get streakMissedDay => 'Marcar un día olvidado';

  @override
  String get actionSave => 'Guardar';

  @override
  String get actionCancel => 'Cancelar';

  @override
  String get actionDelete => 'Borrar';

  @override
  String get actionExpand => 'Mostrar';

  @override
  String get actionCollapse => 'Ocultar';

  @override
  String get actionEdit => 'Editar';

  @override
  String get fieldName => 'Nombre';

  @override
  String get fieldDescription => 'Descripción';

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
      'Nisabitus es gratis, sin cuentas y sin publicidad. Si te sirve, podés colaborar para que siga así.';

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
  String get onboardingWelcome => 'Bienvenido a Nisabitus';

  @override
  String get onboardingWelcomeBody => 'El esfuerzo que te eleva.';

  @override
  String get onboardingNameTitle => '¿Cómo te llamamos?';

  @override
  String get onboardingNameBody => '¿Cómo te llamamos?';

  @override
  String get onboardingTabsTitle => '¿Qué querés ver?';

  @override
  String get onboardingTabsBody => '¿Qué querés ver?';

  @override
  String get tutorialHabitsTitle => 'Hábitos y rachas';

  @override
  String get tutorialHabitsBody => 'Sostener, no arrancar.';

  @override
  String get tutorialTrackTitle => 'Sueño y journal';

  @override
  String get tutorialTrackBody => 'Registrar es entenderse.';

  @override
  String get tutorialFocusTitle => 'Foco y tareas';

  @override
  String get tutorialFocusBody => 'Una cosa a la vez.';

  @override
  String get pomodoroTitle => 'Pomodoro';

  @override
  String get pomodoroSessions => 'Sesiones';

  @override
  String get pomodoroNew => 'Nueva sesión';

  @override
  String get pomodoroEdit => 'Editar sesión';

  @override
  String get pomodoroEmpty => 'Todavía no hay sesiones';

  @override
  String get pomodoroEmptyHint => 'Creá una y entrá en modo foco';

  @override
  String get pomodoroStatePending => 'Pendiente';

  @override
  String get pomodoroStateInProgress => 'En progreso';

  @override
  String get pomodoroStateCompleted => 'Completada';

  @override
  String get pomodoroStateCancelled => 'Cancelada';

  @override
  String get pomodoroCycles => 'Ciclos';

  @override
  String get pomodoroFocusMinutes => 'Minutos de foco';

  @override
  String get pomodoroBreakMinutes => 'Minutos de descanso';

  @override
  String get pomodoroPurpose => 'Propósito';

  @override
  String get pomodoroCurrentSession => 'Sesión actual';

  @override
  String get pomodoroPhaseFocus => 'Foco';

  @override
  String get pomodoroPhaseRest => 'Descanso';

  @override
  String pomodoroCycleOf(int done, int total) {
    return 'Ciclo $done de $total';
  }

  @override
  String get pomodoroStart => 'Iniciar';

  @override
  String get pomodoroPause => 'Pausar';

  @override
  String get pomodoroSkip => 'Siguiente fase';

  @override
  String get pomodoroFinish => 'Finalizar';

  @override
  String get pomodoroCancel => 'Cancelar sesión';

  @override
  String get pomodoroClose => 'Cerrar sin guardar';

  @override
  String get pomodoroStats => 'Estadísticas';

  @override
  String get pomodoroTotalFocus => 'Foco total';

  @override
  String get pomodoroTotalCycles => 'Ciclos completados';

  @override
  String get pomodoroByCategory => 'Por categoría';

  @override
  String get pomodoroMinutesPerDay => 'Minutos por día';

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
    return 'Entre $min y $max';
  }

  @override
  String get todoTitle => 'To-Do';

  @override
  String get todoProjects => 'Proyectos';

  @override
  String get todoNewProject => 'Nuevo proyecto';

  @override
  String get todoNewSubproject => 'Nuevo subproyecto';

  @override
  String get todoNoProjects => 'Todavía no hay proyectos';

  @override
  String get todoNoProjectsHint =>
      'Creá uno para empezar a organizar tus tareas';

  @override
  String get todoPickProject => 'Elegí un proyecto';

  @override
  String get todoPickProjectHint => 'Sus tareas van a aparecer acá';

  @override
  String get todoIncludeSubprojects => 'Incluir subproyectos';

  @override
  String get todoViewKanban => 'Tablero';

  @override
  String get todoViewList => 'Lista';

  @override
  String get todoNewTask => 'Nueva tarea';

  @override
  String get todoEditTask => 'Editar tarea';

  @override
  String get todoNoTasks => 'Sin tareas';

  @override
  String get todoNoTasksHint => 'Agregá la primera con el botón de abajo';

  @override
  String get todoStatusTodo => 'Por hacer';

  @override
  String get todoStatusInProgress => 'En curso';

  @override
  String get todoStatusDone => 'Hecho';

  @override
  String get todoPriorityLow => 'Baja';

  @override
  String get todoPriorityMedium => 'Media';

  @override
  String get todoPriorityHigh => 'Alta';

  @override
  String get todoPriorityUrgent => 'Urgente';

  @override
  String get todoDueOverdue => 'Vencida';

  @override
  String get todoDueToday => 'Vence hoy';

  @override
  String get todoDueUpcoming => 'Próxima';

  @override
  String get todoFieldTitle => 'Título';

  @override
  String get todoFieldDescription => 'Descripción';

  @override
  String get todoFieldDue => 'Vencimiento';

  @override
  String get todoFieldPriority => 'Prioridad';

  @override
  String get todoFieldStatus => 'Estado';

  @override
  String get todoComments => 'Avances';

  @override
  String get todoCommentHint => 'Anotá un avance';

  @override
  String get todoNoComments => 'Sin avances todavía';

  @override
  String get todoFilters => 'Filtros';

  @override
  String get todoFilterCategory => 'Categoría contiene';

  @override
  String get todoFilterClear => 'Limpiar';

  @override
  String todoTaskCount(int count) {
    return '$count tareas';
  }

  @override
  String get todoMoveNotAllowed =>
      'Ese movimiento rompería el árbol de proyectos';

  @override
  String dashboardGreeting(String name) {
    return 'Hola, $name';
  }

  @override
  String get dashboardGreetingAnonymous => 'Hola';

  @override
  String get dashboardSubtitle => 'Esto es lo de hoy.';

  @override
  String get dashboardRefresh => 'Actualizar';

  @override
  String get dashboardPendingTasks => 'Tareas pendientes';

  @override
  String dashboardOverdue(int count) {
    return '$count vencidas';
  }

  @override
  String get dashboardNoOverdue => 'Ninguna vencida';

  @override
  String get dashboardHabitsToday => 'Hábitos de hoy';

  @override
  String dashboardHabitsRatio(int done, int total) {
    return '$done de $total';
  }

  @override
  String get dashboardFocus => 'Foco';

  @override
  String get dashboardFocusEmpty => 'Nada pendiente. Disfrutalo.';

  @override
  String get dashboardHealth => 'Salud y journal';

  @override
  String get dashboardSleepToday => 'Sueño de hoy';

  @override
  String get dashboardJournalReady => 'Listo';

  @override
  String get dashboardJournalPending => 'Pendiente';

  @override
  String get dashboardNoJournal => 'Sin entrada';

  @override
  String get dashboardQuickActions => 'Accesos rápidos';

  @override
  String get dashboardNoDue => 'Sin fecha';

  @override
  String tutorialPageOf(int page, int total) {
    return '$page de $total';
  }

  @override
  String get onboardingWelcomeDetail =>
      'Nisabitus reúne hábitos, rachas, sueño, diario y tareas en un solo lugar que vive en tu dispositivo. Sin cuentas, sin nube, sin telemetría: tus datos no salen de tu equipo, y la app funciona igual sin conexión.';

  @override
  String get tutorialHabitsDetail =>
      'Definí lo que querés repetir y resolvelo cada día con un toque. Elegí si es diario, semanal, mensual o anual, y en qué días esperás cumplirlo.\n\nLas rachas cuentan aparte: llevan los días seguidos de algo y guardan tu récord, aunque después vuelvas a cero.';

  @override
  String get tutorialTrackDetail =>
      'Anotá cuántas horas dormiste y la app te dice cómo estuvo la noche, saca tu promedio y te muestra la tendencia.\n\nEl journal te propone seis campos cortos para cerrar el día: cómo estuviste, qué agradecés, en qué pusiste el foco y con qué querés empezar mañana.\n\nLa tira semanal te deja completar días que te salteaste.';

  @override
  String get tutorialFocusDetail =>
      'El pomodoro parte tu trabajo en ciclos de foco y descanso, y lleva la cuenta de los minutos que realmente concentraste.\n\nEl To-Do organiza tus tareas en proyectos con hasta tres niveles, y las movés entre Por hacer, En curso y Hecho arrastrándolas por el tablero.';

  @override
  String get onboardingNameDetail =>
      'Solo lo usamos para saludarte en el panel. No sale de este dispositivo y podés cambiarlo o borrarlo cuando quieras.';

  @override
  String get onboardingTabsDetail =>
      'Elegí las secciones que te sirven y dejá afuera las que no. Podés cambiarlo en cualquier momento desde Configuración, que siempre está a mano arriba a la izquierda.';

  @override
  String get settingsTheme => 'Tema';

  @override
  String get themeSystem => 'Sistema';

  @override
  String get themeLight => 'Claro';

  @override
  String get themeDark => 'Oscuro';

  @override
  String get settingsLanguage => 'Idioma';

  @override
  String get languageSpanish => 'Español';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageSystem => 'Sistema';

  @override
  String get tabHealth => 'Salud';

  @override
  String get healthSleep => 'Sueño';

  @override
  String get healthNutrition => 'Alimentación';

  @override
  String get healthExercise => 'Ejercicio';

  @override
  String get nutritionGoals => 'Objetivos diarios';

  @override
  String get nutritionEditGoals => 'Editar objetivos';

  @override
  String get nutritionCalories => 'Calorías';

  @override
  String get nutritionProtein => 'Proteínas';

  @override
  String get nutritionCarbs => 'Carbohidratos';

  @override
  String get nutritionFat => 'Grasas';

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
    return '$value de $target';
  }

  @override
  String nutritionRemaining(int value) {
    return 'Te quedan $value kcal';
  }

  @override
  String nutritionOver(int value) {
    return 'Te pasaste por $value kcal';
  }

  @override
  String get nutritionToday => 'Lo que comiste';

  @override
  String get nutritionEmpty => 'Sin registros ese día';

  @override
  String get nutritionEmptyHint => 'Anotá lo que comiste y se suma solo';

  @override
  String get nutritionAdd => 'Agregar alimento';

  @override
  String get nutritionEditEntry => 'Editar alimento';

  @override
  String get nutritionPortion => 'Porción';

  @override
  String get nutritionPortionHint => '150 g, 1 plato, 2 unidades';

  @override
  String get tabMeditation => 'Meditación';

  @override
  String get meditationTitle => 'Meditación';

  @override
  String get meditationToday => 'Lo que sentaste';

  @override
  String get meditationEmpty => 'Ese día no anotaste nada';

  @override
  String get meditationEmptyHint => 'Anotá cuánto sentaste y cómo te fue';

  @override
  String get meditationAdd => 'Anotar sesión';

  @override
  String get meditationEdit => 'Editar sesión';

  @override
  String meditationMinutes(Object value) {
    return '$value min';
  }

  @override
  String meditationDayTotal(Object value) {
    return '$value min ese día';
  }

  @override
  String get meditationDuration => 'Duración';

  @override
  String get meditationNote => 'Cómo te fue';

  @override
  String get meditationNoteHint => 'Costó arrancar, me dormí, quedé tranquilo…';

  @override
  String meditationValidationMinutes(Object max) {
    return 'Ingresá un número entre 1 y $max';
  }

  @override
  String get meditationMinutesPerDay => 'Minutos por día';

  @override
  String get meditationAverageDaily => 'Promedio diario';

  @override
  String get meditationDaysPractised => 'Días que sentaste';

  @override
  String get meditationLongestStreak => 'Racha más larga';

  @override
  String get hydration => 'Hidratación';

  @override
  String get hydrationTarget => 'Objetivo diario';

  @override
  String get hydrationEditTarget => 'Editar objetivo';

  @override
  String hydrationMillilitres(Object value) {
    return '$value ml';
  }

  @override
  String hydrationRemaining(Object value) {
    return 'Te faltan $value ml';
  }

  @override
  String get hydrationReached => 'Llegaste al objetivo';

  @override
  String get hydrationToday => 'Lo que tomaste';

  @override
  String get hydrationEmpty => 'Sin registros ese día';

  @override
  String get hydrationEmptyHint => 'Anotá cada vaso y se suma solo';

  @override
  String get hydrationAdd => 'Agregar';

  @override
  String get hydrationCustom => 'Otra cantidad';

  @override
  String get hydrationAmount => 'Cantidad';

  @override
  String hydrationValidationAmount(Object max) {
    return 'Ingresá un número entre 1 y $max';
  }

  @override
  String get hydrationPerDay => 'Mililitros por día';

  @override
  String get hydrationAverageDaily => 'Promedio diario';

  @override
  String get hydrationDaysOnTarget => 'Días en objetivo';

  @override
  String get nutritionMeal => 'Comida';

  @override
  String get nutritionMealBreakfast => 'Desayuno';

  @override
  String get nutritionMealLunch => 'Almuerzo';

  @override
  String get nutritionMealSnack => 'Merienda';

  @override
  String get nutritionMealDinner => 'Cena';

  @override
  String get nutritionMealNone => 'Sin comida';

  @override
  String get nutritionUnassigned => 'Sin asignar';

  @override
  String get nutritionSaved => 'Lo que comés seguido';

  @override
  String get nutritionSavedHint => 'Se llena solo con lo que vas anotando';

  @override
  String get nutritionSavedEmpty => 'Todavía no anotaste nada';

  @override
  String get nutritionPickSaved => 'Elegir de lo que comés seguido';

  @override
  String get nutritionForget => 'Sacar de la lista';

  @override
  String get nutritionForgetHint =>
      'Sale de la lista. Lo que ya comiste queda como está.';

  @override
  String nutritionValidationNumber(int max) {
    return 'Ingresá un número entre 0 y $max';
  }

  @override
  String get discipline => 'Disciplinas';

  @override
  String get disciplineHint =>
      'Natación, correr, bici — lo que se mide en tiempo, no en series';

  @override
  String get disciplineEmpty => 'Nada practicado ese día';

  @override
  String get disciplineAdd => 'Anotar disciplina';

  @override
  String get disciplineEdit => 'Editar disciplina';

  @override
  String get disciplineName => 'Qué practicaste';

  @override
  String get disciplineNameHint => 'Natación, Correr, Bici, Yoga…';

  @override
  String get disciplineDuration => 'Duración';

  @override
  String get disciplineDistance => 'Distancia';

  @override
  String disciplineMinutes(int value) {
    return '$value min';
  }

  @override
  String disciplineKm(String value) {
    return '$value km';
  }

  @override
  String get disciplineNotes => 'Notas';

  @override
  String get disciplineCompleteTitle => '¿Cómo te fue?';

  @override
  String get disciplineCompleteHint =>
      'Anotá el tiempo y la distancia reales. Lo que dejes en blanco queda como estaba planeado.';

  @override
  String disciplineValidationMinutes(int max) {
    return 'Ingresá un número entre 1 y $max';
  }

  @override
  String disciplineValidationDistance(int max) {
    return 'Ingresá un número entre 0 y $max';
  }

  @override
  String get plan => 'Plan';

  @override
  String get planToday => 'Lo que toca ese día';

  @override
  String get planEmpty => 'Nada anotado para ese día';

  @override
  String get planEmptyHint =>
      'Anotá un ejercicio y, si se repite, decí en qué días';

  @override
  String get planAdd => 'Anotar ejercicio';

  @override
  String get planEdit => 'Editar ejercicio';

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
  String get planComments => 'Indicaciones';

  @override
  String get planCommentsHint => 'Bajar hasta paralelo, sin rebote…';

  @override
  String get planFeedback => 'Cómo te fue';

  @override
  String get planFeedbackHint =>
      'La última salió fea, pesó más de lo esperado…';

  @override
  String get planDone => 'Hecho';

  @override
  String get planReopen => 'Volver a pendiente';

  @override
  String get planComplete => 'Marcar como hecho';

  @override
  String get planCompleteTitle => '¿Cómo te fue?';

  @override
  String get planCompleteHint =>
      'Anotá el peso y el esfuerzo reales. Lo que dejes en blanco queda como estaba planeado.';

  @override
  String get planRepeat => 'Repetir';

  @override
  String get planRepeatDays => 'Días';

  @override
  String get planRepeatUntilLabel => 'Hasta cuándo';

  @override
  String get planRepeatWeeks => 'Por semanas';

  @override
  String get planRepeatUntil => 'Hasta una fecha';

  @override
  String get planRepeatForever => 'Siempre';

  @override
  String get planRepeatWeeksValue => 'Cantidad de semanas';

  @override
  String get planRepeatUntilValue => 'Termina el';

  @override
  String planRepeatSummary(String days) {
    return 'Se repite $days';
  }

  @override
  String get planStopRepeat => 'Dejar de repetir';

  @override
  String get planStopRepeatTitle => '¿Dejar de repetir?';

  @override
  String get planStopRepeatBody =>
      'Se borran los días siguientes que todavía no hiciste. Lo que ya entrenaste queda como está.';

  @override
  String get planValidationDays => 'Elegí al menos un día';

  @override
  String planValidationNumber(int max) {
    return 'Ingresá un número entre 1 y $max';
  }

  @override
  String get planValidationRpe => 'El RPE va de 1 a 10';

  @override
  String get planValidationEndDate =>
      'La repetición no puede terminar antes de empezar';

  @override
  String get exerciseVideo => 'Video de referencia';

  @override
  String get exerciseVideoHint => 'Link a un video que muestre el movimiento';

  @override
  String get exerciseOpenVideo => 'Ver el video';

  @override
  String get exerciseSetNote => 'Cómo se sintió';

  @override
  String get exerciseSetNoteHint =>
      'La última salió fea, pesó más de lo esperado…';

  @override
  String get exerciseCatalogue => 'Ejercicios';

  @override
  String get exerciseNew => 'Nuevo ejercicio';

  @override
  String get exerciseEdit => 'Editar ejercicio';

  @override
  String get exerciseNoneYet => 'Todavía no hay ejercicios';

  @override
  String get exerciseNoneYetHint => 'Creá uno y empezá a registrar tus series';

  @override
  String get exerciseMuscleGroup => 'Grupo muscular';

  @override
  String get exerciseDescription => 'Descripción';

  @override
  String get exerciseWorkout => 'Entrenamiento';

  @override
  String get exerciseNoSets => 'Sin series ese día';

  @override
  String get exerciseNoSetsHint =>
      'Elegí un ejercicio y anotá tu primera serie';

  @override
  String get exerciseAddSet => 'Agregar serie';

  @override
  String get exerciseEditSet => 'Editar serie';

  @override
  String get exerciseSets => 'Series';

  @override
  String get exerciseReps => 'Repeticiones';

  @override
  String get exerciseWeight => 'Peso (kg)';

  @override
  String get exerciseBodyweight => 'Peso corporal';

  @override
  String exerciseSetLine(int reps) {
    return '$reps reps';
  }

  @override
  String exerciseSetLineWeighted(int reps, String weight) {
    return '$reps reps × $weight kg';
  }

  @override
  String get exerciseTotalSets => 'Series';

  @override
  String get exerciseTotalReps => 'Repeticiones';

  @override
  String get exerciseVolume => 'Volumen';

  @override
  String exerciseVolumeValue(String value) {
    return '$value kg';
  }

  @override
  String exerciseTopWeight(String weight) {
    return 'Máximo: $weight kg';
  }

  @override
  String get exercisePickOne => 'Elegí un ejercicio';

  @override
  String get disclaimerTitle => 'Esto es un registro, no un consejo médico';

  @override
  String get disclaimerBody =>
      'Nisabitus no es una aplicación médica ni nutricional. Es un registro: guarda lo que vos anotás y te lo devuelve ordenado.\n\nNo diagnostica, no interpreta síntomas, no calcula dosis y no recomienda tratamientos, dietas ni rutinas. Los objetivos que definas son tuyos, no una indicación profesional.\n\nAntes de empezar, cambiar o suspender una medicación, un suplemento, una dieta o un plan de entrenamiento, hablá con un profesional de la salud. Ante cualquier síntoma que te preocupe, consultá sin demora.';

  @override
  String get disclaimerAction => 'Entendido';

  @override
  String get disclaimerTooltip => 'Sobre estos datos';

  @override
  String get healthMeds => 'Medicación';

  @override
  String get medsTitle => 'Medicación y suplementos';

  @override
  String get medsToday => 'Para ese día';

  @override
  String get medsCatalogue => 'Lo que tomás';

  @override
  String get medsNew => 'Agregar';

  @override
  String get medsEdit => 'Editar';

  @override
  String get medsEmpty => 'Todavía no cargaste nada';

  @override
  String get medsEmptyHint => 'Agregá lo que tomás y marcalo cada día';

  @override
  String get medsKind => 'Tipo';

  @override
  String get medsKindMedication => 'Medicación';

  @override
  String get medsKindSupplement => 'Suplemento';

  @override
  String get medsDose => 'Dosis';

  @override
  String get medsDoseHint => '500 mg, 2 cápsulas, 10 gotas';

  @override
  String get medsSchedule => 'Cuándo';

  @override
  String get medsScheduleHint => 'Mañana, cada 8 h, con la cena';

  @override
  String get medsNotes => 'Notas';

  @override
  String get medsActive => 'Activo';

  @override
  String get medsInactiveHint => 'Lo pausado no aparece en el día';

  @override
  String medsTakenCount(int done, int total) {
    return '$done de $total';
  }

  @override
  String get medsNoneActive => 'Nada activo para marcar';

  @override
  String get medsNoneActiveHint => 'Activá algo de la lista de abajo';

  @override
  String get progressEntries => 'Registros';

  @override
  String get progressPerDay => 'Por día';

  @override
  String get nutritionCaloriesPerDay => 'Calorías por día';

  @override
  String get nutritionAverageDaily => 'Promedio diario';

  @override
  String get nutritionDaysLogged => 'Días registrados';

  @override
  String get exerciseVolumePerDay => 'Volumen por día';

  @override
  String get exerciseDaysTrained => 'Días entrenados';

  @override
  String get medsAdherence => 'Cumplimiento';

  @override
  String get medsAdherencePerDay => 'Cumplimiento por día';

  @override
  String get medsDaysComplete => 'Días completos';

  @override
  String get journalEntriesWritten => 'Entradas escritas';

  @override
  String get journalCoverage => 'Cobertura';

  @override
  String get journalLongestRun => 'Racha más larga';

  @override
  String get journalPerDay => 'Entradas por día';

  @override
  String get todoProgress => 'Progreso';

  @override
  String get todoCompletedPerDay => 'Tareas completadas por día';

  @override
  String get todoCompleted => 'Completadas';

  @override
  String get todoOpen => 'Abiertas';

  @override
  String get todoOverdue => 'Vencidas';

  @override
  String get sleepHoursPerNight => 'Horas por noche';

  @override
  String progressDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count días',
      one: '1 día',
    );
    return '$_temp0';
  }

  @override
  String get todoProgressEmptyHint => 'Completá una tarea y aparece acá';

  @override
  String get settingsBackup => 'Copia de seguridad';

  @override
  String get settingsYourData => 'Tus datos';

  @override
  String get settingsSupport => 'Soporte';

  @override
  String get backupHint =>
      'Todo lo que anotaste, en un archivo tuyo. No se sube a ningún lado: queda donde vos lo guardes.';

  @override
  String get backupExport => 'Exportar';

  @override
  String get backupImport => 'Importar';

  @override
  String get backupReplaceWarning =>
      'Importar reemplaza todo lo que tenés ahora.';

  @override
  String get backupConfirmTitle => '¿Reemplazar todos tus datos?';

  @override
  String get backupConfirmBody =>
      'Se borra lo que hay ahora y queda lo que traiga el archivo. No se puede deshacer, así que exportá antes si tenés dudas.';

  @override
  String get backupConfirmAction => 'Reemplazar';

  @override
  String backupExported(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Copia guardada: $count registros',
      one: 'Copia guardada: 1 registro',
    );
    return '$_temp0';
  }

  @override
  String backupImported(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Datos restaurados: $count registros',
      one: 'Datos restaurados: 1 registro',
    );
    return '$_temp0';
  }

  @override
  String get backupNotABackup => 'Ese archivo no es una copia de Nisabitus';

  @override
  String get backupNewerVersion =>
      'La copia viene de una versión más nueva de Nisabitus';

  @override
  String get backupCorrupt => 'La copia está dañada y no se puede leer';

  @override
  String get backupFailed => 'No se pudo completar la operación';

  @override
  String get settingsReleaseNotes => 'Novedades';

  @override
  String get releaseNotesWhatsNew => 'Novedades';

  @override
  String get releaseNotesHistory => 'Historial de novedades';

  @override
  String releaseNotesVersion(String version) {
    return 'Versión $version';
  }

  @override
  String get releaseNotesClose => 'Entendido';
}
