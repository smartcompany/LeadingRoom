import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ko.dart';

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
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ko'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In ko, this message translates to:
  /// **'리딩방'**
  String get appTitle;

  /// No description provided for @tabSignals.
  ///
  /// In ko, this message translates to:
  /// **'시그널'**
  String get tabSignals;

  /// No description provided for @tabMarkets.
  ///
  /// In ko, this message translates to:
  /// **'종목'**
  String get tabMarkets;

  /// No description provided for @tabPerformance.
  ///
  /// In ko, this message translates to:
  /// **'성과'**
  String get tabPerformance;

  /// No description provided for @marketUs.
  ///
  /// In ko, this message translates to:
  /// **'미국'**
  String get marketUs;

  /// No description provided for @marketKr.
  ///
  /// In ko, this message translates to:
  /// **'한국'**
  String get marketKr;

  /// No description provided for @marketCrypto.
  ///
  /// In ko, this message translates to:
  /// **'암호화폐'**
  String get marketCrypto;

  /// No description provided for @buy.
  ///
  /// In ko, this message translates to:
  /// **'매수'**
  String get buy;

  /// No description provided for @sell.
  ///
  /// In ko, this message translates to:
  /// **'매도'**
  String get sell;

  /// No description provided for @free.
  ///
  /// In ko, this message translates to:
  /// **'무료'**
  String get free;

  /// No description provided for @pro.
  ///
  /// In ko, this message translates to:
  /// **'프로'**
  String get pro;

  /// No description provided for @proLocked.
  ///
  /// In ko, this message translates to:
  /// **'프로 구독 필요'**
  String get proLocked;

  /// No description provided for @loginTitle.
  ///
  /// In ko, this message translates to:
  /// **'로그인'**
  String get loginTitle;

  /// No description provided for @email.
  ///
  /// In ko, this message translates to:
  /// **'이메일'**
  String get email;

  /// No description provided for @password.
  ///
  /// In ko, this message translates to:
  /// **'비밀번호'**
  String get password;

  /// No description provided for @signIn.
  ///
  /// In ko, this message translates to:
  /// **'로그인'**
  String get signIn;

  /// No description provided for @signUp.
  ///
  /// In ko, this message translates to:
  /// **'회원가입'**
  String get signUp;

  /// No description provided for @signOut.
  ///
  /// In ko, this message translates to:
  /// **'로그아웃'**
  String get signOut;

  /// No description provided for @loading.
  ///
  /// In ko, this message translates to:
  /// **'불러오는 중…'**
  String get loading;

  /// No description provided for @emptySignals.
  ///
  /// In ko, this message translates to:
  /// **'아직 시그널이 없습니다'**
  String get emptySignals;

  /// No description provided for @emptySymbols.
  ///
  /// In ko, this message translates to:
  /// **'종목이 없습니다'**
  String get emptySymbols;

  /// No description provided for @winRate.
  ///
  /// In ko, this message translates to:
  /// **'승률'**
  String get winRate;

  /// No description provided for @avgPnl.
  ///
  /// In ko, this message translates to:
  /// **'평균 수익'**
  String get avgPnl;

  /// No description provided for @closedTrades.
  ///
  /// In ko, this message translates to:
  /// **'청산 건수'**
  String get closedTrades;

  /// No description provided for @chartTitle.
  ///
  /// In ko, this message translates to:
  /// **'차트'**
  String get chartTitle;

  /// No description provided for @rationale.
  ///
  /// In ko, this message translates to:
  /// **'근거'**
  String get rationale;

  /// No description provided for @disclaimer.
  ///
  /// In ko, this message translates to:
  /// **'본 정보는 투자 자문이 아니며, 페이퍼 트레이딩 성과입니다.'**
  String get disclaimer;

  /// No description provided for @errorGeneric.
  ///
  /// In ko, this message translates to:
  /// **'오류가 발생했습니다'**
  String get errorGeneric;

  /// No description provided for @retry.
  ///
  /// In ko, this message translates to:
  /// **'다시 시도'**
  String get retry;

  /// No description provided for @stopHint.
  ///
  /// In ko, this message translates to:
  /// **'손절 힌트'**
  String get stopHint;

  /// No description provided for @noPerformance.
  ///
  /// In ko, this message translates to:
  /// **'청산된 페이퍼 트레이드가 없습니다'**
  String get noPerformance;

  /// No description provided for @guestContinue.
  ///
  /// In ko, this message translates to:
  /// **'둘러보기'**
  String get guestContinue;

  /// No description provided for @chartInterval.
  ///
  /// In ko, this message translates to:
  /// **'차트 기준'**
  String get chartInterval;

  /// No description provided for @interval1h.
  ///
  /// In ko, this message translates to:
  /// **'1시간'**
  String get interval1h;

  /// No description provided for @interval4h.
  ///
  /// In ko, this message translates to:
  /// **'4시간'**
  String get interval4h;

  /// No description provided for @interval1d.
  ///
  /// In ko, this message translates to:
  /// **'일'**
  String get interval1d;

  /// No description provided for @interval1w.
  ///
  /// In ko, this message translates to:
  /// **'주'**
  String get interval1w;

  /// No description provided for @interval1mo.
  ///
  /// In ko, this message translates to:
  /// **'월'**
  String get interval1mo;

  /// No description provided for @interval1y.
  ///
  /// In ko, this message translates to:
  /// **'년'**
  String get interval1y;
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
      <String>['en', 'ko'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ko':
      return AppLocalizationsKo();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
