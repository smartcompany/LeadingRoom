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
  late Future<List<SignalItem>> _future;

  @override
  void initState() {
    super.initState();
    _future = ApiService.shared.fetchSignals();
  }

  bool _canView(SignalItem s) {
    // MVP: 전 종목 개방 (구독 게이트는 이후 재적용)
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final fmt = DateFormat('MM/dd HH:mm');

    return RefreshIndicator(
      onRefresh: () async {
        final next = ApiService.shared.fetchSignals();
        setState(() {
          _future = next;
        });
        await next;
      },
      child: FutureBuilder<List<SignalItem>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return ListView(
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
              children: [
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(l10n.emptySignals),
                ),
              ],
            );
          }
          return ListView.separated(
            itemCount: items.length,
            separatorBuilder: (_, index) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final s = items[i];
              final locked = !_canView(s);
              final isBuy = s.side == 'buy';
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: isBuy
                      ? Colors.green.shade100
                      : Colors.red.shade100,
                  child: Text(
                    isBuy ? l10n.buy : l10n.sell,
                    style: TextStyle(
                      color: isBuy ? Colors.green.shade800 : Colors.red.shade800,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                title: Text(
                  '${s.displayName ?? s.ticker ?? s.symbolId} · ${s.price}',
                ),
                subtitle: Text(
                  locked ? l10n.proLocked : s.rationale,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: Text(
                  fmt.format(s.createdAt.toLocal()),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                onTap: locked
                    ? null
                    : () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => SymbolChartScreen(
                              symbolId: s.symbolId,
                              title: s.displayName ?? s.ticker ?? '',
                            ),
                          ),
                        );
                      },
              );
            },
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
