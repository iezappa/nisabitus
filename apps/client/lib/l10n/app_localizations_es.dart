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
}
