import 'package:flutter/material.dart';
import 'package:leading_room/l10n/app_localizations.dart';
import 'package:leading_room/models/models.dart';
import 'package:leading_room/services/api_service.dart';
import 'package:leading_room/services/chart_interval_store.dart';
import 'package:leading_room/widgets/chart/price_chart.dart';

class SymbolChartScreen extends StatefulWidget {
  const SymbolChartScreen({
    super.key,
    required this.symbolId,
    required this.title,
  });

  final String symbolId;
  final String title;

  @override
  State<SymbolChartScreen> createState() => _SymbolChartScreenState();
}

class _SymbolChartScreenState extends State<SymbolChartScreen> {
  ChartInterval _interval = ChartInterval.d1;
  late Future<({List<CandlePoint> candles, List<PaperTradeMarker> trades})>
      _future;
  var _ready = false;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final saved = await ChartIntervalStore.shared.load();
    if (!mounted) return;
    setState(() {
      _interval = saved;
      _ready = true;
      _future = _load();
    });
  }

  Future<({List<CandlePoint> candles, List<PaperTradeMarker> trades})>
      _load() async {
    final candles = await ApiService.shared.fetchCandles(
      widget.symbolId,
      timeframe: _interval.apiValue,
    );
    final trades = await ApiService.shared.fetchTrades(widget.symbolId);
    return (candles: candles, trades: trades);
  }

  Future<void> _onIntervalSelected(ChartInterval interval) async {
    if (interval == _interval) return;
    await ChartIntervalStore.shared.set(interval);
    if (!mounted) return;
    setState(() {
      _interval = interval;
      _future = _load();
    });
  }

  String _labelFor(AppLocalizations l10n, ChartInterval interval) {
    switch (interval) {
      case ChartInterval.h1:
        return l10n.interval1h;
      case ChartInterval.h4:
        return l10n.interval4h;
      case ChartInterval.d1:
        return l10n.interval1d;
      case ChartInterval.w1:
        return l10n.interval1w;
      case ChartInterval.mo1:
        return l10n.interval1mo;
      case ChartInterval.y1:
        return l10n.interval1y;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          PopupMenuButton<ChartInterval>(
            tooltip: l10n.chartInterval,
            initialValue: _interval,
            onSelected: _onIntervalSelected,
            itemBuilder: (context) => [
              PopupMenuItem(
                value: ChartInterval.h1,
                child: Text(_labelFor(l10n, ChartInterval.h1)),
              ),
              PopupMenuItem(
                value: ChartInterval.h4,
                child: Text(_labelFor(l10n, ChartInterval.h4)),
              ),
              const PopupMenuDivider(),
              PopupMenuItem(
                value: ChartInterval.d1,
                child: Text(_labelFor(l10n, ChartInterval.d1)),
              ),
              PopupMenuItem(
                value: ChartInterval.w1,
                child: Text(_labelFor(l10n, ChartInterval.w1)),
              ),
              PopupMenuItem(
                value: ChartInterval.mo1,
                child: Text(_labelFor(l10n, ChartInterval.mo1)),
              ),
              PopupMenuItem(
                value: ChartInterval.y1,
                child: Text(_labelFor(l10n, ChartInterval.y1)),
              ),
            ],
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  Text(
                    _labelFor(l10n, _interval),
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const Icon(Icons.arrow_drop_down),
                ],
              ),
            ),
          ),
        ],
      ),
      body: !_ready
          ? Center(child: Text(l10n.loading))
          : FutureBuilder(
              future: _future,
              builder: (context, snap) {
                if (snap.connectionState != ConnectionState.done) {
                  return Center(child: Text(l10n.loading));
                }
                if (snap.hasError) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(l10n.errorGeneric),
                        TextButton(
                          onPressed: () => setState(() => _future = _load()),
                          child: Text(l10n.retry),
                        ),
                      ],
                    ),
                  );
                }
                final data = snap.data!;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                      child: Text(
                        l10n.chartTitle,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: PriceChart(
                          candles: data.candles,
                          trades: data.trades,
                          interval: _interval,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        l10n.disclaimer,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }
}
