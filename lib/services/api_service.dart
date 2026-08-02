import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:leading_room/config/app_config.dart';
import 'package:leading_room/models/models.dart';

class ApiService {
  ApiService._();
  static final ApiService shared = ApiService._();

  Uri _uri(String path, [Map<String, String>? query]) {
    final base = AppConfig.shared.apiBaseUrl;
    return Uri.parse('$base$path').replace(queryParameters: query);
  }

  Future<List<MarketSymbol>> fetchSymbols({String? marketId}) async {
    final uri = _uri(
      '/api/symbols',
      marketId == null ? null : {'market': marketId},
    );
    final res = await http.get(uri);
    if (res.statusCode != 200) {
      throw StateError('symbols failed: ${res.statusCode}');
    }
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    final list = body['symbols'] as List<dynamic>;
    return list
        .cast<Map<String, dynamic>>()
        .map(MarketSymbol.fromJson)
        .toList();
  }

  Future<List<SignalItem>> fetchSignals({int limit = 50, String? symbolId}) async {
    final query = <String, String>{'limit': '$limit'};
    if (symbolId != null) query['symbolId'] = symbolId;
    final res = await http.get(_uri('/api/signals', query));
    if (res.statusCode != 200) {
      throw StateError('signals failed: ${res.statusCode}');
    }
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    final list = body['signals'] as List<dynamic>;
    return list.cast<Map<String, dynamic>>().map(SignalItem.fromJson).toList();
  }

  Future<List<CandlePoint>> fetchCandles(
    String symbolId, {
    String timeframe = '1d',
    int limit = 260,
  }) async {
    final res = await http.get(
      _uri('/api/candles/$symbolId', {
        'timeframe': timeframe,
        'limit': '$limit',
      }),
    );
    if (res.statusCode != 200) {
      throw StateError('candles failed: ${res.statusCode}');
    }
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    final list = body['candles'] as List<dynamic>;
    return list.cast<Map<String, dynamic>>().map(CandlePoint.fromJson).toList();
  }

  Future<List<PaperTradeMarker>> fetchTrades(String symbolId) async {
    final res = await http.get(_uri('/api/trades/$symbolId'));
    if (res.statusCode != 200) {
      throw StateError('trades failed: ${res.statusCode}');
    }
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    final list = body['trades'] as List<dynamic>;
    return list
        .cast<Map<String, dynamic>>()
        .map(PaperTradeMarker.fromJson)
        .toList();
  }

  Future<PerformanceSummary> fetchPerformance() async {
    final res = await http.get(_uri('/api/performance'));
    if (res.statusCode != 200) {
      throw StateError('performance failed: ${res.statusCode}');
    }
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    return PerformanceSummary.fromJson(body);
  }
}
