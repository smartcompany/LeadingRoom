import 'package:leading_room/models/models.dart';

/// 줌된 X(시간) 구간에 맞춰 Y축 min/max를 계산합니다. (업비트식 자동 맞춤)
class ChartVisibleYRange {
  const ChartVisibleYRange({
    required this.min,
    required this.max,
  });

  final double min;
  final double max;

  static ChartVisibleYRange? fromValues(
    Iterable<double> values, {
    double padFraction = 0.02,
  }) {
    var lo = double.infinity;
    var hi = double.negativeInfinity;
    var any = false;
    for (final v in values) {
      if (v.isNaN || v.isInfinite) continue;
      any = true;
      if (v < lo) lo = v;
      if (v > hi) hi = v;
    }
    if (!any) return null;
    if (hi <= lo) {
      final pad = lo.abs() < 1e-9 ? 1.0 : lo.abs() * 0.01;
      return ChartVisibleYRange(min: lo - pad, max: hi + pad);
    }
    final pad = (hi - lo) * padFraction;
    return ChartVisibleYRange(min: lo - pad, max: hi + pad);
  }

  static bool inWindow(DateTime t, DateTime from, DateTime to) {
    return !t.isBefore(from) && !t.isAfter(to);
  }

  static ChartVisibleYRange? fromCandles({
    required List<CandlePoint> candles,
    required DateTime from,
    required DateTime to,
    bool useCandleExtremes = true,
    double padFraction = 0.02,
  }) {
    final values = <double>[];
    for (final c in candles) {
      if (!inWindow(c.time, from, to)) continue;
      if (useCandleExtremes) {
        values.add(c.high);
        values.add(c.low);
      } else {
        values.add(c.close);
      }
    }
    return fromValues(values, padFraction: padFraction);
  }

  static DateTime? parseAxisDate(dynamic value) {
    if (value is DateTime) return value;
    if (value is num) {
      return DateTime.fromMillisecondsSinceEpoch(value.round());
    }
    return null;
  }
}
