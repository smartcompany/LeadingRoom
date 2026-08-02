import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:leading_room/models/models.dart';
import 'package:leading_room/services/chart_interval_store.dart';
import 'package:leading_room/widgets/chart/chart_crosshair.dart';
import 'package:leading_room/widgets/chart/chart_visible_y_range.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class PriceChart extends StatefulWidget {
  const PriceChart({
    super.key,
    required this.candles,
    required this.trades,
    required this.interval,
  });

  final List<CandlePoint> candles;
  final List<PaperTradeMarker> trades;
  final ChartInterval interval;

  @override
  State<PriceChart> createState() => _PriceChartState();
}

class _PriceChartState extends State<PriceChart> {
  late ZoomPanBehavior _zoomPan;
  late final ChartGuideController _guide;
  double? _yMin;
  double? _yMax;
  DateTime? _visibleFrom;
  DateTime? _visibleTo;
  Timer? _fitTimer;
  var _disposed = false;

  @override
  void initState() {
    super.initState();
    _guide = ChartGuideController(
      onVisibilityChanged: () {
        if (_disposed || !mounted) return;
        setState(() {
          _zoomPan = createChartZoomPanBehavior(enablePanning: !_guide.visible);
        });
      },
    );
    _zoomPan = createChartZoomPanBehavior(enablePanning: true);
    _fitFullRange();
  }

  @override
  void didUpdateWidget(covariant PriceChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.candles != widget.candles) {
      _guide.hide();
      _fitFullRange();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _fitTimer?.cancel();
    _fitTimer = null;
    _guide.hide();
    super.dispose();
  }

  void _fitFullRange() {
    if (widget.candles.isEmpty) return;
    final from = widget.candles.first.time;
    final to = widget.candles.last.time;
    final range = ChartVisibleYRange.fromCandles(
      candles: widget.candles,
      from: from,
      to: to,
    );
    _visibleFrom = from;
    _visibleTo = to;
    _yMin = range?.min;
    _yMax = range?.max;
    if (_disposed || !mounted) return;
    setState(() {});
  }

  void _bindGuide(BuildContext context) {
    final locale = Localizations.localeOf(context).toLanguageTag();
    _guide.bind(
      priceLabel: '',
      priceAt: _priceAt,
      formatTime: (t) => formatGuideAxisTime(
        t,
        hourlyGranularity: widget.interval.isHourly,
        localeTag: locale,
      ),
      formatPrice: (p) => NumberFormat('#,##0.##', locale).format(p),
      backgroundColor: Theme.of(context).colorScheme.inverseSurface,
      foregroundColor: Theme.of(context).colorScheme.onInverseSurface,
    );
  }

  num? _priceAt(DateTime time) {
    if (widget.candles.isEmpty) return null;
    var best = widget.candles.first;
    var bestDiff = (best.time.difference(time)).abs();
    for (final c in widget.candles) {
      final diff = (c.time.difference(time)).abs();
      if (diff < bestDiff) {
        best = c;
        bestDiff = diff;
      }
    }
    return best.close;
  }

  void _onActualRangeChanged(ActualRangeChangedArgs args) {
    if (args.orientation != AxisOrientation.horizontal) return;
    if (widget.candles.isEmpty) return;

    final from = _resolveVisibleBound(args.visibleMin, lower: true);
    final to = _resolveVisibleBound(args.visibleMax, lower: false);
    if (from == null || to == null) return;

    _visibleFrom = from;
    _visibleTo = to;
    _fitTimer?.cancel();
    _fitTimer = Timer(const Duration(milliseconds: 24), _applyYAxisFit);
  }

  DateTime? _resolveVisibleBound(dynamic value, {required bool lower}) {
    final asDate = ChartVisibleYRange.parseAxisDate(value);
    if (asDate != null) return asDate;

    if (value is num) {
      final last = widget.candles.length - 1;
      final idx = lower ? value.floor() : value.ceil();
      final clamped = idx.clamp(0, last);
      return widget.candles[clamped].time;
    }
    return null;
  }

  void _applyYAxisFit() {
    final from = _visibleFrom;
    final to = _visibleTo;
    if (from == null || to == null || _disposed || !mounted) return;
    final range = ChartVisibleYRange.fromCandles(
      candles: widget.candles,
      from: from,
      to: to,
    );
    if (range == null) return;
    setState(() {
      _yMin = range.min;
      _yMax = range.max;
    });
  }

  List<PaperTradeMarker> _snapTrades(List<PaperTradeMarker> trades) {
    if (widget.candles.isEmpty || trades.isEmpty) return trades;
    return trades.map((t) {
      final nearest = _nearestCandleTime(t.executedAt);
      if (nearest == t.executedAt) return t;
      return PaperTradeMarker(
        side: t.side,
        price: t.price,
        executedAt: nearest,
        pnlPct: t.pnlPct,
      );
    }).toList();
  }

  DateTime _nearestCandleTime(DateTime target) {
    var best = widget.candles.first.time;
    var bestDiff = (best.difference(target)).abs();
    for (final c in widget.candles) {
      final diff = (c.time.difference(target)).abs();
      if (diff < bestDiff) {
        best = c.time;
        bestDiff = diff;
      }
    }
    return best;
  }

  DateFormat _axisDateFormat() {
    switch (widget.interval) {
      case ChartInterval.h1:
      case ChartInterval.h4:
        return DateFormat('M/d HH');
      case ChartInterval.d1:
      case ChartInterval.w1:
        return DateFormat('yy/M/d');
      case ChartInterval.mo1:
        return DateFormat('yy/M');
      case ChartInterval.y1:
        return DateFormat('yyyy');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.candles.isEmpty) {
      return const SizedBox.shrink();
    }

    _bindGuide(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final buys = _snapTrades(
      widget.trades.where((t) => t.side == 'buy').toList(),
    );
    final sells = _snapTrades(
      widget.trades.where((t) => t.side == 'sell').toList(),
    );
    final cs = Theme.of(context).colorScheme;

    return ChartGuideGestureLayer(
      controller: _guide,
      child: SfCartesianChart(
        onActualRangeChanged: _onActualRangeChanged,
        zoomPanBehavior: _zoomPan,
        crosshairBehavior: _guide.crosshair,
        trackballBehavior: _guide.trackball,
        onZoomStart: _guide.onZoomEvent,
        onZoomEnd: _guide.onZoomEvent,
        onCrosshairPositionChanging: (args) {
          formatChartCrosshairLabels(
            args,
            hourlyGranularity: widget.interval.isHourly,
            localeTag: locale,
          );
        },
        primaryXAxis: DateTimeCategoryAxis(
          dateFormat: _axisDateFormat(),
          labelRotation: -45,
          majorGridLines: const MajorGridLines(width: 0.4),
          interactiveTooltip: chartAxisInteractiveTooltip(
            color: cs.inverseSurface,
            textColor: cs.onInverseSurface,
          ),
        ),
        primaryYAxis: NumericAxis(
          minimum: _yMin,
          maximum: _yMax,
          anchorRangeToVisiblePoints: true,
          rangePadding: ChartRangePadding.none,
          interactiveTooltip: chartAxisInteractiveTooltip(
            color: cs.inverseSurface,
            textColor: cs.onInverseSurface,
          ),
        ),
        series: <CartesianSeries>[
          CandleSeries<CandlePoint, DateTime>(
            dataSource: widget.candles,
            xValueMapper: (c, _) => c.time,
            lowValueMapper: (c, _) => c.low,
            highValueMapper: (c, _) => c.high,
            openValueMapper: (c, _) => c.open,
            closeValueMapper: (c, _) => c.close,
            name: 'Price',
          ),
          ScatterSeries<PaperTradeMarker, DateTime>(
            dataSource: buys,
            xValueMapper: (t, _) => t.executedAt,
            yValueMapper: (t, _) => t.price,
            markerSettings: const MarkerSettings(
              isVisible: true,
              height: 18,
              width: 18,
              shape: DataMarkerType.image,
              image: AssetImage('assets/markers/arrow_shape_up.png'),
            ),
            name: 'Buy',
          ),
          ScatterSeries<PaperTradeMarker, DateTime>(
            dataSource: sells,
            xValueMapper: (t, _) => t.executedAt,
            yValueMapper: (t, _) => t.price,
            markerSettings: const MarkerSettings(
              isVisible: true,
              height: 18,
              width: 18,
              shape: DataMarkerType.image,
              image: AssetImage('assets/markers/arrow_shape_down.png'),
            ),
            name: 'Sell',
          ),
        ],
      ),
    );
  }
}
