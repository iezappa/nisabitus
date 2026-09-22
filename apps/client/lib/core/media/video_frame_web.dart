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
/// already there.
///
/// Three attributes here are the difference between a player and a blank
/// rectangle, and each one was a way this failed:
///
/// - `credentialless`. This app asks for cross-origin isolation so the
///   database can use OPFS, which means `Cross-Origin-Embedder-Policy:
///   require-corp`, which means every framed document must send that header
///   itself. YouTube sends it report-only, so the frame was refused before
///   it began. A credentialless frame is the exception written for exactly
///   this: it loads without the app's credentials, in its own ephemeral
///   storage, and isolation survives.
/// - `allow-same-origin`. Without it the frame is an opaque origin, where
///   reading `localStorage` throws — and a player whose first act is to
///   read its own settings dies there. It does not hand the frame anything
///   of this app's: the frame is cross-origin, so it keeps YouTube's origin
///   and can no more reach this one than any other tab could. Only a
///   same-origin frame could use it to drop its own sandbox.
/// - `referrerpolicy=strict-origin-when-cross-origin`. An embed is allowed
///   or refused by the site it is embedded on, and with no referrer at all
///   a video whose channel restricts embedding answers "unavailable". This
///   sends the origin and nothing more — not the path, which is the part
///   that would say what the user was doing.
///
/// What remains off is what a video does not need: no top-level navigation,
/// so a page cannot take the tab away from the app, and no forms, popups or
/// downloads.
Widget? buildVideoFrame(String url) {
  final viewType = 'video-frame-${url.hashCode}';

  if (_registered.add(viewType)) {
    ui_web.platformViewRegistry.registerViewFactory(viewType, (int _) {
      final frame = web.HTMLIFrameElement()
        ..src = url
        ..allow = 'accelerometer; autoplay; encrypted-media; picture-in-picture'
        ..allowFullscreen = true
        ..setAttribute(
          'sandbox',
          'allow-scripts allow-same-origin allow-presentation',
        )
        ..setAttribute('credentialless', '')
        ..setAttribute('referrerpolicy', 'strict-origin-when-cross-origin')
        ..style.border = 'none'
        ..style.width = '100%'
        ..style.height = '100%';

      return frame as JSAny;
    });
  }

  return HtmlElementView(viewType: viewType);
}
