// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Dutch Flemish (`nl`).
class AppLocalizationsNl extends AppLocalizations {
  AppLocalizationsNl([String locale = 'nl']) : super(locale);

  @override
  String get appTitle => 'Locatiewekker';

  @override
  String get alarmsTitle => 'Wekkers';

  @override
  String get noAlarmsYet => 'Nog geen wekkers';

  @override
  String get tapToCreateFirst => 'Tik op + om je eerste wekker aan te maken';

  @override
  String get failedToLoadAlarms => 'Kan wekkers niet laden';

  @override
  String get retry => 'Opnieuw';

  @override
  String get sortBy => 'Sorteren op';

  @override
  String get sortAlarms => 'Wekkers sorteren';

  @override
  String get sortDateCreated => 'Aangemaakt';

  @override
  String get sortName => 'Naam';

  @override
  String get settings => 'Instellingen';

  @override
  String get about => 'Over';

  @override
  String nSelected(int count) {
    return '$count geselecteerd';
  }

  @override
  String get deleteSelected => 'Selectie verwijderen';

  @override
  String deleteNAlarms(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count wekkers',
      one: '1 wekker',
    );
    return '$_temp0 verwijderen?';
  }

  @override
  String deleteNAlarmsBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count wekkers',
      one: '1 wekker',
    );
    return '$_temp0 wordt permanent verwijderd.';
  }

  @override
  String get cancel => 'Annuleren';

  @override
  String get delete => 'Verwijderen';

  @override
  String get ok => 'OK';

  @override
  String alarmDeactivated(String name) {
    return '$name gedeactiveerd';
  }

  @override
  String alarmActivated(String name, String distance) {
    return '$name geactiveerd — $distance verwijderd';
  }

  @override
  String get locationPermissionRequired => 'Locatietoegang vereist';

  @override
  String get notificationsDisabled =>
      'Meldingen uitgeschakeld — je hoort de wekker niet';

  @override
  String get alreadyInsideAlarmArea => 'Al in het wekkergebied';

  @override
  String alreadyInsideAlarmAreaBody(
    String distance,
    String name,
    String radius,
  ) {
    return 'Je bent $distance van \"$name\". Verlaat de $radius radius om te activeren.';
  }

  @override
  String get gpsDisabled => 'GPS is uitgeschakeld';

  @override
  String get openSettings => 'Open instellingen';

  @override
  String get couldNotAcquireLocation => 'Kan locatie niet bepalen';

  @override
  String nAlarmsDeleted(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count wekkers',
      one: '1 wekker',
    );
    return '$_temp0 verwijderd';
  }

  @override
  String deleteFailed(String message) {
    return 'Verwijderen mislukt: $message';
  }

  @override
  String get alarmsNotMonitored => 'Wekkers worden niet bewaakt';

  @override
  String get tapToCheckPermissions => 'Tik om machtigingen te controleren';

  @override
  String get backgroundLocationRequired => 'Achtergrondlocatie vereist';

  @override
  String get gettingLocation => 'Locatie ophalen…';

  @override
  String alarmDefaultName(int id) {
    return 'Wekker #$id';
  }

  @override
  String get active => 'actief';

  @override
  String get inactive => 'inactief';

  @override
  String get backgroundLocationNeeded => 'Achtergrondlocatie nodig';

  @override
  String get backgroundLocationBody =>
      'Locatiewekker moet je locatie op de achtergrond volgen om wekkers te laten afgaan wanneer je aankomt.\n\nSelecteer op het volgende scherm \"Altijd toestaan\".';

  @override
  String get continueButton => 'Doorgaan';

  @override
  String get disableBatteryOptimization => 'Batterijoptimalisatie uitschakelen';

  @override
  String get batteryOptimizationBody =>
      'Om je locatie betrouwbaar op de achtergrond te volgen, moet Locatiewekker worden uitgesloten van batterijoptimalisatie.\n\nZonder dit kan Android de wekkerdienst stoppen om batterij te besparen.';

  @override
  String get skip => 'Overslaan';

  @override
  String get disableOptimization => 'Uitschakelen';

  @override
  String get insideAlarmArea => 'In het wekkergebied';

  @override
  String get insideAlarmAreaBody =>
      'Je bent momenteel in het wekkergebied. De wekker wordt inactief opgeslagen en geactiveerd zodra je het gebied verlaat.';

  @override
  String get saveInactive => 'Inactief opslaan';

  @override
  String get discardChanges => 'Wijzigingen verwerpen?';

  @override
  String get unsavedChangesBody =>
      'Je niet-opgeslagen wijzigingen gaan verloren.';

  @override
  String get keepEditing => 'Blijven bewerken';

  @override
  String get discard => 'Verwerpen';

  @override
  String get locationUnavailable => 'Locatie niet beschikbaar';

  @override
  String get failedToLoadAlarm => 'Kan wekker niet laden';

  @override
  String get osmAttribution => '© OpenStreetMap';

  @override
  String get searchLocation => 'Zoek locatie';

  @override
  String get noResultsFound => 'Geen resultaten gevonden';

  @override
  String get label => 'Label';

  @override
  String get save => 'Opslaan';

  @override
  String get centerOnMyLocation => 'Centreer op mijn locatie';

  @override
  String get resetNorth => 'Herstel noord';

  @override
  String get createAlarm => 'Wekker aanmaken';

  @override
  String get dismiss => 'Sluiten';

  @override
  String get locationAlarmDefault => 'Locatiewekker';

  @override
  String alarmBodyWithinRadius(int radius) {
    return 'Je bent binnen $radius m van je bestemming';
  }

  @override
  String get appearance => 'Weergave';

  @override
  String get theme => 'Thema';

  @override
  String get themeSystem => 'Systeem';

  @override
  String get themeLight => 'Licht';

  @override
  String get themeDark => 'Donker';

  @override
  String get trueBlack => 'Echt zwart';

  @override
  String get trueBlackSubtitle => 'Puur zwart voor AMOLED-schermen';

  @override
  String get aboutTitle => 'Over';

  @override
  String get appTagline => 'Ontvang een melding wanneer je aankomt';

  @override
  String get version => 'Versie';

  @override
  String get license => 'Licentie';

  @override
  String get licenseValue => 'PolyForm Shield 1.0.0';

  @override
  String get mapData => 'Kaartgegevens';

  @override
  String get mapDataValue => 'OpenStreetMap-bijdragers · OSM France';

  @override
  String get geocoding => 'Geocodering';

  @override
  String get geocodingValue => 'Photon door Komoot';

  @override
  String get openSourceLicenses => 'Open source-licenties';

  @override
  String alarmSaved(String name) {
    return '$name opgeslagen';
  }

  @override
  String alarmSavedNoGps(String name) {
    return '$name opgeslagen (inactief — geen GPS)';
  }

  @override
  String alarmSavedInside(String name) {
    return '$name opgeslagen (inactief)';
  }

  @override
  String alarmSavedNoPermission(String name) {
    return '$name opgeslagen — schakel achtergrondlocatie in';
  }
}
