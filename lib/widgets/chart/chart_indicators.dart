import 'package:leading_room/models/models.dart';

class TimedValue {
  TimedValue({required this.time, required this.value});

  final DateTime time;
  final double? value;
}

class MacdPoint {
  MacdPoint({
    required this.time,
    required this.macd,
    required this.signal,
    required this.hist,
  });

  final DateTime time;
  final double? macd;
  final double? signal;
  final double? hist;
}

/// 서버 `technical.ts`와 동일한 규칙으로 차트용 지표 시계열 생성.
class ChartIndicators {
  ChartIndicators._(this.ma20, this.ma50, this.rsi, this.macd, this.volume);

  final List<TimedValue> ma20;
  final List<TimedValue> ma50;
  final List<TimedValue> rsi;
  final List<MacdPoint> macd;
  final List<TimedValue> volume;

  factory ChartIndicators.fromCandles(List<CandlePoint> candles) {
    final closes = candles.map((c) => c.close).toList();
    final volumes = candles.map((c) => c.volume).toList();
    final ma20Raw = _smaSeries(closes, 20);
    final ma50Raw = _smaSeries(closes, 50);
    final rsiRaw = _rsiSeries(closes, 14);
    final macdRaw = _macdSeries(closes);

    return ChartIndicators._(
      [
        for (var i = 0; i < candles.length; i++)
          TimedValue(time: candles[i].time, value: ma20Raw[i]),
      ],
      [
        for (var i = 0; i < candles.length; i++)
          TimedValue(time: candles[i].time, value: ma50Raw[i]),
      ],
      [
        for (var i = 0; i < candles.length; i++)
          TimedValue(time: candles[i].time, value: rsiRaw[i]),
      ],
      [
        for (var i = 0; i < candles.length; i++)
          MacdPoint(
            time: candles[i].time,
            macd: macdRaw[i].macd,
            signal: macdRaw[i].signal,
            hist: macdRaw[i].hist,
          ),
      ],
      [
        for (var i = 0; i < candles.length; i++)
          TimedValue(time: candles[i].time, value: volumes[i]),
      ],
    );
  }

  static List<double?> _smaSeries(List<double> values, int period) {
    return List<double?>.generate(values.length, (i) {
      if (i + 1 < period) return null;
      var sum = 0.0;
      for (var j = i - period + 1; j <= i; j++) {
        sum += values[j];
      }
      return sum / period;
    });
  }

  static List<double?> _emaSeries(List<double> values, int period) {
    final out = List<double?>.filled(values.length, null);
    if (values.length < period) return out;
    final k = 2 / (period + 1);
    var prev = values.take(period).reduce((a, b) => a + b) / period;
    out[period - 1] = prev;
    for (var i = period; i < values.length; i++) {
      prev = values[i] * k + prev * (1 - k);
      out[i] = prev;
    }
    return out;
  }

  /// 서버와 동일: 최근 period 구간의 단순 RSI.
  static List<double?> _rsiSeries(List<double> closes, int period) {
    return List<double?>.generate(closes.length, (i) {
      if (i < period) return null;
      var gains = 0.0;
      var losses = 0.0;
      for (var j = i - period + 1; j <= i; j++) {
        final diff = closes[j] - closes[j - 1];
        if (diff >= 0) {
          gains += diff;
        } else {
          losses -= diff;
        }
      }
      if (losses == 0) return 100;
      final rs = gains / losses;
      return 100 - 100 / (1 + rs);
    });
  }

  static List<({double? macd, double? signal, double? hist})> _macdSeries(
    List<double> closes,
  ) {
    final ema12 = _emaSeries(closes, 12);
    final ema26 = _emaSeries(closes, 26);
    final macdLine = List<double?>.generate(closes.length, (i) {
      final a = ema12[i];
      final b = ema26[i];
      if (a == null || b == null) return null;
      return a - b;
    });

    final compact = <double>[];
    final compactIndex = <int>[];
    for (var i = 0; i < macdLine.length; i++) {
      final v = macdLine[i];
      if (v == null) continue;
      compact.add(v);
      compactIndex.add(i);
    }
    final signalCompact = _emaSeries(compact, 9);
    final signalLine = List<double?>.filled(closes.length, null);
    for (var i = 0; i < compact.length; i++) {
      signalLine[compactIndex[i]] = signalCompact[i];
    }

    return List.generate(closes.length, (i) {
      final m = macdLine[i];
      final s = signalLine[i];
      return (
        macd: m,
        signal: s,
        hist: (m != null && s != null) ? m - s : null,
      );
    });
  }
}
