import 'package:shared_preferences/shared_preferences.dart';

/// 시그널 지표 오버레이/패널 표시 여부 (앱 전역 기억).
class ChartIndicatorStore {
  ChartIndicatorStore._();
  static final ChartIndicatorStore shared = ChartIndicatorStore._();

  static const _maKey = 'lr_chart_ind_ma';
  static const _rsiKey = 'lr_chart_ind_rsi';
  static const _macdKey = 'lr_chart_ind_macd';
  static const _volKey = 'lr_chart_ind_vol';

  var showMa = true;
  var showRsi = false;
  var showMacd = false;
  var showVolume = false;
  var _loaded = false;

  Future<void> load() async {
    if (_loaded) return;
    final prefs = await SharedPreferences.getInstance();
    showMa = prefs.getBool(_maKey) ?? true;
    showRsi = prefs.getBool(_rsiKey) ?? false;
    showMacd = prefs.getBool(_macdKey) ?? false;
    showVolume = prefs.getBool(_volKey) ?? false;
    _loaded = true;
  }

  Future<void> setMa(bool value) async {
    showMa = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_maKey, value);
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
