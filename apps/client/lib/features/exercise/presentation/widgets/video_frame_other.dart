import 'package:flutter/material.dart';

/// Nothing to frame off the web.
///
/// Android and the desktop builds have no browser to put a page in without
/// taking a webview dependency, and a webview is a whole engine shipped so a
/// card can hold a video. The viewer offers the link instead, which is what
/// those platforms do well: it opens in the app the user already watches
/// videos in, signed in, at the quality they chose.
Widget? buildVideoFrame(String url) => null;
