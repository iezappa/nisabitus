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
