import 'package:shared_preferences/shared_preferences.dart';

enum ChartInterval {
  h1('1h'),
  h4('4h'),
  d1('1d'),
  w1('1w'),
  mo1('1mo'),
  y1('1y');

  const ChartInterval(this.apiValue);
  final String apiValue;

  bool get isHourly => this == ChartInterval.h1 || this == ChartInterval.h4;

  static ChartInterval fromApiValue(String value) {
    for (final item in ChartInterval.values) {
      if (item.apiValue == value) return item;
    }
    return ChartInterval.d1;
  }
}

/// 차트 기준(봉 간격) — 앱 전역으로 기억.
class ChartIntervalStore {
  ChartIntervalStore._();
  static final ChartIntervalStore shared = ChartIntervalStore._();

  static const _prefsKey = 'lr_chart_interval';

  ChartInterval _current = ChartInterval.d1;
  bool _loaded = false;

  ChartInterval get current => _current;

  Future<ChartInterval> load() async {
    if (_loaded) return _current;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw != null) {
      _current = ChartInterval.fromApiValue(raw);
    }
    _loaded = true;
    return _current;
  }

  Future<void> set(ChartInterval interval) async {
    _current = interval;
    _loaded = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, interval.apiValue);
  }
}
