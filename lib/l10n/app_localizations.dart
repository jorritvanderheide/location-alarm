import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_nl.dart';

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

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
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
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('nl'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'There Yet'**
  String get appTitle;

  /// No description provided for @alarmsTitle.
  ///
  /// In en, this message translates to:
  /// **'Alarms'**
  String get alarmsTitle;

  /// No description provided for @noAlarmsYet.
  ///
  /// In en, this message translates to:
  /// **'No alarms yet'**
  String get noAlarmsYet;

  /// No description provided for @tapToCreateFirst.
  ///
  /// In en, this message translates to:
  /// **'Tap + to create your first alarm'**
  String get tapToCreateFirst;

  /// No description provided for @failedToLoadAlarms.
  ///
  /// In en, this message translates to:
  /// **'Failed to load alarms'**
  String get failedToLoadAlarms;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @sortBy.
  ///
  /// In en, this message translates to:
  /// **'Sort by'**
  String get sortBy;

  /// No description provided for @sortAlarms.
  ///
  /// In en, this message translates to:
  /// **'Sort alarms'**
  String get sortAlarms;

  /// No description provided for @sortDateCreated.
  ///
  /// In en, this message translates to:
  /// **'Date created'**
  String get sortDateCreated;

  /// No description provided for @sortName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get sortName;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @nSelected.
  ///
  /// In en, this message translates to:
  /// **'{count} selected'**
  String nSelected(int count);

  /// No description provided for @deleteSelected.
  ///
  /// In en, this message translates to:
  /// **'Delete selected'**
  String get deleteSelected;

  /// No description provided for @deleteNAlarms.
  ///
  /// In en, this message translates to:
  /// **'Delete {count, plural, =1{1 alarm} other{{count} alarms}}?'**
  String deleteNAlarms(int count);

  /// No description provided for @deleteNAlarmsBody.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 alarm} other{{count} alarms}} will be permanently removed.'**
  String deleteNAlarmsBody(int count);

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @alarmDeactivated.
  ///
  /// In en, this message translates to:
  /// **'{name} deactivated'**
  String alarmDeactivated(String name);

  /// No description provided for @alarmActivated.
  ///
  /// In en, this message translates to:
  /// **'{name} activated — {distance} away'**
  String alarmActivated(String name, String distance);

  /// No description provided for @locationPermissionRequired.
  ///
  /// In en, this message translates to:
  /// **'Location permission required'**
  String get locationPermissionRequired;

  /// No description provided for @notificationsDisabled.
  ///
  /// In en, this message translates to:
  /// **'Notifications disabled — you won\'t hear the alarm'**
  String get notificationsDisabled;

  /// No description provided for @alreadyInsideAlarmArea.
  ///
  /// In en, this message translates to:
  /// **'Already inside alarm area'**
  String get alreadyInsideAlarmArea;

  /// No description provided for @alreadyInsideAlarmAreaBody.
  ///
  /// In en, this message translates to:
  /// **'You are {distance} from \"{name}\". Move outside the {radius} radius to activate.'**
  String alreadyInsideAlarmAreaBody(
    String distance,
    String name,
    String radius,
  );

  /// No description provided for @gpsDisabled.
  ///
  /// In en, this message translates to:
  /// **'GPS is disabled'**
  String get gpsDisabled;

  /// No description provided for @openSettings.
  ///
  /// In en, this message translates to:
  /// **'Open Settings'**
  String get openSettings;

  /// No description provided for @couldNotAcquireLocation.
  ///
  /// In en, this message translates to:
  /// **'Could not acquire location'**
  String get couldNotAcquireLocation;

  /// No description provided for @nAlarmsDeleted.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 alarm} other{{count} alarms}} deleted'**
  String nAlarmsDeleted(int count);

  /// No description provided for @deleteFailed.
  ///
  /// In en, this message translates to:
  /// **'Delete failed: {message}'**
  String deleteFailed(String message);

  /// No description provided for @alarmsNotMonitored.
  ///
  /// In en, this message translates to:
  /// **'Alarms are not being monitored'**
  String get alarmsNotMonitored;

  /// No description provided for @tapToCheckPermissions.
  ///
  /// In en, this message translates to:
  /// **'Tap to check permissions'**
  String get tapToCheckPermissions;

  /// No description provided for @backgroundLocationRequired.
  ///
  /// In en, this message translates to:
  /// **'Background location permission required'**
  String get backgroundLocationRequired;

  /// No description provided for @gettingLocation.
  ///
  /// In en, this message translates to:
  /// **'Getting location…'**
  String get gettingLocation;

  /// No description provided for @alarmDefaultName.
  ///
  /// In en, this message translates to:
  /// **'Alarm #{id}'**
  String alarmDefaultName(int id);

  /// No description provided for @active.
  ///
  /// In en, this message translates to:
  /// **'active'**
  String get active;

  /// No description provided for @inactive.
  ///
  /// In en, this message translates to:
  /// **'inactive'**
  String get inactive;

  /// No description provided for @backgroundLocationNeeded.
  ///
  /// In en, this message translates to:
  /// **'Background location needed'**
  String get backgroundLocationNeeded;

  /// No description provided for @backgroundLocationBody.
  ///
  /// In en, this message translates to:
  /// **'There Yet needs to monitor your location in the background to trigger alarms when you arrive.\n\nOn the next screen, select \"Allow all the time\".'**
  String get backgroundLocationBody;

  /// No description provided for @continueButton.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueButton;

  /// No description provided for @disableBatteryOptimization.
  ///
  /// In en, this message translates to:
  /// **'Disable battery optimization'**
  String get disableBatteryOptimization;

  /// No description provided for @batteryOptimizationBody.
  ///
  /// In en, this message translates to:
  /// **'To reliably monitor your location in the background, There Yet needs to be excluded from battery optimization.\n\nWithout this, Android may stop the alarm service to save battery.'**
  String get batteryOptimizationBody;

  /// No description provided for @skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// No description provided for @disableOptimization.
  ///
  /// In en, this message translates to:
  /// **'Disable optimization'**
  String get disableOptimization;

  /// No description provided for @insideAlarmArea.
  ///
  /// In en, this message translates to:
  /// **'Inside alarm area'**
  String get insideAlarmArea;

  /// No description provided for @insideAlarmAreaBody.
  ///
  /// In en, this message translates to:
  /// **'You are currently inside this alarm area. The alarm will be saved inactive and activate once you leave.'**
  String get insideAlarmAreaBody;

  /// No description provided for @saveInactive.
  ///
  /// In en, this message translates to:
  /// **'Save inactive'**
  String get saveInactive;

  /// No description provided for @discardChanges.
  ///
  /// In en, this message translates to:
  /// **'Discard changes?'**
  String get discardChanges;

  /// No description provided for @unsavedChangesBody.
  ///
  /// In en, this message translates to:
  /// **'Your unsaved changes will be lost.'**
  String get unsavedChangesBody;

  /// No description provided for @keepEditing.
  ///
  /// In en, this message translates to:
  /// **'Keep editing'**
  String get keepEditing;

  /// No description provided for @discard.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get discard;

  /// No description provided for @locationUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Location unavailable'**
  String get locationUnavailable;

  /// No description provided for @failedToLoadAlarm.
  ///
  /// In en, this message translates to:
  /// **'Failed to load alarm'**
  String get failedToLoadAlarm;

  /// No description provided for @osmAttribution.
  ///
  /// In en, this message translates to:
  /// **'© OpenStreetMap'**
  String get osmAttribution;

  /// No description provided for @searchLocation.
  ///
  /// In en, this message translates to:
  /// **'Search location'**
  String get searchLocation;

  /// No description provided for @searchLocationOffline.
  ///
  /// In en, this message translates to:
  /// **'Search unavailable (offline)'**
  String get searchLocationOffline;

  /// No description provided for @noResultsFound.
  ///
  /// In en, this message translates to:
  /// **'No results found'**
  String get noResultsFound;

  /// No description provided for @label.
  ///
  /// In en, this message translates to:
  /// **'Label'**
  String get label;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @centerOnMyLocation.
  ///
  /// In en, this message translates to:
  /// **'Center on my location'**
  String get centerOnMyLocation;

  /// No description provided for @resetNorth.
  ///
  /// In en, this message translates to:
  /// **'Reset north'**
  String get resetNorth;

  /// No description provided for @createAlarm.
  ///
  /// In en, this message translates to:
  /// **'Create alarm'**
  String get createAlarm;

  /// No description provided for @dismiss.
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get dismiss;

  /// No description provided for @locationAlarmDefault.
  ///
  /// In en, this message translates to:
  /// **'There Yet'**
  String get locationAlarmDefault;

  /// No description provided for @alarmBodyWithinRadius.
  ///
  /// In en, this message translates to:
  /// **'You are within {radius} m of your destination'**
  String alarmBodyWithinRadius(int radius);

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// No description provided for @theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @materialYou.
  ///
  /// In en, this message translates to:
  /// **'Material You'**
  String get materialYou;

  /// No description provided for @materialYouSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Use your wallpaper colors'**
  String get materialYouSubtitle;

  /// No description provided for @trueBlack.
  ///
  /// In en, this message translates to:
  /// **'True black'**
  String get trueBlack;

  /// No description provided for @trueBlackSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Pure black background for AMOLED displays'**
  String get trueBlackSubtitle;

  /// No description provided for @aboutTitle.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get aboutTitle;

  /// No description provided for @appTagline.
  ///
  /// In en, this message translates to:
  /// **'Get alerted when you arrive'**
  String get appTagline;

  /// No description provided for @version.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get version;

  /// No description provided for @license.
  ///
  /// In en, this message translates to:
  /// **'License'**
  String get license;

  /// No description provided for @licenseValue.
  ///
  /// In en, this message translates to:
  /// **'EUPL 1.2'**
  String get licenseValue;

  /// No description provided for @mapData.
  ///
  /// In en, this message translates to:
  /// **'Map data'**
  String get mapData;

  /// No description provided for @mapDataValue.
  ///
  /// In en, this message translates to:
  /// **'OpenStreetMap contributors · OSM France'**
  String get mapDataValue;

  /// No description provided for @geocoding.
  ///
  /// In en, this message translates to:
  /// **'Geocoding'**
  String get geocoding;

  /// No description provided for @geocodingValue.
  ///
  /// In en, this message translates to:
  /// **'Photon by Komoot'**
  String get geocodingValue;

  /// No description provided for @openSourceLicenses.
  ///
  /// In en, this message translates to:
  /// **'Open source licenses'**
  String get openSourceLicenses;

  /// No description provided for @alarmSaved.
  ///
  /// In en, this message translates to:
  /// **'{name} saved'**
  String alarmSaved(String name);

  /// No description provided for @alarmSavedNoGps.
  ///
  /// In en, this message translates to:
  /// **'{name} saved (inactive — no GPS lock)'**
  String alarmSavedNoGps(String name);

  /// No description provided for @alarmSavedInside.
  ///
  /// In en, this message translates to:
  /// **'{name} saved (inactive)'**
  String alarmSavedInside(String name);

  /// No description provided for @alarmSavedNoPermission.
  ///
  /// In en, this message translates to:
  /// **'{name} saved — enable background location to monitor'**
  String alarmSavedNoPermission(String name);
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
      <String>['en', 'nl'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'nl':
      return AppLocalizationsNl();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
