// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Location Alarm';

  @override
  String get alarmsTitle => 'Alarms';

  @override
  String get noAlarmsYet => 'No alarms yet';

  @override
  String get tapToCreateFirst => 'Tap + to create your first alarm';

  @override
  String get failedToLoadAlarms => 'Failed to load alarms';

  @override
  String get retry => 'Retry';

  @override
  String get sortBy => 'Sort by';

  @override
  String get sortAlarms => 'Sort alarms';

  @override
  String get sortDateCreated => 'Date created';

  @override
  String get sortName => 'Name';

  @override
  String get settings => 'Settings';

  @override
  String get about => 'About';

  @override
  String nSelected(int count) {
    return '$count selected';
  }

  @override
  String get deleteSelected => 'Delete selected';

  @override
  String deleteNAlarms(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count alarms',
      one: '1 alarm',
    );
    return 'Delete $_temp0?';
  }

  @override
  String deleteNAlarmsBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count alarms',
      one: '1 alarm',
    );
    return '$_temp0 will be permanently removed.';
  }

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get ok => 'OK';

  @override
  String alarmDeactivated(String name) {
    return '$name deactivated';
  }

  @override
  String alarmActivated(String name, String distance) {
    return '$name activated — $distance away';
  }

  @override
  String get locationPermissionRequired => 'Location permission required';

  @override
  String get notificationsDisabled =>
      'Notifications disabled — you won\'t hear the alarm';

  @override
  String get alreadyInsideAlarmArea => 'Already inside alarm area';

  @override
  String alreadyInsideAlarmAreaBody(
    String distance,
    String name,
    String radius,
  ) {
    return 'You are $distance from \"$name\". Move outside the $radius radius to activate.';
  }

  @override
  String get gpsDisabled => 'GPS is disabled';

  @override
  String get openSettings => 'Open Settings';

  @override
  String get couldNotAcquireLocation => 'Could not acquire location';

  @override
  String nAlarmsDeleted(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count alarms',
      one: '1 alarm',
    );
    return '$_temp0 deleted';
  }

  @override
  String deleteFailed(String message) {
    return 'Delete failed: $message';
  }

  @override
  String get alarmsNotMonitored => 'Alarms are not being monitored';

  @override
  String get tapToCheckPermissions => 'Tap to check permissions';

  @override
  String get backgroundLocationRequired =>
      'Background location permission required';

  @override
  String get gettingLocation => 'Getting location…';

  @override
  String alarmDefaultName(int id) {
    return 'Alarm #$id';
  }

  @override
  String get active => 'active';

  @override
  String get inactive => 'inactive';

  @override
  String get backgroundLocationNeeded => 'Background location needed';

  @override
  String get backgroundLocationBody =>
      'Location Alarm needs to monitor your location in the background to trigger alarms when you arrive.\n\nOn the next screen, select \"Allow all the time\".';

  @override
  String get continueButton => 'Continue';

  @override
  String get disableBatteryOptimization => 'Disable battery optimization';

  @override
  String get batteryOptimizationBody =>
      'To reliably monitor your location in the background, Location Alarm needs to be excluded from battery optimization.\n\nWithout this, Android may stop the alarm service to save battery.';

  @override
  String get skip => 'Skip';

  @override
  String get disableOptimization => 'Disable optimization';

  @override
  String get insideAlarmArea => 'Inside alarm area';

  @override
  String get insideAlarmAreaBody =>
      'You are currently inside this alarm area. The alarm will be saved inactive and activate once you leave.';

  @override
  String get saveInactive => 'Save inactive';

  @override
  String get discardChanges => 'Discard changes?';

  @override
  String get unsavedChangesBody => 'Your unsaved changes will be lost.';

  @override
  String get keepEditing => 'Keep editing';

  @override
  String get discard => 'Discard';

  @override
  String get locationUnavailable => 'Location unavailable';

  @override
  String get failedToLoadAlarm => 'Failed to load alarm';

  @override
  String get osmAttribution => '© OpenStreetMap';

  @override
  String get searchLocation => 'Search location';

  @override
  String get noResultsFound => 'No results found';

  @override
  String get label => 'Label';

  @override
  String get save => 'Save';

  @override
  String get centerOnMyLocation => 'Center on my location';

  @override
  String get resetNorth => 'Reset north';

  @override
  String get createAlarm => 'Create alarm';

  @override
  String get dismiss => 'Dismiss';

  @override
  String get locationAlarmDefault => 'Location Alarm';

  @override
  String alarmBodyWithinRadius(int radius) {
    return 'You are within $radius m of your destination';
  }

  @override
  String get appearance => 'Appearance';

  @override
  String get theme => 'Theme';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get materialYou => 'Material You';

  @override
  String get materialYouSubtitle => 'Use your wallpaper colors';

  @override
  String get trueBlack => 'True black';

  @override
  String get trueBlackSubtitle => 'Pure black background for AMOLED displays';

  @override
  String get aboutTitle => 'About';

  @override
  String get appTagline => 'Get alerted when you arrive';

  @override
  String get version => 'Version';

  @override
  String get license => 'License';

  @override
  String get licenseValue => 'PolyForm Shield 1.0.0';

  @override
  String get mapData => 'Map data';

  @override
  String get mapDataValue => 'OpenStreetMap contributors · OSM France';

  @override
  String get geocoding => 'Geocoding';

  @override
  String get geocodingValue => 'Photon by Komoot';

  @override
  String get openSourceLicenses => 'Open source licenses';

  @override
  String alarmSaved(String name) {
    return '$name saved';
  }

  @override
  String alarmSavedNoGps(String name) {
    return '$name saved (inactive — no GPS lock)';
  }

  @override
  String alarmSavedInside(String name) {
    return '$name saved (inactive)';
  }

  @override
  String alarmSavedNoPermission(String name) {
    return '$name saved — enable background location to monitor';
  }
}
