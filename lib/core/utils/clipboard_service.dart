import 'dart:async';

import 'package:flutter/services.dart';

/// Copies text and schedules the clipboard to be cleared after the configured
/// number of seconds. A shared timer means quick successive copies reset the
/// countdown instead of tearing each other's text from the clipboard.
class ClipboardService {
  const ClipboardService._();

  static Timer? _clearTimer;

  static Future<void> copy(String text, {required int seconds}) async {
    final secs = seconds > 0 ? seconds : 30;
    await Clipboard.setData(ClipboardData(text: text));
    _clearTimer?.cancel();
    _clearTimer = Timer(Duration(seconds: secs), () {
      Clipboard.setData(const ClipboardData(text: ''));
    });
  }
}
