/// 시그널 근거 문구 → 초보자용 상세 설명.
class SignalRationaleExplain {
  SignalRationaleExplain._();

  static final _atrNote = RegExp(r'ATR\s*손절\s*추정\s*[\d.]+%');

  static const _junkPhrases = [
    '백테스트 · 기술 분석만',
    '백테스트',
    '기술 분석만',
  ];

  /// 히스토리 한 줄 요약용 (잡음·손절 힌트 제거).
  static String cleanSummary(String? rationale) {
    if (rationale == null || rationale.trim().isEmpty) return '';
    final parts = rationale
        .split('·')
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty)
        .where((p) => !_junkPhrases.contains(p))
        .where((p) => !p.contains('기술 분석만'))
        .where((p) => !_atrNote.hasMatch(p) && !p.contains('ATR'))
        .toList();
    return parts.join(' · ');
  }

  static double? atrFromRationale(String? rationale) {
    if (rationale == null) return null;
    final m = RegExp(r'ATR\s*손절\s*추정\s*([\d.]+)%').firstMatch(rationale);
    if (m == null) return null;
    return double.tryParse(m.group(1)!);
  }

  static List<({String title, String body})> sections({
    required String side,
    required String? rationale,
    double? stopHintPct,
    bool hasScoreTable = false,
  }) {
    final cleaned = cleanSummary(rationale);
    final notes = cleaned.isEmpty
        ? <String>[]
        : cleaned
            .split('·')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();

    final atrPct = stopHintPct ?? atrFromRationale(rationale);

    final out = <({String title, String body})>[
      (
        title: side == 'buy' ? '왜 매수인가요?' : '왜 매도인가요?',
        body: side == 'buy'
            ? '아래 점수표 합산(종합 점수)이 매수 기준(≥ 0.1)을 넘겼습니다. '
                '실제 투자 권유가 아니라 과거 차트 시뮬레이션입니다.'
            : '보유 중이라고 가정한 상태에서, 종합 점수가 매도 기준(≤ −0.35)이거나 '
                '추세 붕괴 강제 매도 조건이 맞았습니다. 실제 투자 권유가 아닙니다.',
      ),
    ];

    if (notes.isNotEmpty) {
      out.add((
        title: '한줄 메모',
        body: notes.map((n) => '· $n').join('\n'),
      ));

      final explained = <String>{};
      for (final note in notes) {
        for (final item in _explainNote(note)) {
          if (explained.add(item.title)) {
            out.add(item);
          }
        }
      }
    }

    if (!hasScoreTable) {
      out.addAll(_rulebookSections());
    }

    if (atrPct != null && side != 'buy') {
      out.add((
        title: '손절 참고',
        body: 'ATR ${atrPct.toStringAsFixed(1)}%는 최근 출렁임 참고값이며 '
            '매수·매도 점수에는 들어가지 않습니다.',
      ));
    }

    out.add((
      title: '차트에서 같이 보면 좋아요',
      body: '이평(MA20·MA50), RSI·MACD·거래량 토글을 켜 두면 '
          '점수 항목을 눈으로 확인할 수 있습니다.',
    ));

    return out;
  }

  static List<({String title, String body})> _rulebookSections() {
    return [
      (
        title: '매수 / 매도 기준',
        body: '· 매수: 종합 점수 ≥ 0.1\n'
            '· 매도(보유 중): 종합 점수 ≤ −0.35\n'
            '· 강제 매도(보유 중): 하락 추세 + RSI > 55',
      ),
    ];
  }

  static List<({String title, String body})> _explainNote(String note) {
    if (note.contains('상승 추세')) {
      return [
        (
          title: '상승 추세 (이평선)',
          body: '단기 평균(MA20)이 장기 평균(MA50) 위에 있고, 가격도 단기 평균 위에 있으면 '
              '“위로 가는 흐름”으로 봅니다.',
        ),
      ];
    }
    if (note.contains('하락 추세')) {
      return [
        (
          title: '하락 추세 (이평선)',
          body: '가격과 단기 평균이 장기 평균 아래로 내려가면 “아래로 가는 흐름”으로 봅니다.',
        ),
      ];
    }
    if (note.contains('RSI')) {
      return [
        (
          title: 'RSI',
          body: '0~100으로 과매수·과매도를 봅니다. 30 아래에서 회복하면 가점, '
              '70 초과면 감점입니다.',
        ),
      ];
    }
    if (note.contains('MACD')) {
      return [
        (
          title: 'MACD',
          body: 'MACD선이 시그널선을 아래에서 위로 뚫을 때만 가점됩니다.',
        ),
      ];
    }
    if (note.contains('거래량')) {
      return [
        (
          title: '거래량',
          body: '평소(20봉 평균) 대비 2.4배 이상일 때만 가점·문구에 나옵니다.',
        ),
      ];
    }
    if (note.contains('저항')) {
      return [
        (
          title: '저항 돌파',
          body: '상승 추세에서 최근 저항 구간에 근접하면 가점됩니다.',
        ),
      ];
    }
    if (note.contains('추세 붕괴') || note.contains('청산')) {
      return [
        (
          title: '추세 붕괴 청산',
          body: '보유 중 하락 추세 + RSI > 55이면 점수와 무관하게 강제 매도합니다.',
        ),
      ];
    }
    return const [];
  }
}
