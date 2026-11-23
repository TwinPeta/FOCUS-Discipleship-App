import 'dart:convert';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// One unexpected error the app caught.
class CrashEntry {
  const CrashEntry({
    required this.at,
    required this.error,
    required this.stack,
    required this.source,
  });

  final DateTime at;
  final String error;
  final String stack;

  /// 'flutter' (a framework/widget error) or 'async' (an uncaught one).
  final String source;

  Map<String, Object> toJson() => {
    'at': at.toIso8601String(),
    'error': error,
    'stack': stack,
    'source': source,
  };

  static CrashEntry? fromJson(Object? j) {
    if (j is! Map<String, dynamic>) return null;
    return CrashEntry(
      at: DateTime.tryParse((j['at'] as String?) ?? '') ?? DateTime(2000),
      error: (j['error'] as String?) ?? '',
      stack: (j['stack'] as String?) ?? '',
      source: (j['source'] as String?) ?? '',
    );
  }
}

/// The last [maxEntries] unexpected errors, kept on the phone (plain
/// preferences: no personal content, only error text and the top of the
/// stack), so a support request can include them. Installed by `main`.
class CrashLog {
  CrashLog(this._prefs);

  static const key = 'fcu.crash_log';
  static const maxEntries = 20;

  /// Lines of stack kept per entry.
  static const _stackLines = 12;

  final SharedPreferences? _prefs;

  List<CrashEntry> get entries {
    try {
      final raw = _prefs?.getString(key);
      if (raw == null) return const [];
      return [
        for (final j in jsonDecode(raw) as List)
          ?CrashEntry.fromJson(j),
      ];
    } catch (_) {
      return const [];
    }
  }

  void record(Object error, StackTrace? stack, {required String source}) {
    try {
      final entry = CrashEntry(
        at: DateTime.now(),
        error: '$error'.length > 500 ? '$error'.substring(0, 500) : '$error',
        stack: (stack?.toString() ?? '')
            .split('\n')
            .take(_stackLines)
            .join('\n'),
        source: source,
      );
      final kept = [...entries, entry];
      final trimmed = kept.length > maxEntries
          ? kept.sublist(kept.length - maxEntries)
          : kept;
      _prefs?.setString(
        key,
        jsonEncode([for (final e in trimmed) e.toJson()]),
      );
    } catch (_) {
      // Logging must never be the thing that fails.
    }
  }

  void clear() => _prefs?.remove(key);

  /// Catches what nothing else did:
  /// - framework errors (build, layout, paint) are reported as before and
  ///   recorded;
  /// - uncaught async errors are recorded and treated as handled, so the
  ///   app keeps running;
  /// - in release builds a widget that fails to build shows a small
  ///   "Something went wrong here" card instead of a grey box (debug
  ///   builds keep Flutter's red error screen).
  void install() {
    final previous = FlutterError.onError;
    FlutterError.onError = (details) {
      record(details.exception, details.stack, source: 'flutter');
      if (previous != null) {
        previous(details);
      } else {
        FlutterError.presentError(details);
      }
    };
    PlatformDispatcher.instance.onError = (error, stack) {
      record(error, stack, source: 'async');
      if (kDebugMode) debugPrint('Uncaught: $error\n$stack');
      return true;
    };
    if (kReleaseMode) ErrorWidget.builder = (_) => const BrokenPart();
  }
}

/// Shown in place of a part of a screen that failed to build (release).
/// Small and layout-safe: it may land in a tight spot such as a list row.
class BrokenPart extends StatelessWidget {
  const BrokenPart({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final roomy =
            constraints.maxWidth >= 160 && constraints.maxHeight >= 72;
        return Semantics(
          label: 'Something went wrong here',
          child: ColoredBox(
            color: AppColors.page,
            child: Center(
              child: roomy
                  ? Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.error_outline_rounded,
                            color: AppColors.muted,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              'Something went wrong here. '
                              'Go back and try again.',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.body.copyWith(
                                color: AppColors.muted,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  : Icon(
                      Icons.error_outline_rounded,
                      color: AppColors.muted,
                      size: 16,
                    ),
            ),
          ),
        );
      },
    );
  }
}
