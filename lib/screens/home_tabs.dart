import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:leading_room/l10n/app_localizations.dart';
import 'package:leading_room/models/models.dart';
import 'package:leading_room/screens/symbol_chart_screen.dart';
import 'package:leading_room/services/api_service.dart';

class SignalsScreen extends StatefulWidget {
  const SignalsScreen({super.key, required this.tier});

  final String tier;

  @override
  State<SignalsScreen> createState() => _SignalsScreenState();
}

class _SignalsScreenState extends State<SignalsScreen> {
  late Future<List<AnalysisItem>> _future;

  @override
  void initState() {
    super.initState();
    _future = ApiService.shared.fetchLatestAnalyses();
  }

  String _sideLabel(AppLocalizations l10n, String side) {
    switch (side) {
      case 'buy':
        return l10n.buy;
      case 'sell':
        return l10n.sell;
      default:
        return l10n.hold;
    }
  }

  Color _sideBg(String side) {
    switch (side) {
      case 'buy':
        return Colors.green.shade100;
      case 'sell':
        return Colors.red.shade100;
      default:
        return Colors.blueGrey.shade50;
    }
  }

  Color _sideFg(String side) {
    switch (side) {
      case 'buy':
        return Colors.green.shade800;
      case 'sell':
        return Colors.red.shade800;
      default:
        return Colors.blueGrey.shade600;
    }
  }

  Color? _rowBg(String side, {required bool emphasized}) {
    if (!emphasized) return null;
    switch (side) {
      case 'buy':
        return Colors.green.shade50;
      case 'sell':
        return Colors.red.shade50;
      default:
        return null;
    }
  }

  void _openChart(AnalysisItem s) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SymbolChartScreen(
          symbolId: s.symbolId,
          title: s.displayName,
        ),
      ),
    );
  }

  Widget _sectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }

  Widget _stanceChip(AppLocalizations l10n, String side) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: _sideBg(side),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        _sideLabel(l10n, side),
        style: TextStyle(
          color: _sideFg(side),
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _analysisTile({
    required BuildContext context,
    required AppLocalizations l10n,
    required AnalysisItem s,
    required DateFormat fmt,
    required NumberFormat scoreFmt,
    required bool emphasized,
  }) {
    final isAction = s.side == 'buy' || s.side == 'sell';
    return Material(
      color: _rowBg(s.side, emphasized: emphasized && isAction),
      child: ListTile(
        leading: SizedBox(
          width: 52,
          child: Center(child: _stanceChip(l10n, s.side)),
        ),
        title: Text(
          '${s.displayName} (${s.ticker})',
          style: TextStyle(
            fontWeight: emphasized && isAction ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
        subtitle: Text(
          '${l10n.scoreLabel} ${scoreFmt.format(s.combinedScore)}\n${s.rationale}',
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        ),
        isThreeLine: true,
        trailing: Text(
          fmt.format(s.analyzedAt.toLocal()),
          style: Theme.of(context).textTheme.bodySmall,
        ),
        onTap: () => _openChart(s),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final fmt = DateFormat('MM/dd HH:mm');
    final scoreFmt = NumberFormat('+0.00;-0.00');

    return RefreshIndicator(
      onRefresh: () async {
        final next = ApiService.shared.fetchLatestAnalyses();
        setState(() {
          _future = next;
        });
        await next;
      },
      child: FutureBuilder<List<AnalysisItem>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                SizedBox(
                  height: MediaQuery.sizeOf(context).height * 0.4,
                  child: Center(child: Text(l10n.loading)),
                ),
              ],
            );
          }
          if (snap.hasError) {
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(l10n.errorGeneric),
                ),
              ],
            );
          }
          final items = snap.data ?? [];
          if (items.isEmpty) {
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(l10n.emptySignals),
                ),
              ],
            );
          }

          final picks = items
              .where((s) => s.side == 'buy' || s.side == 'sell')
              .toList();
          final all = [...items]..sort((a, b) {
              const order = {'buy': 0, 'sell': 1, 'hold': 2};
              final bySide =
                  (order[a.side] ?? 3).compareTo(order[b.side] ?? 3);
              if (bySide != 0) return bySide;
              return a.displayName.compareTo(b.displayName);
            });

          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              _sectionHeader(context, l10n.recommendSection),
              if (picks.isEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Text(
                    l10n.noRecommendations,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                )
              else
                ...picks.map(
                  (s) => _analysisTile(
                    context: context,
                    l10n: l10n,
                    s: s,
                    fmt: fmt,
                    scoreFmt: scoreFmt,
                    emphasized: true,
                  ),
                ),
              const Divider(height: 24),
              _sectionHeader(context, l10n.allSymbolsSection),
              ...all.map(
                (s) => _analysisTile(
                  context: context,
                  l10n: l10n,
                  s: s,
                  fmt: fmt,
                  scoreFmt: scoreFmt,
                  emphasized: false,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class MarketsScreen extends StatefulWidget {
  const MarketsScreen({super.key, required this.tier});

  final String tier;

  @override
  State<MarketsScreen> createState() => _MarketsScreenState();
}

class _MarketsScreenState extends State<MarketsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs =
      TabController(length: 3, vsync: this);
  late Future<List<MarketSymbol>> _future;

  static const _markets = ['us', 'kr', 'crypto'];

  @override
  void initState() {
    super.initState();
    _future = ApiService.shared.fetchSymbols();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      children: [
        TabBar(
          controller: _tabs,
          tabs: [
            Tab(text: l10n.marketUs),
            Tab(text: l10n.marketKr),
            Tab(text: l10n.marketCrypto),
          ],
        ),
        Expanded(
          child: FutureBuilder<List<MarketSymbol>>(
            future: _future,
            builder: (context, snap) {
              if (snap.connectionState != ConnectionState.done) {
                return Center(child: Text(l10n.loading));
              }
              if (snap.hasError) {
                return Center(child: Text(l10n.errorGeneric));
              }
              final all = snap.data ?? [];
              return TabBarView(
                controller: _tabs,
                children: _markets.map((m) {
                  final list = all.where((s) => s.marketId == m).toList();
                  if (list.isEmpty) {
                    return Center(child: Text(l10n.emptySymbols));
                  }
                  return ListView.builder(
                    itemCount: list.length,
                    itemBuilder: (context, i) {
                      final s = list[i];
                      return ListTile(
                        title: Text(s.displayName),
                        subtitle: Text(s.ticker),
                        trailing: s.isFree
                            ? Chip(label: Text(l10n.free))
                            : Chip(label: Text(l10n.pro)),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => SymbolChartScreen(
                                symbolId: s.id,
                                title: s.displayName,
                              ),
                            ),
                          );
                        },
                      );
                    },
                  );
                }).toList(),
              );
            },
          ),
        ),
      ],
    );
  }
}

class PerformanceScreen extends StatefulWidget {
  const PerformanceScreen({super.key});

  @override
  State<PerformanceScreen> createState() => _PerformanceScreenState();
}

class _PerformanceScreenState extends State<PerformanceScreen> {
  late Future<PerformanceSummary> _future;

  @override
  void initState() {
    super.initState();
    _future = ApiService.shared.fetchPerformance();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return RefreshIndicator(
      onRefresh: () async {
        final next = ApiService.shared.fetchPerformance();
        setState(() {
          _future = next;
        });
        await next;
      },
      child: FutureBuilder<PerformanceSummary>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return ListView(
              children: [Center(child: Padding(
                padding: const EdgeInsets.all(48),
                child: Text(l10n.loading),
              ))],
            );
          }
          if (snap.hasError) {
            return ListView(
              children: [
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(l10n.errorGeneric),
                ),
              ],
            );
          }
          final p = snap.data!;
          if (p.closedCount == 0) {
            return ListView(
              children: [
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(l10n.noPerformance),
                ),
              ],
            );
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                children: [
                  _StatCard(
                    label: l10n.closedTrades,
                    value: '${p.closedCount}',
                  ),
                  const SizedBox(width: 8),
                  _StatCard(
                    label: l10n.winRate,
                    value: p.winRate == null
                        ? '-'
                        : '${(p.winRate! * 100).toStringAsFixed(1)}%',
                  ),
                  const SizedBox(width: 8),
                  _StatCard(
                    label: l10n.avgPnl,
                    value: p.avgPnlPct == null
                        ? '-'
                        : '${p.avgPnlPct!.toStringAsFixed(2)}%',
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ...p.positions.map((row) {
                final sym = row['lr_symbols'] as Map<String, dynamic>?;
                final name = sym?['display_name'] ?? sym?['ticker'] ?? '';
                final pnl = row['pnl_pct'];
                return ListTile(
                  title: Text('$name'),
                  trailing: Text(
                    pnl == null ? '-' : '${(pnl as num).toStringAsFixed(2)}%',
                    style: TextStyle(
                      color: (pnl is num && pnl >= 0)
                          ? Colors.green.shade700
                          : Colors.red.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              }),
              const SizedBox(height: 24),
              Text(
                l10n.disclaimer,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).dividerColor),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 4),
            Text(value, style: Theme.of(context).textTheme.titleMedium),
          ],
        ),
      ),
    );
  }
}
