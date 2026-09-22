import 'dart:js_interop';
import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

/// The view type is registered once per URL, because the registry keeps
/// whatever it was given the first time under a name.
final _registered = <String>{};

/// An `<iframe>` behind a Flutter widget, for the web build.
///
/// The one platform where showing a page costs nothing: the browser is
/// already there. The frame is sandboxed to what playing a video needs and
/// nothing else — no top-level navigation, so a page cannot take the tab
/// away from the app, and no same-origin, so it cannot reach this app's
/// storage.
Widget? buildVideoFrame(String url) {
  final viewType = 'video-frame-${url.hashCode}';

  if (_registered.add(viewType)) {
    ui_web.platformViewRegistry.registerViewFactory(viewType, (int _) {
      final frame = web.HTMLIFrameElement()
        ..src = url
        ..allow = 'accelerometer; encrypted-media; picture-in-picture'
        ..allowFullscreen = true
        ..setAttribute('sandbox', 'allow-scripts allow-presentation')
        ..setAttribute('referrerpolicy', 'no-referrer')
        ..style.border = 'none'
        ..style.width = '100%'
        ..style.height = '100%';

      return frame as JSAny;
    });
  }

  return HtmlElementView(viewType: viewType);
}
