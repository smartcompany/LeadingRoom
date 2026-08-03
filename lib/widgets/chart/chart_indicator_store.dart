import 'package:shared_preferences/shared_preferences.dart';

/// 시그널 지표 오버레이/패널 표시 여부 (앱 전역 기억).
class ChartIndicatorStore {
  ChartIndicatorStore._();
  static final ChartIndicatorStore shared = ChartIndicatorStore._();

  static const _ma20Key = 'lr_chart_ind_ma20';
  static const _ma50Key = 'lr_chart_ind_ma50';
  static const _ema9Key = 'lr_chart_ind_ema9';
  static const _ema12Key = 'lr_chart_ind_ema12';
  static const _ema26Key = 'lr_chart_ind_ema26';
  static const _rsiKey = 'lr_chart_ind_rsi';
  static const _macdKey = 'lr_chart_ind_macd';
  static const _volKey = 'lr_chart_ind_vol';
  // legacy keys (마이그레이션)
  static const _legacyMaKey = 'lr_chart_ind_ma';
  static const _legacyEmaKey = 'lr_chart_ind_ema';

  var showMa20 = true;
  var showMa50 = true;
  var showEma9 = false;
  var showEma12 = false;
  var showEma26 = false;
  var showRsi = false;
  var showMacd = false;
  var showVolume = false;
  var _loaded = false;

  bool get anyMa => showMa20 || showMa50;
  bool get anyEma => showEma9 || showEma12 || showEma26;

  Future<void> load() async {
    if (_loaded) return;
    final prefs = await SharedPreferences.getInstance();

    if (prefs.containsKey(_ma20Key) || prefs.containsKey(_ma50Key)) {
      showMa20 = prefs.getBool(_ma20Key) ?? false;
      showMa50 = prefs.getBool(_ma50Key) ?? false;
    } else {
      final legacy = prefs.getBool(_legacyMaKey) ?? true;
      showMa20 = legacy;
      showMa50 = legacy;
    }

    if (prefs.containsKey(_ema9Key) ||
        prefs.containsKey(_ema12Key) ||
        prefs.containsKey(_ema26Key)) {
      showEma9 = prefs.getBool(_ema9Key) ?? false;
      showEma12 = prefs.getBool(_ema12Key) ?? false;
      showEma26 = prefs.getBool(_ema26Key) ?? false;
    } else {
      final legacy = prefs.getBool(_legacyEmaKey) ?? false;
      showEma9 = legacy;
      showEma12 = legacy;
      showEma26 = legacy;
    }

    showRsi = prefs.getBool(_rsiKey) ?? false;
    showMacd = prefs.getBool(_macdKey) ?? false;
    showVolume = prefs.getBool(_volKey) ?? false;
    _loaded = true;
  }

  Future<void> setMa20(bool value) async {
    showMa20 = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_ma20Key, value);
  }

  Future<void> setMa50(bool value) async {
    showMa50 = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_ma50Key, value);
  }

  Future<void> setEma9(bool value) async {
    showEma9 = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_ema9Key, value);
  }

  Future<void> setEma12(bool value) async {
    showEma12 = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_ema12Key, value);
  }

  Future<void> setEma26(bool value) async {
    showEma26 = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_ema26Key, value);
  }

  Future<void> setRsi(bool value) async {
    showRsi = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_rsiKey, value);
  }

  Future<void> setMacd(bool value) async {
    showMacd = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_macdKey, value);
  }

  Future<void> setVolume(bool value) async {
    showVolume = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_volKey, value);
  }
}
