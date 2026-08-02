import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:leading_room/l10n/app_localizations.dart';
import 'package:leading_room/models/models.dart';
import 'package:leading_room/services/api_service.dart';
import 'package:leading_room/services/chart_interval_store.dart';
import 'package:leading_room/utils/signal_rationale_explain.dart';
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
  late Future<
      ({
        List<CandlePoint> candles,
        BacktestResult backtest,
      })> _future;
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

  Future<
      ({
        List<CandlePoint> candles,
        BacktestResult backtest,
      })> _load() async {
    final candlesFuture = ApiService.shared.fetchCandles(
      widget.symbolId,
      timeframe: _interval.apiValue,
    );
    final backtestFuture = ApiService.shared.fetchBacktest(
      widget.symbolId,
      timeframe: _interval.apiValue,
    );
    final candles = await candlesFuture;
    final backtest = await backtestFuture;
    return (candles: candles, backtest: backtest);
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

  void _showTradeHistory(
    BuildContext context,
    AppLocalizations l10n,
    List<PaperTradeMarker> trades,
  ) {
    final fmt = DateFormat('yyyy/MM/dd HH:mm');
    final pnlFmt = NumberFormat('+0.00%;-0.00%');

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return SafeArea(
          child: SizedBox(
            height: MediaQuery.sizeOf(context).height * 0.55,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Text(
                    l10n.tradeHistory,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
                Expanded(
                  child: trades.isEmpty
                      ? Center(child: Text(l10n.noTradeHistory))
                      : ListView.separated(
                          itemCount: trades.length,
                          separatorBuilder: (_, index) =>
                              const Divider(height: 1),
                          itemBuilder: (context, i) {
                            final t = trades[i];
                            final isBuy = t.side == 'buy';
                            final sideLabel = isBuy ? l10n.buy : l10n.sell;
                            final pnlText = t.pnlPct == null
                                ? null
                                : pnlFmt.format(t.pnlPct! / 100);
                            final summary =
                                SignalRationaleExplain.cleanSummary(t.rationale);
                            return ListTile(
                              leading: Icon(
                                isBuy
                                    ? Icons.arrow_upward
                                    : Icons.arrow_downward,
                                color: isBuy
                                    ? Colors.green.shade700
                                    : Colors.red.shade700,
                              ),
                              title: Text(
                                '$sideLabel · ${NumberFormat('#,##0.##').format(t.price)}',
                              ),
                              subtitle: Text(
                                [
                                  fmt.format(t.executedAt.toLocal()),
                                  if (summary.isNotEmpty) summary,
                                ].join('\n'),
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                              ),
                              isThreeLine: summary.isNotEmpty,
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (pnlText != null)
                                    Text(
                                      pnlText,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        color: (t.pnlPct ?? 0) >= 0
                                            ? Colors.green.shade700
                                            : Colors.red.shade700,
                                      ),
                                    ),
                                  TextButton(
                                    onPressed: () => _showTradeDetail(
                                      context,
                                      l10n,
                                      t,
                                    ),
                                    child: Text(l10n.tradeHistoryDetail),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showTradeDetail(
    BuildContext context,
    AppLocalizations l10n,
    PaperTradeMarker trade,
  ) {
    final fmt = DateFormat('yyyy/MM/dd HH:mm');
    final scoreFmt = NumberFormat('+0.00;-0.00');
    final hasTable = trade.scoreLines.isNotEmpty;
    final sections = SignalRationaleExplain.sections(
      side: trade.side,
      rationale: trade.rationale,
      stopHintPct: trade.stopHintPct,
      hasScoreTable: hasTable,
    );

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return SafeArea(
          child: SizedBox(
            height: MediaQuery.sizeOf(context).height * 0.85,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          l10n.tradeHistoryDetailTitle,
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Text(
                    '${trade.side == 'buy' ? l10n.buy : l10n.sell} · '
                    '${NumberFormat('#,##0.##').format(trade.price)} · '
                    '${fmt.format(trade.executedAt.toLocal())}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                    children: [
                      if (hasTable) ...[
                        Text(
                          '점수 내역',
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 8),
                        _ScoreTable(lines: trade.scoreLines, scoreFmt: scoreFmt),
                        const SizedBox(height: 12),
                        _ScoreTotalRow(
                          label: '기술 점수',
                          value: trade.techScore,
                          scoreFmt: scoreFmt,
                        ),
                        _ScoreTotalRow(
                          label: '종합 점수',
                          value: trade.combinedScore,
                          scoreFmt: scoreFmt,
                          emphasize: true,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '판정 기준',
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '· 매수: 종합 점수 ≥ +0.10\n'
                          '· 매도(보유 중): 종합 점수 ≤ −0.35\n'
                          '· 강제 매도(보유 중): 하락 추세 + RSI > 55',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        if (trade.forcedSell) ...[
                          const SizedBox(height: 8),
                          Text(
                            '이번 매도는 강제 매도(추세 붕괴) 조건으로 나갔습니다.',
                            style: TextStyle(
                              color: Colors.red.shade800,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                        const SizedBox(height: 8),
                        Text(
                          '활성(적용)된 항목은 진하게 표시됩니다. '
                          '거래량 등은 기준 미달이면 0점·비활성입니다.',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                              ),
                        ),
                        const SizedBox(height: 20),
                        const Divider(height: 1),
                        const SizedBox(height: 16),
                      ],
                      for (var i = 0; i < sections.length; i++) ...[
                        if (i > 0) const SizedBox(height: 16),
                        Text(
                          sections[i].title,
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          sections[i].body,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _summaryBar(
    BuildContext context,
    AppLocalizations l10n,
    BacktestSummary s,
    List<PaperTradeMarker> trades,
  ) {
    final retFmt = NumberFormat('+0.00%;-0.00%');
    final winFmt = NumberFormat('0%');
    final retColor = s.totalReturnPct >= 0
        ? Colors.green.shade800
        : Colors.red.shade800;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${l10n.backtestReturn} ${retFmt.format(s.totalReturnPct / 100)}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: retColor,
                      ),
                ),
              ),
              TextButton(
                onPressed: () => _showTradeHistory(context, l10n, trades),
                child: Text(l10n.tradeHistory),
              ),
            ],
          ),
          Text(
            [
              if (s.winRate != null)
                '${l10n.backtestWinRate} ${winFmt.format(s.winRate)}',
              '${l10n.backtestTrades} ${s.closedCount}',
              if (s.open) l10n.backtestOpen,
            ].join(' · '),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 4),
          Text(
            l10n.backtestNote,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
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
                    _summaryBar(
                      context,
                      l10n,
                      data.backtest.summary,
                      data.backtest.trades,
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: PriceChart(
                          candles: data.candles,
                          trades: data.backtest.trades,
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

class _ScoreTable extends StatelessWidget {
  const _ScoreTable({required this.lines, required this.scoreFmt});

  final List<ScoreLineItem> lines;
  final NumberFormat scoreFmt;

  @override
  Widget build(BuildContext context) {
    final headerStyle = Theme.of(context).textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.w700,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        );
    return Table(
      columnWidths: const {
        0: FlexColumnWidth(1.1),
        1: FlexColumnWidth(2.2),
        2: FlexColumnWidth(0.9),
      },
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      children: [
        TableRow(
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text('항목', style: headerStyle),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text('조건', style: headerStyle),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                '점수',
                style: headerStyle,
                textAlign: TextAlign.right,
              ),
            ),
          ],
        ),
        for (final line in lines)
          TableRow(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Text(
                  line.label,
                  style: TextStyle(
                    fontWeight:
                        line.active ? FontWeight.w700 : FontWeight.w400,
                    color: line.active
                        ? null
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Text(
                  line.condition,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight:
                        line.active ? FontWeight.w600 : FontWeight.w400,
                    color: line.active
                        ? null
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Text(
                  scoreFmt.format(line.points),
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontWeight:
                        line.active ? FontWeight.w700 : FontWeight.w400,
                    color: line.points > 0
                        ? Colors.green.shade800
                        : line.points < 0
                            ? Colors.red.shade800
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }
}

class _ScoreTotalRow extends StatelessWidget {
  const _ScoreTotalRow({
    required this.label,
    required this.value,
    required this.scoreFmt,
    this.emphasize = false,
  });

  final String label;
  final double? value;
  final NumberFormat scoreFmt;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    if (value == null) return const SizedBox.shrink();
    final style = emphasize
        ? Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
            )
        : Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            );
    final color = value! > 0
        ? Colors.green.shade800
        : value! < 0
            ? Colors.red.shade800
            : null;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Expanded(child: Text(label, style: style)),
          Text(
            scoreFmt.format(value),
            style: style?.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}
