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
  });

  final String side;
  final double price;
  final DateTime executedAt;
  final double? pnlPct;

  factory PaperTradeMarker.fromJson(Map<String, dynamic> json) {
    return PaperTradeMarker(
      side: json['side'] as String,
      price: (json['price'] as num).toDouble(),
      executedAt: DateTime.parse(json['executed_at'] as String),
      pnlPct: json['pnl_pct'] == null
          ? null
          : (json['pnl_pct'] as num).toDouble(),
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
