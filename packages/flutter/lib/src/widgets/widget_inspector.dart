// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui
    show
        window,
        ClipOp,
        Image,
        ImageByteFormat,
        Paragraph,
        Picture,
        PictureRecorder,
        PointMode,
        SceneBuilder,
        Vertices;
import 'dart:ui' show Canvas, Offset;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:vector_math/vector_math_64.dart';

import 'app.dart';
import 'basic.dart';
import 'binding.dart';
import 'framework.dart';
import 'gesture_detector.dart';
import 'icon_data.dart';

/// Signature for the builder callback used by
/// [WidgetInspector.selectButtonBuilder].
typedef InspectorSelectButtonBuilder = Widget Function(BuildContext context, VoidCallback onPressed);

typedef _RegisterServiceExtensionCallback = void Function({
  @required String name,
  @required ServiceExtensionCallback callback
});

/// A layer that mimics the behavior of another layer.
///
/// A proxy layer is used for cases where a layer needs to be placed into
/// multiple trees of layers.
class _ProxyLayer extends Layer {
  _ProxyLayer(this._layer);

  final Layer _layer;

  @override
  void addToScene(ui.SceneBuilder builder, [Offset layerOffset = Offset.zero]) {
    _layer.addToScene(builder, layerOffset);
  }

  @override
  S find<S>(Offset regionOffset) => _layer.find(regionOffset);
}

/// A [Canvas] that multicasts all method calls to a main canvas and a
/// secondary screenshot canvas so that a screenshot can be recorded at the same
/// time as performing a normal paint.
class _MulticastCanvas implements Canvas {
  _MulticastCanvas({
    @required Canvas main,
    @required Canvas screenshot,
  }) : assert(main != null),
       assert(screenshot != null),
       _main = main,
       _screenshot = screenshot;

  final Canvas _main;
  final Canvas _screenshot;

  @override
  void clipPath(Path path, {bool doAntiAlias = true}) {
    _main.clipPath(path, doAntiAlias: doAntiAlias);
    _screenshot.clipPath(path, doAntiAlias: doAntiAlias);
  }

  @override
  void clipRRect(RRect rrect, {bool doAntiAlias = true}) {
    _main.clipRRect(rrect, doAntiAlias: doAntiAlias);
    _screenshot.clipRRect(rrect, doAntiAlias: doAntiAlias);
  }

  @override
  void clipRect(Rect rect, {ui.ClipOp clipOp = ui.ClipOp.intersect, bool doAntiAlias = true}) {
    _main.clipRect(rect, clipOp: clipOp, doAntiAlias: doAntiAlias);
    _screenshot.clipRect(rect, clipOp: clipOp, doAntiAlias: doAntiAlias);
  }

  @override
  void drawArc(Rect rect, double startAngle, double sweepAngle, bool useCenter, Paint paint) {
    _main.drawArc(rect, startAngle, sweepAngle, useCenter, paint);
    _screenshot.drawArc(rect, startAngle, sweepAngle, useCenter, paint);
  }

  @override
  void drawAtlas(ui.Image atlas, List<RSTransform> transforms, List<Rect> rects, List<Color> colors, BlendMode blendMode, Rect cullRect, Paint paint) {
    _main.drawAtlas(atlas, transforms, rects, colors, blendMode, cullRect, paint);
    _screenshot.drawAtlas(atlas, transforms, rects, colors, blendMode, cullRect, paint);
  }

  @override
  void drawCircle(Offset c, double radius, Paint paint) {
    _main.drawCircle(c, radius, paint);
    _screenshot.drawCircle(c, radius, paint);
  }

  @override
  void drawColor(Color color, BlendMode blendMode) {
    _main.drawColor(color, blendMode);
    _screenshot.drawColor(color, blendMode);
  }

  @override
  void drawDRRect(RRect outer, RRect inner, Paint paint) {
    _main.drawDRRect(outer, inner, paint);
    _screenshot.drawDRRect(outer, inner, paint);
  }

  @override
  void drawImage(ui.Image image, Offset p, Paint paint) {
    _main.drawImage(image, p, paint);
    _screenshot.drawImage(image, p, paint);
  }

  @override
  void drawImageNine(ui.Image image, Rect center, Rect dst, Paint paint) {
    _main.drawImageNine(image, center, dst, paint);
    _screenshot.drawImageNine(image, center, dst, paint);
  }

  @override
  void drawImageRect(ui.Image image, Rect src, Rect dst, Paint paint) {
    _main.drawImageRect(image, src, dst, paint);
    _screenshot.drawImageRect(image, src, dst, paint);
  }

  @override
  void drawLine(Offset p1, Offset p2, Paint paint) {
    _main.drawLine(p1, p2, paint);
    _screenshot.drawLine(p1, p2, paint);
  }

  @override
  void drawOval(Rect rect, Paint paint) {
    _main.drawOval(rect, paint);
    _screenshot.drawOval(rect, paint);
  }

  @override
  void drawPaint(Paint paint) {
    _main.drawPaint(paint);
    _screenshot.drawPaint(paint);
  }

  @override
  void drawParagraph(ui.Paragraph paragraph, Offset offset) {
    _main.drawParagraph(paragraph, offset);
    _screenshot.drawParagraph(paragraph, offset);
  }

  @override
  void drawPath(Path path, Paint paint) {
    _main.drawPath(path, paint);
    _screenshot.drawPath(path, paint);
  }

  @override
  void drawPicture(ui.Picture picture) {
    _main.drawPicture(picture);
    _screenshot.drawPicture(picture);
  }

  @override
  void drawPoints(ui.PointMode pointMode, List<Offset> points, Paint paint) {
    _main.drawPoints(pointMode, points, paint);
    _screenshot.drawPoints(pointMode, points, paint);
  }

  @override
  void drawRRect(RRect rrect, Paint paint) {
    _main.drawRRect(rrect, paint);
    _screenshot.drawRRect(rrect, paint);
  }

  @override
  void drawRawAtlas(ui.Image atlas, Float32List rstTransforms, Float32List rects, Int32List colors, BlendMode blendMode, Rect cullRect, Paint paint) {
    _main.drawRawAtlas(atlas, rstTransforms, rects, colors, blendMode, cullRect, paint);
    _screenshot.drawRawAtlas(atlas, rstTransforms, rects, colors, blendMode, cullRect, paint);
  }

  @override
  void drawRawPoints(ui.PointMode pointMode, Float32List points, Paint paint) {
    _main.drawRawPoints(pointMode, points, paint);
    _screenshot.drawRawPoints(pointMode, points, paint);
  }

  @override
  void drawRect(Rect rect, Paint paint) {
    _main.drawRect(rect, paint);
    _screenshot.drawRect(rect, paint);
  }

  @override
  void drawShadow(Path path, Color color, double elevation, bool transparentOccluder) {
    _main.drawShadow(path, color, elevation, transparentOccluder);
    _screenshot.drawShadow(path, color, elevation, transparentOccluder);
  }

  @override
  void drawVertices(ui.Vertices vertices, BlendMode blendMode, Paint paint) {
    _main.drawVertices(vertices, blendMode, paint);
    _screenshot.drawVertices(vertices, blendMode, paint);
  }

  @override
  int getSaveCount() {
    // The main canvas is used instead of the screenshot canvas as the main
    // canvas is guaranteed to be consistent with the canvas expected by the
    // normal paint pipeline so any logic depending on getSaveCount() will
    // behave the same as for the regular paint pipeline.
    return _main.getSaveCount();
  }

  @override
  void restore() {
    _main.restore();
    _screenshot.restore();
  }

  @override
  void rotate(double radians) {
    _main.rotate(radians);
    _screenshot.rotate(radians);
  }

  @override
  void save() {
    _main.save();
    _screenshot.save();
  }

  @override
  void saveLayer(Rect bounds, Paint paint) {
    _main.saveLayer(bounds, paint);
    _screenshot.saveLayer(bounds, paint);
  }

  @override
  void scale(double sx, [double sy]) {
    _main.scale(sx, sy);
    _screenshot.scale(sx, sy);
  }

  @override
  void skew(double sx, double sy) {
    _main.skew(sx, sy);
    _screenshot.skew(sx, sy);
  }

  @override
  void transform(Float64List matrix4) {
    _main.transform(matrix4);
    _screenshot.transform(matrix4);
  }

  @override
  void translate(double dx, double dy) {
    _main.translate(dx, dy);
    _screenshot.translate(dx, dy);
  }
}

Rect _calculateSubtreeBoundsHelper(RenderObject object, Matrix4 transform) {
  Rect bounds = MatrixUtils.transformRect(transform, object.semanticBounds);

  object.visitChildren((RenderObject child) {
    final Matrix4 childTransform = transform.clone();
    object.applyPaintTransform(child, childTransform);
    Rect childBounds = _calculateSubtreeBoundsHelper(child, childTransform);
    final Rect paintClip = object.describeApproximatePaintClip(child);
    if (paintClip != null) {
      final Rect transformedPaintClip = MatrixUtils.transformRect(
        transform,
        paintClip,
      );
      childBounds = childBounds.intersect(transformedPaintClip);
    }

    if (childBounds.isFinite && !childBounds.isEmpty) {
      bounds = bounds.isEmpty ? childBounds : bounds.expandToInclude(childBounds);
    }
  });

  return bounds;
}

/// Calculate bounds for a render object and all of its descendants.
Rect _calculateSubtreeBounds(RenderObject object) {
  return _calculateSubtreeBoundsHelper(object, Matrix4.identity());
}

/// A layer that omits its own offset when adding children to the scene so that
/// screenshots render to the scene in the local coordinate system of the layer.
class _ScreenshotContainerLayer extends OffsetLayer {
  @override
  void addToScene(ui.SceneBuilder builder, [Offset layerOffset = Offset.zero]) {
    addChildrenToScene(builder, layerOffset);
  }
}

/// Data shared between nested [_ScreenshotPaintingContext] objects recording
/// a screenshot.
class _ScreenshotData {
  _ScreenshotData({
    @required this.target,
  }) : assert(target != null),
       containerLayer = _ScreenshotContainerLayer();

  /// Target to take a screenshot of.
  final RenderObject target;

  /// Root of the layer tree containing the screenshot.
  final OffsetLayer containerLayer;

  /// Whether the screenshot target has already been found in the render tree.
  bool foundTarget = false;

  /// Whether paint operations should record to the screenshot.
  ///
  /// At least one of [includeInScreenshot] and [includeInRegularContext] must
  /// be true.
  bool includeInScreenshot = false;

  /// Whether paint operations should record to the regular context.
  ///
  /// This should only be set to false before paint operations that should only
  /// apply to the screenshot such rendering debug information about the
  /// [target].
  ///
  /// At least one of [includeInScreenshot] and [includeInRegularContext] must
  /// be true.
  bool includeInRegularContext = true;

  /// Offset of the screenshot corresponding to the offset [target] was given as
  /// part of the regular paint.
  Offset get screenshotOffset {
    assert(foundTarget);
    return containerLayer.offset;
  }
  set screenshotOffset(Offset offset) {
    containerLayer.offset = offset;
  }
}

/// A place to paint to build screenshots of [RenderObject]s.
///
/// Requires that the render objects have already painted successfully as part
/// of the regular rendering pipeline.
/// This painting context behaves the same as standard [PaintingContext] with
/// instrumentation added to compute a screenshot of a specified [RenderObject]
/// added. To correctly mimic the behavor of the regular rendering pipeline, the
/// full subtree of the first [RepaintBoundary] ancestor of the specified
/// [RenderObject] will also be rendered rather than just the subtree of the
/// render object.
class _ScreenshotPaintingContext extends PaintingContext {
  _ScreenshotPaintingContext({
    @required ContainerLayer containerLayer,
    @required Rect estimatedBounds,
    @required _ScreenshotData screenshotData,
  }) : _data = screenshotData,
       super(containerLayer, estimatedBounds);

  final _ScreenshotData _data;

  // Recording state
  PictureLayer _screenshotCurrentLayer;
  ui.PictureRecorder _screenshotRecorder;
  Canvas _screenshotCanvas;
  _MulticastCanvas _multicastCanvas;

  @override
  Canvas get canvas {
    if (_data.includeInScreenshot) {
      if (_screenshotCanvas == null) {
        _startRecordingScreenshot();
      }
      assert(_screenshotCanvas != null);
      return _data.includeInRegularContext ? _multicastCanvas : _screenshotCanvas;
    } else {
      assert(_data.includeInRegularContext);
      return super.canvas;
    }
  }

  bool get _isScreenshotRecording {
    final bool hasScreenshotCanvas = _screenshotCanvas != null;
    assert(() {
      if (hasScreenshotCanvas) {
        assert(_screenshotCurrentLayer != null);
        assert(_screenshotRecorder != null);
        assert(_screenshotCanvas != null);
      } else {
        assert(_screenshotCurrentLayer == null);
        assert(_screenshotRecorder == null);
        assert(_screenshotCanvas == null);
      }
      return true;
    }());
    return hasScreenshotCanvas;
  }

  void _startRecordingScreenshot() {
    assert(_data.includeInScreenshot);
    assert(!_isScreenshotRecording);
    _screenshotCurrentLayer = PictureLayer(estimatedBounds);
    _screenshotRecorder = ui.PictureRecorder();
    _screenshotCanvas = Canvas(_screenshotRecorder);
    _data.containerLayer.append(_screenshotCurrentLayer);
    if (_data.includeInRegularContext) {
      _multicastCanvas = _MulticastCanvas(
        main: super.canvas,
        screenshot: _screenshotCanvas,
      );
    } else {
      _multicastCanvas = null;
    }
  }

  @override
  void stopRecordingIfNeeded() {
    super.stopRecordingIfNeeded();
    _stopRecordingScreenshotIfNeeded();
  }

  void _stopRecordingScreenshotIfNeeded() {
    if (!_isScreenshotRecording)
      return;
    // There is no need to ever draw repaint rainbows as part of the screenshot.
    _screenshotCurrentLayer.picture = _screenshotRecorder.endRecording();
    _screenshotCurrentLayer = null;
    _screenshotRecorder = null;
    _multicastCanvas = null;
    _screenshotCanvas = null;
  }

  @override
  void appendLayer(Layer layer) {
    if (_data.includeInRegularContext) {
      super.appendLayer(layer);
      if (_data.includeInScreenshot) {
        assert(!_isScreenshotRecording);
        // We must use a proxy layer here as the layer is already attached to
        // the regular layer tree.
        _data.containerLayer.append(_ProxyLayer(layer));
      }
    } else {
      // Only record to the screenshot.
      assert(!_isScreenshotRecording);
      assert(_data.includeInScreenshot);
      layer.remove();
      _data.containerLayer.append(layer);
      return;
    }
  }

  @override
  PaintingContext createChildContext(ContainerLayer childLayer, Rect bounds) {
    if (_data.foundTarget) {
      // We have already found the screenshotTarget in the layer tree
      // so we can optimize and use a standard PaintingContext.
      return super.createChildContext(childLayer, bounds);
    } else {
      return _ScreenshotPaintingContext(
        containerLayer: childLayer,
        estimatedBounds: bounds,
        screenshotData: _data,
      );
    }
  }

  @override
  void paintChild(RenderObject child, Offset offset) {
    final bool isScreenshotTarget = identical(child, _data.target);
    if (isScreenshotTarget) {
      assert(!_data.includeInScreenshot);
      assert(!_data.foundTarget);
      _data.foundTarget = true;
      _data.screenshotOffset = offset;
      _data.includeInScreenshot = true;
    }
    super.paintChild(child, offset);
    if (isScreenshotTarget) {
      _stopRecordingScreenshotIfNeeded();
      _data.includeInScreenshot = false;
    }
  }

  /// Captures an image of the current state of [renderObject] and its children.
  ///
  /// The returned [ui.Image] has uncompressed raw RGBA bytes, will be offset
  /// by the top-left corner of [renderBounds], and have dimensions equal to the
  /// size of [renderBounds] multiplied by [pixelRatio].
  ///
  /// To use [toImage], the render object must have gone through the paint phase
  /// (i.e. [debugNeedsPaint] must be false).
  ///
  /// The [pixelRatio] describes the scale between the logical pixels and the
  /// size of the output image. It is independent of the
  /// [window.devicePixelRatio] for the device, so specifying 1.0 (the default)
  /// will give you a 1:1 mapping between logical pixels and the output pixels
  /// in the image.
  ///
  /// The [debugPaint] argument specifies whether the image should include the
  /// output of [RenderObject.debugPaint] for [renderObject] with
  /// [debugPaintSizeEnabled] set to `true`. Debug paint information is not
  /// included for the children of [renderObject] so that it is clear precisely
  /// which object the debug paint information references.
  ///
  /// See also:
  ///
  ///  * [RenderRepaintBoundary.toImage] for a similar API for [RenderObject]s
  ///    that are repaint boundaries that can be used outside of the inspector.
  ///  * [OffsetLayer.toImage] for a similar API at the layer level.
  ///  * [dart:ui.Scene.toImage] for more information about the image returned.
  static Future<ui.Image> toImage(
    RenderObject renderObject,
    Rect renderBounds, {
    double pixelRatio = 1.0,
    bool debugPaint = false,
  }) {
    RenderObject repaintBoundary = renderObject;
    while (repaintBoundary != null && !repaintBoundary.isRepaintBoundary) {
      repaintBoundary = repaintBoundary.parent;
    }
    assert(repaintBoundary != null);
    final _ScreenshotData data = _ScreenshotData(target: renderObject);
    final _ScreenshotPaintingContext context = _ScreenshotPaintingContext(
      containerLayer: repaintBoundary.debugLayer,
      estimatedBounds: repaintBoundary.paintBounds,
      screenshotData: data,
    );

    if (identical(renderObject, repaintBoundary)) {
      // Painting the existing repaint boundary to the screenshot is sufficient.
      // We don't just take a direct screenshot of the repaint boundary as we
      // want to capture debugPaint information as well.
      data.containerLayer.append(_ProxyLayer(repaintBoundary.layer));
      data.foundTarget = true;
      data.screenshotOffset = repaintBoundary.layer.offset;
    } else {
      // Repaint everything under the repaint boundary.
      // We call debugInstrumentRepaintCompositedChild instead of paintChild as
      // we need to force everything under the repaint boundary to repaint.
      PaintingContext.debugInstrumentRepaintCompositedChild(
        repaintBoundary,
        customContext: context,
      );
    }

    // The check that debugPaintSizeEnabled is false exists to ensure we only
    // call debugPaint when it wasn't already called.
    if (debugPaint && !debugPaintSizeEnabled) {
      data.includeInRegularContext = false;
      // Existing recording may be to a canvas that draws to both the normal and
      // screenshot canvases.
      context.stopRecordingIfNeeded();
      assert(data.foundTarget);
      data.includeInScreenshot = true;

      debugPaintSizeEnabled = true;
      try {
        renderObject.debugPaint(context, data.screenshotOffset);
      } finally {
        debugPaintSizeEnabled = false;
        context.stopRecordingIfNeeded();
      }
    }

    // We must build the regular scene before we can build the screenshot
    // scene as building the screenshot scene assumes addToScene has already
    // been called successfully for all layers in the regular scene.
    repaintBoundary.layer.addToScene(ui.SceneBuilder());

    return data.containerLayer.toImage(renderBounds, pixelRatio: pixelRatio);
  }
}

/// A class describing a step along a path through a tree of [DiagnosticsNode]
/// objects.
///
/// This class is used to bundle all data required to display the tree with just
/// the nodes along a path expanded into a single JSON payload.
class _DiagnosticsPathNode {
  /// Creates a full description of a step in a path through a tree of
  /// [DiagnosticsNode] objects.
  ///
  /// The [node] and [child] arguments must not be null.
  _DiagnosticsPathNode({ @required this.node, @required this.children, this.childIndex }) : assert(node != null), assert(children != null);

  /// Node at the point in the path this [_DiagnosticsPathNode] is describing.
  final DiagnosticsNode node;

  /// Children of the [node] being described.
  ///
  /// This value is cached instead of relying on `node.getChildren()` as that
  /// method call might create new [DiagnosticsNode] objects for each child
  /// and we would prefer to use the identical [DiagnosticsNode] for each time
  /// a node exists in the path.
  final List<DiagnosticsNode> children;

  /// Index of the child that the path continues on.
  ///
  /// Equal to `null` if the path does not continue.
  final int childIndex;
}

List<_DiagnosticsPathNode> _followDiagnosticableChain(List<Diagnosticable> chain, {
  String name,
  DiagnosticsTreeStyle style,
}) {
  final List<_DiagnosticsPathNode> path = <_DiagnosticsPathNode>[];
  if (chain.isEmpty)
    return path;
  DiagnosticsNode diagnostic = chain.first.toDiagnosticsNode(name: name, style: style);
  for (int i = 1; i < chain.length; i += 1) {
    final Diagnosticable target = chain[i];
    bool foundMatch = false;
    final List<DiagnosticsNode> children = diagnostic.getChildren();
    for (int j = 0; j < children.length; j += 1) {
      final DiagnosticsNode child = children[j];
      if (child.value == target) {
        foundMatch = true;
        path.add(_DiagnosticsPathNode(
          node: diagnostic,
          children: children,
          childIndex: j,
        ));
        diagnostic = child;
        break;
      }
    }
    assert(foundMatch);
  }
  path.add(_DiagnosticsPathNode(node: diagnostic, children: diagnostic.getChildren()));
  return path;
}

/// Signature for the selection change callback used by
/// [WidgetInspectorService.selectionChangedCallback].
typedef InspectorSelectionChangedCallback = void Function();

/// Structure to help reference count Dart objects referenced by a GUI tool
/// using [WidgetInspectorService].
class _InspectorReferenceData {
  _InspectorReferenceData(this.object);

  final Object object;
  int count = 1;
}

/// Configuration controlling how [DiagnosticsNode] objects are serialized to
/// JSON mainly focused on if and how children are included in the JSON.
class _SerializeConfig {
  _SerializeConfig({
    @required this.groupName,
    this.summaryTree = false,
    this.subtreeDepth  = 1,
    this.pathToInclude,
    this.includeProperties = false,
    this.expandPropertyValues = true,
  });

  _SerializeConfig.merge(
    _SerializeConfig base, {
    int subtreeDepth,
    Iterable<Diagnosticable> pathToInclude,
  }) :
    groupName = base.groupName,
    summaryTree = base.summaryTree,
    subtreeDepth = subtreeDepth ?? base.subtreeDepth,
    pathToInclude = pathToInclude ?? base.pathToInclude,
    includeProperties = base.includeProperties,
    expandPropertyValues = base.expandPropertyValues;

  final String groupName;

  /// Whether to only include children that would exist in the summary tree.
  final bool summaryTree;

  /// How many levels of children to include in the JSON payload.
  final int subtreeDepth;

  /// Path of nodes through the children of this node to include even if
  /// subtreeDepth is exceeded.
  final Iterable<Diagnosticable> pathToInclude;

  /// Include information about properties in the JSON instead of requiring
  /// a separate request to determine properties.
  final bool includeProperties;

  /// Expand children of properties that have values that are themselves
  /// Diagnosticable objects.
  final bool expandPropertyValues;
}

// Production implementation of [WidgetInspectorService].
class _WidgetInspectorService = Object with WidgetInspectorService;

/// Service used by GUI tools to interact with the [WidgetInspector].
///
/// Calls to this object are typically made from GUI tools such as the [Flutter
/// IntelliJ Plugin](https://github.com/flutter/flutter-intellij/blob/master/README.md)
/// using the [Dart VM Service protocol](https://github.com/dart-lang/sdk/blob/master/runtime/vm/service/service.md).
/// This class uses its own object id and manages object lifecycles itself
/// instead of depending on the [object ids](https://github.com/dart-lang/sdk/blob/master/runtime/vm/service/service.md#getobject)
/// specified by the VM Service Protocol because the VM Service Protocol ids
/// expire unpredictably. Object references are tracked in groups so that tools
/// that clients can use dereference all objects in a group with a single
/// operation making it easier to avoid memory leaks.
///
/// All methods in this class are appropriate to invoke from debugging tools
/// using the Observatory service protocol to evaluate Dart expressions of the
/// form `WidgetInspectorService.instance.methodName(arg1, arg2, ...)`. If you
/// make changes to any instance method of this class you need to verify that
/// the [Flutter IntelliJ Plugin](https://github.com/flutter/flutter-intellij/blob/master/README.md)
/// widget inspector support still works with the changes.
///
/// All methods returning String values return JSON.
mixin WidgetInspectorService {
  /// Ring of cached JSON values to prevent json from being garbage
  /// collected before it can be requested over the Observatory protocol.
  final List<String> _serializeRing = List<String>(20);
  int _serializeRingIndex = 0;

  /// The current [WidgetInspectorService].
  static WidgetInspectorService get instance => _instance;
  static WidgetInspectorService _instance = _WidgetInspectorService();
  @protected
  static set instance(WidgetInspectorService instance) {
    _instance = instance;
  }

  static bool _debugServiceExtensionsRegistered = false;

  /// Ground truth tracking what object(s) are currently selected used by both
  /// GUI tools such as the Flutter IntelliJ Plugin and the [WidgetInspector]
  /// displayed on the device.
  final InspectorSelection selection = InspectorSelection();

  /// Callback typically registered by the [WidgetInspector] to receive
  /// notifications when [selection] changes.
  ///
  /// The Flutter IntelliJ Plugin does not need to listen for this event as it
  /// instead listens for `dart:developer` `inspect` events which also trigger
  /// when the inspection target changes on device.
  InspectorSelectionChangedCallback selectionChangedCallback;

  /// The Observatory protocol does not keep alive object references so this
  /// class needs to manually manage groups of objects that should be kept
  /// alive.
  final Map<String, Set<_InspectorReferenceData>> _groups = <String, Set<_InspectorReferenceData>>{};
  final Map<String, _InspectorReferenceData> _idToReferenceData = <String, _InspectorReferenceData>{};
  final Map<Object, String> _objectToId = Map<Object, String>.identity();
  int _nextId = 0;

  List<String> _pubRootDirectories;

  _RegisterServiceExtensionCallback _registerServiceExtensionCallback;
  /// Registers a service extension method with the given name (full
  /// name "ext.flutter.inspector.name").
  ///
  /// The given callback is called when the extension method is called. The
  /// callback must return a value that can be converted to JSON using
  /// `json.encode()` (see [JsonEncoder]). The return value is stored as a
  /// property named `result` in the JSON. In case of failure, the failure is
  /// reported to the remote caller and is dumped to the logs.
  @protected
  void registerServiceExtension({
    @required String name,
    @required ServiceExtensionCallback callback,
  }) {
    _registerServiceExtensionCallback(
      name: 'inspector.$name',
      callback: callback,
    );
  }

  /// Registers a service extension method with the given name (full
  /// name "ext.flutter.inspector.name"), which takes no arguments.
  void _registerSignalServiceExtension({
    @required String name,
    @required FutureOr<Object> callback(),
  }) {
    registerServiceExtension(
      name: name,
      callback: (Map<String, String> parameters) async {
        return <String, Object>{'result': await callback()};
      },
    );
  }

  /// Registers a service extension method with the given name (full
  /// name "ext.flutter.inspector.name"), which takes a single required argument
  /// "objectGroup" specifying what group is used to manage lifetimes of
  /// object references in the returned JSON (see [disposeGroup]).
  void _registerObjectGroupServiceExtension({
    @required String name,
    @required FutureOr<Object> callback(String objectGroup),
  }) {
    registerServiceExtension(
      name: name,
      callback: (Map<String, String> parameters) async {
        assert(parameters.containsKey('objectGroup'));
        return <String, Object>{'result': await callback(parameters['objectGroup'])};
      },
    );
  }

  /// Registers a service extension method with the given name (full
  /// name "ext.flutter.inspector.name"), which takes a single argument
  /// "enabled" which can have the value "true" or the value "false"
  /// or can be omitted to read the current value. (Any value other
  /// than "true" is considered equivalent to "false". Other arguments
  /// are ignored.)
  ///
  /// Calls the `getter` callback to obtain the value when
  /// responding to the service extension method being called.
  ///
  /// Calls the `setter` callback with the new value when the
  /// service extension method is called with a new value.
  void _registerBoolServiceExtension({
    @required String name,
    @required AsyncValueGetter<bool> getter,
    @required AsyncValueSetter<bool> setter
  }) {
    assert(name != null);
    assert(getter != null);
    assert(setter != null);
    registerServiceExtension(
      name: name,
      callback: (Map<String, String> parameters) async {
        if (parameters.containsKey('enabled'))
          await setter(parameters['enabled'] == 'true');
        return <String, dynamic>{ 'enabled': await getter() ? 'true' : 'false' };
      },
    );
  }

  /// Registers a service extension method with the given name (full
  /// name "ext.flutter.inspector.name") which takes an optional parameter named
  /// "arg" and a required parameter named "objectGroup" used to control the
  /// lifetimes of object references in the returned JSON (see [disposeGroup]).
  void _registerServiceExtensionWithArg({
    @required String name,
    @required FutureOr<Object> callback(String objectId, String objectGroup),
  }) {
    registerServiceExtension(
      name: name,
      callback: (Map<String, String> parameters) async {
        assert(parameters.containsKey('objectGroup'));
        return <String, Object>{
          'result': await callback(parameters['arg'], parameters['objectGroup']),
        };
      },
    );
  }

  /// Registers a service extension method with the given name (full
  /// name "ext.flutter.inspector.name"), that takes arguments
  /// "arg0", "arg1", "arg2", ..., "argn".
  void _registerServiceExtensionVarArgs({
    @required String name,
    @required FutureOr<Object> callback(List<String> args),
  }) {
    registerServiceExtension(
      name: name,
      callback: (Map<String, String> parameters) async {
        const String argPrefix = 'arg';
        final List<String> args = <String>[];
        parameters.forEach((String name, String value) {
          if (name.startsWith(argPrefix)) {
            final int index = int.parse(name.substring(argPrefix.length));
            if (index >= args.length) {
              args.length = index + 1;
            }
            args[index] = value;
          }
        });
        return <String, Object>{'result': await callback(args)};
      },
    );
  }

  /// Cause the entire tree to be rebuilt. This is used by development tools
  /// when the application code has changed and is being hot-reloaded, to cause
  /// the widget tree to pick up any changed implementations.
  ///
  /// This is expensive and should not be called except during development.
  @protected
  Future<void> forceRebuild() {
    final WidgetsBinding binding = WidgetsBinding.instance;
    if (binding.renderViewElement != null) {
      binding.buildOwner.reassemble(binding.renderViewElement);
      return binding.endOfFrame;
    }
    return Future<void>.value();
  }

  /// Called to register service extensions.
  ///
  /// See also:
  ///
  ///  * <https://github.com/dart-lang/sdk/blob/master/runtime/vm/service/service.md#rpcs-requests-and-responses>
  ///  * [BindingBase.initServiceExtensions], which explains when service
  ///    extensions can be used.
  void initServiceExtensions(
      _RegisterServiceExtensionCallback registerServiceExtensionCallback) {
    _registerServiceExtensionCallback = registerServiceExtensionCallback;
    assert(!_debugServiceExtensionsRegistered);
    assert(() { _debugServiceExtensionsRegistered = true; return true; }());

    _registerBoolServiceExtension(
      name: 'show',
      getter: () async => WidgetsApp.debugShowWidgetInspectorOverride,
      setter: (bool value) {
        if (WidgetsApp.debugShowWidgetInspectorOverride == value) {
          return Future<void>.value();
        }
        WidgetsApp.debugShowWidgetInspectorOverride = value;
        return forceRebuild();
      },
    );

    _registerSignalServiceExtension(
      name: 'disposeAllGroups',
      callback: disposeAllGroups,
    );
    _registerObjectGroupServiceExtension(
      name: 'disposeGroup',
      callback: disposeGroup,
    );
    _registerSignalServiceExtension(
      name: 'isWidgetTreeReady',
      callback: isWidgetTreeReady,
    );
    _registerServiceExtensionWithArg(
      name: 'disposeId',
      callback: disposeId,
    );
    _registerServiceExtensionVarArgs(
      name: 'setPubRootDirectories',
      callback: setPubRootDirectories,
    );
    _registerServiceExtensionWithArg(
      name: 'setSelectionById',
      callback: setSelectionById,
    );
    _registerServiceExtensionWithArg(
      name: 'getParentChain',
      callback: _getParentChain,
    );
    _registerServiceExtensionWithArg(
      name: 'getProperties',
      callback: _getProperties,
    );
    _registerServiceExtensionWithArg(
      name: 'getChildren',
      callback: _getChildren,
    );

    _registerServiceExtensionWithArg(
      name: 'getChildrenSummaryTree',
      callback: _getChildrenSummaryTree,
    );

    _registerServiceExtensionWithArg(
      name: 'getChildrenDetailsSubtree',
      callback: _getChildrenDetailsSubtree,
    );

    _registerObjectGroupServiceExtension(
      name: 'getRootWidget',
      callback: _getRootWidget,
    );
    _registerObjectGroupServiceExtension(
      name: 'getRootRenderObject',
      callback: _getRootRenderObject,
    );
    _registerObjectGroupServiceExtension(
      name: 'getRootWidgetSummaryTree',
      callback: _getRootWidgetSummaryTree,
    );

    _registerServiceExtensionWithArg(
      name: 'getDetailsSubtree',
      callback: _getDetailsSubtree,
    );
    _registerServiceExtensionWithArg(
      name: 'getSelectedRenderObject',
      callback: _getSelectedRenderObject,
    );
    _registerServiceExtensionWithArg(
      name: 'getSelectedWidget',
      callback: _getSelectedWidget,
    );
    _registerServiceExtensionWithArg(
      name: 'getSelectedSummaryWidget',
      callback: _getSelectedSummaryWidget,
    );

    _registerSignalServiceExtension(
      name: 'isWidgetCreationTracked',
      callback: isWidgetCreationTracked,
    );
    registerServiceExtension(
      name: 'screenshot',
      callback: (Map<String, String> parameters) async {
        assert(parameters.containsKey('id'));
        assert(parameters.containsKey('width'));
        assert(parameters.containsKey('height'));

        final ui.Image image = await screenshot(
          toObject(parameters['id']),
          width: double.parse(parameters['width']),
          height: double.parse(parameters['height']),
          margin: parameters.containsKey('margin') ?
              double.parse(parameters['margin']) : 0.0,
          maxPixelRatio: parameters.containsKey('maxPixelRatio') ?
              double.parse(parameters['maxPixelRatio']) : 1.0,
          debugPaint: parameters['debugPaint'] == 'true',
        );
        if (image == null) {
          return <String, Object>{'result': null};
        }
        final ByteData byteData = await image.toByteData(format:ui.ImageByteFormat.png);

        return <String, Object>{
          'result': base64.encoder.convert(Uint8List.view(byteData.buffer)),
        };
      },
    );
  }

  /// Clear all InspectorService object references.
  ///
  /// Use this method only for testing to ensure that object references from one
  /// test case do not impact other test cases.
  @protected
  void disposeAllGroups() {
    _groups.clear();
    _idToReferenceData.clear();
    _objectToId.clear();
    _nextId = 0;
  }

  /// Free all references to objects in a group.
  ///
  /// Objects and their associated ids in the group may be kept alive by
  /// references from a different group.
  @protected
  void disposeGroup(String name) {
    final Set<_InspectorReferenceData> references = _groups.remove(name);
    if (references == null)
      return;
    references.forEach(_decrementReferenceCount);
  }

  void _decrementReferenceCount(_InspectorReferenceData reference) {
    reference.count -= 1;
    assert(reference.count >= 0);
    if (reference.count == 0) {
      final String id = _objectToId.remove(reference.object);
      assert(id != null);
      _idToReferenceData.remove(id);
    }
  }

  /// Returns a unique id for [object] that will remain live at least until
  /// [disposeGroup] is called on [groupName] or [dispose] is called on the id
  /// returned by this method.
  @protected
  String toId(Object object, String groupName) {
    if (object == null)
      return null;

    final Set<_InspectorReferenceData> group = _groups.putIfAbsent(groupName, () => Set<_InspectorReferenceData>.identity());
    String id = _objectToId[object];
    _InspectorReferenceData referenceData;
    if (id == null) {
      id = 'inspector-$_nextId';
      _nextId += 1;
      _objectToId[object] = id;
      referenceData = _InspectorReferenceData(object);
      _idToReferenceData[id] = referenceData;
      group.add(referenceData);
    } else {
      referenceData = _idToReferenceData[id];
      if (group.add(referenceData))
        referenceData.count += 1;
    }
    return id;
  }

  /// Returns whether the application has rendered its first frame and it is
  /// appropriate to display the Widget tree in the inspector.
  @protected
  bool isWidgetTreeReady([String groupName]) {
    return WidgetsBinding.instance != null &&
           WidgetsBinding.instance.debugDidSendFirstFrameEvent;
  }

  /// Returns the Dart object associated with a reference id.
  ///
  /// The `groupName` parameter is not required by is added to regularize the
  /// API surface of the methods in this class called from the Flutter IntelliJ
  /// Plugin.
  @protected
  Object toObject(String id, [String groupName]) {
    if (id == null)
      return null;

    final _InspectorReferenceData data = _idToReferenceData[id];
    if (data == null) {
      throw FlutterError('Id does not exist.');
    }
    return data.object;
  }

  /// Returns the object to introspect to determine the source location of an
  /// object's class.
  ///
  /// The Dart object for the id is returned for all cases but [Element] objects
  /// where the [Widget] configuring the [Element] is returned instead as the
  /// class of the [Widget] is more relevant than the class of the [Element].
  ///
  /// The `groupName` parameter is not required by is added to regularize the
  /// API surface of methods called from the Flutter IntelliJ Plugin.
  @protected
  Object toObjectForSourceLocation(String id, [String groupName]) {
    final Object object = toObject(id);
    if (object is Element) {
      return object.widget;
    }
    return object;
  }

  /// Remove the object with the specified `id` from the specified object
  /// group.
  ///
  /// If the object exists in other groups it will remain alive and the object
  /// id will remain valid.
  @protected
  void disposeId(String id, String groupName) {
    if (id == null)
      return;

    final _InspectorReferenceData referenceData = _idToReferenceData[id];
    if (referenceData == null)
      throw FlutterError('Id does not exist');
    if (_groups[groupName]?.remove(referenceData) != true)
      throw FlutterError('Id is not in group');
    _decrementReferenceCount(referenceData);
  }

  /// Set the list of directories that should be considered part of the local
  /// project.
  ///
  /// The local project directories are used to distinguish widgets created by
  /// the local project over widgets created from inside the framework.
  @protected
  void setPubRootDirectories(List<Object> pubRootDirectories) {
    _pubRootDirectories = pubRootDirectories.map<String>(
      (Object directory) => Uri.parse(directory).path,
    ).toList();
  }

  /// Set the [WidgetInspector] selection to the object matching the specified
  /// id if the object is valid object to set as the inspector selection.
  ///
  /// Returns `true` if the selection was changed.
  ///
  /// The `groupName` parameter is not required by is added to regularize the
  /// API surface of methods called from the Flutter IntelliJ Plugin.
  @protected
  bool setSelectionById(String id, [String groupName]) {
    return setSelection(toObject(id), groupName);
  }

  /// Set the [WidgetInspector] selection to the specified `object` if it is
  /// a valid object to set as the inspector selection.
  ///
  /// Returns `true` if the selection was changed.
  ///
  /// The `groupName` parameter is not needed but is specified to regularize the
  /// API surface of methods called from the Flutter IntelliJ Plugin.
  @protected
  bool setSelection(Object object, [String groupName]) {
    if (object is Element || object is RenderObject) {
      if (object is Element) {
        if (object == selection.currentElement) {
          return false;
        }
        selection.currentElement = object;
      } else {
        if (object == selection.current) {
          return false;
        }
        selection.current = object;
      }
      if (selectionChangedCallback != null) {
        if (WidgetsBinding.instance.schedulerPhase == SchedulerPhase.idle) {
          selectionChangedCallback();
        } else {
          // It isn't safe to trigger the selection change callback if we are in
          // the middle of rendering the frame.
          SchedulerBinding.instance.scheduleTask(
            selectionChangedCallback,
            Priority.touch,
          );
        }
      }
      return true;
    }
    return false;
  }

  /// Returns JSON representing the chain of [DiagnosticsNode] instances from
  /// root of thee tree to the [Element] or [RenderObject] matching `id`.
  ///
  /// The JSON contains all information required to display a tree view with
  /// all nodes other than nodes along the path collapsed.
  @protected
  String getParentChain(String id, String groupName) {
    return _safeJsonEncode(_getParentChain(id, groupName));
  }

  List<Object> _getParentChain(String id, String groupName) {
    final Object value = toObject(id);
    List<_DiagnosticsPathNode> path;
    if (value is RenderObject)
      path = _getRenderObjectParentChain(value, groupName);
    else if (value is Element)
      path = _getElementParentChain(value, groupName);
    else
      throw FlutterError('Cannot get parent chain for node of type ${value.runtimeType}');

    return path.map<Object>((_DiagnosticsPathNode node) => _pathNodeToJson(
      node,
      _SerializeConfig(groupName: groupName),
    )).toList();
  }

  Map<String, Object> _pathNodeToJson(_DiagnosticsPathNode pathNode, _SerializeConfig config) {
    if (pathNode == null)
      return null;
    return <String, Object>{
      'node': _nodeToJson(pathNode.node, config),
      'children': _nodesToJson(pathNode.children, config),
      'childIndex': pathNode.childIndex,
    };
  }

  List<Element> _getRawElementParentChain(Element element, {int numLocalParents}) {
    List<Element> elements = element?.debugGetDiagnosticChain();
    if (numLocalParents != null) {
      for (int i = 0; i < elements.length; i += 1) {
        if (_isValueCreatedByLocalProject(elements[i])) {
          numLocalParents--;
          if (numLocalParents <= 0) {
            elements = elements.take(i + 1).toList();
            break;
          }
        }
      }
    }
    return elements?.reversed?.toList();
  }

  List<_DiagnosticsPathNode> _getElementParentChain(Element element, String groupName, {int numLocalParents}) {
    return _followDiagnosticableChain(
      _getRawElementParentChain(element, numLocalParents: numLocalParents),
    ) ?? const <_DiagnosticsPathNode>[];
  }

  List<_DiagnosticsPathNode> _getRenderObjectParentChain(RenderObject renderObject, String groupName, {int maxparents}) {
    final List<RenderObject> chain = <RenderObject>[];
    while (renderObject != null) {
      chain.add(renderObject);
      renderObject = renderObject.parent;
    }
    return _followDiagnosticableChain(chain.reversed.toList());
  }

  Map<String, Object> _nodeToJson(
    DiagnosticsNode node,
    _SerializeConfig config,
  ) {
    if (node == null)
      return null;
    final Map<String, Object> json = node.toJsonMap();

    json['objectId'] = toId(node, config.groupName);
    final Object value = node.value;
    json['valueId'] = toId(value, config.groupName);

    if (config.summaryTree) {
      json['summaryTree'] = true;
    }

    final _Location creationLocation = _getCreationLocation(value);
    bool createdByLocalProject = false;
    if (creationLocation != null) {
      json['creationLocation'] = creationLocation.toJsonMap();
      if (_isLocalCreationLocation(creationLocation)) {
        createdByLocalProject = true;
        json['createdByLocalProject'] = true;
      }
    }

    if (config.subtreeDepth > 0 ||
        (config.pathToInclude != null && config.pathToInclude.isNotEmpty)) {
      json['children'] = _nodesToJson(_getChildrenHelper(node, config), config);
    }

    if (config.includeProperties) {
      json['properties'] = _nodesToJson(
        node.getProperties().where(
          (DiagnosticsNode node) => !node.isFiltered(createdByLocalProject ? DiagnosticLevel.fine : DiagnosticLevel.info),
        ),
        _SerializeConfig(groupName: config.groupName, subtreeDepth: 1, expandPropertyValues: true),
      );
    }

    if (node is DiagnosticsProperty) {
      // Add additional information about properties needed for graphical
      // display of properties.
      if (value is Color) {
        json['valueProperties'] = <String, Object>{
          'red': value.red,
          'green': value.green,
          'blue': value.blue,
          'alpha': value.alpha,
        };
      } else if (value is IconData) {
        json['valueProperties'] = <String, Object>{
          'codePoint': value.codePoint,
        };
      }
      if (config.expandPropertyValues && value is Diagnosticable) {
        json['properties'] = _nodesToJson(
          value.toDiagnosticsNode().getProperties().where(
                (DiagnosticsNode node) => !node.isFiltered(DiagnosticLevel.info),
          ),
          _SerializeConfig(groupName: config.groupName,
              subtreeDepth: 0,
              expandPropertyValues: false,
          ),
        );
      }
    }
    return json;
  }

  bool _isValueCreatedByLocalProject(Object value) {
    final _Location creationLocation = _getCreationLocation(value);
    if (creationLocation == null) {
      return false;
    }
    return _isLocalCreationLocation(creationLocation);
  }

  bool _isLocalCreationLocation(_Location location) {
    if (_pubRootDirectories == null || location == null || location.file == null) {
      return false;
    }
    final String file = Uri.parse(location.file).path;
    for (String directory in _pubRootDirectories) {
      if (file.startsWith(directory)) {
        return true;
      }
    }
    return false;
  }

  /// Wrapper around `json.encode` that uses a ring of cached values to prevent
  /// the Dart garbage collector from collecting objects between when
  /// the value is returned over the Observatory protocol and when the
  /// separate observatory protocol command has to be used to retrieve its full
  /// contents.
  //
  // TODO(jacobr): Replace this with a better solution once
  // https://github.com/dart-lang/sdk/issues/32919 is fixed.
  String _safeJsonEncode(Object object) {
    final String jsonString = json.encode(object);
    _serializeRing[_serializeRingIndex] = jsonString;
    _serializeRingIndex = (_serializeRingIndex + 1)  % _serializeRing.length;
    return jsonString;
  }

  List<Map<String, Object>> _nodesToJson(
    Iterable<DiagnosticsNode> nodes,
    _SerializeConfig config,
  ) {
    if (nodes == null)
      return <Map<String, Object>>[];
    return nodes.map<Map<String, Object>>(
      (DiagnosticsNode node) {
        if (config.pathToInclude != null && config.pathToInclude.isNotEmpty) {
          if (config.pathToInclude.first == node.value) {
            return _nodeToJson(
              node,
              _SerializeConfig.merge(config, pathToInclude: config.pathToInclude.skip(1)),
            );
          } else {
            return _nodeToJson(node, _SerializeConfig.merge(config));
          }
        }
        // The tricky special case here is that when in the detailsTree,
        // we keep subtreeDepth from going down to zero until we reach nodes
        // that also exist in the summary tree. This ensures that every time
        // you expand a node in the details tree, you expand the entire subtree
        // up until you reach the next nodes shared with the summary tree.
        return _nodeToJson(
          node,
          config.summaryTree || config.subtreeDepth > 1 || _shouldShowInSummaryTree(node) ?
              _SerializeConfig.merge(config, subtreeDepth: config.subtreeDepth - 1) : config,
        );
      }).toList();
  }

  /// Returns a JSON representation of the properties of the [DiagnosticsNode]
  /// object that `diagnosticsNodeId` references.
  @protected
  String getProperties(String diagnosticsNodeId, String groupName) {
    return _safeJsonEncode(_getProperties(diagnosticsNodeId, groupName));
  }

  List<Object> _getProperties(String diagnosticsNodeId, String groupName) {
    final DiagnosticsNode node = toObject(diagnosticsNodeId);
    return _nodesToJson(node == null ? const <DiagnosticsNode>[] : node.getProperties(), _SerializeConfig(groupName: groupName));
  }

  /// Returns a JSON representation of the children of the [DiagnosticsNode]
  /// object that `diagnosticsNodeId` references.
  String getChildren(String diagnosticsNodeId, String groupName) {
    return _safeJsonEncode(_getChildren(diagnosticsNodeId, groupName));
  }

  List<Object> _getChildren(String diagnosticsNodeId, String groupName) {
    final DiagnosticsNode node = toObject(diagnosticsNodeId);
    final _SerializeConfig config = _SerializeConfig(groupName: groupName);
    return _nodesToJson(node == null ? const <DiagnosticsNode>[] : _getChildrenHelper(node, config), config);
  }

  /// Returns a JSON representation of the children of the [DiagnosticsNode]
  /// object that `diagnosticsNodeId` references only including children that
  /// were created directly by user code.
  ///
  /// Requires [Widget] creation locations which are only available for debug
  /// mode builds when the `--track-widget-creation` flag is passed to
  /// `flutter_tool`.
  ///
  /// See also:
  ///
  ///  * [isWidgetCreationTracked] which indicates whether this method can be
  ///    used.
  String getChildrenSummaryTree(String diagnosticsNodeId, String groupName) {
    return _safeJsonEncode(_getChildrenSummaryTree(diagnosticsNodeId, groupName));
  }

  List<Object> _getChildrenSummaryTree(String diagnosticsNodeId, String groupName) {
    final DiagnosticsNode node = toObject(diagnosticsNodeId);
    final _SerializeConfig config = _SerializeConfig(groupName: groupName, summaryTree: true);
    return _nodesToJson(node == null ? const <DiagnosticsNode>[] : _getChildrenHelper(node, config), config);
  }

  /// Returns a JSON representation of the children of the [DiagnosticsNode]
  /// object that `diagnosticsNodeId` references providing information needed
  /// for the details subtree view.
  ///
  /// The details subtree shows properties inline and includes all children
  /// rather than a filtered set of important children.
  String getChildrenDetailsSubtree(String diagnosticsNodeId, String groupName) {
    return _safeJsonEncode(_getChildrenDetailsSubtree(diagnosticsNodeId, groupName));
  }

  List<Object> _getChildrenDetailsSubtree(String diagnosticsNodeId, String groupName) {
    final DiagnosticsNode node = toObject(diagnosticsNodeId);
    // With this value of minDepth we only expand one extra level of important nodes.
    final _SerializeConfig config = _SerializeConfig(groupName: groupName, subtreeDepth: 1,  includeProperties: true);
    return _nodesToJson(node == null ? const <DiagnosticsNode>[] : _getChildrenHelper(node, config), config);
  }

  List<DiagnosticsNode> _getChildrenHelper(DiagnosticsNode node, _SerializeConfig config) {
    return _getChildrenFiltered(node, config).toList();
  }

  bool _shouldShowInSummaryTree(DiagnosticsNode node) {
    final Object value = node.value;
    if (value is! Diagnosticable) {
      return true;
    }
    if (value is! Element || !isWidgetCreationTracked()) {
      // Creation locations are not availabe so include all nodes in the
      // summary tree.
      return true;
    }
    return _isValueCreatedByLocalProject(value);
  }

  List<DiagnosticsNode> _getChildrenFiltered(
    DiagnosticsNode node,
    _SerializeConfig config,
  ) {
    final List<DiagnosticsNode> children = <DiagnosticsNode>[];
    for (DiagnosticsNode child in node.getChildren()) {
      if (!config.summaryTree || _shouldShowInSummaryTree(child)) {
        children.add(child);
      } else {
        children.addAll(_getChildrenFiltered(child, config));
      }
    }
    return children;
  }

  /// Returns a JSON representation of the [DiagnosticsNode] for the root
  /// [Element].
  String getRootWidget(String groupName) {
    return _safeJsonEncode(_getRootWidget(groupName));
  }

  Map<String, Object> _getRootWidget(String groupName) {
    return _nodeToJson(WidgetsBinding.instance?.renderViewElement?.toDiagnosticsNode(), _SerializeConfig(groupName: groupName));
  }

  /// Returns a JSON representation of the [DiagnosticsNode] for the root
  /// [Element] showing only nodes that should be included in a summary tree.
  String getRootWidgetSummaryTree(String groupName) {
    return _safeJsonEncode(_getRootWidgetSummaryTree(groupName));
  }

  Map<String, Object> _getRootWidgetSummaryTree(String groupName) {
    return _nodeToJson(
      WidgetsBinding.instance?.renderViewElement?.toDiagnosticsNode(),
      _SerializeConfig(groupName: groupName, subtreeDepth: 1000000, summaryTree: true),
    );
  }

  /// Returns a JSON representation of the [DiagnosticsNode] for the root
  /// [RenderObject].
  @protected
  String getRootRenderObject(String groupName) {
    return _safeJsonEncode(_getRootRenderObject(groupName));
  }

  Map<String, Object> _getRootRenderObject(String groupName) {
    return _nodeToJson(RendererBinding.instance?.renderView?.toDiagnosticsNode(), _SerializeConfig(groupName: groupName));
  }

  /// Returns a JSON representation of the subtree rooted at the
  /// [DiagnosticsNode] object that `diagnosticsNodeId` references providing
  /// information needed for the details subtree view.
  ///
  /// See also:
  ///  * [getChildrenDetailsSubtree], a method to get children of a node
  ///    in the details subtree.
  String getDetailsSubtree(String id, String groupName) {
    return _safeJsonEncode(_getDetailsSubtree( id, groupName));
  }

  Map<String, Object> _getDetailsSubtree(String id, String groupName) {
    final DiagnosticsNode root = toObject(id);
    if (root == null) {
      return null;
    }
    return _nodeToJson(
      root,
      _SerializeConfig(
        groupName: groupName,
        summaryTree: false,
        subtreeDepth: 2,  // TODO(jacobr): make subtreeDepth configurable.
        includeProperties: true,
      ),
    );
  }

  /// Returns a [DiagnosticsNode] representing the currently selected
  /// [RenderObject].
  ///
  /// If the currently selected [RenderObject] is identical to the
  /// [RenderObject] referenced by `previousSelectionId` then the previous
  /// [DiagnosticNode] is reused.
  @protected
  String getSelectedRenderObject(String previousSelectionId, String groupName) {
    return _safeJsonEncode(_getSelectedRenderObject(previousSelectionId, groupName));
  }

  Map<String, Object> _getSelectedRenderObject(String previousSelectionId, String groupName) {
    final DiagnosticsNode previousSelection = toObject(previousSelectionId);
    final RenderObject current = selection?.current;
    return _nodeToJson(current == previousSelection?.value ? previousSelection : current?.toDiagnosticsNode(), _SerializeConfig(groupName: groupName));
  }

  /// Returns a [DiagnosticsNode] representing the currently selected [Element].
  ///
  /// If the currently selected [Element] is identical to the [Element]
  /// referenced by `previousSelectionId` then the previous [DiagnosticNode] is
  /// reused.
  @protected
  String getSelectedWidget(String previousSelectionId, String groupName) {
    return _safeJsonEncode(_getSelectedWidget(previousSelectionId, groupName));
  }

  /// Captures an image of the current state of an [object] that is a
  /// [RenderObject] or [Element].
  ///
  /// The returned [ui.Image] has uncompressed raw RGBA bytes and will be scaled
  /// to be at most [width] pixels wide and [height] pixels tall. The returned
  /// image will never have a scale between logical pixels and the
  /// size of the output image larger than maxPixelRatio.
  /// [margin] indicates the number of pixels relative to the unscaled size of
  /// the [object] to include as a margin to include around the bounds of the
  /// [object] in the screenshot. Including a margin can be useful to capture
  /// areas that are slightly outside of the normal bounds of an object such as
  /// some debug paint information.
  @protected
  Future<ui.Image> screenshot(
    Object object, {
    @required double width,
    @required double height,
    double margin = 0.0,
    double maxPixelRatio = 1.0,
    bool debugPaint = false,
  }) async {
    if (object is! Element && object is! RenderObject) {
      return null;
    }
    final RenderObject renderObject = object is Element ? object.renderObject : object;
    if (renderObject == null || !renderObject.attached) {
      return null;
    }

    if (renderObject.debugNeedsLayout) {
      final PipelineOwner owner = renderObject.owner;
      assert(owner != null);
      assert(!owner.debugDoingLayout);
      owner
        ..flushLayout()
        ..flushCompositingBits()
        ..flushPaint();

      // If we still need layout, then that means that renderObject was skipped
      // in the layout phase and therefore can't be painted. It is clearer to
      // return null indicating that a screenshot is unavailable than to return
      // an empty image.
      if (renderObject.debugNeedsLayout) {
        return null;
      }
    }

    Rect renderBounds = _calculateSubtreeBounds(renderObject);
    if (margin != 0.0) {
      renderBounds = renderBounds.inflate(margin);
    }
    if (renderBounds.isEmpty) {
      return null;
    }

    final double pixelRatio = math.min(
      maxPixelRatio,
      math.min(
        width / renderBounds.width,
        height / renderBounds.height,
      ),
    );

    return _ScreenshotPaintingContext.toImage(
      renderObject,
      renderBounds,
      pixelRatio: pixelRatio,
      debugPaint: debugPaint,
    );
  }

  Map<String, Object> _getSelectedWidget(String previousSelectionId, String groupName) {
    final DiagnosticsNode previousSelection = toObject(previousSelectionId);
    final Element current = selection?.currentElement;
    return _nodeToJson(current == previousSelection?.value ? previousSelection : current?.toDiagnosticsNode(), _SerializeConfig(groupName: groupName));
  }

  /// Returns a [DiagnosticsNode] representing the currently selected [Element]
  /// if the selected [Element] should be shown in the summary tree otherwise
  /// returns the first ancestor of the selected [Element] shown in the summary
  /// tree.
  ///
  /// If the currently selected [Element] is identical to the [Element]
  /// referenced by `previousSelectionId` then the previous [DiagnosticNode] is
  /// reused.
  String getSelectedSummaryWidget(String previousSelectionId, String groupName) {
    return _safeJsonEncode(_getSelectedSummaryWidget(previousSelectionId, groupName));
  }

  Map<String, Object> _getSelectedSummaryWidget(String previousSelectionId, String groupName) {
    if (!isWidgetCreationTracked()) {
      return _getSelectedWidget(previousSelectionId, groupName);
    }
    final DiagnosticsNode previousSelection = toObject(previousSelectionId);
    Element current = selection?.currentElement;
    if (current != null && !_isValueCreatedByLocalProject(current)) {
      Element firstLocal;
      for (Element candidate in current.debugGetDiagnosticChain()) {
        if (_isValueCreatedByLocalProject(candidate)) {
          firstLocal = candidate;
          break;
        }
      }
      current = firstLocal;
    }
    return _nodeToJson(current == previousSelection?.value ? previousSelection : current?.toDiagnosticsNode(), _SerializeConfig(groupName: groupName));
  }

  /// Returns whether [Widget] creation locations are available.
  ///
  /// [Widget] creation locations are only available for debug mode builds when
  /// the `--track-widget-creation` flag is passed to `flutter_tool`. Dart 2.0
  /// is required as injecting creation locations requires a
  /// [Dart Kernel Transformer](https://github.com/dart-lang/sdk/wiki/Kernel-Documentation).
  @protected
  bool isWidgetCreationTracked() {
    _widgetCreationTracked ??= _WidgetForTypeTests() is _HasCreationLocation;
    return _widgetCreationTracked;
  }

  bool _widgetCreationTracked;
}

class _WidgetForTypeTests extends Widget {
  @override
  Element createElement() => null;
}

/// A widget that enables inspecting the child widget's structure.
///
/// Select a location on your device or emulator and view what widgets and
/// render object that best matches the location. An outline of the selected
/// widget and terse summary information is shown on device with detailed
/// information is shown in the observatory or in IntelliJ when using the
/// Flutter Plugin.
///
/// The inspector has a select mode and a view mode.
///
/// In the select mode, tapping the device selects the widget that best matches
/// the location of the touch and switches to view mode. Dragging a finger on
/// the device selects the widget under the drag location but does not switch
/// modes. Touching the very edge of the bounding box of a widget triggers
/// selecting the widget even if another widget that also overlaps that
/// location would otherwise have priority.
///
/// In the view mode, the previously selected widget is outlined, however,
/// touching the device has the same effect it would have if the inspector
/// wasn't present. This allows interacting with the application and viewing how
/// the selected widget changes position. Clicking on the select icon in the
/// bottom left corner of the application switches back to select mode.
class WidgetInspector extends StatefulWidget {
  /// Creates a widget that enables inspection for the child.
  ///
  /// The [child] argument must not be null.
  const WidgetInspector({
    Key key,
    @required this.child,
    @required this.selectButtonBuilder,
  }) : assert(child != null),
       super(key: key);

  /// The widget that is being inspected.
  final Widget child;

  /// A builder that is called to create the select button.
  ///
  /// The `onPressed` callback passed as an argument to the builder should be
  /// hooked up to the returned widget.
  final InspectorSelectButtonBuilder selectButtonBuilder;

  @override
  _WidgetInspectorState createState() => _WidgetInspectorState();
}

class _WidgetInspectorState extends State<WidgetInspector>
    with WidgetsBindingObserver {

  _WidgetInspectorState() : selection = WidgetInspectorService.instance.selection;

  Offset _lastPointerLocation;

  final InspectorSelection selection;

  /// Whether the inspector is in select mode.
  ///
  /// In select mode, pointer interactions trigger widget selection instead of
  /// normal interactions. Otherwise the previously selected widget is
  /// highlighted but the application can be interacted with normally.
  bool isSelectMode = true;

  final GlobalKey _ignorePointerKey = GlobalKey();

  /// Distance from the edge of of the bounding box for an element to consider
  /// as selecting the edge of the bounding box.
  static const double _edgeHitMargin = 2.0;

  InspectorSelectionChangedCallback _selectionChangedCallback;
  @override
  void initState() {
    super.initState();

    _selectionChangedCallback = () {
      setState(() {
        // The [selection] property which the build method depends on has
        // changed.
      });
    };
    assert(WidgetInspectorService.instance.selectionChangedCallback == null);
    WidgetInspectorService.instance.selectionChangedCallback = _selectionChangedCallback;
  }

  @override
  void dispose() {
    if (WidgetInspectorService.instance.selectionChangedCallback == _selectionChangedCallback) {
      WidgetInspectorService.instance.selectionChangedCallback = null;
    }
    super.dispose();
  }

  bool _hitTestHelper(
    List<RenderObject> hits,
    List<RenderObject> edgeHits,
    Offset position,
    RenderObject object,
    Matrix4 transform,
  ) {
    bool hit = false;
    final Matrix4 inverse = Matrix4.tryInvert(transform);
    if (inverse == null) {
      // We cannot invert the transform. That means the object doesn't appear on
      // screen and cannot be hit.
      return false;
    }
    final Offset localPosition = MatrixUtils.transformPoint(inverse, position);

    final List<DiagnosticsNode> children = object.debugDescribeChildren();
    for (int i = children.length - 1; i >= 0; i -= 1) {
      final DiagnosticsNode diagnostics = children[i];
      assert(diagnostics != null);
      if (diagnostics.style == DiagnosticsTreeStyle.offstage ||
          diagnostics.value is! RenderObject)
        continue;
      final RenderObject child = diagnostics.value;
      final Rect paintClip = object.describeApproximatePaintClip(child);
      if (paintClip != null && !paintClip.contains(localPosition))
        continue;

      final Matrix4 childTransform = transform.clone();
      object.applyPaintTransform(child, childTransform);
      if (_hitTestHelper(hits, edgeHits, position, child, childTransform))
        hit = true;
    }

    final Rect bounds = object.semanticBounds;
    if (bounds.contains(localPosition)) {
      hit = true;
      // Hits that occur on the edge of the bounding box of an object are
      // given priority to provide a way to select objects that would
      // otherwise be hard to select.
      if (!bounds.deflate(_edgeHitMargin).contains(localPosition))
        edgeHits.add(object);
    }
    if (hit)
      hits.add(object);
    return hit;
  }

  /// Returns the list of render objects located at the given position ordered
  /// by priority.
  ///
  /// All render objects that are not offstage that match the location are
  /// included in the list of matches. Priority is given to matches that occur
  /// on the edge of a render object's bounding box and to matches found by
  /// [RenderBox.hitTest].
  List<RenderObject> hitTest(Offset position, RenderObject root) {
    final List<RenderObject> regularHits = <RenderObject>[];
    final List<RenderObject> edgeHits = <RenderObject>[];

    _hitTestHelper(regularHits, edgeHits, position, root, root.getTransformTo(null));
    // Order matches by the size of the hit area.
    double _area(RenderObject object) {
      final Size size = object.semanticBounds?.size;
      return size == null ? double.maxFinite : size.width * size.height;
    }
    regularHits.sort((RenderObject a, RenderObject b) => _area(a).compareTo(_area(b)));
    final Set<RenderObject> hits = LinkedHashSet<RenderObject>();
    hits..addAll(edgeHits)..addAll(regularHits);
    return hits.toList();
  }

  void _inspectAt(Offset position) {
    if (!isSelectMode)
      return;

    final RenderIgnorePointer ignorePointer = _ignorePointerKey.currentContext.findRenderObject();
    final RenderObject userRender = ignorePointer.child;
    final List<RenderObject> selected = hitTest(position, userRender);

    setState(() {
      selection.candidates = selected;
    });
  }

  void _handlePanDown(DragDownDetails event) {
    _lastPointerLocation = event.globalPosition;
    _inspectAt(event.globalPosition);
  }

  void _handlePanUpdate(DragUpdateDetails event) {
    _lastPointerLocation = event.globalPosition;
    _inspectAt(event.globalPosition);
  }

  void _handlePanEnd(DragEndDetails details) {
    // If the pan ends on the edge of the window assume that it indicates the
    // pointer is being dragged off the edge of the display not a regular touch
    // on the edge of the display. If the pointer is being dragged off the edge
    // of the display we do not want to select anything. A user can still select
    // a widget that is only at the exact screen margin by tapping.
    final Rect bounds = (Offset.zero & (ui.window.physicalSize / ui.window.devicePixelRatio)).deflate(_kOffScreenMargin);
    if (!bounds.contains(_lastPointerLocation)) {
      setState(() {
        selection.clear();
      });
    }
  }

  void _handleTap() {
    if (!isSelectMode)
      return;
    if (_lastPointerLocation != null) {
      _inspectAt(_lastPointerLocation);

      if (selection != null) {
        // Notify debuggers to open an inspector on the object.
        developer.inspect(selection.current);
      }
    }
    setState(() {
      // Only exit select mode if there is a button to return to select mode.
      if (widget.selectButtonBuilder != null)
        isSelectMode = false;
    });
  }

  void _handleEnableSelect() {
    setState(() {
      isSelectMode = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> children = <Widget>[];
    children.add(GestureDetector(
      onTap: _handleTap,
      onPanDown: _handlePanDown,
      onPanEnd: _handlePanEnd,
      onPanUpdate: _handlePanUpdate,
      behavior: HitTestBehavior.opaque,
      excludeFromSemantics: true,
      child: IgnorePointer(
        ignoring: isSelectMode,
        key: _ignorePointerKey,
        ignoringSemantics: false,
        child: widget.child,
      ),
    ));
    if (!isSelectMode && widget.selectButtonBuilder != null) {
      children.add(Positioned(
        left: _kInspectButtonMargin,
        bottom: _kInspectButtonMargin,
        child: widget.selectButtonBuilder(context, _handleEnableSelect)
      ));
    }
    children.add(_InspectorOverlay(selection: selection));
    return Stack(children: children);
  }
}

/// Mutable selection state of the inspector.
class InspectorSelection {
  /// Render objects that are candidates to be selected.
  ///
  /// Tools may wish to iterate through the list of candidates.
  List<RenderObject> get candidates => _candidates;
  List<RenderObject> _candidates = <RenderObject>[];
  set candidates(List<RenderObject> value) {
    _candidates = value;
    _index = 0;
    _computeCurrent();
  }

  /// Index within the list of candidates that is currently selected.
  int get index => _index;
  int _index = 0;
  set index(int value) {
    _index = value;
    _computeCurrent();
  }

  /// Set the selection to empty.
  void clear() {
    _candidates = <RenderObject>[];
    _index = 0;
    _computeCurrent();
  }

  /// Selected render object typically from the [candidates] list.
  ///
  /// Setting [candidates] or calling [clear] resets the selection.
  ///
  /// Returns null if the selection is invalid.
  RenderObject get current => _current;
  RenderObject _current;
  set current(RenderObject value) {
    if (_current != value) {
      _current = value;
      _currentElement = value.debugCreator.element;
    }
  }

  /// Selected [Element] consistent with the [current] selected [RenderObject].
  ///
  /// Setting [candidates] or calling [clear] resets the selection.
  ///
  /// Returns null if the selection is invalid.
  Element get currentElement => _currentElement;
  Element _currentElement;
  set currentElement(Element element) {
    if (currentElement != element) {
      _currentElement = element;
      _current = element.findRenderObject();
    }
  }

  void _computeCurrent() {
    if (_index < candidates.length) {
      _current = candidates[index];
      _currentElement = _current.debugCreator.element;
    } else {
      _current = null;
      _currentElement = null;
    }
  }

  /// Whether the selected render object is attached to the tree or has gone
  /// out of scope.
  bool get active => _current != null && _current.attached;
}

class _InspectorOverlay extends LeafRenderObjectWidget {
  const _InspectorOverlay({
    Key key,
    @required this.selection,
  }) : super(key: key);

  final InspectorSelection selection;

  @override
  _RenderInspectorOverlay createRenderObject(BuildContext context) {
    return _RenderInspectorOverlay(selection: selection);
  }

  @override
  void updateRenderObject(BuildContext context, _RenderInspectorOverlay renderObject) {
    renderObject.selection = selection;
  }
}

class _RenderInspectorOverlay extends RenderBox {
  /// The arguments must not be null.
  _RenderInspectorOverlay({ @required InspectorSelection selection }) : _selection = selection, assert(selection != null);

  InspectorSelection get selection => _selection;
  InspectorSelection _selection;
  set selection(InspectorSelection value) {
    if (value != _selection) {
      _selection = value;
    }
    markNeedsPaint();
  }

  @override
  bool get sizedByParent => true;

  @override
  bool get alwaysNeedsCompositing => true;

  @override
  void performResize() {
    size = constraints.constrain(const Size(double.infinity, double.infinity));
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    assert(needsCompositing);
    context.addLayer(_InspectorOverlayLayer(
      overlayRect: Rect.fromLTWH(offset.dx, offset.dy, size.width, size.height),
      selection: selection,
    ));
  }
}

class _TransformedRect {
  _TransformedRect(RenderObject object) :
    rect = object.semanticBounds,
    transform = object.getTransformTo(null);

  final Rect rect;
  final Matrix4 transform;

  @override
  bool operator ==(dynamic other) {
    if (other.runtimeType != runtimeType)
      return false;
    final _TransformedRect typedOther = other;
    return rect == typedOther.rect && transform == typedOther.transform;
  }

  @override
  int get hashCode => hashValues(rect, transform);
}

/// State describing how the inspector overlay should be rendered.
///
/// The equality operator can be used to determine whether the overlay needs to
/// be rendered again.
class _InspectorOverlayRenderState {
  _InspectorOverlayRenderState({
    @required this.overlayRect,
    @required this.selected,
    @required this.candidates,
    @required this.tooltip,
    @required this.textDirection,
  });

  final Rect overlayRect;
  final _TransformedRect selected;
  final List<_TransformedRect> candidates;
  final String tooltip;
  final TextDirection textDirection;

  @override
  bool operator ==(dynamic other) {
    if (other.runtimeType != runtimeType)
      return false;

    final _InspectorOverlayRenderState typedOther = other;
    return overlayRect == typedOther.overlayRect
        && selected == typedOther.selected
        && listEquals<_TransformedRect>(candidates, typedOther.candidates)
        && tooltip == typedOther.tooltip;
  }

  @override
  int get hashCode => hashValues(overlayRect, selected, hashList(candidates), tooltip);
}

const int _kMaxTooltipLines = 5;
const Color _kTooltipBackgroundColor = Color.fromARGB(230, 60, 60, 60);
const Color _kHighlightedRenderObjectFillColor = Color.fromARGB(128, 128, 128, 255);
const Color _kHighlightedRenderObjectBorderColor = Color.fromARGB(128, 64, 64, 128);

/// A layer that outlines the selected [RenderObject] and candidate render
/// objects that also match the last pointer location.
///
/// This approach is horrific for performance and is only used here because this
/// is limited to debug mode. Do not duplicate the logic in production code.
class _InspectorOverlayLayer extends Layer {
  /// Creates a layer that displays the inspector overlay.
  _InspectorOverlayLayer({
    @required this.overlayRect,
    @required this.selection,
  }) : assert(overlayRect != null), assert(selection != null) {
    bool inDebugMode = false;
    assert(() {
      inDebugMode = true;
      return true;
    }());
    if (inDebugMode == false) {
      throw FlutterError(
        'The inspector should never be used in production mode due to the '
        'negative performance impact.'
      );
    }
  }

  InspectorSelection selection;

  /// The rectangle in this layer's coordinate system that the overlay should
  /// occupy.
  ///
  /// The scene must be explicitly recomposited after this property is changed
  /// (as described at [Layer]).
  final Rect overlayRect;

  _InspectorOverlayRenderState _lastState;

  /// Picture generated from _lastState.
  ui.Picture _picture;

  TextPainter _textPainter;
  double _textPainterMaxWidth;

  @override
  void addToScene(ui.SceneBuilder builder, [Offset layerOffset = Offset.zero]) {
    if (!selection.active)
      return;

    final RenderObject selected = selection.current;
    final List<_TransformedRect> candidates = <_TransformedRect>[];
    for (RenderObject candidate in selection.candidates) {
      if (candidate == selected || !candidate.attached)
        continue;
      candidates.add(_TransformedRect(candidate));
    }

    final _InspectorOverlayRenderState state = _InspectorOverlayRenderState(
      overlayRect: overlayRect,
      selected: _TransformedRect(selected),
      tooltip: selection.currentElement.toStringShort(),
      textDirection: TextDirection.ltr,
      candidates: candidates,
    );

    if (state != _lastState) {
      _lastState = state;
      _picture = _buildPicture(state);
    }
    builder.addPicture(layerOffset, _picture);
  }

  ui.Picture _buildPicture(_InspectorOverlayRenderState state) {
    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(recorder, state.overlayRect);
    final Size size = state.overlayRect.size;

    final Paint fillPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = _kHighlightedRenderObjectFillColor;

    final Paint borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..color = _kHighlightedRenderObjectBorderColor;

    // Highlight the selected renderObject.
    final Rect selectedPaintRect = state.selected.rect.deflate(0.5);
    canvas
      ..save()
      ..transform(state.selected.transform.storage)
      ..drawRect(selectedPaintRect, fillPaint)
      ..drawRect(selectedPaintRect, borderPaint)
      ..restore();

    // Show all other candidate possibly selected elements. This helps selecting
    // render objects by selecting the edge of the bounding box shows all
    // elements the user could toggle the selection between.
    for (_TransformedRect transformedRect in state.candidates) {
      canvas
        ..save()
        ..transform(transformedRect.transform.storage)
        ..drawRect(transformedRect.rect.deflate(0.5), borderPaint)
        ..restore();
    }

    final Rect targetRect = MatrixUtils.transformRect(
        state.selected.transform, state.selected.rect);
    final Offset target = Offset(targetRect.left, targetRect.center.dy);
    const double offsetFromWidget = 9.0;
    final double verticalOffset = (targetRect.height) / 2 + offsetFromWidget;

    _paintDescription(canvas, state.tooltip, state.textDirection, target, verticalOffset, size, targetRect);

    // TODO(jacobr): provide an option to perform a debug paint of just the
    // selected widget.
    return recorder.endRecording();
  }

  void _paintDescription(
    Canvas canvas,
    String message,
    TextDirection textDirection,
    Offset target,
    double verticalOffset,
    Size size,
    Rect targetRect,
  ) {
    canvas.save();
    final double maxWidth = size.width - 2 * (_kScreenEdgeMargin + _kTooltipPadding);
    if (_textPainter == null || _textPainter.text.text != message || _textPainterMaxWidth != maxWidth) {
      _textPainterMaxWidth = maxWidth;
      _textPainter = TextPainter()
        ..maxLines = _kMaxTooltipLines
        ..ellipsis = '...'
        ..text = TextSpan(style: _messageStyle, text: message)
        ..textDirection = textDirection
        ..layout(maxWidth: maxWidth);
    }

    final Size tooltipSize = _textPainter.size + const Offset(_kTooltipPadding * 2, _kTooltipPadding * 2);
    final Offset tipOffset = positionDependentBox(
      size: size,
      childSize: tooltipSize,
      target: target,
      verticalOffset: verticalOffset,
      preferBelow: false,
    );

    final Paint tooltipBackground = Paint()
      ..style = PaintingStyle.fill
      ..color = _kTooltipBackgroundColor;
    canvas.drawRect(
      Rect.fromPoints(
        tipOffset,
        tipOffset.translate(tooltipSize.width, tooltipSize.height),
      ),
      tooltipBackground,
    );

    double wedgeY = tipOffset.dy;
    final bool tooltipBelow = tipOffset.dy > target.dy;
    if (!tooltipBelow)
      wedgeY += tooltipSize.height;

    const double wedgeSize = _kTooltipPadding * 2;
    double wedgeX = math.max(tipOffset.dx, target.dx) + wedgeSize * 2;
    wedgeX = math.min(wedgeX, tipOffset.dx + tooltipSize.width - wedgeSize * 2);
    final List<Offset> wedge = <Offset>[
      Offset(wedgeX - wedgeSize, wedgeY),
      Offset(wedgeX + wedgeSize, wedgeY),
      Offset(wedgeX, wedgeY + (tooltipBelow ? -wedgeSize : wedgeSize)),
    ];
    canvas.drawPath(Path()..addPolygon(wedge, true,), tooltipBackground);
    _textPainter.paint(canvas, tipOffset + const Offset(_kTooltipPadding, _kTooltipPadding));
    canvas.restore();
  }

  @override
  S find<S>(Offset regionOffset) => null;
}

const double _kScreenEdgeMargin = 10.0;
const double _kTooltipPadding = 5.0;
const double _kInspectButtonMargin = 10.0;

/// Interpret pointer up events within with this margin as indicating the
/// pointer is moving off the device.
const double _kOffScreenMargin = 1.0;

const TextStyle _messageStyle = TextStyle(
  color: Color(0xFFFFFFFF),
  fontSize: 10.0,
  height: 1.2,
);

/// Interface for classes that track the source code location the their
/// constructor was called from.
///
/// A [Dart Kernel Transformer](https://github.com/dart-lang/sdk/wiki/Kernel-Documentation).
/// adds this interface to the [Widget] class when the
/// `--track-widget-creation` flag is passed to `flutter_tool`. Dart 2.0 is
/// required as injecting creation locations requires a
/// [Dart Kernel Transformer](https://github.com/dart-lang/sdk/wiki/Kernel-Documentation).
// ignore: unused_element
abstract class _HasCreationLocation {
  _Location get _location;
}

/// A tuple with file, line, and column number, for displaying human-readable
/// file locations.
class _Location {
  const _Location({
    this.file,
    this.line,
    this.column,
    this.name,
    this.parameterLocations
  });

  /// File path of the location.
  final String file;

  /// 1-based line number.
  final int line;
  /// 1-based column number.
  final int column;

  /// Optional name of the parameter or function at this location.
  final String name;

  /// Optional locations of the parameters of the member at this location.
  final List<_Location> parameterLocations;

  Map<String, Object> toJsonMap() {
    final Map<String, Object> json = <String, Object>{
      'file': file,
      'line': line,
      'column': column,
    };
    if (name != null) {
      json['name'] = name;
    }
    if (parameterLocations != null) {
      json['parameterLocations'] = parameterLocations.map<Map<String, Object>>(
          (_Location location) => location.toJsonMap()).toList();
    }
    return json;
  }

  @override
  String toString() {
    final List<String> parts = <String>[];
    if (name != null) {
      parts.add(name);
    }
    if (file != null) {
      parts.add(file);
    }
    parts..add('$line')..add('$column');
    return parts.join(':');
  }
}

/// Returns the creation location of an object if one is available.
///
/// Creation locations are only available for debug mode builds when
/// the `--track-widget-creation` flag is passed to `flutter_tool`. Dart 2.0 is
/// required as injecting creation locations requires a
/// [Dart Kernel Transformer](https://github.com/dart-lang/sdk/wiki/Kernel-Documentation).
///
/// Currently creation locations are only available for [Widget] and [Element]
_Location _getCreationLocation(Object object) {
  final Object candidate =  object is Element ? object.widget : object;
  return candidate is _HasCreationLocation ? candidate._location : null;
}
