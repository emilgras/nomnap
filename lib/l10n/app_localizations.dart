import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

/// App strings for the Nordic locales we ship: English (fallback), Danish,
/// Norwegian Bokmål, Swedish, Finnish and Icelandic.
///
/// Each string picks a translation via [_t]; any language left null falls back
/// to English. Icelandic uses the named param `isl` because `is` is a reserved
/// word in Dart.
class S {
  final String _lang;
  S._(this._lang);

  static S of(BuildContext context) => Localizations.of<S>(context, S)!;

  static const delegate = _SDelegate();

  /// Language codes we support, in display order.
  static const languageCodes = ['en', 'da', 'nb', 'sv', 'fi', 'is'];

  static const supportedLocales = [
    Locale('en'),
    Locale('da'),
    Locale('nb'),
    Locale('sv'),
    Locale('fi'),
    Locale('is'),
  ];

  /// Native names shown in the language picker, keyed by language code.
  static const languageNames = {
    'en': 'English',
    'da': 'Dansk',
    'nb': 'Norsk',
    'sv': 'Svenska',
    'fi': 'Suomi',
    'is': 'Íslenska',
  };

  String get localeCode => _lang;

  String _t({
    required String en,
    String? da,
    String? nb,
    String? sv,
    String? fi,
    String? isl,
  }) {
    switch (_lang) {
      case 'da':
        return da ?? en;
      case 'nb':
        return nb ?? en;
      case 'sv':
        return sv ?? en;
      case 'fi':
        return fi ?? en;
      case 'is':
        return isl ?? en;
      default:
        return en;
    }
  }

  // Navigation
  String get navTrack =>
      _t(en: 'Track', da: 'Spor', nb: 'Spor', sv: 'Spåra', fi: 'Seuranta', isl: 'Skrá');
  String get navStats => _t(
      en: 'Stats', da: 'Statistik', nb: 'Statistikk', sv: 'Statistik', fi: 'Tilastot', isl: 'Tölfræði');
  String get navHistory => _t(
      en: 'History', da: 'Historik', nb: 'Historikk', sv: 'Historik', fi: 'Historia', isl: 'Saga');
  String get navProfile => _t(
      en: 'Profile', da: 'Profil', nb: 'Profil', sv: 'Profil', fi: 'Profiili', isl: 'Prófíll');

  // Greetings
  String greetingForHour(int h) {
    if (h < 5) {
      return _t(
          en: 'Good night',
          da: 'Godnat',
          nb: 'God natt',
          sv: 'God natt',
          fi: 'Hyvää yötä',
          isl: 'Góða nótt');
    }
    if (h < 12) {
      return _t(
          en: 'Good morning',
          da: 'Godmorgen',
          nb: 'God morgen',
          sv: 'God morgon',
          fi: 'Hyvää huomenta',
          isl: 'Góðan morgun');
    }
    if (h < 18) {
      return _t(
          en: 'Good afternoon',
          da: 'God eftermiddag',
          nb: 'God ettermiddag',
          sv: 'God eftermiddag',
          fi: 'Hyvää iltapäivää',
          isl: 'Góðan dag');
    }
    return _t(
        en: 'Good evening',
        da: 'God aften',
        nb: 'God kveld',
        sv: 'God kväll',
        fi: 'Hyvää iltaa',
        isl: 'Gott kvöld');
  }

  // Sleep
  String get sleep =>
      _t(en: 'Sleep', da: 'Søvn', nb: 'Søvn', sv: 'Sömn', fi: 'Uni', isl: 'Svefn');
  String get sleeping => _t(
      en: 'Sleeping', da: 'Sover', nb: 'Sover', sv: 'Sover', fi: 'Nukkuu', isl: 'Sefur');
  String get awake =>
      _t(en: 'Awake', da: 'Vågen', nb: 'Våken', sv: 'Vaken', fi: 'Hereillä', isl: 'Vakandi');
  String get startSleep => _t(
      en: 'Start Sleep',
      da: 'Start søvn',
      nb: 'Start søvn',
      sv: 'Starta sömn',
      fi: 'Aloita uni',
      isl: 'Hefja svefn');
  String get wakeUp =>
      _t(en: 'Wake Up', da: 'Vågn op', nb: 'Våkne', sv: 'Vakna', fi: 'Herää', isl: 'Vakna');
  String get slept =>
      _t(en: 'Slept', da: 'Sov', nb: 'Sov', sv: 'Sov', fi: 'Nukkui', isl: 'Svaf');

  // Breastfeed
  String get feed => _t(
      en: 'Breastfeed', da: 'Amning', nb: 'Amming', sv: 'Amning', fi: 'Imetys', isl: 'Brjóstagjöf');
  String get feeding => _t(
      en: 'Breastfeeding',
      da: 'Ammer',
      nb: 'Ammer',
      sv: 'Ammar',
      fi: 'Imettää',
      isl: 'Á brjósti');
  String get notFeeding => _t(
      en: 'Not breastfeeding',
      da: 'Ammer ikke',
      nb: 'Ammer ikke',
      sv: 'Ammar inte',
      fi: 'Ei imetä',
      isl: 'Ekki á brjósti');
  String get stopFeed => _t(
      en: 'Stop breastfeeding',
      da: 'Stop amning',
      nb: 'Stopp amming',
      sv: 'Avsluta amning',
      fi: 'Lopeta imetys',
      isl: 'Stöðva brjóstagjöf');
  String get fed => _t(
      en: 'Breastfed', da: 'Ammede', nb: 'Ammet', sv: 'Ammade', fi: 'Imetti', isl: 'Gaf brjóst');
  String get left =>
      _t(en: 'Left', da: 'Venstre', nb: 'Venstre', sv: 'Vänster', fi: 'Vasen', isl: 'Vinstri');
  String get right =>
      _t(en: 'Right', da: 'Højre', nb: 'Høyre', sv: 'Höger', fi: 'Oikea', isl: 'Hægri');

  // Feed types
  String get breast =>
      _t(en: 'Breast', da: 'Amning', nb: 'Bryst', sv: 'Bröst', fi: 'Rinta', isl: 'Brjóst');
  String get bottle =>
      _t(en: 'Bottle', da: 'Flaske', nb: 'Flaske', sv: 'Flaska', fi: 'Pullo', isl: 'Pela');
  String get tube =>
      _t(en: 'Tube', da: 'Sonde', nb: 'Sonde', sv: 'Sond', fi: 'Letku', isl: 'Sonda');
  String get tapToLog => _t(
      en: 'Tap to log',
      da: 'Tryk for at logge',
      nb: 'Trykk for å logge',
      sv: 'Tryck för att logga',
      fi: 'Kirjaa napauttamalla',
      isl: 'Smelltu til að skrá');
  String get feedAmount =>
      _t(en: 'Amount', da: 'Mængde', nb: 'Mengde', sv: 'Mängd', fi: 'Määrä', isl: 'Magn');
  String get ml => 'ml';
  String amountMl(String n) => '$n ml';

  /// Short "Add" action used on the quick-log card buttons (bottle/tube and
  /// growth measurements).
  String get add => _t(
      en: 'Add', da: 'Tilføj', nb: 'Legg til', sv: 'Lägg till', fi: 'Lisää', isl: 'Bæta við');

  // Growth measurements (weight / length / head circumference)
  String get weight =>
      _t(en: 'Weight', da: 'Vægt', nb: 'Vekt', sv: 'Vikt', fi: 'Paino', isl: 'Þyngd');
  String get length =>
      _t(en: 'Length', da: 'Længde', nb: 'Lengde', sv: 'Längd', fi: 'Pituus', isl: 'Lengd');
  String get headCirc => _t(
      en: 'Head',
      da: 'Hovedomfang',
      nb: 'Hodeomkrets',
      sv: 'Huvudomfång',
      fi: 'Päänympärys',
      isl: 'Höfuðummál');
  String get gramsUnit => 'g';
  String get cmUnit => 'cm';
  String get notMeasuredYet => _t(
      en: 'Not measured yet',
      da: 'Ikke målt endnu',
      nb: 'Ikke målt ennå',
      sv: 'Inte mätt än',
      fi: 'Ei vielä mitattu',
      isl: 'Ekki mælt enn');
  /// "<value> <unit>" e.g. "4250 g" or "55 cm" — unit-agnostic across locales.
  String measurementValue(String value, String unit) => '$value $unit';
  /// Home-card subtitle for the last recorded measurement, e.g. "4250 g · 2d ago".
  String lastMeasured(String value, String ago) => '$value · $ago';

  // Tracker groups (Tilpas + the + sheet)
  String get groupFood => _t(
      en: 'Feeding', da: 'Mad', nb: 'Mat', sv: 'Mat', fi: 'Ruokailu', isl: 'Næring');
  String get groupActivity => _t(
      en: 'Activity',
      da: 'Aktivitet',
      nb: 'Aktivitet',
      sv: 'Aktivitet',
      fi: 'Toiminta',
      isl: 'Virkni');
  String get groupGrowth => _t(
      en: 'Growth', da: 'Vækst', nb: 'Vekst', sv: 'Tillväxt', fi: 'Kasvu', isl: 'Vöxtur');

  // Stats time ranges
  String get rangeWeek =>
      _t(en: 'Week', da: 'Uge', nb: 'Uke', sv: 'Vecka', fi: 'Viikko', isl: 'Vika');
  String get rangeMonth => _t(
      en: 'Month', da: 'Måned', nb: 'Måned', sv: 'Månad', fi: 'Kuukausi', isl: 'Mánuður');
  String get rangeAll =>
      _t(en: 'All', da: 'Alt', nb: 'Alt', sv: 'Allt', fi: 'Kaikki', isl: 'Allt');
  String get noDataInRange => _t(
      en: 'No data in this range yet.',
      da: 'Ingen data i denne periode endnu.',
      nb: 'Ingen data i denne perioden ennå.',
      sv: 'Ingen data i denna period än.',
      fi: 'Ei tietoja tällä ajanjaksolla vielä.',
      isl: 'Engin gögn á þessu tímabili enn.');

  // Diaper
  String get diaper =>
      _t(en: 'Diaper', da: 'Ble', nb: 'Bleie', sv: 'Blöja', fi: 'Vaippa', isl: 'Bleia');
  String get logAChange => _t(
      en: 'Log a change',
      da: 'Log et bleskift',
      nb: 'Logg et skift',
      sv: 'Logga ett byte',
      fi: 'Kirjaa vaihto',
      isl: 'Skrá skipti');
  String get pee =>
      _t(en: 'Pee', da: 'Tis', nb: 'Tiss', sv: 'Kiss', fi: 'Pissa', isl: 'Piss');
  String get poop =>
      _t(en: 'Poop', da: 'Bæ', nb: 'Bæsj', sv: 'Bajs', fi: 'Kakka', isl: 'Kúkur');
  String get diaperSize => _t(
      en: 'Diaper size',
      da: 'Blestørrelse',
      nb: 'Bleiestørrelse',
      sv: 'Blöjstorlek',
      fi: 'Vaipan koko',
      isl: 'Stærð bleiu');
  String get sizeSmall =>
      _t(en: 'Small', da: 'Lille', nb: 'Liten', sv: 'Liten', fi: 'Pieni', isl: 'Lítil');
  String get sizeMedium => _t(
      en: 'Medium', da: 'Mellem', nb: 'Middels', sv: 'Mellan', fi: 'Keskikoko', isl: 'Miðlungs');
  String get sizeLarge =>
      _t(en: 'Large', da: 'Stor', nb: 'Stor', sv: 'Stor', fi: 'Suuri', isl: 'Stór');
  String sizeLabel(String? code) {
    switch (code) {
      case 'S':
        return sizeSmall;
      case 'M':
        return sizeMedium;
      case 'L':
        return sizeLarge;
    }
    return '';
  }

  // Per-tracker options
  String get trackSize => _t(
      en: 'Track size (S/M/L)',
      da: 'Spor størrelse (S/M/L)',
      nb: 'Spor størrelse (S/M/L)',
      sv: 'Spåra storlek (S/M/L)',
      fi: 'Seuraa kokoa (S/M/L)',
      isl: 'Skrá stærð (S/M/L)');
  String get trackAmount => _t(
      en: 'Track amount (ml)',
      da: 'Spor mængde (ml)',
      nb: 'Spor mengde (ml)',
      sv: 'Spåra mängd (ml)',
      fi: 'Seuraa määrää (ml)',
      isl: 'Skrá magn (ml)');

  // Today summary
  String get today =>
      _t(en: 'Today', da: 'I dag', nb: 'I dag', sv: 'Idag', fi: 'Tänään', isl: 'Í dag');
  String get yesterday =>
      _t(en: 'Yesterday', da: 'I går', nb: 'I går', sv: 'Igår', fi: 'Eilen', isl: 'Í gær');
  String get recentActivity => _t(
      en: 'Recent activity',
      da: 'Seneste aktivitet',
      nb: 'Siste aktivitet',
      sv: 'Senaste aktivitet',
      fi: 'Viimeisin toiminta',
      isl: 'Nýleg virkni');
  String get emptyTracker => _t(
      en: 'Tap a button above to start tracking.',
      da: 'Tryk på en knap for at begynde.',
      nb: 'Trykk på en knapp for å begynne.',
      sv: 'Tryck på en knapp ovan för att börja.',
      fi: 'Aloita seuranta napauttamalla yllä olevaa painiketta.',
      isl: 'Smelltu á hnapp að ofan til að byrja.');
  String sleepPlural(int n) => n == 1
      ? sleep
      : _t(
          en: 'Sleeps',
          da: 'Søvn',
          nb: 'Søvner',
          sv: 'Sömnpass',
          fi: 'Unijaksot',
          isl: 'Svefnlotur');
  String feedPlural(int n) => n == 1
      ? feed
      : _t(
          en: 'Breastfeeds',
          da: 'Amninger',
          nb: 'Amminger',
          sv: 'Amningar',
          fi: 'Imetykset',
          isl: 'Brjóstagjafir');
  String diaperPlural(int n) => n == 1
      ? diaper
      : _t(
          en: 'Diapers',
          da: 'Bleer',
          nb: 'Bleier',
          sv: 'Blöjor',
          fi: 'Vaipat',
          isl: 'Bleiur');

  // Customize home
  String get customizeHome => _t(
      en: 'Customize home',
      da: 'Tilpas forside',
      nb: 'Tilpass forsiden',
      sv: 'Anpassa startsidan',
      fi: 'Mukauta etusivua',
      isl: 'Sérsníða forsíðu');
  String get customizeHomeHint => _t(
      en: 'Toggle on/off and drag to reorder.',
      da: 'Tænd, sluk og træk for at omarrangere.',
      nb: 'Slå på/av og dra for å endre rekkefølge.',
      sv: 'Slå på/av och dra för att ändra ordning.',
      fi: 'Kytke päälle/pois ja järjestä vetämällä.',
      isl: 'Kveiktu/slökktu og dragðu til að endurraða.');
  String get noTrackersHint => _t(
      en: 'No trackers shown. Tap Customize to add some.',
      da: 'Ingen trackere vises. Tryk på Tilpas for at tilføje nogle.',
      nb: 'Ingen sporere vises. Trykk på Tilpass for å legge til.',
      sv: 'Inga spårare visas. Tryck på Anpassa för att lägga till.',
      fi: 'Ei näytettäviä seurantoja. Lisää napauttamalla Mukauta.',
      isl: 'Engar skráningar sýndar. Smelltu á Sérsníða til að bæta við.');
  String get customize => _t(
      en: 'Customize', da: 'Tilpas', nb: 'Tilpass', sv: 'Anpassa', fi: 'Mukauta', isl: 'Sérsníða');

  // Suggest-a-tracker ("Missing one?")
  String get missingTrackerPrompt => _t(
      en: 'Missing one?',
      da: 'Mangler der en?',
      nb: 'Mangler du en?',
      sv: 'Saknas någon?',
      fi: 'Puuttuuko jokin?',
      isl: 'Vantar eitthvað?');
  String get missingTrackerCta => _t(
      en: "Tell us and we'll add it for you.",
      da: 'Fortæl os det, så tilføjer vi den.',
      nb: 'Si fra, så legger vi den til.',
      sv: 'Berätta så lägger vi till den.',
      fi: 'Kerro meille, niin lisäämme sen.',
      isl: 'Láttu okkur vita og við bætum því við.');
  String get suggestTrackerTitle => _t(
      en: 'Suggest a tracker',
      da: 'Foreslå en tracker',
      nb: 'Foreslå en sporer',
      sv: 'Föreslå en spårare',
      fi: 'Ehdota seurantaa',
      isl: 'Stinga upp á skráningu');
  String get suggestTrackerPlaceholder => _t(
      en: 'What would you like to track?',
      da: 'Hvad vil du gerne kunne spore?',
      nb: 'Hva vil du spore?',
      sv: 'Vad vill du spåra?',
      fi: 'Mitä haluaisit seurata?',
      isl: 'Hvað viltu skrá?');
  String get suggestEmailPlaceholder => _t(
      en: 'Your email (optional)',
      da: 'Din e-mail (valgfri)',
      nb: 'Din e-post (valgfri)',
      sv: 'Din e-post (valfritt)',
      fi: 'Sähköpostisi (valinnainen)',
      isl: 'Netfangið þitt (valfrjálst)');
  String get suggestEmailHint => _t(
      en: "So we can let you know when it's ready.",
      da: 'Så kan vi sige til, når den er klar.',
      nb: 'Så vi kan si fra når den er klar.',
      sv: 'Så att vi kan höra av oss när den är klar.',
      fi: 'Jotta voimme ilmoittaa, kun se on valmis.',
      isl: 'Svo við getum látið þig vita þegar hún er tilbúin.');
  String get suggestEmailInvalid => _t(
      en: 'Please enter a valid email.',
      da: 'Indtast en gyldig e-mail.',
      nb: 'Skriv inn en gyldig e-post.',
      sv: 'Ange en giltig e-post.',
      fi: 'Anna kelvollinen sähköposti.',
      isl: 'Sláðu inn gilt netfang.');
  String get send =>
      _t(en: 'Send', da: 'Send', nb: 'Send', sv: 'Skicka', fi: 'Lähetä', isl: 'Senda');
  String get sending => _t(
      en: 'Sending…', da: 'Sender…', nb: 'Sender…', sv: 'Skickar…', fi: 'Lähetetään…', isl: 'Sendi…');
  String get suggestThanks => _t(
      en: 'Thanks! We got your suggestion.',
      da: 'Tak! Vi har modtaget dit forslag.',
      nb: 'Takk! Vi har mottatt forslaget ditt.',
      sv: 'Tack! Vi har fått ditt förslag.',
      fi: 'Kiitos! Saimme ehdotuksesi.',
      isl: 'Takk! Við fengum tillöguna þína.');
  String get suggestFailed => _t(
      en: "Couldn't send. Please try again.",
      da: 'Kunne ikke sende. Prøv igen.',
      nb: 'Kunne ikke sende. Prøv igjen.',
      sv: 'Kunde inte skicka. Försök igen.',
      fi: 'Lähetys epäonnistui. Yritä uudelleen.',
      isl: 'Tókst ekki að senda. Reyndu aftur.');

  // Last activity (home card subtitles). [ago] comes from relativeTimeAgo.
  String lastSlept(String ago) => _t(
      en: 'Last slept $ago',
      da: 'Sov sidst $ago',
      nb: 'Sov sist $ago',
      sv: 'Sov senast $ago',
      fi: 'Nukkui viimeksi $ago',
      isl: 'Svaf síðast $ago');
  String lastFed(String ago) => _t(
      en: 'Last fed $ago',
      da: 'Ammede sidst $ago',
      nb: 'Ammet sist $ago',
      sv: 'Ammade senast $ago',
      fi: 'Syötetty viimeksi $ago',
      isl: 'Síðast gefið $ago');
  String lastAgo(String ago) => _t(
      en: 'Last $ago',
      da: 'Sidst $ago',
      nb: 'Sist $ago',
      sv: 'Senast $ago',
      fi: 'Viimeksi $ago',
      isl: 'Síðast $ago');
  String lastPee(String ago) => _t(
      en: 'Pee $ago',
      da: 'Tis $ago',
      nb: 'Tiss $ago',
      sv: 'Kiss $ago',
      fi: 'Pissa $ago',
      isl: 'Piss $ago');
  String lastPoo(String ago) => _t(
      en: 'Poo $ago',
      da: 'Bæ $ago',
      nb: 'Bæsj $ago',
      sv: 'Bajs $ago',
      fi: 'Kakka $ago',
      isl: 'Kúkur $ago');

  // Shared
  String since(String time) => _t(
      en: 'Since $time',
      da: 'Siden $time',
      nb: 'Siden $time',
      sv: 'Sedan $time',
      fi: '$time alkaen',
      isl: 'Síðan $time');
  String sideLabel(String? code) {
    if (code == 'L') return left;
    if (code == 'R') return right;
    return '';
  }

  // Stats
  String get stats => _t(
      en: 'Stats', da: 'Statistik', nb: 'Statistikk', sv: 'Statistik', fi: 'Tilastot', isl: 'Tölfræði');
  String get noDataYet => _t(
      en: 'No data yet.\nStart tracking to see your averages.',
      da: 'Ingen data endnu.\nBegynd at spore for at se gennemsnit.',
      nb: 'Ingen data ennå.\nBegynn å spore for å se gjennomsnitt.',
      sv: 'Ingen data än.\nBörja spåra för att se dina genomsnitt.',
      fi: 'Ei vielä tietoja.\nAloita seuranta nähdäksesi keskiarvot.',
      isl: 'Engin gögn enn.\nByrjaðu að skrá til að sjá meðaltöl.');
  String get dailyAverages => _t(
      en: 'Daily averages',
      da: 'Daglige gennemsnit',
      nb: 'Daglige gjennomsnitt',
      sv: 'Dagliga genomsnitt',
      fi: 'Päivittäiset keskiarvot',
      isl: 'Dagleg meðaltöl');
  String get sessionAverages => _t(
      en: 'Session averages',
      da: 'Sessionsgennemsnit',
      nb: 'Gjennomsnitt per økt',
      sv: 'Genomsnitt per pass',
      fi: 'Jaksojen keskiarvot',
      isl: 'Meðaltöl lotu');
  String get avgSleepLength => _t(
      en: 'Avg sleep length',
      da: 'Gns. søvnlængde',
      nb: 'Gj.sn. søvnlengde',
      sv: 'Snittlängd sömn',
      fi: 'Unen keskipituus',
      isl: 'Meðallengd svefns');
  String get avgFeedLength => _t(
      en: 'Avg breastfeed length',
      da: 'Gns. amningslængde',
      nb: 'Gj.sn. ammelengde',
      sv: 'Snittlängd amning',
      fi: 'Imetyksen keskipituus',
      isl: 'Meðallengd brjóstagjafar');
  String get longestSleep => _t(
      en: 'Longest sleep',
      da: 'Længste søvn',
      nb: 'Lengste søvn',
      sv: 'Längsta sömn',
      fi: 'Pisin uni',
      isl: 'Lengsti svefn');
  String get sleepPerDay => _t(
      en: 'Sleep / day',
      da: 'Søvn / dag',
      nb: 'Søvn / dag',
      sv: 'Sömn / dag',
      fi: 'Uni / päivä',
      isl: 'Svefn / dag');
  String get feedingPerDay => _t(
      en: 'Breastfeeding / day',
      da: 'Amning / dag',
      nb: 'Amming / dag',
      sv: 'Amning / dag',
      fi: 'Imetys / päivä',
      isl: 'Brjóstagjöf / dag');
  String get sessions => _t(
      en: 'sessions', da: 'sessioner', nb: 'økter', sv: 'pass', fi: 'jaksoa', isl: 'lotur');
  String get byDay => _t(
      en: 'By day', da: 'Per dag', nb: 'Per dag', sv: 'Per dag', fi: 'Päivittäin', isl: 'Eftir dögum');
  String diapersPerDay(String n) => _t(
      en: '$n diapers / day',
      da: '$n bleer / dag',
      nb: '$n bleier / dag',
      sv: '$n blöjor / dag',
      fi: '$n vaippaa / päivä',
      isl: '$n bleiur / dag');
  String feedsPerDay(String n) => _t(
      en: '$n feeds / day',
      da: '$n måltider / dag',
      nb: '$n måltider / dag',
      sv: '$n måltider / dag',
      fi: '$n ateriaa / päivä',
      isl: '$n máltíðir / dag');
  String mlPerDay(String n) => _t(
      en: '$n ml / day',
      da: '$n ml / dag',
      nb: '$n ml / dag',
      sv: '$n ml / dag',
      fi: '$n ml / päivä',
      isl: '$n ml / dag');

  // History
  String get history => _t(
      en: 'History', da: 'Historik', nb: 'Historikk', sv: 'Historik', fi: 'Historia', isl: 'Saga');
  String get emptyHistory => _t(
      en: 'Your tracked sessions will appear here.',
      da: 'Dine sessioner vises her.',
      nb: 'Øktene dine vises her.',
      sv: 'Dina pass visas här.',
      fi: 'Seuratut jaksot näkyvät tässä.',
      isl: 'Skráðar lotur birtast hér.');
  String get clearAllTitle => _t(
      en: 'Clear all data?',
      da: 'Slet alle data?',
      nb: 'Slette alle data?',
      sv: 'Rensa all data?',
      fi: 'Tyhjennetäänkö kaikki tiedot?',
      isl: 'Eyða öllum gögnum?');
  String get clearAllMessage => _t(
      en: 'This will permanently delete all tracked data. This cannot be undone.',
      da: 'Dette sletter permanent alle data. Det kan ikke fortrydes.',
      nb: 'Dette sletter alle data permanent. Dette kan ikke angres.',
      sv: 'Detta raderar all data permanent. Det går inte att ångra.',
      fi: 'Tämä poistaa kaikki tiedot pysyvästi. Tätä ei voi kumota.',
      isl: 'Þetta eyðir öllum gögnum varanlega. Ekki er hægt að afturkalla.');
  String get deleteAll => _t(
      en: 'Delete all', da: 'Slet alt', nb: 'Slett alt', sv: 'Radera allt', fi: 'Poista kaikki', isl: 'Eyða öllu');
  String get cancel => _t(
      en: 'Cancel', da: 'Annuller', nb: 'Avbryt', sv: 'Avbryt', fi: 'Peruuta', isl: 'Hætta við');
  String get delete =>
      _t(en: 'Delete', da: 'Slet', nb: 'Slett', sv: 'Radera', fi: 'Poista', isl: 'Eyða');
  String get deleteThisSession => _t(
      en: 'Delete this session?',
      da: 'Slet denne session?',
      nb: 'Slette denne økten?',
      sv: 'Radera detta pass?',
      fi: 'Poistetaanko tämä jakso?',
      isl: 'Eyða þessari lotu?');
  String get deleteThisDiaper => _t(
      en: 'Delete this diaper entry?',
      da: 'Slet dette bleskift?',
      nb: 'Slette dette bleieskiftet?',
      sv: 'Radera detta blöjbyte?',
      fi: 'Poistetaanko tämä vaipanvaihto?',
      isl: 'Eyða þessu bleiuskipti?');
  String get deleteThisEntry => _t(
      en: 'Delete this entry?',
      da: 'Slet denne registrering?',
      nb: 'Slette denne oppføringen?',
      sv: 'Radera denna post?',
      fi: 'Poistetaanko tämä merkintä?',
      isl: 'Eyða þessari færslu?');
  String get editTime => _t(
      en: 'Edit time', da: 'Rediger tid', nb: 'Rediger tid', sv: 'Ändra tid', fi: 'Muokkaa aikaa', isl: 'Breyta tíma');
  String get editStart => _t(
      en: 'Edit start',
      da: 'Rediger start',
      nb: 'Rediger start',
      sv: 'Ändra start',
      fi: 'Muokkaa alkua',
      isl: 'Breyta upphafi');
  String get editEnd => _t(
      en: 'Edit end',
      da: 'Rediger slut',
      nb: 'Rediger slutt',
      sv: 'Ändra slut',
      fi: 'Muokkaa loppua',
      isl: 'Breyta lokum');
  String get editStartTime => _t(
      en: 'Edit start time',
      da: 'Rediger starttid',
      nb: 'Rediger starttid',
      sv: 'Ändra starttid',
      fi: 'Muokkaa alkamisaikaa',
      isl: 'Breyta upphafstíma');
  String get editEndTime => _t(
      en: 'Edit end time',
      da: 'Rediger sluttid',
      nb: 'Rediger sluttid',
      sv: 'Ändra sluttid',
      fi: 'Muokkaa päättymisaikaa',
      isl: 'Breyta lokatíma');
  String get endNow => _t(
      en: 'End now', da: 'Afslut nu', nb: 'Avslutt nå', sv: 'Avsluta nu', fi: 'Lopeta nyt', isl: 'Ljúka núna');
  String get deleteSession => _t(
      en: 'Delete session',
      da: 'Slet session',
      nb: 'Slett økt',
      sv: 'Radera pass',
      fi: 'Poista jakso',
      isl: 'Eyða lotu');
  String get switchToRight => _t(
      en: 'Switch to Right',
      da: 'Skift til højre',
      nb: 'Bytt til høyre',
      sv: 'Byt till höger',
      fi: 'Vaihda oikeaan',
      isl: 'Skipta í hægri');
  String get switchToLeft => _t(
      en: 'Switch to Left',
      da: 'Skift til venstre',
      nb: 'Bytt til venstre',
      sv: 'Byt till vänster',
      fi: 'Vaihda vasempaan',
      isl: 'Skipta í vinstri');
  String get save =>
      _t(en: 'Save', da: 'Gem', nb: 'Lagre', sv: 'Spara', fi: 'Tallenna', isl: 'Vista');

  // Add entry
  String get addEntry => _t(
      en: 'Add entry', da: 'Tilføj', nb: 'Legg til', sv: 'Lägg till', fi: 'Lisää', isl: 'Bæta við');
  String get started => _t(
      en: 'Started', da: 'Startet', nb: 'Startet', sv: 'Startade', fi: 'Alkoi', isl: 'Hófst');
  String get ended => _t(
      en: 'Ended', da: 'Sluttet', nb: 'Avsluttet', sv: 'Avslutades', fi: 'Päättyi', isl: 'Lauk');
  String get time => _t(en: 'Time', da: 'Tid', nb: 'Tid', sv: 'Tid', fi: 'Aika', isl: 'Tími');
  String get stillInProgress => _t(
      en: 'Still in progress',
      da: 'Stadig i gang',
      nb: 'Fortsatt pågår',
      sv: 'Pågår fortfarande',
      fi: 'Vielä käynnissä',
      isl: 'Enn í gangi');
  String get startTime => _t(
      en: 'Start time', da: 'Starttid', nb: 'Starttid', sv: 'Starttid', fi: 'Alkamisaika', isl: 'Upphafstími');
  String get endTime => _t(
      en: 'End time', da: 'Sluttid', nb: 'Sluttid', sv: 'Sluttid', fi: 'Päättymisaika', isl: 'Lokatími');
  String get done =>
      _t(en: 'Done', da: 'Færdig', nb: 'Ferdig', sv: 'Klar', fi: 'Valmis', isl: 'Lokið');
  String get inProgress => _t(
      en: 'In progress', da: 'I gang', nb: 'Pågår', sv: 'Pågår', fi: 'Käynnissä', isl: 'Í gangi');
  String durationLabel(String d) => _t(
      en: 'Duration  $d',
      da: 'Varighed  $d',
      nb: 'Varighet  $d',
      sv: 'Längd  $d',
      fi: 'Kesto  $d',
      isl: 'Lengd  $d');
  String get errorTimeFuture => _t(
      en: "Time can't be in the future.",
      da: 'Tidspunktet kan ikke være i fremtiden.',
      nb: 'Tidspunktet kan ikke være i fremtiden.',
      sv: 'Tiden kan inte vara i framtiden.',
      fi: 'Aika ei voi olla tulevaisuudessa.',
      isl: 'Tími getur ekki verið í framtíðinni.');
  String get errorStartFuture => _t(
      en: "Start can't be in the future.",
      da: 'Start kan ikke være i fremtiden.',
      nb: 'Start kan ikke være i fremtiden.',
      sv: 'Starten kan inte vara i framtiden.',
      fi: 'Alku ei voi olla tulevaisuudessa.',
      isl: 'Upphaf getur ekki verið í framtíðinni.');
  String get errorEndAfterStart => _t(
      en: 'End must be after start.',
      da: 'Slut skal være efter start.',
      nb: 'Slutt må være etter start.',
      sv: 'Slut måste vara efter start.',
      fi: 'Lopun on oltava alun jälkeen.',
      isl: 'Lok verða að vera eftir upphaf.');
  String get sleepAlreadyInProgress => _t(
      en: 'A sleep is already in progress.',
      da: 'En søvn er allerede i gang.',
      nb: 'En søvn pågår allerede.',
      sv: 'En sömn pågår redan.',
      fi: 'Uni on jo käynnissä.',
      isl: 'Svefn er þegar í gangi.');
  String get feedAlreadyInProgress => _t(
      en: 'A breastfeed is already in progress.',
      da: 'En amning er allerede i gang.',
      nb: 'En amming pågår allerede.',
      sv: 'En amning pågår redan.',
      fi: 'Imetys on jo käynnissä.',
      isl: 'Brjóstagjöf er þegar í gangi.');

  // Profile
  String get profileAccount => _t(
      en: 'ACCOUNT', da: 'KONTO', nb: 'KONTO', sv: 'KONTO', fi: 'TILI', isl: 'AÐGANGUR');
  String get profileThisDevice => _t(
      en: 'This device',
      da: 'Denne enhed',
      nb: 'Denne enheten',
      sv: 'Den här enheten',
      fi: 'Tämä laite',
      isl: 'Þetta tæki');
  String get profileThisDeviceSub => _t(
      en: 'Your data is saved on this device and synced to the cloud.',
      da: 'Dine data gemmes på denne enhed og synkroniseres til skyen.',
      nb: 'Dataene dine lagres på denne enheten og synkroniseres til skyen.',
      sv: 'Dina data sparas på den här enheten och synkas till molnet.',
      fi: 'Tietosi tallennetaan tähän laitteeseen ja synkronoidaan pilveen.',
      isl: 'Gögnin þín eru vistuð í þessu tæki og samstillt við skýið.');
  String get profileBackup => _t(
      en: 'Back up your account',
      da: 'Sikkerhedskopiér din konto',
      nb: 'Sikkerhetskopier kontoen din',
      sv: 'Säkerhetskopiera ditt konto',
      fi: 'Varmuuskopioi tilisi',
      isl: 'Taktu öryggisafrit af aðgangnum');
  String get profileBackupSub => _t(
      en: 'Add an email to recover on a new phone.',
      da: 'Tilføj en e-mail for at gendanne på en ny telefon.',
      nb: 'Legg til en e-post for å gjenopprette på en ny telefon.',
      sv: 'Lägg till en e-post för att återställa på en ny telefon.',
      fi: 'Lisää sähköposti palauttaaksesi uudella puhelimella.',
      isl: 'Bættu við netfangi til að endurheimta í nýjum síma.');
  String get soon =>
      _t(en: 'Soon', da: 'Snart', nb: 'Snart', sv: 'Snart', fi: 'Pian', isl: 'Bráðum');
  String get profilePreferences => _t(
      en: 'PREFERENCES',
      da: 'INDSTILLINGER',
      nb: 'INNSTILLINGER',
      sv: 'INSTÄLLNINGAR',
      fi: 'ASETUKSET',
      isl: 'STILLINGAR');
  String get language =>
      _t(en: 'Language', da: 'Sprog', nb: 'Språk', sv: 'Språk', fi: 'Kieli', isl: 'Tungumál');
  String get languageSub => _t(
      en: 'Choose the app language.',
      da: 'Vælg appens sprog.',
      nb: 'Velg appens språk.',
      sv: 'Välj appens språk.',
      fi: 'Valitse sovelluksen kieli.',
      isl: 'Veldu tungumál forritsins.');
  String get dayStart => _t(
      en: 'Day start',
      da: 'Dagens start',
      nb: 'Dagens start',
      sv: 'Dygnets start',
      fi: 'Päivän alku',
      isl: 'Upphaf dags');
  String get dayStartSub => _t(
      en: 'When a new day begins in stats and history.',
      da: 'Hvornår en ny dag starter i statistik og historik.',
      nb: 'Når en ny dag starter i statistikk og historikk.',
      sv: 'När ett nytt dygn börjar i statistik och historik.',
      fi: 'Milloin uusi päivä alkaa tilastoissa ja historiassa.',
      isl: 'Hvenær nýr dagur hefst í tölfræði og sögu.');
  String get dayStartTitle => _t(
      en: 'Day starts at',
      da: 'Dagen starter kl.',
      nb: 'Dagen starter kl.',
      sv: 'Dygnet börjar kl.',
      fi: 'Päivä alkaa klo',
      isl: 'Dagur hefst kl.');
  String dayStartValue(int hour) {
    final hh = hour.toString().padLeft(2, '0');
    final label = '$hh:00';
    if (hour != 0) return label;
    return _t(
      en: '$label (midnight)',
      da: '$label (midnat)',
      nb: '$label (midnatt)',
      sv: '$label (midnatt)',
      fi: '$label (keskiyö)',
      isl: '$label (miðnætti)',
    );
  }

  String get profileSharing => _t(
      en: 'SHARING', da: 'DELING', nb: 'DELING', sv: 'DELNING', fi: 'JAKAMINEN', isl: 'DEILING');
  String get caregivers => _t(
      en: 'Caregivers',
      da: 'Omsorgspersoner',
      nb: 'Omsorgspersoner',
      sv: 'Vårdgivare',
      fi: 'Hoitajat',
      isl: 'Umönnunaraðilar');
  String get caregiversSub => _t(
      en: 'Invite and manage who tracks this baby with you.',
      da: 'Inviter og administrer, hvem der følger denne baby med dig.',
      nb: 'Inviter og administrer hvem som følger denne babyen med deg.',
      sv: 'Bjud in och hantera vilka som följer den här bebisen med dig.',
      fi: 'Kutsu ja hallitse, ketkä seuraavat tätä vauvaa kanssasi.',
      isl: 'Bjóddu og stýrðu hverjir fylgjast með þessu barni með þér.');
  String get profileAbout =>
      _t(en: 'ABOUT', da: 'OM', nb: 'OM', sv: 'OM', fi: 'TIETOJA', isl: 'UM');
  String get appTagline => _t(
      en: 'A simple, elegant baby sleep & feed tracker.',
      da: 'En enkel og elegant tracker til babyens søvn og mad.',
      nb: 'En enkel og elegant sporer for babyens søvn og mat.',
      sv: 'En enkel och elegant spårare för bebisens sömn och mat.',
      fi: 'Yksinkertainen ja tyylikäs vauvan unen ja ruokailun seuranta.',
      isl: 'Einfalt og glæsilegt forrit fyrir svefn og næringu barnsins.');

  // Profile deletion
  String get profileData => _t(
      en: 'DATA & PRIVACY',
      da: 'DATA & PRIVATLIV',
      nb: 'DATA OG PERSONVERN',
      sv: 'DATA & INTEGRITET',
      fi: 'TIEDOT JA YKSITYISYYS',
      isl: 'GÖGN OG FRIÐHELGI');
  String get deleteProfile => _t(
      en: 'Delete profile & data',
      da: 'Slet profil og data',
      nb: 'Slett profil og data',
      sv: 'Radera profil och data',
      fi: 'Poista profiili ja tiedot',
      isl: 'Eyða notandasniði og gögnum');
  String get deleteProfileSub => _t(
      en: 'Permanently erase this profile and everything tracked.',
      da: 'Slet permanent denne profil og alt det registrerede.',
      nb: 'Slett permanent denne profilen og alt som er registrert.',
      sv: 'Radera permanent denna profil och allt som registrerats.',
      fi: 'Poista pysyvästi tämä profiili ja kaikki tallennettu.',
      isl: 'Eyða varanlega þessu notandasniði og öllu skráðu.');
  String get deleteProfileTitle => _t(
      en: 'Delete profile & all data?',
      da: 'Slet profil og alle data?',
      nb: 'Slette profil og alle data?',
      sv: 'Radera profil och all data?',
      fi: 'Poistetaanko profiili ja kaikki tiedot?',
      isl: 'Eyða notandasniði og öllum gögnum?');
  String get deleteProfileMessage => _t(
      en: 'This permanently deletes your profile and all tracked sleep, feeds, diapers and measurements for everyone sharing this baby. Your invite codes stop working and this cannot be undone.',
      da: 'Dette sletter permanent din profil og alle registrerede data om søvn, mad, bleer og målinger for alle, der deler denne baby. Dine invitationskoder holder op med at virke, og det kan ikke fortrydes.',
      nb: 'Dette sletter permanent profilen din og alle registrerte data om søvn, mating, bleier og målinger for alle som deler denne babyen. Invitasjonskodene dine slutter å virke, og dette kan ikke angres.',
      sv: 'Detta raderar permanent din profil och all registrerad data om sömn, matning, blöjor och mätningar för alla som delar den här bebisen. Dina inbjudningskoder slutar fungera och det går inte att ångra.',
      fi: 'Tämä poistaa pysyvästi profiilisi ja kaikki tallennetut uni-, ruokailu-, vaippa- ja mittaustiedot kaikilta, jotka jakavat tämän vauvan. Kutsukoodisi lakkaavat toimimasta, eikä tätä voi kumota.',
      isl: 'Þetta eyðir varanlega notandasniðinu þínu og öllum skráðum svefn-, næringar-, bleyju- og mælingargögnum fyrir alla sem deila þessu barni. Boðskóðarnir þínir hætta að virka og ekki er hægt að afturkalla þetta.');
  String get deleteProfileConfirm => _t(
      en: 'Delete everything',
      da: 'Slet alt',
      nb: 'Slett alt',
      sv: 'Radera allt',
      fi: 'Poista kaikki',
      isl: 'Eyða öllu');
  // Caregiver variant: leaves the shared baby but keeps its data for the owner.
  String get leaveProfile => _t(
      en: 'Leave & delete profile',
      da: 'Forlad og slet profil',
      nb: 'Forlat og slett profil',
      sv: 'Lämna och radera profil',
      fi: 'Poistu ja poista profiili',
      isl: 'Fara og eyða notandasniði');
  String get leaveProfileSub => _t(
      en: 'Leave this shared baby and erase your profile.',
      da: 'Forlad denne delte baby, og slet din profil.',
      nb: 'Forlat denne delte babyen og slett profilen din.',
      sv: 'Lämna den här delade bebisen och radera din profil.',
      fi: 'Poistu tästä jaetusta vauvasta ja poista profiilisi.',
      isl: 'Farðu úr þessu deilda barni og eyddu notandasniðinu þínu.');
  String get leaveProfileTitle => _t(
      en: 'Leave & delete profile?',
      da: 'Forlad og slet profil?',
      nb: 'Forlate og slette profil?',
      sv: 'Lämna och radera profil?',
      fi: 'Poistutaanko ja poistetaanko profiili?',
      isl: 'Fara og eyða notandasniði?');
  String get leaveProfileMessage => _t(
      en: "This removes you from this shared baby and permanently deletes your profile on this device. The baby's tracked data stays for the other caregivers. This cannot be undone.",
      da: 'Dette fjerner dig fra denne delte baby og sletter permanent din profil på denne enhed. Babyens registrerede data forbliver hos de andre omsorgspersoner. Det kan ikke fortrydes.',
      nb: 'Dette fjerner deg fra denne delte babyen og sletter profilen din permanent på denne enheten. Babyens registrerte data blir værende hos de andre omsorgspersonene. Dette kan ikke angres.',
      sv: 'Detta tar bort dig från den här delade bebisen och raderar permanent din profil på den här enheten. Bebisens registrerade data stannar kvar hos de andra vårdgivarna. Det går inte att ångra.',
      fi: 'Tämä poistaa sinut tästä jaetusta vauvasta ja poistaa pysyvästi profiilisi tältä laitteelta. Vauvan tallennetut tiedot säilyvät muilla hoitajilla. Tätä ei voi kumota.',
      isl: 'Þetta fjarlægir þig úr þessu deilda barni og eyðir varanlega notandasniðinu þínu á þessu tæki. Skráð gögn barnsins haldast hjá hinum umönnunaraðilunum. Ekki er hægt að afturkalla þetta.');
  String get leaveProfileConfirm => _t(
      en: 'Leave & delete',
      da: 'Forlad og slet',
      nb: 'Forlat og slett',
      sv: 'Lämna och radera',
      fi: 'Poistu ja poista',
      isl: 'Fara og eyða');

  // Caregivers / sharing
  String get inviteSectionTitle => _t(
      en: 'INVITE A CAREGIVER',
      da: 'INVITER EN OMSORGSPERSON',
      nb: 'INVITER EN OMSORGSPERSON',
      sv: 'BJUD IN EN VÅRDGIVARE',
      fi: 'KUTSU HOITAJA',
      isl: 'BJÓÐA UMÖNNUNARAÐILA');
  String get inviteIntro => _t(
      en: 'Share a code so another phone can track this baby with you. Codes expire after 7 days.',
      da: 'Del en kode, så en anden telefon kan følge denne baby sammen med dig. Koder udløber efter 7 dage.',
      nb: 'Del en kode så en annen telefon kan følge denne babyen sammen med deg. Koder utløper etter 7 dager.',
      sv: 'Dela en kod så att en annan telefon kan följa den här bebisen med dig. Koder upphör efter 7 dagar.',
      fi: 'Jaa koodi, jotta toinen puhelin voi seurata tätä vauvaa kanssasi. Koodit vanhenevat 7 päivän kuluttua.',
      isl: 'Deildu kóða svo annar sími geti fylgst með þessu barni með þér. Kóðar renna út eftir 7 daga.');
  String get createInviteCode => _t(
      en: 'Create invite code',
      da: 'Opret invitationskode',
      nb: 'Opprett invitasjonskode',
      sv: 'Skapa inbjudningskod',
      fi: 'Luo kutsukoodi',
      isl: 'Búa til boðskóða');
  String get copy =>
      _t(en: 'Copy', da: 'Kopiér', nb: 'Kopier', sv: 'Kopiera', fi: 'Kopioi', isl: 'Afrita');
  String get share =>
      _t(en: 'Share', da: 'Del', nb: 'Del', sv: 'Dela', fi: 'Jaa', isl: 'Deila');
  String get caregiversSectionTitle => _t(
      en: 'CAREGIVERS',
      da: 'OMSORGSPERSONER',
      nb: 'OMSORGSPERSONER',
      sv: 'VÅRDGIVARE',
      fi: 'HOITAJAT',
      isl: 'UMÖNNUNARAÐILAR');
  String get joinSectionTitle => _t(
      en: 'JOIN WITH A CODE',
      da: 'DELTAG MED EN KODE',
      nb: 'BLI MED VIA EN KODE',
      sv: 'GÅ MED VIA EN KOD',
      fi: 'LIITY KOODILLA',
      isl: 'TAKA ÞÁTT MEÐ KÓÐA');
  String get joinIntro => _t(
      en: 'Got a code from another caregiver? Enter it to track their baby together.',
      da: 'Har du en kode fra en anden omsorgsperson? Indtast den for at følge deres baby sammen.',
      nb: 'Har du en kode fra en annen omsorgsperson? Skriv den inn for å følge babyen sammen.',
      sv: 'Har du en kod från en annan vårdgivare? Ange den för att följa deras bebis tillsammans.',
      fi: 'Saitko koodin toiselta hoitajalta? Syötä se seurataksesi heidän vauvaansa yhdessä.',
      isl: 'Ertu með kóða frá öðrum umönnunaraðila? Sláðu hann inn til að fylgjast með barninu saman.');
  String get joinCodePlaceholder => _t(
      en: 'e.g. ABCD2345',
      da: 'f.eks. ABCD2345',
      nb: 'f.eks. ABCD2345',
      sv: 't.ex. ABCD2345',
      fi: 'esim. ABCD2345',
      isl: 't.d. ABCD2345');
  String get join =>
      _t(en: 'Join', da: 'Deltag', nb: 'Bli med', sv: 'Gå med', fi: 'Liity', isl: 'Taka þátt');
  String get meSelf =>
      _t(en: 'You', da: 'Dig', nb: 'Deg', sv: 'Du', fi: 'Sinä', isl: 'Þú');
  String get meSelfOwner => _t(
      en: 'You (owner)',
      da: 'Dig (ejer)',
      nb: 'Deg (eier)',
      sv: 'Du (ägare)',
      fi: 'Sinä (omistaja)',
      isl: 'Þú (eigandi)');
  String get roleOwner =>
      _t(en: 'Owner', da: 'Ejer', nb: 'Eier', sv: 'Ägare', fi: 'Omistaja', isl: 'Eigandi');
  String get roleCaregiver => _t(
      en: 'Caregiver',
      da: 'Omsorgsperson',
      nb: 'Omsorgsperson',
      sv: 'Vårdgivare',
      fi: 'Hoitaja',
      isl: 'Umönnunaraðili');
  String get leaveHouseholdTitle => _t(
      en: 'Leave household?',
      da: 'Forlad husstand?',
      nb: 'Forlate husstanden?',
      sv: 'Lämna hushållet?',
      fi: 'Poistutaanko taloudesta?',
      isl: 'Yfirgefa heimili?');
  String get removeCaregiverTitle => _t(
      en: 'Remove caregiver?',
      da: 'Fjern omsorgsperson?',
      nb: 'Fjerne omsorgsperson?',
      sv: 'Ta bort vårdgivare?',
      fi: 'Poistetaanko hoitaja?',
      isl: 'Fjarlægja umönnunaraðila?');
  String get leaveHouseholdMsg => _t(
      en: "You'll lose access to this baby's shared data on this device.",
      da: 'Du mister adgang til denne babys delte data på denne enhed.',
      nb: 'Du mister tilgang til denne babyens delte data på denne enheten.',
      sv: 'Du förlorar åtkomst till den här bebisens delade data på den här enheten.',
      fi: 'Menetät pääsyn tämän vauvan jaettuihin tietoihin tällä laitteella.',
      isl: 'Þú missir aðgang að sameiginlegum gögnum þessa barns í þessu tæki.');
  String get removeCaregiverMsg => _t(
      en: "They will immediately lose access to this baby's data.",
      da: 'De mister øjeblikkeligt adgang til denne babys data.',
      nb: 'De mister umiddelbart tilgang til denne babyens data.',
      sv: 'De förlorar omedelbart åtkomst till den här bebisens data.',
      fi: 'He menettävät heti pääsyn tämän vauvan tietoihin.',
      isl: 'Þeir missa strax aðgang að gögnum þessa barns.');
  String get leave =>
      _t(en: 'Leave', da: 'Forlad', nb: 'Forlat', sv: 'Lämna', fi: 'Poistu', isl: 'Yfirgefa');
  String get remove =>
      _t(en: 'Remove', da: 'Fjern', nb: 'Fjern', sv: 'Ta bort', fi: 'Poista', isl: 'Fjarlægja');
  String get ok => 'OK';
  String get codeCopied => _t(
      en: 'Code copied',
      da: 'Kode kopieret',
      nb: 'Kode kopiert',
      sv: 'Kod kopierad',
      fi: 'Koodi kopioitu',
      isl: 'Kóði afritaður');
  String get errCreateInvite => _t(
      en: 'Could not create an invite. Check your connection.',
      da: 'Kunne ikke oprette en invitation. Tjek din forbindelse.',
      nb: 'Kunne ikke opprette en invitasjon. Sjekk tilkoblingen din.',
      sv: 'Kunde inte skapa en inbjudan. Kontrollera din anslutning.',
      fi: 'Kutsun luominen epäonnistui. Tarkista yhteytesi.',
      isl: 'Tókst ekki að búa til boð. Athugaðu tenginguna.');
  String get errJoin => _t(
      en: 'Could not join. Check your connection and the code.',
      da: 'Kunne ikke deltage. Tjek din forbindelse og koden.',
      nb: 'Kunne ikke bli med. Sjekk tilkoblingen og koden.',
      sv: 'Kunde inte gå med. Kontrollera din anslutning och koden.',
      fi: 'Liittyminen epäonnistui. Tarkista yhteys ja koodi.',
      isl: 'Tókst ekki að taka þátt. Athugaðu tenginguna og kóðann.');
  String get errUpdate => _t(
      en: 'Could not update. Check your connection.',
      da: 'Kunne ikke opdatere. Tjek din forbindelse.',
      nb: 'Kunne ikke oppdatere. Sjekk tilkoblingen din.',
      sv: 'Kunde inte uppdatera. Kontrollera din anslutning.',
      fi: 'Päivitys epäonnistui. Tarkista yhteytesi.',
      isl: 'Tókst ekki að uppfæra. Athugaðu tenginguna.');
  String get errSave => _t(
      en: "Couldn't save. Check your connection and try again.",
      da: 'Kunne ikke gemme. Tjek din forbindelse og prøv igen.',
      nb: 'Kunne ikke lagre. Sjekk tilkoblingen og prøv igjen.',
      sv: 'Kunde inte spara. Kontrollera din anslutning och försök igen.',
      fi: 'Tallennus epäonnistui. Tarkista yhteytesi ja yritä uudelleen.',
      isl: 'Tókst ekki að vista. Athugaðu tenginguna og reyndu aftur.');
  String get errLoadCaregivers => _t(
      en: "Couldn't load caregivers. Check your connection.",
      da: 'Kunne ikke indlæse omsorgspersoner. Tjek din forbindelse.',
      nb: 'Kunne ikke laste omsorgspersoner. Sjekk tilkoblingen din.',
      sv: 'Kunde inte ladda vårdgivare. Kontrollera din anslutning.',
      fi: 'Hoitajien lataaminen epäonnistui. Tarkista yhteytesi.',
      isl: 'Tókst ekki að hlaða umönnunaraðilum. Athugaðu tenginguna.');
  String get errInviteNotFound => _t(
      en: 'This invite code does not exist.',
      da: 'Denne invitationskode findes ikke.',
      nb: 'Denne invitasjonskoden finnes ikke.',
      sv: 'Den här inbjudningskoden finns inte.',
      fi: 'Tätä kutsukoodia ei ole olemassa.',
      isl: 'Þessi boðskóði er ekki til.');
  String get errInviteExpired => _t(
      en: 'This invite has expired.',
      da: 'Denne invitation er udløbet.',
      nb: 'Denne invitasjonen er utløpt.',
      sv: 'Den här inbjudan har upphört.',
      fi: 'Tämä kutsu on vanhentunut.',
      isl: 'Þetta boð er útrunnið.');
  String get shareInviteSubject => _t(
      en: 'NomNap invite',
      da: 'NomNap-invitation',
      nb: 'NomNap-invitasjon',
      sv: 'NomNap-inbjudan',
      fi: 'NomNap-kutsu',
      isl: 'NomNap-boð');
  String shareInviteText(String code) => _t(
      en: 'Join me on NomNap to track our baby together.\n\nOpen NomNap → Caregivers → enter this code:\n$code',
      da: 'Følg vores baby sammen med mig på NomNap.\n\nÅbn NomNap → Omsorgspersoner → indtast denne kode:\n$code',
      nb: 'Følg babyen vår sammen med meg på NomNap.\n\nÅpne NomNap → Omsorgspersoner → skriv inn denne koden:\n$code',
      sv: 'Följ vår bebis tillsammans med mig på NomNap.\n\nÖppna NomNap → Vårdgivare → ange den här koden:\n$code',
      fi: 'Seuraa vauvaamme kanssani NomNapissa.\n\nAvaa NomNap → Hoitajat → syötä tämä koodi:\n$code',
      isl: 'Fylgstu með barninu okkar með mér á NomNap.\n\nOpnaðu NomNap → Umönnunaraðilar → sláðu inn þennan kóða:\n$code');

  /// Maps an [InviteException.code] to a localized message.
  String inviteError(String code) {
    switch (code) {
      case 'not_found':
        return errInviteNotFound;
      case 'expired':
        return errInviteExpired;
    }
    return errJoin;
  }

  // Format helpers
  String get justNow => _t(
      en: 'just now', da: 'lige nu', nb: 'akkurat nå', sv: 'just nu', fi: 'juuri nyt', isl: 'rétt í þessu');

  String relativeTimeAgo(DateTime when) {
    final diff = DateTime.now().difference(when);
    if (diff.inSeconds < 60) return justNow;
    if (diff.inMinutes < 60) {
      final n = diff.inMinutes;
      return _t(
          en: '${n}m ago',
          da: '${n}m siden',
          nb: '${n}m siden',
          sv: '${n}m sedan',
          fi: '$n min sitten',
          isl: 'fyrir $n mín');
    }
    if (diff.inHours < 24) {
      final h = diff.inHours;
      final m = diff.inMinutes.remainder(60);
      if (m == 0) {
        return _t(
            en: '${h}h ago',
            da: '${h}t siden',
            nb: '${h}t siden',
            sv: '${h}h sedan',
            fi: '$h h sitten',
            isl: 'fyrir $h klst');
      }
      return _t(
          en: '${h}h ${m}m ago',
          da: '${h}t ${m}m siden',
          nb: '${h}t ${m}m siden',
          sv: '${h}h ${m}m sedan',
          fi: '$h h $m min sitten',
          isl: 'fyrir $h klst $m mín');
    }
    if (diff.inDays < 7) {
      final n = diff.inDays;
      return _t(
          en: '${n}d ago',
          da: '${n}d siden',
          nb: '${n}d siden',
          sv: '${n}d sedan',
          fi: '$n pv sitten',
          isl: 'fyrir $n d');
    }
    return DateFormat.MMMd(localeCode).format(when);
  }

  /// [d] is a day key (see `dayKeyFor`). [dayStartHour] must match the boundary
  /// used to build the keys so "today"/"yesterday" line up with the logical day.
  String formatDayHeader(DateTime d, {int dayStartHour = 0}) {
    final now = DateTime.now().subtract(Duration(hours: dayStartHour));
    final t = DateTime(now.year, now.month, now.day);
    final dd = DateTime(d.year, d.month, d.day);
    final diff = t.difference(dd).inDays;
    if (diff == 0) return today;
    if (diff == 1) return yesterday;
    return DateFormat('EEEE, MMM d', localeCode).format(d);
  }

  String formatDateShort(DateTime d) => DateFormat('EEE, MMM d', localeCode).format(d);

  String formatStamp(DateTime t) {
    final now = DateTime.now();
    final todayDate = DateTime(now.year, now.month, now.day);
    final dd = DateTime(t.year, t.month, t.day);
    final diff = todayDate.difference(dd).inDays;
    String prefix;
    if (diff == 0) {
      prefix = today;
    } else if (diff == 1) {
      prefix = yesterday;
    } else {
      prefix = DateFormat('EEE, MMM d', localeCode).format(t);
    }
    return '$prefix  ${DateFormat('HH:mm').format(t)}';
  }

  // ─── Onboarding & baby profile ──────────────────────────────────────────

  String get onboardingSkip => _t(
      en: 'Skip', da: 'Spring over', nb: 'Hopp over', sv: 'Hoppa över', fi: 'Ohita', isl: 'Sleppa');
  String get onboardingContinue => _t(
      en: 'Continue', da: 'Fortsæt', nb: 'Fortsett', sv: 'Fortsätt', fi: 'Jatka', isl: 'Halda áfram');

  String get onboardingWelcomeTitle => _t(
      en: 'Welcome, little one 💜',
      da: 'Velkommen, lille skat 💜',
      nb: 'Velkommen, lille venn 💜',
      sv: 'Välkommen, lilla vän 💜',
      fi: 'Tervetuloa, pikkuinen 💜',
      isl: 'Velkomin, litla krútt 💜');
  String get onboardingWelcomeBody => _t(
      en: 'Naps 😴 feeds 🍼 and all the little moments — in one cozy place ✨',
      da: 'Lure 😴 måltider 🍼 og alle de små øjeblikke — samlet ét hyggeligt sted ✨',
      nb: 'Lurer 😴 måltider 🍼 og alle de små øyeblikkene — samlet på ett koselig sted ✨',
      sv: 'Tupplurar 😴 mat 🍼 och alla små ögonblick — samlade på ett mysigt ställe ✨',
      fi: 'Unet 😴 syötöt 🍼 ja kaikki pienet hetket — yhdessä kodikkaassa paikassa ✨',
      isl: 'Blundar 😴 gjafir 🍼 og öll litlu augnablikin — á einum notalegum stað ✨');

  String get onboardingNameTitle => _t(
      en: 'What’s your baby’s name?',
      da: 'Hvad hedder din baby?',
      nb: 'Hva heter babyen din?',
      sv: 'Vad heter din bebis?',
      fi: 'Mikä on vauvasi nimi?',
      isl: 'Hvað heitir barnið þitt?');
  String get onboardingNamePlaceholder => _t(
      en: 'Baby’s name',
      da: 'Babyens navn',
      nb: 'Babyens navn',
      sv: 'Bebisens namn',
      fi: 'Vauvan nimi',
      isl: 'Nafn barnsins');

  String get onboardingBirthTitle => _t(
      en: 'When was your baby born?',
      da: 'Hvornår blev din baby født?',
      nb: 'Når ble babyen din født?',
      sv: 'När föddes din bebis?',
      fi: 'Milloin vauvasi syntyi?',
      isl: 'Hvenær fæddist barnið þitt?');
  String onboardingBirthTitleNamed(String name) => _t(
      en: 'When was $name born?',
      da: 'Hvornår blev $name født?',
      nb: 'Når ble $name født?',
      sv: 'När föddes $name?',
      fi: 'Milloin $name syntyi?',
      isl: 'Hvenær fæddist $name?');

  String get onboardingSexTitle => _t(
      en: 'Boy or girl?',
      da: 'Dreng eller pige?',
      nb: 'Gutt eller jente?',
      sv: 'Pojke eller flicka?',
      fi: 'Poika vai tyttö?',
      isl: 'Strákur eða stelpa?');
  String get sexBoy => _t(
      en: 'Boy', da: 'Dreng', nb: 'Gutt', sv: 'Pojke', fi: 'Poika', isl: 'Strákur');
  String get sexGirl => _t(
      en: 'Girl', da: 'Pige', nb: 'Jente', sv: 'Flicka', fi: 'Tyttö', isl: 'Stelpa');

  String get onboardingFeedingTitle => _t(
      en: 'How do you feed?',
      da: 'Hvordan fodrer du?',
      nb: 'Hvordan mater du?',
      sv: 'Hur matar du?',
      fi: 'Miten ruokit?',
      isl: 'Hvernig nærirðu?');
  String get onboardingFeedingBody => _t(
      en: 'We’ll show the right feed trackers. You can change this anytime.',
      da: 'Vi viser de rette mad-trackere. Du kan ændre det når som helst.',
      nb: 'Vi viser de riktige mat-sporerne. Du kan endre det når som helst.',
      sv: 'Vi visar rätt matspårare. Du kan ändra det när som helst.',
      fi: 'Näytämme oikeat ruokailun seurannat. Voit muuttaa tätä milloin tahansa.',
      isl: 'Við sýnum réttu næringar-mælana. Þú getur breytt þessu hvenær sem er.');
  String get feedingBreast => _t(
      en: 'Breast', da: 'Bryst', nb: 'Bryst', sv: 'Bröst', fi: 'Rinta', isl: 'Brjóst');
  String get feedingBottle => _t(
      en: 'Bottle', da: 'Flaske', nb: 'Flaske', sv: 'Flaska', fi: 'Pullo', isl: 'Pela');
  String get feedingMixed => _t(
      en: 'Mixed', da: 'Blandet', nb: 'Blandet', sv: 'Blandat', fi: 'Sekä että', isl: 'Blandað');

  String get onboardingTrackTitle => _t(
      en: 'What do you want to track?',
      da: 'Hvad vil du spore?',
      nb: 'Hva vil du spore?',
      sv: 'Vad vill du spåra?',
      fi: 'Mitä haluat seurata?',
      isl: 'Hvað viltu skrá?');
  String get onboardingTrackBody => _t(
      en: 'Pick what shows on your home screen — you can change it anytime.',
      da: 'Vælg hvad der vises på din startskærm — du kan ændre det når som helst.',
      nb: 'Velg hva som vises på startskjermen — du kan endre det når som helst.',
      sv: 'Välj vad som visas på startskärmen — du kan ändra det när som helst.',
      fi: 'Valitse mitä aloitusnäytöllä näkyy — voit muuttaa sitä milloin tahansa.',
      isl: 'Veldu hvað birtist á heimaskjánum — þú getur breytt því hvenær sem er.');

  String get onboardingMeasureTitle => _t(
      en: 'Birth measurements',
      da: 'Mål ved fødslen',
      nb: 'Mål ved fødsel',
      sv: 'Mått vid födseln',
      fi: 'Syntymämitat',
      isl: 'Mælingar við fæðingu');
  String get onboardingMeasureBody => _t(
      en: 'Optional — a great first point for growth charts.',
      da: 'Valgfrit — et godt første punkt til vækstkurver.',
      nb: 'Valgfritt — et fint første punkt for vekstkurver.',
      sv: 'Valfritt — en bra första punkt för tillväxtkurvor.',
      fi: 'Valinnainen — hyvä ensimmäinen piste kasvukäyrille.',
      isl: 'Valfrjálst — góður fyrsti punktur fyrir vaxtarkúrfur.');
  String get measureWeight => _t(
      en: 'Weight', da: 'Vægt', nb: 'Vekt', sv: 'Vikt', fi: 'Paino', isl: 'Þyngd');
  String get measureLength => _t(
      en: 'Length', da: 'Længde', nb: 'Lengde', sv: 'Längd', fi: 'Pituus', isl: 'Lengd');
  String get measureHead => _t(
      en: 'Head', da: 'Hoved', nb: 'Hode', sv: 'Huvud', fi: 'Pää', isl: 'Höfuð');

  String get onboardingDoneTitle => _t(
      en: 'You’re all set!',
      da: 'Så er du klar!',
      nb: 'Alt er klart!',
      sv: 'Allt är klart!',
      fi: 'Kaikki valmista!',
      isl: 'Allt tilbúið!');
  String get onboardingDoneBody => _t(
      en: 'Everything’s ready — let’s start tracking.',
      da: 'Alt er klar — lad os begynde at spore.',
      nb: 'Alt er klart — la oss begynne å spore.',
      sv: 'Allt är klart — nu börjar vi spåra.',
      fi: 'Kaikki valmista — aloitetaan seuranta.',
      isl: 'Allt tilbúið — byrjum að skrá.');
  String get onboardingStart => _t(
      en: 'Start tracking',
      da: 'Begynd at spore',
      nb: 'Begynn å spore',
      sv: 'Börja spåra',
      fi: 'Aloita seuranta',
      isl: 'Byrja að skrá');

  // Profile — baby section
  String get profileBaby => _t(
      en: 'Baby', da: 'Baby', nb: 'Baby', sv: 'Bebis', fi: 'Vauva', isl: 'Barn');
  String get profileFinishSetup => _t(
      en: 'Finish setting up',
      da: 'Færdiggør opsætning',
      nb: 'Fullfør oppsett',
      sv: 'Slutför inställningen',
      fi: 'Viimeistele määritys',
      isl: 'Ljúka uppsetningu');
  String get profileFinishSetupSub => _t(
      en: 'Add your baby’s details',
      da: 'Tilføj din babys oplysninger',
      nb: 'Legg til babyens detaljer',
      sv: 'Lägg till din bebis uppgifter',
      fi: 'Lisää vauvan tiedot',
      isl: 'Bættu við upplýsingum barnsins');
  String get profileBabyDetails => _t(
      en: 'Baby profile',
      da: 'Babyprofil',
      nb: 'Babyprofil',
      sv: 'Bebisprofil',
      fi: 'Vauvan profiili',
      isl: 'Barnaprófíll');
  String get profileAddDetails => _t(
      en: 'Add details',
      da: 'Tilføj oplysninger',
      nb: 'Legg til detaljer',
      sv: 'Lägg till uppgifter',
      fi: 'Lisää tiedot',
      isl: 'Bæta við upplýsingum');

  // Age — a compact "how old" label derived from the birth date.
  String get ageNewborn => _t(
      en: 'Newborn', da: 'Nyfødt', nb: 'Nyfødt', sv: 'Nyfödd', fi: 'Vastasyntynyt', isl: 'Nýfætt');
  String _ageDays(int n) => _t(
      en: '$n ${n == 1 ? 'day' : 'days'}',
      da: '$n ${n == 1 ? 'dag' : 'dage'}',
      nb: '$n ${n == 1 ? 'dag' : 'dager'}',
      sv: '$n ${n == 1 ? 'dag' : 'dagar'}',
      fi: '$n ${n == 1 ? 'päivä' : 'päivää'}',
      isl: '$n ${n == 1 ? 'dagur' : 'dagar'}');
  String _ageWeeks(int n) => _t(
      en: '$n ${n == 1 ? 'week' : 'weeks'}',
      da: '$n ${n == 1 ? 'uge' : 'uger'}',
      nb: '$n ${n == 1 ? 'uke' : 'uker'}',
      sv: '$n ${n == 1 ? 'vecka' : 'veckor'}',
      fi: '$n ${n == 1 ? 'viikko' : 'viikkoa'}',
      isl: '$n ${n == 1 ? 'vika' : 'vikur'}');
  String _ageMonths(int n) => _t(
      en: '$n ${n == 1 ? 'month' : 'months'}',
      da: '$n ${n == 1 ? 'måned' : 'måneder'}',
      nb: '$n ${n == 1 ? 'måned' : 'måneder'}',
      sv: '$n ${n == 1 ? 'månad' : 'månader'}',
      fi: '$n ${n == 1 ? 'kuukausi' : 'kuukautta'}',
      isl: '$n ${n == 1 ? 'mánuður' : 'mánuðir'}');
  String _ageYears(int n) => _t(
      en: '$n ${n == 1 ? 'year' : 'years'}',
      da: '$n år',
      nb: '$n år',
      sv: '$n år',
      fi: '$n ${n == 1 ? 'vuosi' : 'vuotta'}',
      isl: '$n ár');

  /// A short, friendly age label ("Newborn", "5 days", "3 weeks", "4 months",
  /// "2 years"). Returns an empty string for a future date.
  String formatAge(DateTime birth) {
    final now = DateTime.now();
    final birthDay = DateTime(birth.year, birth.month, birth.day);
    final today = DateTime(now.year, now.month, now.day);
    final days = today.difference(birthDay).inDays;
    if (days < 0) return '';
    if (days == 0) return ageNewborn;
    if (days < 14) return _ageDays(days);
    if (days < 70) return _ageWeeks(days ~/ 7);
    var months = (now.year - birth.year) * 12 + (now.month - birth.month);
    if (now.day < birth.day) months -= 1;
    if (months < 24) return _ageMonths(months);
    return _ageYears(months ~/ 12);
  }
}

class _SDelegate extends LocalizationsDelegate<S> {
  const _SDelegate();

  @override
  bool isSupported(Locale locale) => S.languageCodes.contains(locale.languageCode);

  @override
  Future<S> load(Locale locale) => SynchronousFuture(S._(locale.languageCode));

  @override
  bool shouldReload(_SDelegate old) => false;
}
