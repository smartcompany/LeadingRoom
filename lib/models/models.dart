class MarketSymbol {
  MarketSymbol({
    required this.id,
    required this.marketId,
    required this.ticker,
    required this.displayName,
    required this.isFree,
    required this.isActive,
  });

  final String id;
  final String marketId;
  final String ticker;
  final String displayName;
  final bool isFree;
  final bool isActive;

  factory MarketSymbol.fromJson(Map<String, dynamic> json) {
    return MarketSymbol(
      id: json['id'] as String,
      marketId: json['market_id'] as String,
      ticker: json['ticker'] as String,
      displayName: json['display_name'] as String,
      isFree: json['is_free'] as bool,
      isActive: json['is_active'] as bool,
    );
  }
}

class SignalItem {
  SignalItem({
    required this.id,
    required this.symbolId,
    required this.side,
    required this.strength,
    required this.price,
    required this.rationale,
    required this.createdAt,
    this.stopHintPct,
    this.ticker,
    this.displayName,
    this.marketId,
    this.isFree,
  });

  final String id;
  final String symbolId;
  final String side;
  final String strength;
  final double price;
  final double? stopHintPct;
  final String rationale;
  final DateTime createdAt;
  final String? ticker;
  final String? displayName;
  final String? marketId;
  final bool? isFree;

  factory SignalItem.fromJson(Map<String, dynamic> json) {
    final sym = json['lr_symbols'] as Map<String, dynamic>?;
    return SignalItem(
      id: json['id'] as String,
      symbolId: json['symbol_id'] as String,
      side: json['side'] as String,
      strength: json['strength'] as String,
      price: (json['price'] as num).toDouble(),
      stopHintPct: json['stop_hint_pct'] == null
          ? null
          : (json['stop_hint_pct'] as num).toDouble(),
      rationale: json['rationale'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      ticker: sym?['ticker'] as String?,
      displayName: sym?['display_name'] as String?,
      marketId: sym?['market_id'] as String?,
      isFree: sym?['is_free'] as bool?,
    );
  }
}

class AnalysisItem {
  AnalysisItem({
    required this.id,
    required this.symbolId,
    required this.ticker,
    required this.displayName,
    required this.marketId,
    required this.side,
    required this.combinedScore,
    required this.rationale,
    required this.analyzedAt,
    this.techScore,
    this.qualScore,
  });

  final int id;
  final String symbolId;
  final String ticker;
  final String displayName;
  final String marketId;
  final String side;
  final double combinedScore;
  final double? techScore;
  final double? qualScore;
  final String rationale;
  final DateTime analyzedAt;

  factory AnalysisItem.fromJson(Map<String, dynamic> json) {
    return AnalysisItem(
      id: (json['id'] as num).toInt(),
      symbolId: json['symbolId'] as String,
      ticker: json['ticker'] as String,
      displayName: json['displayName'] as String,
      marketId: json['marketId'] as String,
      side: json['side'] as String,
      combinedScore: (json['combinedScore'] as num).toDouble(),
      techScore: json['techScore'] == null
          ? null
          : (json['techScore'] as num).toDouble(),
      qualScore: json['qualScore'] == null
          ? null
          : (json['qualScore'] as num).toDouble(),
      rationale: json['rationale'] as String,
      analyzedAt: DateTime.parse(json['analyzedAt'] as String),
    );
  }
}

class CandlePoint {
  CandlePoint({
    required this.time,
    required this.open,
    required this.high,
    required this.low,
    required this.close,
    required this.volume,
  });

  final DateTime time;
  final double open;
  final double high;
  final double low;
  final double close;
  final double volume;

  factory CandlePoint.fromJson(Map<String, dynamic> json) {
    return CandlePoint(
      time: DateTime.parse(json['ts'] as String),
      open: (json['open'] as num).toDouble(),
      high: (json['high'] as num).toDouble(),
      low: (json['low'] as num).toDouble(),
      close: (json['close'] as num).toDouble(),
      volume: (json['volume'] as num).toDouble(),
    );
  }
}

class PaperTradeMarker {
  PaperTradeMarker({
    required this.side,
    required this.price,
    required this.executedAt,
    this.pnlPct,
    this.rationale,
    this.stopHintPct,
    this.techScore,
    this.combinedScore,
    this.forcedSell = false,
    this.scoreLines = const [],
  });

  final String side;
  final double price;
  final DateTime executedAt;
  final double? pnlPct;
  final String? rationale;
  final double? stopHintPct;
  final double? techScore;
  final double? combinedScore;
  final bool forcedSell;
  final List<ScoreLineItem> scoreLines;

  factory PaperTradeMarker.fromJson(Map<String, dynamic> json) {
    final linesRaw = json['scoreLines'] as List<dynamic>?;
    return PaperTradeMarker(
      side: json['side'] as String,
      price: (json['price'] as num).toDouble(),
      executedAt: DateTime.parse(
        (json['executedAt'] ?? json['executed_at']) as String,
      ),
      pnlPct: json['pnlPct'] == null && json['pnl_pct'] == null
          ? null
          : ((json['pnlPct'] ?? json['pnl_pct']) as num).toDouble(),
      rationale: json['rationale'] as String?,
      stopHintPct: json['stopHintPct'] == null && json['stop_hint_pct'] == null
          ? null
          : ((json['stopHintPct'] ?? json['stop_hint_pct']) as num).toDouble(),
      techScore: json['techScore'] == null
          ? null
          : (json['techScore'] as num).toDouble(),
      combinedScore: json['combinedScore'] == null
          ? null
          : (json['combinedScore'] as num).toDouble(),
      forcedSell: json['forcedSell'] as bool? ?? false,
      scoreLines: linesRaw == null
          ? const []
          : linesRaw
              .cast<Map<String, dynamic>>()
              .map(ScoreLineItem.fromJson)
              .toList(),
    );
  }
}

class ScoreLineItem {
  ScoreLineItem({
    required this.key,
    required this.label,
    required this.condition,
    required this.points,
    required this.active,
  });

  final String key;
  final String label;
  final String condition;
  final double points;
  final bool active;

  factory ScoreLineItem.fromJson(Map<String, dynamic> json) {
    return ScoreLineItem(
      key: json['key'] as String? ?? '',
      label: json['label'] as String? ?? '',
      condition: json['condition'] as String? ?? '',
      points: (json['points'] as num?)?.toDouble() ?? 0,
      active: json['active'] as bool? ?? false,
    );
  }
}

class BacktestSummary {
  BacktestSummary({
    required this.barCount,
    required this.tradeCount,
    required this.closedCount,
    required this.totalReturnPct,
    required this.open,
    this.winRate,
    this.avgPnlPct,
    this.unrealizedPnlPct,
  });

  final int barCount;
  final int tradeCount;
  final int closedCount;
  final double? winRate;
  final double? avgPnlPct;
  final double totalReturnPct;
  final double? unrealizedPnlPct;
  final bool open;

  factory BacktestSummary.fromJson(Map<String, dynamic> json) {
    return BacktestSummary(
      barCount: json['barCount'] as int,
      tradeCount: json['tradeCount'] as int,
      closedCount: json['closedCount'] as int,
      winRate: json['winRate'] == null
          ? null
          : (json['winRate'] as num).toDouble(),
      avgPnlPct: json['avgPnlPct'] == null
          ? null
          : (json['avgPnlPct'] as num).toDouble(),
      totalReturnPct: (json['totalReturnPct'] as num).toDouble(),
      unrealizedPnlPct: json['unrealizedPnlPct'] == null
          ? null
          : (json['unrealizedPnlPct'] as num).toDouble(),
      open: json['open'] as bool? ?? false,
    );
  }
}

class BacktestResult {
  BacktestResult({
    required this.summary,
    required this.trades,
  });

  final BacktestSummary summary;
  final List<PaperTradeMarker> trades;

  factory BacktestResult.fromJson(Map<String, dynamic> json) {
    final list = json['trades'] as List<dynamic>? ?? [];
    return BacktestResult(
      summary: BacktestSummary.fromJson(
        json['summary'] as Map<String, dynamic>,
      ),
      trades: list
          .cast<Map<String, dynamic>>()
          .map(PaperTradeMarker.fromJson)
          .toList(),
    );
  }
}

class PerformanceSummary {
  PerformanceSummary({
    required this.closedCount,
    required this.winRate,
    required this.avgPnlPct,
    required this.positions,
  });

  final int closedCount;
  final double? winRate;
  final double? avgPnlPct;
  final List<Map<String, dynamic>> positions;

  factory PerformanceSummary.fromJson(Map<String, dynamic> json) {
    return PerformanceSummary(
      closedCount: json['closedCount'] as int,
      winRate: json['winRate'] == null
          ? null
          : (json['winRate'] as num).toDouble(),
      avgPnlPct: json['avgPnlPct'] == null
          ? null
          : (json['avgPnlPct'] as num).toDouble(),
      positions: (json['positions'] as List<dynamic>)
          .cast<Map<String, dynamic>>(),
    );
  }
}
