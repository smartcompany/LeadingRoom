import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

/// iOS/Android는 핀치 줌을 쓰므로 +/- 버튼은 웹·데스크톱만 표시.
bool get showChartZoomButtons {
  if (kIsWeb) return true;
  return defaultTargetPlatform != TargetPlatform.iOS &&
      defaultTargetPlatform != TargetPlatform.android;
}

/// 차트 ZoomPanBehavior.
/// [enablePanning]: 가이드가 꺼져 있을 때만 true — 줌 후 가려진 구간을 드래그로 이동.
ZoomPanBehavior createChartZoomPanBehavior({bool enablePanning = true}) {
  return ZoomPanBehavior(
    enablePinching: true,
    enablePanning: enablePanning,
    enableDoubleTapZooming: true,
    enableMouseWheelZooming: true,
    zoomMode: ZoomMode.x,
  );
}

/// 가이드 상태·십자선/트랙볼. 입력은 [ChartGuideGestureLayer]가 전달합니다.
class ChartGuideController {
  ChartGuideController({
    Color? lineColor,
    this.onVisibilityChanged,
  })
      : crosshair = CrosshairBehavior(
          enable: true,
          activationMode: ActivationMode.none,
          lineType: CrosshairLineType.both,
          lineDashArray: const <double>[5, 4],
          lineWidth: 1,
          lineColor: lineColor,
          shouldAlwaysShow: true,
        ) {
    trackball = TrackballBehavior(
      enable: true,
      activationMode: ActivationMode.none,
      lineType: TrackballLineType.none,
      tooltipDisplayMode: TrackballDisplayMode.groupAllPoints,
      shouldAlwaysShow: true,
      builder: _buildTooltip,
    );
  }

  final VoidCallback? onVisibilityChanged;

  final CrosshairBehavior crosshair;
  late final TrackballBehavior trackball;

  bool visible = false;
  Offset? _lastPosition;
  DateTime? _axisX;
  double? _axisY;
  DateTime? _suppressTapUntil;

  static const Duration _zoomSuppressDuration = Duration(milliseconds: 450);

  String priceLabel = '';
  num? Function(DateTime time)? priceAt;
  String Function(DateTime time)? formatTime;
  String Function(num price)? formatPrice;
  Color? backgroundColor;
  Color? foregroundColor;

  void bind({
    required String priceLabel,
    required num? Function(DateTime time) priceAt,
    required String Function(DateTime time) formatTime,
    required String Function(num price) formatPrice,
    Color? backgroundColor,
    Color? foregroundColor,
  }) {
    this.priceLabel = priceLabel;
    this.priceAt = priceAt;
    this.formatTime = formatTime;
    this.formatPrice = formatPrice;
    this.backgroundColor = backgroundColor;
    this.foregroundColor = foregroundColor;
  }

  void onTap(Offset globalPosition) {
    if (_isTapSuppressed) return;
    if (visible) {
      hide();
      return;
    }
    show(_toCrosshairLocalFromGlobal(globalPosition));
  }

  void onPanUpdate(Offset delta) {
    if (!visible) return;
    final current = _lastPosition;
    if (current == null) return;
    final next = current + delta;
    _lastPosition = next;
    _moveTo(next);
  }

  void onPanEnd() {
    final p = _lastPosition;
    if (visible && p != null) _moveTo(p);
  }

  void onZoomEvent([ZoomPanArgs? _]) {
    _suppressTapUntil = DateTime.now().add(_zoomSuppressDuration);
  }

  bool get _isTapSuppressed {
    final until = _suppressTapUntil;
    if (until == null) return false;
    if (DateTime.now().isBefore(until)) return true;
    _suppressTapUntil = null;
    return false;
  }

  void show(Offset localPosition) {
    _lastPosition = localPosition;
    final wasVisible = visible;
    visible = true;
    _moveTo(localPosition);
    if (!wasVisible) {
      onVisibilityChanged?.call();
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (!visible) return;
        final p = _lastPosition;
        if (p != null) _moveTo(p);
      });
    }
  }

  void hide() {
    crosshair.hide();
    trackball.hide();
    _lastPosition = null;
    _axisX = null;
    _axisY = null;
    if (!visible) return;
    visible = false;
    onVisibilityChanged?.call();
  }

  void _moveTo(Offset localPosition) {
    _updateAxisValuesAt(localPosition);
    crosshair.show(localPosition.dx, localPosition.dy, 'pixel');
    trackball.show(localPosition.dx, localPosition.dy, 'pixel');
  }

  void _updateAxisValuesAt(Offset localPosition) {
    final parent = crosshair.parentBox;
    if (parent == null || !parent.attached || !parent.hasSize) return;
    try {
      final dynamic area = parent;
      final dynamic xAxis = area.xAxis;
      final dynamic yAxis = area.yAxis;
      if (xAxis != null) {
        final Rect bounds = xAxis.paintBounds as Rect;
        final num xVal = xAxis.pixelToPoint(
          bounds,
          localPosition.dx,
          localPosition.dy,
        ) as num;
        if (!xVal.isNaN) {
          _axisX = DateTime.fromMillisecondsSinceEpoch(xVal.toInt());
        }
      }
      if (yAxis != null) {
        final Rect bounds = yAxis.paintBounds as Rect;
        final num yVal = yAxis.pixelToPoint(
          bounds,
          localPosition.dx,
          localPosition.dy,
        ) as num;
        if (!yVal.isNaN) {
          _axisY = yVal.toDouble();
        }
      }
    } catch (_) {}
  }

  Offset _toCrosshairLocalFromGlobal(Offset globalPosition) {
    final behavior = crosshair.parentBox;
    if (behavior == null || !behavior.attached || !behavior.hasSize) {
      return globalPosition;
    }
    try {
      return behavior.globalToLocal(globalPosition);
    } catch (_) {
      return globalPosition;
    }
  }

  Widget _buildTooltip(BuildContext context, TrackballDetails details) {
    final time = _axisX;
    var y = _axisY;
    if (time != null && priceAt != null) {
      final snapped = priceAt!(time);
      if (snapped != null) y = snapped.toDouble();
    }
    if (time == null && y == null) return const SizedBox.shrink();

    final cs = Theme.of(context).colorScheme;
    final bg = backgroundColor ?? cs.inverseSurface;
    final fg = foregroundColor ?? cs.onInverseSurface;
    final lines = <String>[
      if (time != null) formatTime?.call(time) ?? time.toLocal().toString(),
      if (y != null)
        '${priceLabel.isEmpty ? '' : '$priceLabel '}'
            '${formatPrice?.call(y) ?? y.toString()}',
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: bg.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DefaultTextStyle(
        style: TextStyle(
          color: fg,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          height: 1.35,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [for (final line in lines) Text(line)],
        ),
      ),
    );
  }
}

class ChartGuideGestureLayer extends StatefulWidget {
  const ChartGuideGestureLayer({
    super.key,
    required this.controller,
    required this.child,
  });

  final ChartGuideController controller;
  final Widget child;

  @override
  State<ChartGuideGestureLayer> createState() => _ChartGuideGestureLayerState();
}

class _ChartGuideGestureLayerState extends State<ChartGuideGestureLayer> {
  int? _activePointer;
  Offset? _downGlobal;
  Offset? _lastGlobal;
  bool _exceededTouchSlop = false;
  bool _guideWasVisibleOnDown = false;
  bool _didPanGuide = false;

  double get _touchSlop {
    return MediaQuery.maybeOf(context)?.gestureSettings.touchSlop ?? kTouchSlop;
  }

  void _onPointerDown(PointerDownEvent event) {
    _activePointer = event.pointer;
    _downGlobal = event.position;
    _lastGlobal = event.position;
    _exceededTouchSlop = false;
    _didPanGuide = false;
    _guideWasVisibleOnDown = widget.controller.visible;
  }

  void _onPointerMove(PointerMoveEvent event) {
    if (event.pointer != _activePointer || _downGlobal == null) return;

    if (!_exceededTouchSlop &&
        (event.position - _downGlobal!).distance > _touchSlop) {
      _exceededTouchSlop = true;
    }

    final prev = _lastGlobal ?? event.position;
    final delta = event.position - prev;
    _lastGlobal = event.position;

    if (_guideWasVisibleOnDown &&
        widget.controller.visible &&
        _exceededTouchSlop &&
        delta != Offset.zero) {
      _didPanGuide = true;
      widget.controller.onPanUpdate(delta);
    }
  }

  void _onPointerUp(PointerUpEvent event) {
    if (event.pointer != _activePointer) return;
    final exceeded = _exceededTouchSlop;
    final guideOnDown = _guideWasVisibleOnDown;
    final didPan = _didPanGuide;
    _resetPointerState();

    if (didPan) {
      widget.controller.onPanEnd();
      return;
    }

    if (!exceeded) {
      widget.controller.onTap(event.position);
      return;
    }

    if (guideOnDown) {
      widget.controller.onPanEnd();
    }
  }

  void _onPointerCancel(PointerCancelEvent event) {
    if (event.pointer != _activePointer) return;
    final didPan = _didPanGuide;
    _resetPointerState();
    if (didPan) {
      widget.controller.onPanEnd();
    }
  }

  void _resetPointerState() {
    _activePointer = null;
    _downGlobal = null;
    _lastGlobal = null;
    _exceededTouchSlop = false;
    _guideWasVisibleOnDown = false;
    _didPanGuide = false;
  }

  @override
  Widget build(BuildContext context) {
    final guideOn = widget.controller.visible;
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: _onPointerDown,
      onPointerMove: _onPointerMove,
      onPointerUp: _onPointerUp,
      onPointerCancel: _onPointerCancel,
      child: AbsorbPointer(
        absorbing: guideOn,
        child: widget.child,
      ),
    );
  }
}

String formatGuideAxisTime(
  DateTime time, {
  required bool hourlyGranularity,
  String? localeTag,
}) {
  final local = time.toLocal();
  final pattern = hourlyGranularity ? 'yyyy-MM-dd HH:mm' : 'yyyy-MM-dd';
  return DateFormat(pattern, localeTag).format(local);
}

void formatChartCrosshairLabels(
  CrosshairRenderArgs args, {
  required bool hourlyGranularity,
  String? localeTag,
}) {
  final value = args.value;
  if (args.orientation == AxisOrientation.horizontal) {
    final time = _asDateTime(value);
    if (time == null) return;
    args.text = formatGuideAxisTime(
      time,
      hourlyGranularity: hourlyGranularity,
      localeTag: localeTag,
    );
    return;
  }

  final num? n = value is num ? value : num.tryParse('$value');
  if (n == null) return;
  args.text = NumberFormat('#,##0.##', localeTag).format(n);
}

DateTime? _asDateTime(dynamic value) {
  if (value is DateTime) return value;
  if (value is num) {
    return DateTime.fromMillisecondsSinceEpoch(value.toInt());
  }
  return null;
}

InteractiveTooltip chartAxisInteractiveTooltip({
  bool enable = true,
  Color? color,
  Color? textColor,
}) {
  return InteractiveTooltip(
    enable: enable,
    color: color,
    textStyle: TextStyle(
      color: textColor,
      fontSize: 11,
      fontWeight: FontWeight.w600,
    ),
    borderRadius: 6,
    decimalPlaces: 2,
  );
}
