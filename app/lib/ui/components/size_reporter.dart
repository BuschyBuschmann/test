// `SizeReporter`: meldet die Größe des Kindes nach dem Layout, damit andere
// Elemente (Snackbar-Abstand, Scroll-Reserven) aus **gemessenen** Höhen
// rechnen statt aus festen Pixelwerten (Plan 4.6). Die Meldung kommt nach dem
// Frame und nur bei einer Änderung.
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

class SizeReporter extends SingleChildRenderObjectWidget {
  const SizeReporter({super.key, required this.onSize, super.child});

  final ValueChanged<Size> onSize;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderSizeReporter(onSize);

  @override
  void updateRenderObject(BuildContext context, RenderObject renderObject) {
    (renderObject as _RenderSizeReporter).onSize = onSize;
  }
}

class _RenderSizeReporter extends RenderProxyBox {
  _RenderSizeReporter(this.onSize);

  ValueChanged<Size> onSize;
  Size? _last;

  @override
  void performLayout() {
    super.performLayout();
    if (size == _last) return;
    _last = size;
    final Size reported = size;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (attached) onSize(reported);
    });
  }
}
