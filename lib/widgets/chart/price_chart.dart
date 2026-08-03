import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:leading_room/l10n/app_localizations.dart';
import 'package:leading_room/models/models.dart';
import 'package:leading_room/services/chart_interval_store.dart';
import 'package:leading_room/widgets/chart/chart_crosshair.dart';
import 'package:leading_room/widgets/chart/chart_indicator_store.dart';
import 'package:leading_room/widgets/chart/chart_indicators.dart';
import 'package:leading_room/widgets/chart/chart_visible_y_range.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

/// 마지막 봉을 화면 왼쪽 20%까지 끌어올 수 있도록 오른쪽에 비워 둘 비율.
const _rightPadFraction = 0.8;

class _PlotCandle {
  const _PlotCandle({
    required this.time,
    required this.open,
    required this.high,
    required this.low,
    required this.close,
    required this.isPadding,
  });

  final DateTime time;
  final double? open;
  final double? high;
  final double? low;
  final double? close;
  final bool isPadding;
}

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
  late ChartIndicators _indicators;
  late List<_PlotCandle> _plotCandles;
  final _indStore = ChartIndicatorStore.shared;

  double? _yMin;
  double? _yMax;
  DateTime? _lastFitFrom;
  DateTime? _lastFitTo;
  DateTime? _realFirst;
  DateTime? _realLast;
  Timer? _yFitDebounce;
  var _disposed = false;
  var _indReady = false;

  bool get _showMa20 => _indStore.showMa20;
  bool get _showMa50 => _indStore.showMa50;
  bool get _showEma9 => _indStore.showEma9;
  bool get _showEma12 => _indStore.showEma12;
  bool get _showEma26 => _indStore.showEma26;
  bool get _anyMa => _indStore.anyMa;
  bool get _anyEma => _indStore.anyEma;
  bool get _showRsi => _indStore.showRsi;
  bool get _showMacd => _indStore.showMacd;
  bool get _showVolume => _indStore.showVolume;

  @override
  void initState() {
    super.initState();
    _rebuildSeriesData();
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
    _loadIndicators();
  }

  Future<void> _loadIndicators() async {
    await _indStore.load();
    if (_disposed || !mounted) return;
    setState(() => _indReady = true);
  }

  @override
  void didUpdateWidget(covariant PriceChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.candles != widget.candles ||
        oldWidget.interval != widget.interval) {
      _rebuildSeriesData();
      _guide.hide();
      _fitFullRange();
    }
  }

  void _rebuildSeriesData() {
    _indicators = ChartIndicators.fromCandles(widget.candles);
    _plotCandles = _buildPlotCandles(widget.candles, widget.interval);
    if (widget.candles.isEmpty) {
      _realFirst = null;
      _realLast = null;
    } else {
      _realFirst = widget.candles.first.time;
      _realLast = widget.candles.last.time;
    }
  }

  static List<_PlotCandle> _buildPlotCandles(
    List<CandlePoint> candles,
    ChartInterval interval,
  ) {
    if (candles.isEmpty) return const [];
    final padCount = math.max(1, (candles.length * _rightPadFraction).ceil());
    final step = _barStep(candles, interval);
    final last = candles.last;
    return [
      for (final c in candles)
        _PlotCandle(
          time: c.time,
          open: c.open,
          high: c.high,
          low: c.low,
          close: c.close,
          isPadding: false,
        ),
      for (var i = 1; i <= padCount; i++)
        _PlotCandle(
          time: last.time.add(step * i),
          open: null,
          high: null,
          low: null,
          close: null,
          isPadding: true,
        ),
    ];
  }

  static Duration _barStep(List<CandlePoint> candles, ChartInterval interval) {
    if (candles.length >= 2) {
      final delta = candles.last.time.difference(candles[candles.length - 2].time);
      if (delta.inMilliseconds > 0) return delta;
    }
    switch (interval) {
      case ChartInterval.h1:
        return const Duration(hours: 1);
      case ChartInterval.h4:
        return const Duration(hours: 4);
      case ChartInterval.d1:
        return const Duration(days: 1);
      case ChartInterval.w1:
        return const Duration(days: 7);
      case ChartInterval.mo1:
        return const Duration(days: 30);
      case ChartInterval.y1:
        return const Duration(days: 365);
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _yFitDebounce?.cancel();
    _yFitDebounce = null;
    _guide.hide();
    super.dispose();
  }

  void _fitFullRange() {
    if (widget.candles.isEmpty) return;
    final from = widget.candles.first.time;
    final to = widget.candles.last.time;
    _applyYAxisFit(from, to);
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
    if (_plotCandles.isEmpty) return;

    final from = _resolveCategoryBound(args.visibleMin, lower: true);
    final to = _resolveCategoryBound(args.visibleMax, lower: false);
    if (from == null || to == null || to.isBefore(from)) return;

    _scheduleYAxisFit(from, to);
  }

  void _scheduleYAxisFit(DateTime from, DateTime to) {
    _yFitDebounce?.cancel();
    _yFitDebounce = Timer(const Duration(milliseconds: 24), () {
      if (_disposed || !mounted) return;
      _applyYAxisFit(from, to);
    });
  }

  DateTime? _resolveCategoryBound(dynamic value, {required bool lower}) {
    if (value is DateTime) return value;
    if (value is! num) return null;

    final last = _plotCandles.length - 1;
    if (last < 0) return null;

    if (value >= -1 && value <= last + 5) {
      final idx = lower ? value.floor() : value.ceil();
      return _plotCandles[idx.clamp(0, last)].time;
    }

    if (value.abs() > 1e11) {
      return DateTime.fromMillisecondsSinceEpoch(value.round());
    }
    return null;
  }

  void _applyYAxisFit(DateTime from, DateTime to) {
    _lastFitFrom = from;
    _lastFitTo = to;
    // Y축은 실제 봉만 사용 (우측 패딩 구간 제외)
    final values = <double>[];
    for (final c in widget.candles) {
      if (!ChartVisibleYRange.inWindow(c.time, from, to)) continue;
      values.add(c.high);
      values.add(c.low);
    }
    void addLine(List<TimedValue> line, bool enabled) {
      if (!enabled) return;
      for (final p in line) {
        if (p.value == null) continue;
        if (!ChartVisibleYRange.inWindow(p.time, from, to)) continue;
        values.add(p.value!);
      }
    }

    addLine(_indicators.ma20, _showMa20);
    addLine(_indicators.ma50, _showMa50);
    addLine(_indicators.ema9, _showEma9);
    addLine(_indicators.ema12, _showEma12);
    addLine(_indicators.ema26, _showEma26);
    final range = ChartVisibleYRange.fromValues(values, padFraction: 0.02);
    if (range == null) return;
    if (range.min == _yMin && range.max == _yMax) {
      if (mounted) setState(() {});
      return;
    }
    if (_disposed || !mounted) return;
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
        rationale: t.rationale,
        stopHintPct: t.stopHintPct,
        techScore: t.techScore,
        combinedScore: t.combinedScore,
        forcedSell: t.forcedSell,
        scoreLines: t.scoreLines,
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

  Widget _toggleChip({
    required String label,
    required bool selected,
    required ValueChanged<bool> onSelected,
  }) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: onSelected,
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  void _refitYIfNeeded() {
    final from = _lastFitFrom;
    final to = _lastFitTo;
    if (from != null && to != null) _applyYAxisFit(from, to);
  }

  Widget _linePickerChip({
    required String label,
    required bool selected,
    required List<
            ({
              String label,
              bool Function() get,
              Future<void> Function(bool) set
            })>
        lines,
  }) {
    return MenuAnchor(
      alignmentOffset: const Offset(0, 4),
      builder: (context, controller, _) {
        return FilterChip(
          label: Text(label),
          selected: selected,
          onSelected: (_) {
            if (controller.isOpen) {
              controller.close();
            } else {
              controller.open();
            }
          },
          visualDensity: VisualDensity.compact,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        );
      },
      menuChildren: [
        for (final line in lines)
          CheckboxMenuButton(
            value: line.get(),
            onChanged: (v) async {
              if (v == null) return;
              await line.set(v);
              if (!mounted) return;
              setState(() {});
              _refitYIfNeeded();
            },
            child: Text(line.label),
          ),
      ],
    );
  }

  Widget _indicatorToggles(AppLocalizations l10n) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
      child: Row(
        children: [
          _linePickerChip(
            label: l10n.indicatorMa,
            selected: _anyMa,
            lines: [
              (
                label: l10n.indicatorMa20,
                get: () => _indStore.showMa20,
                set: _indStore.setMa20,
              ),
              (
                label: l10n.indicatorMa50,
                get: () => _indStore.showMa50,
                set: _indStore.setMa50,
              ),
            ],
          ),
          const SizedBox(width: 6),
          _linePickerChip(
            label: l10n.indicatorEma,
            selected: _anyEma,
            lines: [
              (
                label: l10n.indicatorEma9,
                get: () => _indStore.showEma9,
                set: _indStore.setEma9,
              ),
              (
                label: l10n.indicatorEma12,
                get: () => _indStore.showEma12,
                set: _indStore.setEma12,
              ),
              (
                label: l10n.indicatorEma26,
                get: () => _indStore.showEma26,
                set: _indStore.setEma26,
              ),
            ],
          ),
          const SizedBox(width: 6),
          _toggleChip(
            label: l10n.indicatorRsi,
            selected: _showRsi,
            onSelected: (v) async {
              await _indStore.setRsi(v);
              if (mounted) setState(() {});
            },
          ),
          const SizedBox(width: 6),
          _toggleChip(
            label: l10n.indicatorMacd,
            selected: _showMacd,
            onSelected: (v) async {
              await _indStore.setMacd(v);
              if (mounted) setState(() {});
            },
          ),
          const SizedBox(width: 6),
          _toggleChip(
            label: l10n.indicatorVolume,
            selected: _showVolume,
            onSelected: (v) async {
              await _indStore.setVolume(v);
              if (mounted) setState(() {});
            },
          ),
        ],
      ),
    );
  }

  int get _paneCount {
    var n = 0;
    if (_showRsi) n++;
    if (_showMacd) n++;
    if (_showVolume) n++;
    return n;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.candles.isEmpty || _plotCandles.isEmpty) {
      return const SizedBox.shrink();
    }

    _bindGuide(context);
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final buys = _snapTrades(
      widget.trades.where((t) => t.side == 'buy').toList(),
    );
    final sells = _snapTrades(
      widget.trades.where((t) => t.side == 'sell').toList(),
    );
    final cs = Theme.of(context).colorScheme;
    final panes = _paneCount;
    final mainFlex = panes == 0 ? 1 : (panes >= 2 ? 3 : 2);

    final series = <CartesianSeries>[
      CandleSeries<_PlotCandle, DateTime>(
        dataSource: _plotCandles,
        xValueMapper: (c, _) => c.time,
        lowValueMapper: (c, _) => c.low,
        highValueMapper: (c, _) => c.high,
        openValueMapper: (c, _) => c.open,
        closeValueMapper: (c, _) => c.close,
        name: 'Price',
        emptyPointSettings: const EmptyPointSettings(
          mode: EmptyPointMode.gap,
        ),
      ),
      if (_showMa20)
        LineSeries<TimedValue, DateTime>(
          dataSource: _indicators.ma20,
          xValueMapper: (p, _) => p.time,
          yValueMapper: (p, _) => p.value,
          color: Colors.orange.shade700,
          width: 1.2,
          name: 'MA20',
          animationDuration: 0,
          emptyPointSettings: const EmptyPointSettings(
            mode: EmptyPointMode.gap,
          ),
        ),
      if (_showMa50)
        LineSeries<TimedValue, DateTime>(
          dataSource: _indicators.ma50,
          xValueMapper: (p, _) => p.time,
          yValueMapper: (p, _) => p.value,
          color: Colors.indigo.shade400,
          width: 1.2,
          name: 'MA50',
          animationDuration: 0,
          emptyPointSettings: const EmptyPointSettings(
            mode: EmptyPointMode.gap,
          ),
        ),
      if (_showEma9)
        LineSeries<TimedValue, DateTime>(
          dataSource: _indicators.ema9,
          xValueMapper: (p, _) => p.time,
          yValueMapper: (p, _) => p.value,
          color: Colors.cyan.shade700,
          width: 1.2,
          name: 'EMA9',
          animationDuration: 0,
          emptyPointSettings: const EmptyPointSettings(
            mode: EmptyPointMode.gap,
          ),
        ),
      if (_showEma12)
        LineSeries<TimedValue, DateTime>(
          dataSource: _indicators.ema12,
          xValueMapper: (p, _) => p.time,
          yValueMapper: (p, _) => p.value,
          color: Colors.teal.shade600,
          width: 1.2,
          name: 'EMA12',
          animationDuration: 0,
          emptyPointSettings: const EmptyPointSettings(
            mode: EmptyPointMode.gap,
          ),
        ),
      if (_showEma26)
        LineSeries<TimedValue, DateTime>(
          dataSource: _indicators.ema26,
          xValueMapper: (p, _) => p.time,
          yValueMapper: (p, _) => p.value,
          color: Colors.purple.shade400,
          width: 1.2,
          name: 'EMA26',
          animationDuration: 0,
          emptyPointSettings: const EmptyPointSettings(
            mode: EmptyPointMode.gap,
          ),
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
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_indReady) _indicatorToggles(l10n),
        Expanded(
          flex: mainFlex,
          child: ChartGuideGestureLayer(
            controller: _guide,
            child: SfCartesianChart(
              key: ValueKey(
                'price-${widget.candles.length}-${_realLast?.millisecondsSinceEpoch}',
              ),
              enableAxisAnimation: false,
              onActualRangeChanged: _onActualRangeChanged,
              zoomPanBehavior: _zoomPan,
              crosshairBehavior: _guide.crosshair,
              trackballBehavior: _guide.trackball,
              onZoomStart: _guide.onZoomEvent,
              onZooming: _guide.onZoomEvent,
              onZoomEnd: (args) {
                _guide.onZoomEvent(args);
                final from = _lastFitFrom;
                final to = _lastFitTo;
                if (from != null && to != null) {
                  _scheduleYAxisFit(from, to);
                }
              },
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
                // 초기에는 실봉만 보이게 → 마지막 봉이 오른쪽에.
                // 우측 패딩으로 패닝하면 마지막 봉을 ~20% 지점까지 당길 수 있음.
                initialVisibleMinimum: _realFirst,
                initialVisibleMaximum: _realLast,
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
              series: series,
            ),
          ),
        ),
        if (_showRsi)
          Expanded(
            flex: 1,
            child: _RsiPane(
              key: ValueKey(
                'rsi-${_lastFitFrom?.millisecondsSinceEpoch}-${_lastFitTo?.millisecondsSinceEpoch}',
              ),
              points: _indicators.rsi,
              visibleFrom: _lastFitFrom,
              visibleTo: _lastFitTo,
              dateFormat: _axisDateFormat(),
              label: l10n.indicatorRsi,
            ),
          ),
        if (_showMacd)
          Expanded(
            flex: 1,
            child: _MacdPane(
              key: ValueKey(
                'macd-${_lastFitFrom?.millisecondsSinceEpoch}-${_lastFitTo?.millisecondsSinceEpoch}',
              ),
              points: _indicators.macd,
              visibleFrom: _lastFitFrom,
              visibleTo: _lastFitTo,
              dateFormat: _axisDateFormat(),
              label: l10n.indicatorMacd,
            ),
          ),
        if (_showVolume)
          Expanded(
            flex: 1,
            child: _VolumePane(
              key: ValueKey(
                'vol-${_lastFitFrom?.millisecondsSinceEpoch}-${_lastFitTo?.millisecondsSinceEpoch}',
              ),
              points: _indicators.volume,
              visibleFrom: _lastFitFrom,
              visibleTo: _lastFitTo,
              dateFormat: _axisDateFormat(),
              label: l10n.indicatorVolume,
            ),
          ),
      ],
    );
  }
}

DateTimeCategoryAxis _mirrorXAxis({
  required DateFormat dateFormat,
  required DateTime? visibleFrom,
  required DateTime? visibleTo,
}) {
  return DateTimeCategoryAxis(
    dateFormat: dateFormat,
    isVisible: false,
    majorGridLines: const MajorGridLines(width: 0),
    initialVisibleMinimum: visibleFrom,
    initialVisibleMaximum: visibleTo,
  );
}

class _RsiPane extends StatelessWidget {
  const _RsiPane({
    super.key,
    required this.points,
    required this.visibleFrom,
    required this.visibleTo,
    required this.dateFormat,
    required this.label,
  });

  final List<TimedValue> points;
  final DateTime? visibleFrom;
  final DateTime? visibleTo;
  final DateFormat dateFormat;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, top: 4),
          child: Text(label, style: Theme.of(context).textTheme.labelSmall),
        ),
        Expanded(
          child: SfCartesianChart(
            enableAxisAnimation: false,
            margin: const EdgeInsets.only(top: 0, bottom: 0),
            primaryXAxis: _mirrorXAxis(
              dateFormat: dateFormat,
              visibleFrom: visibleFrom,
              visibleTo: visibleTo,
            ),
            primaryYAxis: NumericAxis(
              minimum: 0,
              maximum: 100,
              interval: 30,
              rangePadding: ChartRangePadding.none,
              plotBands: <PlotBand>[
                PlotBand(
                  start: 30,
                  end: 30,
                  borderColor: Colors.blueGrey.shade300,
                  borderWidth: 0.8,
                ),
                PlotBand(
                  start: 70,
                  end: 70,
                  borderColor: Colors.blueGrey.shade300,
                  borderWidth: 0.8,
                ),
              ],
            ),
            series: <CartesianSeries>[
              LineSeries<TimedValue, DateTime>(
                dataSource: points,
                xValueMapper: (p, _) => p.time,
                yValueMapper: (p, _) => p.value,
                color: Colors.teal.shade600,
                width: 1.2,
                animationDuration: 0,
                emptyPointSettings: const EmptyPointSettings(
                  mode: EmptyPointMode.gap,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MacdPane extends StatelessWidget {
  const _MacdPane({
    super.key,
    required this.points,
    required this.visibleFrom,
    required this.visibleTo,
    required this.dateFormat,
    required this.label,
  });

  final List<MacdPoint> points;
  final DateTime? visibleFrom;
  final DateTime? visibleTo;
  final DateFormat dateFormat;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, top: 4),
          child: Text(label, style: Theme.of(context).textTheme.labelSmall),
        ),
        Expanded(
          child: SfCartesianChart(
            enableAxisAnimation: false,
            margin: EdgeInsets.zero,
            primaryXAxis: _mirrorXAxis(
              dateFormat: dateFormat,
              visibleFrom: visibleFrom,
              visibleTo: visibleTo,
            ),
            primaryYAxis: NumericAxis(
              rangePadding: ChartRangePadding.additional,
              anchorRangeToVisiblePoints: true,
            ),
            series: <CartesianSeries>[
              ColumnSeries<MacdPoint, DateTime>(
                dataSource: points,
                xValueMapper: (p, _) => p.time,
                yValueMapper: (p, _) => p.hist,
                pointColorMapper: (p, _) =>
                    (p.hist ?? 0) >= 0 ? Colors.green.shade400 : Colors.red.shade400,
                animationDuration: 0,
                width: 0.7,
                emptyPointSettings: const EmptyPointSettings(
                  mode: EmptyPointMode.gap,
                ),
              ),
              LineSeries<MacdPoint, DateTime>(
                dataSource: points,
                xValueMapper: (p, _) => p.time,
                yValueMapper: (p, _) => p.macd,
                color: Colors.blue.shade600,
                width: 1,
                animationDuration: 0,
                emptyPointSettings: const EmptyPointSettings(
                  mode: EmptyPointMode.gap,
                ),
              ),
              LineSeries<MacdPoint, DateTime>(
                dataSource: points,
                xValueMapper: (p, _) => p.time,
                yValueMapper: (p, _) => p.signal,
                color: Colors.orange.shade700,
                width: 1,
                animationDuration: 0,
                emptyPointSettings: const EmptyPointSettings(
                  mode: EmptyPointMode.gap,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _VolumePane extends StatelessWidget {
  const _VolumePane({
    super.key,
    required this.points,
    required this.visibleFrom,
    required this.visibleTo,
    required this.dateFormat,
    required this.label,
  });

  final List<TimedValue> points;
  final DateTime? visibleFrom;
  final DateTime? visibleTo;
  final DateFormat dateFormat;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, top: 4),
          child: Text(label, style: Theme.of(context).textTheme.labelSmall),
        ),
        Expanded(
          child: SfCartesianChart(
            enableAxisAnimation: false,
            margin: EdgeInsets.zero,
            primaryXAxis: _mirrorXAxis(
              dateFormat: dateFormat,
              visibleFrom: visibleFrom,
              visibleTo: visibleTo,
            ),
            primaryYAxis: NumericAxis(
              rangePadding: ChartRangePadding.additional,
              anchorRangeToVisiblePoints: true,
              isVisible: false,
            ),
            series: <CartesianSeries>[
              ColumnSeries<TimedValue, DateTime>(
                dataSource: points,
                xValueMapper: (p, _) => p.time,
                yValueMapper: (p, _) => p.value,
                color: Colors.blueGrey.shade300,
                animationDuration: 0,
                width: 0.8,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
