import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_es.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('es')];

  /// No description provided for @appTitle.
  ///
  /// In es, this message translates to:
  /// **'Nísabit'**
  String get appTitle;

  /// No description provided for @appTagline.
  ///
  /// In es, this message translates to:
  /// **'El esfuerzo que te eleva'**
  String get appTagline;

  /// No description provided for @tabDashboard.
  ///
  /// In es, this message translates to:
  /// **'Panel'**
  String get tabDashboard;

  /// No description provided for @tabHabits.
  ///
  /// In es, this message translates to:
  /// **'Hábitos'**
  String get tabHabits;

  /// No description provided for @tabJournal.
  ///
  /// In es, this message translates to:
  /// **'Journal'**
  String get tabJournal;

  /// No description provided for @tabSleep.
  ///
  /// In es, this message translates to:
  /// **'Sueño'**
  String get tabSleep;

  /// No description provided for @tabPomodoro.
  ///
  /// In es, this message translates to:
  /// **'Pomodoro'**
  String get tabPomodoro;

  /// No description provided for @tabTodo.
  ///
  /// In es, this message translates to:
  /// **'To-Do'**
  String get tabTodo;

  /// No description provided for @habitsTitle.
  ///
  /// In es, this message translates to:
  /// **'Hábitos'**
  String get habitsTitle;

  /// No description provided for @habitsList.
  ///
  /// In es, this message translates to:
  /// **'Lista'**
  String get habitsList;

  /// No description provided for @habitsProgress.
  ///
  /// In es, this message translates to:
  /// **'Progreso'**
  String get habitsProgress;

  /// No description provided for @frequencyDaily.
  ///
  /// In es, this message translates to:
  /// **'Diario'**
  String get frequencyDaily;

  /// No description provided for @frequencyWeekly.
  ///
  /// In es, this message translates to:
  /// **'Semanal'**
  String get frequencyWeekly;

  /// No description provided for @frequencyMonthly.
  ///
  /// In es, this message translates to:
  /// **'Mensual'**
  String get frequencyMonthly;

  /// No description provided for @frequencyYearly.
  ///
  /// In es, this message translates to:
  /// **'Anual'**
  String get frequencyYearly;

  /// No description provided for @habitsEmpty.
  ///
  /// In es, this message translates to:
  /// **'Todavía no hay hábitos acá'**
  String get habitsEmpty;

  /// No description provided for @habitsEmptyHint.
  ///
  /// In es, this message translates to:
  /// **'Creá el primero y empezá a sostenerlo'**
  String get habitsEmptyHint;

  /// No description provided for @habitNew.
  ///
  /// In es, this message translates to:
  /// **'Nuevo hábito'**
  String get habitNew;

  /// No description provided for @habitDone.
  ///
  /// In es, this message translates to:
  /// **'Hecho'**
  String get habitDone;

  /// No description provided for @habitCancel.
  ///
  /// In es, this message translates to:
  /// **'Cancelar'**
  String get habitCancel;

  /// No description provided for @habitCompleted.
  ///
  /// In es, this message translates to:
  /// **'Completado'**
  String get habitCompleted;

  /// No description provided for @habitCancelled.
  ///
  /// In es, this message translates to:
  /// **'Cancelado'**
  String get habitCancelled;

  /// No description provided for @habitFinishedOn.
  ///
  /// In es, this message translates to:
  /// **'Finalizado el {date}'**
  String habitFinishedOn(String date);

  /// No description provided for @habitTargetBadge.
  ///
  /// In es, this message translates to:
  /// **'{count}x'**
  String habitTargetBadge(int count);

  /// No description provided for @streaksTitle.
  ///
  /// In es, this message translates to:
  /// **'Rachas'**
  String get streaksTitle;

  /// No description provided for @streaksEmpty.
  ///
  /// In es, this message translates to:
  /// **'Todavía no hay rachas'**
  String get streaksEmpty;

  /// No description provided for @streaksEmptyHint.
  ///
  /// In es, this message translates to:
  /// **'Una racha cuenta los días seguidos que sostenés algo'**
  String get streaksEmptyHint;

  /// No description provided for @streakNew.
  ///
  /// In es, this message translates to:
  /// **'Nueva racha'**
  String get streakNew;

  /// No description provided for @streakDays.
  ///
  /// In es, this message translates to:
  /// **'días'**
  String get streakDays;

  /// No description provided for @streakRecord.
  ///
  /// In es, this message translates to:
  /// **'Récord: {count}'**
  String streakRecord(int count);

  /// No description provided for @streakIncrement.
  ///
  /// In es, this message translates to:
  /// **'+1'**
  String get streakIncrement;

  /// No description provided for @streakReset.
  ///
  /// In es, this message translates to:
  /// **'Reiniciar'**
  String get streakReset;

  /// No description provided for @actionSave.
  ///
  /// In es, this message translates to:
  /// **'Guardar'**
  String get actionSave;

  /// No description provided for @actionCancel.
  ///
  /// In es, this message translates to:
  /// **'Cancelar'**
  String get actionCancel;

  /// No description provided for @actionDelete.
  ///
  /// In es, this message translates to:
  /// **'Borrar'**
  String get actionDelete;

  /// No description provided for @actionEdit.
  ///
  /// In es, this message translates to:
  /// **'Editar'**
  String get actionEdit;

  /// No description provided for @fieldName.
  ///
  /// In es, this message translates to:
  /// **'Nombre'**
  String get fieldName;

  /// No description provided for @fieldCategory.
  ///
  /// In es, this message translates to:
  /// **'Categoría'**
  String get fieldCategory;

  /// No description provided for @fieldFrequency.
  ///
  /// In es, this message translates to:
  /// **'Frecuencia'**
  String get fieldFrequency;

  /// No description provided for @fieldTarget.
  ///
  /// In es, this message translates to:
  /// **'Objetivo por período'**
  String get fieldTarget;

  /// No description provided for @validationNameRequired.
  ///
  /// In es, this message translates to:
  /// **'El nombre es obligatorio'**
  String get validationNameRequired;

  /// No description provided for @deleteConfirmTitle.
  ///
  /// In es, this message translates to:
  /// **'¿Borrar {name}?'**
  String deleteConfirmTitle(String name);

  /// No description provided for @deleteConfirmBody.
  ///
  /// In es, this message translates to:
  /// **'Esta acción no se puede deshacer.'**
  String get deleteConfirmBody;

  /// No description provided for @comingSoon.
  ///
  /// In es, this message translates to:
  /// **'En construcción'**
  String get comingSoon;

  /// No description provided for @comingSoonHint.
  ///
  /// In es, this message translates to:
  /// **'Este módulo todavía no está implementado.'**
  String get comingSoonHint;

  /// No description provided for @weekdayShortMonday.
  ///
  /// In es, this message translates to:
  /// **'L'**
  String get weekdayShortMonday;

  /// No description provided for @weekdayShortTuesday.
  ///
  /// In es, this message translates to:
  /// **'M'**
  String get weekdayShortTuesday;

  /// No description provided for @weekdayShortWednesday.
  ///
  /// In es, this message translates to:
  /// **'X'**
  String get weekdayShortWednesday;

  /// No description provided for @weekdayShortThursday.
  ///
  /// In es, this message translates to:
  /// **'J'**
  String get weekdayShortThursday;

  /// No description provided for @weekdayShortFriday.
  ///
  /// In es, this message translates to:
  /// **'V'**
  String get weekdayShortFriday;

  /// No description provided for @weekdayShortSaturday.
  ///
  /// In es, this message translates to:
  /// **'S'**
  String get weekdayShortSaturday;

  /// No description provided for @weekdayShortSunday.
  ///
  /// In es, this message translates to:
  /// **'D'**
  String get weekdayShortSunday;

  /// No description provided for @habitRepeatForever.
  ///
  /// In es, this message translates to:
  /// **'Repetir por siempre'**
  String get habitRepeatForever;

  /// No description provided for @habitEndDate.
  ///
  /// In es, this message translates to:
  /// **'Fecha de fin'**
  String get habitEndDate;

  /// No description provided for @habitRepeatDays.
  ///
  /// In es, this message translates to:
  /// **'Días de repetición'**
  String get habitRepeatDays;

  /// No description provided for @habitEdit.
  ///
  /// In es, this message translates to:
  /// **'Editar hábito'**
  String get habitEdit;

  /// No description provided for @habitScheduledOn.
  ///
  /// In es, this message translates to:
  /// **'Programado: {days}'**
  String habitScheduledOn(String days);

  /// No description provided for @habitRevert.
  ///
  /// In es, this message translates to:
  /// **'Volver a pendiente'**
  String get habitRevert;

  /// No description provided for @habitsToday.
  ///
  /// In es, this message translates to:
  /// **'Progreso de hoy'**
  String get habitsToday;

  /// No description provided for @habitsTodayCount.
  ///
  /// In es, this message translates to:
  /// **'{done} de {total}'**
  String habitsTodayCount(int done, int total);

  /// No description provided for @streakCurrent.
  ///
  /// In es, this message translates to:
  /// **'Racha actual'**
  String get streakCurrent;

  /// No description provided for @streakLongest.
  ///
  /// In es, this message translates to:
  /// **'Récord'**
  String get streakLongest;

  /// No description provided for @rangeDay.
  ///
  /// In es, this message translates to:
  /// **'Día'**
  String get rangeDay;

  /// No description provided for @rangeWeek.
  ///
  /// In es, this message translates to:
  /// **'Semana'**
  String get rangeWeek;

  /// No description provided for @rangeMonth.
  ///
  /// In es, this message translates to:
  /// **'Mes'**
  String get rangeMonth;

  /// No description provided for @rangeYear.
  ///
  /// In es, this message translates to:
  /// **'Año'**
  String get rangeYear;

  /// No description provided for @statsCompleted.
  ///
  /// In es, this message translates to:
  /// **'Completados'**
  String get statsCompleted;

  /// No description provided for @statsSuccessRate.
  ///
  /// In es, this message translates to:
  /// **'Tasa de éxito'**
  String get statsSuccessRate;

  /// No description provided for @statsPercent.
  ///
  /// In es, this message translates to:
  /// **'{value}%'**
  String statsPercent(int value);

  /// No description provided for @statsRangeCaption.
  ///
  /// In es, this message translates to:
  /// **'Últimos {days} días'**
  String statsRangeCaption(int days);

  /// No description provided for @chartEmpty.
  ///
  /// In es, this message translates to:
  /// **'Sin datos en este rango'**
  String get chartEmpty;

  /// No description provided for @chartEmptyHint.
  ///
  /// In es, this message translates to:
  /// **'Resolvé algún hábito y el progreso aparece acá'**
  String get chartEmptyHint;

  /// No description provided for @chartStreaksEmptyHint.
  ///
  /// In es, this message translates to:
  /// **'Sumá a una racha y su evolución aparece acá'**
  String get chartStreaksEmptyHint;

  /// No description provided for @habitsCompletionsPerDay.
  ///
  /// In es, this message translates to:
  /// **'Cumplimientos por día'**
  String get habitsCompletionsPerDay;

  /// No description provided for @streaksEvolution.
  ///
  /// In es, this message translates to:
  /// **'Evolución'**
  String get streaksEvolution;

  /// No description provided for @weekPrevious.
  ///
  /// In es, this message translates to:
  /// **'Semana anterior'**
  String get weekPrevious;

  /// No description provided for @weekNext.
  ///
  /// In es, this message translates to:
  /// **'Semana siguiente'**
  String get weekNext;

  /// No description provided for @sleepTitle.
  ///
  /// In es, this message translates to:
  /// **'Sueño'**
  String get sleepTitle;

  /// No description provided for @sleepLastNight.
  ///
  /// In es, this message translates to:
  /// **'Esa noche'**
  String get sleepLastNight;

  /// No description provided for @sleepHours.
  ///
  /// In es, this message translates to:
  /// **'{hours} h'**
  String sleepHours(String hours);

  /// No description provided for @sleepNoRecord.
  ///
  /// In es, this message translates to:
  /// **'Sin registro'**
  String get sleepNoRecord;

  /// No description provided for @sleepNoRecordHint.
  ///
  /// In es, this message translates to:
  /// **'Anotá cuántas horas dormiste ese día'**
  String get sleepNoRecordHint;

  /// No description provided for @sleepQualityOptimal.
  ///
  /// In es, this message translates to:
  /// **'Óptimo'**
  String get sleepQualityOptimal;

  /// No description provided for @sleepQualityAcceptable.
  ///
  /// In es, this message translates to:
  /// **'Aceptable'**
  String get sleepQualityAcceptable;

  /// No description provided for @sleepQualityPoor.
  ///
  /// In es, this message translates to:
  /// **'A mejorar'**
  String get sleepQualityPoor;

  /// No description provided for @sleepLog.
  ///
  /// In es, this message translates to:
  /// **'Registrar sueño'**
  String get sleepLog;

  /// No description provided for @sleepFieldHours.
  ///
  /// In es, this message translates to:
  /// **'Horas dormidas'**
  String get sleepFieldHours;

  /// No description provided for @sleepSave.
  ///
  /// In es, this message translates to:
  /// **'Registrar'**
  String get sleepSave;

  /// No description provided for @sleepUpdate.
  ///
  /// In es, this message translates to:
  /// **'Actualizar'**
  String get sleepUpdate;

  /// No description provided for @sleepHistory.
  ///
  /// In es, this message translates to:
  /// **'Historial'**
  String get sleepHistory;

  /// No description provided for @sleepAverage.
  ///
  /// In es, this message translates to:
  /// **'Promedio'**
  String get sleepAverage;

  /// No description provided for @sleepRecords.
  ///
  /// In es, this message translates to:
  /// **'Registros'**
  String get sleepRecords;

  /// No description provided for @sleepOptimalNights.
  ///
  /// In es, this message translates to:
  /// **'Noches óptimas'**
  String get sleepOptimalNights;

  /// No description provided for @sleepRange.
  ///
  /// In es, this message translates to:
  /// **'Rango'**
  String get sleepRange;

  /// No description provided for @sleepRangeValue.
  ///
  /// In es, this message translates to:
  /// **'{min} – {max} h'**
  String sleepRangeValue(String min, String max);

  /// No description provided for @sleepInsights.
  ///
  /// In es, this message translates to:
  /// **'Bienestar'**
  String get sleepInsights;

  /// No description provided for @sleepInsightAverageGood.
  ///
  /// In es, this message translates to:
  /// **'Tu promedio está en la franja recomendada. Sostenelo.'**
  String get sleepInsightAverageGood;

  /// No description provided for @sleepInsightAverageLow.
  ///
  /// In es, this message translates to:
  /// **'Estás durmiendo por debajo de lo recomendado.'**
  String get sleepInsightAverageLow;

  /// No description provided for @sleepInsightAverageHigh.
  ///
  /// In es, this message translates to:
  /// **'Estás durmiendo por encima de lo habitual.'**
  String get sleepInsightAverageHigh;

  /// No description provided for @sleepInsightConsistency.
  ///
  /// In es, this message translates to:
  /// **'Consistencia'**
  String get sleepInsightConsistency;

  /// No description provided for @sleepInsightConsistencySteady.
  ///
  /// In es, this message translates to:
  /// **'Tus noches son parejas.'**
  String get sleepInsightConsistencySteady;

  /// No description provided for @sleepInsightConsistencyErratic.
  ///
  /// In es, this message translates to:
  /// **'Tus horas varían bastante de una noche a otra.'**
  String get sleepInsightConsistencyErratic;

  /// No description provided for @sleepValidationHours.
  ///
  /// In es, this message translates to:
  /// **'Ingresá un número entre 0 y 24'**
  String get sleepValidationHours;

  /// No description provided for @journalTitle.
  ///
  /// In es, this message translates to:
  /// **'Journal'**
  String get journalTitle;

  /// No description provided for @journalMood.
  ///
  /// In es, this message translates to:
  /// **'Estado emocional'**
  String get journalMood;

  /// No description provided for @journalMoodHint.
  ///
  /// In es, this message translates to:
  /// **'¿Cómo te sentiste?'**
  String get journalMoodHint;

  /// No description provided for @journalEnergy.
  ///
  /// In es, this message translates to:
  /// **'Energía'**
  String get journalEnergy;

  /// No description provided for @journalEnergyLow.
  ///
  /// In es, this message translates to:
  /// **'Baja'**
  String get journalEnergyLow;

  /// No description provided for @journalEnergyMedium.
  ///
  /// In es, this message translates to:
  /// **'Media'**
  String get journalEnergyMedium;

  /// No description provided for @journalEnergyHigh.
  ///
  /// In es, this message translates to:
  /// **'Alta'**
  String get journalEnergyHigh;

  /// No description provided for @journalGratitude.
  ///
  /// In es, this message translates to:
  /// **'Gratitud'**
  String get journalGratitude;

  /// No description provided for @journalGratitudeHint.
  ///
  /// In es, this message translates to:
  /// **'¿Qué agradecés de hoy?'**
  String get journalGratitudeHint;

  /// No description provided for @journalFocus.
  ///
  /// In es, this message translates to:
  /// **'Foco del día'**
  String get journalFocus;

  /// No description provided for @journalFocusHint.
  ///
  /// In es, this message translates to:
  /// **'¿En qué pusiste tu atención?'**
  String get journalFocusHint;

  /// No description provided for @journalReflection.
  ///
  /// In es, this message translates to:
  /// **'Reflexión'**
  String get journalReflection;

  /// No description provided for @journalReflectionHint.
  ///
  /// In es, this message translates to:
  /// **'Escribí lo que quieras. Sin apuro.'**
  String get journalReflectionHint;

  /// No description provided for @journalIntention.
  ///
  /// In es, this message translates to:
  /// **'Intención para mañana'**
  String get journalIntention;

  /// No description provided for @journalIntentionHint.
  ///
  /// In es, this message translates to:
  /// **'¿Con qué querés empezar mañana?'**
  String get journalIntentionHint;

  /// No description provided for @journalSave.
  ///
  /// In es, this message translates to:
  /// **'Guardar'**
  String get journalSave;

  /// No description provided for @journalUpdate.
  ///
  /// In es, this message translates to:
  /// **'Actualizar'**
  String get journalUpdate;

  /// No description provided for @journalSaved.
  ///
  /// In es, this message translates to:
  /// **'Guardado'**
  String get journalSaved;

  /// No description provided for @journalEntry.
  ///
  /// In es, this message translates to:
  /// **'Entrada del día'**
  String get journalEntry;

  /// No description provided for @journalHistory.
  ///
  /// In es, this message translates to:
  /// **'Entradas anteriores'**
  String get journalHistory;

  /// No description provided for @journalHistoryEmpty.
  ///
  /// In es, this message translates to:
  /// **'Todavía no hay entradas'**
  String get journalHistoryEmpty;

  /// No description provided for @journalHistoryEmptyHint.
  ///
  /// In es, this message translates to:
  /// **'Lo que escribas va a aparecer acá'**
  String get journalHistoryEmptyHint;

  /// No description provided for @journalNoPreview.
  ///
  /// In es, this message translates to:
  /// **'Sin contenido'**
  String get journalNoPreview;

  /// No description provided for @journalPage.
  ///
  /// In es, this message translates to:
  /// **'{page} de {total}'**
  String journalPage(int page, int total);

  /// No description provided for @journalDeleteTitle.
  ///
  /// In es, this message translates to:
  /// **'¿Borrar la entrada?'**
  String get journalDeleteTitle;

  /// No description provided for @supportTitle.
  ///
  /// In es, this message translates to:
  /// **'Apoyar el proyecto'**
  String get supportTitle;

  /// No description provided for @supportBody.
  ///
  /// In es, this message translates to:
  /// **'Nísabit es gratis, sin cuentas y sin publicidad. Si te sirve, podés colaborar para que siga así.'**
  String get supportBody;

  /// No description provided for @supportCafecito.
  ///
  /// In es, this message translates to:
  /// **'Cafecito'**
  String get supportCafecito;

  /// No description provided for @supportPatreon.
  ///
  /// In es, this message translates to:
  /// **'Patreon'**
  String get supportPatreon;

  /// No description provided for @supportLinkFailed.
  ///
  /// In es, this message translates to:
  /// **'No se pudo abrir el enlace'**
  String get supportLinkFailed;

  /// No description provided for @settingsTitle.
  ///
  /// In es, this message translates to:
  /// **'Configuración'**
  String get settingsTitle;

  /// No description provided for @settingsAppearance.
  ///
  /// In es, this message translates to:
  /// **'Apariencia'**
  String get settingsAppearance;

  /// No description provided for @settingsAccent.
  ///
  /// In es, this message translates to:
  /// **'Color de acento'**
  String get settingsAccent;

  /// No description provided for @settingsTabs.
  ///
  /// In es, this message translates to:
  /// **'Pestañas visibles'**
  String get settingsTabs;

  /// No description provided for @settingsTabsHint.
  ///
  /// In es, this message translates to:
  /// **'Elegí qué secciones querés ver. Siempre queda al menos una.'**
  String get settingsTabsHint;

  /// No description provided for @settingsProfile.
  ///
  /// In es, this message translates to:
  /// **'Perfil'**
  String get settingsProfile;

  /// No description provided for @settingsProfileName.
  ///
  /// In es, this message translates to:
  /// **'Tu nombre'**
  String get settingsProfileName;

  /// No description provided for @settingsTutorial.
  ///
  /// In es, this message translates to:
  /// **'Ver el tutorial'**
  String get settingsTutorial;

  /// No description provided for @settingsAbout.
  ///
  /// In es, this message translates to:
  /// **'Acerca de'**
  String get settingsAbout;

  /// No description provided for @accentForest.
  ///
  /// In es, this message translates to:
  /// **'Bosque'**
  String get accentForest;

  /// No description provided for @accentGold.
  ///
  /// In es, this message translates to:
  /// **'Dorado'**
  String get accentGold;

  /// No description provided for @accentClay.
  ///
  /// In es, this message translates to:
  /// **'Arcilla'**
  String get accentClay;

  /// No description provided for @accentIndigo.
  ///
  /// In es, this message translates to:
  /// **'Índigo'**
  String get accentIndigo;

  /// No description provided for @accentPlum.
  ///
  /// In es, this message translates to:
  /// **'Ciruela'**
  String get accentPlum;

  /// No description provided for @accentSlate.
  ///
  /// In es, this message translates to:
  /// **'Pizarra'**
  String get accentSlate;

  /// No description provided for @tabSettings.
  ///
  /// In es, this message translates to:
  /// **'Ajustes'**
  String get tabSettings;

  /// No description provided for @tutorialSkip.
  ///
  /// In es, this message translates to:
  /// **'Saltar'**
  String get tutorialSkip;

  /// No description provided for @tutorialNext.
  ///
  /// In es, this message translates to:
  /// **'Siguiente'**
  String get tutorialNext;

  /// No description provided for @tutorialDone.
  ///
  /// In es, this message translates to:
  /// **'Empezar'**
  String get tutorialDone;

  /// No description provided for @tutorialBack.
  ///
  /// In es, this message translates to:
  /// **'Atrás'**
  String get tutorialBack;

  /// No description provided for @onboardingWelcome.
  ///
  /// In es, this message translates to:
  /// **'Bienvenido a Nísabit'**
  String get onboardingWelcome;

  /// No description provided for @onboardingWelcomeBody.
  ///
  /// In es, this message translates to:
  /// **'El esfuerzo que te eleva.'**
  String get onboardingWelcomeBody;

  /// No description provided for @onboardingNameTitle.
  ///
  /// In es, this message translates to:
  /// **'¿Cómo te llamamos?'**
  String get onboardingNameTitle;

  /// No description provided for @onboardingNameBody.
  ///
  /// In es, this message translates to:
  /// **'¿Cómo te llamamos?'**
  String get onboardingNameBody;

  /// No description provided for @onboardingTabsTitle.
  ///
  /// In es, this message translates to:
  /// **'¿Qué querés ver?'**
  String get onboardingTabsTitle;

  /// No description provided for @onboardingTabsBody.
  ///
  /// In es, this message translates to:
  /// **'¿Qué querés ver?'**
  String get onboardingTabsBody;

  /// No description provided for @tutorialHabitsTitle.
  ///
  /// In es, this message translates to:
  /// **'Hábitos y rachas'**
  String get tutorialHabitsTitle;

  /// No description provided for @tutorialHabitsBody.
  ///
  /// In es, this message translates to:
  /// **'Sostener, no arrancar.'**
  String get tutorialHabitsBody;

  /// No description provided for @tutorialTrackTitle.
  ///
  /// In es, this message translates to:
  /// **'Sueño y journal'**
  String get tutorialTrackTitle;

  /// No description provided for @tutorialTrackBody.
  ///
  /// In es, this message translates to:
  /// **'Registrar es entenderse.'**
  String get tutorialTrackBody;

  /// No description provided for @tutorialFocusTitle.
  ///
  /// In es, this message translates to:
  /// **'Foco y tareas'**
  String get tutorialFocusTitle;

  /// No description provided for @tutorialFocusBody.
  ///
  /// In es, this message translates to:
  /// **'Una cosa a la vez.'**
  String get tutorialFocusBody;

  /// No description provided for @pomodoroTitle.
  ///
  /// In es, this message translates to:
  /// **'Pomodoro'**
  String get pomodoroTitle;

  /// No description provided for @pomodoroSessions.
  ///
  /// In es, this message translates to:
  /// **'Sesiones'**
  String get pomodoroSessions;

  /// No description provided for @pomodoroNew.
  ///
  /// In es, this message translates to:
  /// **'Nueva sesión'**
  String get pomodoroNew;

  /// No description provided for @pomodoroEdit.
  ///
  /// In es, this message translates to:
  /// **'Editar sesión'**
  String get pomodoroEdit;

  /// No description provided for @pomodoroEmpty.
  ///
  /// In es, this message translates to:
  /// **'Todavía no hay sesiones'**
  String get pomodoroEmpty;

  /// No description provided for @pomodoroEmptyHint.
  ///
  /// In es, this message translates to:
  /// **'Creá una y entrá en modo foco'**
  String get pomodoroEmptyHint;

  /// No description provided for @pomodoroStatePending.
  ///
  /// In es, this message translates to:
  /// **'Pendiente'**
  String get pomodoroStatePending;

  /// No description provided for @pomodoroStateInProgress.
  ///
  /// In es, this message translates to:
  /// **'En progreso'**
  String get pomodoroStateInProgress;

  /// No description provided for @pomodoroStateCompleted.
  ///
  /// In es, this message translates to:
  /// **'Completada'**
  String get pomodoroStateCompleted;

  /// No description provided for @pomodoroStateCancelled.
  ///
  /// In es, this message translates to:
  /// **'Cancelada'**
  String get pomodoroStateCancelled;

  /// No description provided for @pomodoroCycles.
  ///
  /// In es, this message translates to:
  /// **'Ciclos'**
  String get pomodoroCycles;

  /// No description provided for @pomodoroFocusMinutes.
  ///
  /// In es, this message translates to:
  /// **'Minutos de foco'**
  String get pomodoroFocusMinutes;

  /// No description provided for @pomodoroBreakMinutes.
  ///
  /// In es, this message translates to:
  /// **'Minutos de descanso'**
  String get pomodoroBreakMinutes;

  /// No description provided for @pomodoroPurpose.
  ///
  /// In es, this message translates to:
  /// **'Propósito'**
  String get pomodoroPurpose;

  /// No description provided for @pomodoroCurrentSession.
  ///
  /// In es, this message translates to:
  /// **'Sesión actual'**
  String get pomodoroCurrentSession;

  /// No description provided for @pomodoroPhaseFocus.
  ///
  /// In es, this message translates to:
  /// **'Foco'**
  String get pomodoroPhaseFocus;

  /// No description provided for @pomodoroPhaseRest.
  ///
  /// In es, this message translates to:
  /// **'Descanso'**
  String get pomodoroPhaseRest;

  /// No description provided for @pomodoroCycleOf.
  ///
  /// In es, this message translates to:
  /// **'Ciclo {done} de {total}'**
  String pomodoroCycleOf(int done, int total);

  /// No description provided for @pomodoroStart.
  ///
  /// In es, this message translates to:
  /// **'Iniciar'**
  String get pomodoroStart;

  /// No description provided for @pomodoroPause.
  ///
  /// In es, this message translates to:
  /// **'Pausar'**
  String get pomodoroPause;

  /// No description provided for @pomodoroSkip.
  ///
  /// In es, this message translates to:
  /// **'Siguiente fase'**
  String get pomodoroSkip;

  /// No description provided for @pomodoroFinish.
  ///
  /// In es, this message translates to:
  /// **'Finalizar'**
  String get pomodoroFinish;

  /// No description provided for @pomodoroCancel.
  ///
  /// In es, this message translates to:
  /// **'Cancelar sesión'**
  String get pomodoroCancel;

  /// No description provided for @pomodoroClose.
  ///
  /// In es, this message translates to:
  /// **'Cerrar sin guardar'**
  String get pomodoroClose;

  /// No description provided for @pomodoroStats.
  ///
  /// In es, this message translates to:
  /// **'Estadísticas'**
  String get pomodoroStats;

  /// No description provided for @pomodoroTotalFocus.
  ///
  /// In es, this message translates to:
  /// **'Foco total'**
  String get pomodoroTotalFocus;

  /// No description provided for @pomodoroTotalCycles.
  ///
  /// In es, this message translates to:
  /// **'Ciclos completados'**
  String get pomodoroTotalCycles;

  /// No description provided for @pomodoroByCategory.
  ///
  /// In es, this message translates to:
  /// **'Por categoría'**
  String get pomodoroByCategory;

  /// No description provided for @pomodoroMinutesPerDay.
  ///
  /// In es, this message translates to:
  /// **'Minutos por día'**
  String get pomodoroMinutesPerDay;

  /// No description provided for @pomodoroMinutes.
  ///
  /// In es, this message translates to:
  /// **'{minutes} min'**
  String pomodoroMinutes(int minutes);

  /// No description provided for @pomodoroHoursMinutes.
  ///
  /// In es, this message translates to:
  /// **'{hours} h {minutes} min'**
  String pomodoroHoursMinutes(int hours, int minutes);

  /// No description provided for @pomodoroValidationRange.
  ///
  /// In es, this message translates to:
  /// **'Entre {min} y {max}'**
  String pomodoroValidationRange(int min, int max);

  /// No description provided for @todoTitle.
  ///
  /// In es, this message translates to:
  /// **'To-Do'**
  String get todoTitle;

  /// No description provided for @todoProjects.
  ///
  /// In es, this message translates to:
  /// **'Proyectos'**
  String get todoProjects;

  /// No description provided for @todoNewProject.
  ///
  /// In es, this message translates to:
  /// **'Nuevo proyecto'**
  String get todoNewProject;

  /// No description provided for @todoNewSubproject.
  ///
  /// In es, this message translates to:
  /// **'Nuevo subproyecto'**
  String get todoNewSubproject;

  /// No description provided for @todoNoProjects.
  ///
  /// In es, this message translates to:
  /// **'Todavía no hay proyectos'**
  String get todoNoProjects;

  /// No description provided for @todoNoProjectsHint.
  ///
  /// In es, this message translates to:
  /// **'Creá uno para empezar a organizar tus tareas'**
  String get todoNoProjectsHint;

  /// No description provided for @todoPickProject.
  ///
  /// In es, this message translates to:
  /// **'Elegí un proyecto'**
  String get todoPickProject;

  /// No description provided for @todoPickProjectHint.
  ///
  /// In es, this message translates to:
  /// **'Sus tareas van a aparecer acá'**
  String get todoPickProjectHint;

  /// No description provided for @todoIncludeSubprojects.
  ///
  /// In es, this message translates to:
  /// **'Incluir subproyectos'**
  String get todoIncludeSubprojects;

  /// No description provided for @todoViewKanban.
  ///
  /// In es, this message translates to:
  /// **'Tablero'**
  String get todoViewKanban;

  /// No description provided for @todoViewList.
  ///
  /// In es, this message translates to:
  /// **'Lista'**
  String get todoViewList;

  /// No description provided for @todoNewTask.
  ///
  /// In es, this message translates to:
  /// **'Nueva tarea'**
  String get todoNewTask;

  /// No description provided for @todoEditTask.
  ///
  /// In es, this message translates to:
  /// **'Editar tarea'**
  String get todoEditTask;

  /// No description provided for @todoNoTasks.
  ///
  /// In es, this message translates to:
  /// **'Sin tareas'**
  String get todoNoTasks;

  /// No description provided for @todoNoTasksHint.
  ///
  /// In es, this message translates to:
  /// **'Agregá la primera con el botón de abajo'**
  String get todoNoTasksHint;

  /// No description provided for @todoStatusTodo.
  ///
  /// In es, this message translates to:
  /// **'Por hacer'**
  String get todoStatusTodo;

  /// No description provided for @todoStatusInProgress.
  ///
  /// In es, this message translates to:
  /// **'En curso'**
  String get todoStatusInProgress;

  /// No description provided for @todoStatusDone.
  ///
  /// In es, this message translates to:
  /// **'Hecho'**
  String get todoStatusDone;

  /// No description provided for @todoPriorityLow.
  ///
  /// In es, this message translates to:
  /// **'Baja'**
  String get todoPriorityLow;

  /// No description provided for @todoPriorityMedium.
  ///
  /// In es, this message translates to:
  /// **'Media'**
  String get todoPriorityMedium;

  /// No description provided for @todoPriorityHigh.
  ///
  /// In es, this message translates to:
  /// **'Alta'**
  String get todoPriorityHigh;

  /// No description provided for @todoPriorityUrgent.
  ///
  /// In es, this message translates to:
  /// **'Urgente'**
  String get todoPriorityUrgent;

  /// No description provided for @todoDueOverdue.
  ///
  /// In es, this message translates to:
  /// **'Vencida'**
  String get todoDueOverdue;

  /// No description provided for @todoDueToday.
  ///
  /// In es, this message translates to:
  /// **'Vence hoy'**
  String get todoDueToday;

  /// No description provided for @todoDueUpcoming.
  ///
  /// In es, this message translates to:
  /// **'Próxima'**
  String get todoDueUpcoming;

  /// No description provided for @todoFieldTitle.
  ///
  /// In es, this message translates to:
  /// **'Título'**
  String get todoFieldTitle;

  /// No description provided for @todoFieldDescription.
  ///
  /// In es, this message translates to:
  /// **'Descripción'**
  String get todoFieldDescription;

  /// No description provided for @todoFieldDue.
  ///
  /// In es, this message translates to:
  /// **'Vencimiento'**
  String get todoFieldDue;

  /// No description provided for @todoFieldPriority.
  ///
  /// In es, this message translates to:
  /// **'Prioridad'**
  String get todoFieldPriority;

  /// No description provided for @todoFieldStatus.
  ///
  /// In es, this message translates to:
  /// **'Estado'**
  String get todoFieldStatus;

  /// No description provided for @todoComments.
  ///
  /// In es, this message translates to:
  /// **'Avances'**
  String get todoComments;

  /// No description provided for @todoCommentHint.
  ///
  /// In es, this message translates to:
  /// **'Anotá un avance'**
  String get todoCommentHint;

  /// No description provided for @todoNoComments.
  ///
  /// In es, this message translates to:
  /// **'Sin avances todavía'**
  String get todoNoComments;

  /// No description provided for @todoFilters.
  ///
  /// In es, this message translates to:
  /// **'Filtros'**
  String get todoFilters;

  /// No description provided for @todoFilterCategory.
  ///
  /// In es, this message translates to:
  /// **'Categoría contiene'**
  String get todoFilterCategory;

  /// No description provided for @todoFilterClear.
  ///
  /// In es, this message translates to:
  /// **'Limpiar'**
  String get todoFilterClear;

  /// No description provided for @todoTaskCount.
  ///
  /// In es, this message translates to:
  /// **'{count} tareas'**
  String todoTaskCount(int count);

  /// No description provided for @todoMoveNotAllowed.
  ///
  /// In es, this message translates to:
  /// **'Ese movimiento rompería el árbol de proyectos'**
  String get todoMoveNotAllowed;

  /// No description provided for @dashboardGreeting.
  ///
  /// In es, this message translates to:
  /// **'Hola, {name}'**
  String dashboardGreeting(String name);

  /// No description provided for @dashboardGreetingAnonymous.
  ///
  /// In es, this message translates to:
  /// **'Hola'**
  String get dashboardGreetingAnonymous;

  /// No description provided for @dashboardSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Esto es lo de hoy.'**
  String get dashboardSubtitle;

  /// No description provided for @dashboardRefresh.
  ///
  /// In es, this message translates to:
  /// **'Actualizar'**
  String get dashboardRefresh;

  /// No description provided for @dashboardPendingTasks.
  ///
  /// In es, this message translates to:
  /// **'Tareas pendientes'**
  String get dashboardPendingTasks;

  /// No description provided for @dashboardOverdue.
  ///
  /// In es, this message translates to:
  /// **'{count} vencidas'**
  String dashboardOverdue(int count);

  /// No description provided for @dashboardNoOverdue.
  ///
  /// In es, this message translates to:
  /// **'Ninguna vencida'**
  String get dashboardNoOverdue;

  /// No description provided for @dashboardHabitsToday.
  ///
  /// In es, this message translates to:
  /// **'Hábitos de hoy'**
  String get dashboardHabitsToday;

  /// No description provided for @dashboardHabitsRatio.
  ///
  /// In es, this message translates to:
  /// **'{done} de {total}'**
  String dashboardHabitsRatio(int done, int total);

  /// No description provided for @dashboardFocus.
  ///
  /// In es, this message translates to:
  /// **'Foco'**
  String get dashboardFocus;

  /// No description provided for @dashboardFocusEmpty.
  ///
  /// In es, this message translates to:
  /// **'Nada pendiente. Disfrutalo.'**
  String get dashboardFocusEmpty;

  /// No description provided for @dashboardHealth.
  ///
  /// In es, this message translates to:
  /// **'Salud y journal'**
  String get dashboardHealth;

  /// No description provided for @dashboardSleepToday.
  ///
  /// In es, this message translates to:
  /// **'Sueño de hoy'**
  String get dashboardSleepToday;

  /// No description provided for @dashboardJournalReady.
  ///
  /// In es, this message translates to:
  /// **'Listo'**
  String get dashboardJournalReady;

  /// No description provided for @dashboardJournalPending.
  ///
  /// In es, this message translates to:
  /// **'Pendiente'**
  String get dashboardJournalPending;

  /// No description provided for @dashboardNoJournal.
  ///
  /// In es, this message translates to:
  /// **'Sin entrada'**
  String get dashboardNoJournal;

  /// No description provided for @dashboardQuickActions.
  ///
  /// In es, this message translates to:
  /// **'Accesos rápidos'**
  String get dashboardQuickActions;

  /// No description provided for @dashboardNoDue.
  ///
  /// In es, this message translates to:
  /// **'Sin fecha'**
  String get dashboardNoDue;

  /// No description provided for @tutorialPageOf.
  ///
  /// In es, this message translates to:
  /// **'{page} de {total}'**
  String tutorialPageOf(int page, int total);

  /// No description provided for @onboardingWelcomeDetail.
  ///
  /// In es, this message translates to:
  /// **'Nísabit reúne hábitos, rachas, sueño, diario y tareas en un solo lugar que vive en tu dispositivo. Sin cuentas, sin nube, sin telemetría: tus datos no salen de tu equipo, y la app funciona igual sin conexión.'**
  String get onboardingWelcomeDetail;

  /// No description provided for @tutorialHabitsDetail.
  ///
  /// In es, this message translates to:
  /// **'Definí lo que querés repetir y resolvelo cada día con un toque. Elegí si es diario, semanal, mensual o anual, y en qué días esperás cumplirlo.\n\nLas rachas cuentan aparte: llevan los días seguidos de algo y guardan tu récord, aunque después vuelvas a cero.'**
  String get tutorialHabitsDetail;

  /// No description provided for @tutorialTrackDetail.
  ///
  /// In es, this message translates to:
  /// **'Anotá cuántas horas dormiste y la app te dice cómo estuvo la noche, saca tu promedio y te muestra la tendencia.\n\nEl journal te propone seis campos cortos para cerrar el día: cómo estuviste, qué agradecés, en qué pusiste el foco y con qué querés empezar mañana.\n\nLa tira semanal te deja completar días que te salteaste.'**
  String get tutorialTrackDetail;

  /// No description provided for @tutorialFocusDetail.
  ///
  /// In es, this message translates to:
  /// **'El pomodoro parte tu trabajo en ciclos de foco y descanso, y lleva la cuenta de los minutos que realmente concentraste.\n\nEl To-Do organiza tus tareas en proyectos con hasta tres niveles, y las movés entre Por hacer, En curso y Hecho arrastrándolas por el tablero.'**
  String get tutorialFocusDetail;

  /// No description provided for @onboardingNameDetail.
  ///
  /// In es, this message translates to:
  /// **'Solo lo usamos para saludarte en el panel. No sale de este dispositivo y podés cambiarlo o borrarlo cuando quieras.'**
  String get onboardingNameDetail;

  /// No description provided for @onboardingTabsDetail.
  ///
  /// In es, this message translates to:
  /// **'Elegí las secciones que te sirven y dejá afuera las que no. Podés cambiarlo en cualquier momento desde Configuración, que siempre está a mano arriba a la izquierda.'**
  String get onboardingTabsDetail;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['es'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'es':
      return AppLocalizationsEs();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
