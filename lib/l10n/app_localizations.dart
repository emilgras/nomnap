import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

class S {
  final bool _da;
  S._(this._da);

  static S of(BuildContext context) => Localizations.of<S>(context, S)!;

  static const delegate = _SDelegate();
  static const supportedLocales = [Locale('en'), Locale('da')];

  String get localeCode => _da ? 'da' : 'en';

  // Navigation
  String get navTrack => _da ? 'Spor' : 'Track';
  String get navStats => _da ? 'Statistik' : 'Stats';
  String get navHistory => _da ? 'Historik' : 'History';

  // Greetings
  String greetingForHour(int h) {
    if (h < 5) return _da ? 'Godnat' : 'Good night';
    if (h < 12) return _da ? 'Godmorgen' : 'Good morning';
    if (h < 18) return _da ? 'God eftermiddag' : 'Good afternoon';
    return _da ? 'God aften' : 'Good evening';
  }

  // Sleep
  String get sleep => _da ? 'Søvn' : 'Sleep';
  String get sleeping => _da ? 'Sover' : 'Sleeping';
  String get awake => _da ? 'Vågen' : 'Awake';
  String get startSleep => _da ? 'Start søvn' : 'Start Sleep';
  String get wakeUp => _da ? 'Vågn op' : 'Wake Up';
  String get slept => _da ? 'Sov' : 'Slept';

  // Feed
  String get feed => _da ? 'Amning' : 'Feed';
  String get feeding => _da ? 'Ammer' : 'Feeding';
  String get notFeeding => _da ? 'Ammer ikke' : 'Not feeding';
  String get stopFeed => _da ? 'Stop amning' : 'Stop Feed';
  String get fed => _da ? 'Ammede' : 'Fed';
  String get left => _da ? 'Venstre' : 'Left';
  String get right => _da ? 'Højre' : 'Right';

  // Diaper
  String get diaper => _da ? 'Ble' : 'Diaper';
  String get logAChange => _da ? 'Log et bleskift' : 'Log a change';
  String get pee => _da ? 'Tis' : 'Pee';
  String get poop => _da ? 'Bæ' : 'Poop';

  // Today summary
  String get today => _da ? 'I dag' : 'Today';
  String get yesterday => _da ? 'I går' : 'Yesterday';
  String get recentActivity => _da ? 'Seneste aktivitet' : 'Recent activity';
  String get emptyTracker =>
      _da ? 'Tryk på en knap for at begynde.' : 'Tap a button above to start tracking.';
  String sleepPlural(int n) => n == 1 ? sleep : (_da ? 'Søvn' : 'Sleeps');
  String feedPlural(int n) => n == 1 ? feed : (_da ? 'Amninger' : 'Feeds');
  String diaperPlural(int n) => n == 1 ? diaper : (_da ? 'Bleer' : 'Diapers');

  // Shared
  String since(String time) => _da ? 'Siden $time' : 'Since $time';
  String sideLabel(String? code) {
    if (code == 'L') return left;
    if (code == 'R') return right;
    return '';
  }

  // Stats
  String get stats => _da ? 'Statistik' : 'Stats';
  String get noDataYet => _da
      ? 'Ingen data endnu.\nBegynd at spore for at se gennemsnit.'
      : 'No data yet.\nStart tracking to see your averages.';
  String get dailyAverages => _da ? 'Daglige gennemsnit' : 'Daily averages';
  String get sessionAverages => _da ? 'Sessionsgennemsnit' : 'Session averages';
  String get avgSleepLength => _da ? 'Gns. søvnlængde' : 'Avg sleep length';
  String get avgFeedLength => _da ? 'Gns. amningslængde' : 'Avg feed length';
  String get longestSleep => _da ? 'Længste søvn' : 'Longest sleep';
  String get sleepPerDay => _da ? 'Søvn / dag' : 'Sleep / day';
  String get feedingPerDay => _da ? 'Amning / dag' : 'Feeding / day';
  String get sessions => _da ? 'sessioner' : 'sessions';
  String get byDay => _da ? 'Per dag' : 'By day';
  String diapersPerDay(String n) => _da ? '$n bleer / dag' : '$n diapers / day';

  // History
  String get history => _da ? 'Historik' : 'History';
  String get emptyHistory =>
      _da ? 'Dine sessioner vises her.' : 'Your tracked sessions will appear here.';
  String get clearAllTitle => _da ? 'Slet alle data?' : 'Clear all data?';
  String get clearAllMessage => _da
      ? 'Dette sletter permanent alle data. Det kan ikke fortrydes.'
      : 'This will permanently delete all tracked data. This cannot be undone.';
  String get deleteAll => _da ? 'Slet alt' : 'Delete all';
  String get cancel => _da ? 'Annuller' : 'Cancel';
  String get delete => _da ? 'Slet' : 'Delete';
  String get deleteThisSession => _da ? 'Slet denne session?' : 'Delete this session?';
  String get deleteThisDiaper => _da ? 'Slet dette bleskift?' : 'Delete this diaper entry?';
  String get editTime => _da ? 'Rediger tid' : 'Edit time';
  String get editStart => _da ? 'Rediger start' : 'Edit start';
  String get editEnd => _da ? 'Rediger slut' : 'Edit end';
  String get editStartTime => _da ? 'Rediger starttid' : 'Edit start time';
  String get editEndTime => _da ? 'Rediger sluttid' : 'Edit end time';
  String get endNow => _da ? 'Afslut nu' : 'End now';
  String get deleteSession => _da ? 'Slet session' : 'Delete session';
  String get switchToRight => _da ? 'Skift til højre' : 'Switch to Right';
  String get switchToLeft => _da ? 'Skift til venstre' : 'Switch to Left';
  String get save => _da ? 'Gem' : 'Save';

  // Add entry
  String get addEntry => _da ? 'Tilføj' : 'Add entry';
  String get started => _da ? 'Startet' : 'Started';
  String get ended => _da ? 'Sluttet' : 'Ended';
  String get time => _da ? 'Tid' : 'Time';
  String get stillInProgress => _da ? 'Stadig i gang' : 'Still in progress';
  String get startTime => _da ? 'Starttid' : 'Start time';
  String get endTime => _da ? 'Sluttid' : 'End time';
  String get done => _da ? 'Færdig' : 'Done';
  String get inProgress => _da ? 'I gang' : 'In progress';
  String durationLabel(String d) => _da ? 'Varighed  $d' : 'Duration  $d';
  String get errorTimeFuture =>
      _da ? 'Tidspunktet kan ikke være i fremtiden.' : "Time can't be in the future.";
  String get errorStartFuture =>
      _da ? 'Start kan ikke være i fremtiden.' : "Start can't be in the future.";
  String get errorEndAfterStart =>
      _da ? 'Slut skal være efter start.' : 'End must be after start.';
  String get sleepAlreadyInProgress =>
      _da ? 'En søvn er allerede i gang.' : 'A sleep is already in progress.';
  String get feedAlreadyInProgress =>
      _da ? 'En amning er allerede i gang.' : 'A feed is already in progress.';

  // Format helpers
  String get justNow => _da ? 'lige nu' : 'just now';

  String relativeTimeAgo(DateTime when) {
    final diff = DateTime.now().difference(when);
    if (diff.inSeconds < 60) return justNow;
    if (diff.inMinutes < 60) {
      final n = diff.inMinutes;
      return _da ? '${n}m siden' : '${n}m ago';
    }
    if (diff.inHours < 24) {
      final h = diff.inHours;
      final m = diff.inMinutes.remainder(60);
      if (m == 0) return _da ? '${h}t siden' : '${h}h ago';
      return _da ? '${h}t ${m}m siden' : '${h}h ${m}m ago';
    }
    if (diff.inDays < 7) {
      final n = diff.inDays;
      return _da ? '${n}d siden' : '${n}d ago';
    }
    return DateFormat.MMMd(localeCode).format(when);
  }

  String formatDayHeader(DateTime d) {
    final now = DateTime.now();
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
}

class _SDelegate extends LocalizationsDelegate<S> {
  const _SDelegate();

  @override
  bool isSupported(Locale locale) => ['en', 'da'].contains(locale.languageCode);

  @override
  Future<S> load(Locale locale) =>
      SynchronousFuture(S._(locale.languageCode == 'da'));

  @override
  bool shouldReload(_SDelegate old) => false;
}
