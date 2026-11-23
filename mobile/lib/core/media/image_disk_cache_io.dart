import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:material_ui/material_ui.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'image_disk_cache.dart';

ImageDiskCacheStore createImageDiskCache() => _FileCache();

class _FileCache implements ImageDiskCacheStore {
  Future<Directory?>? _dir;
  final http.Client _http = http.Client();

  /// Requests for the same photo share one download.
  final Map<String, Future<Uint8List>> _loading = {};

  Future<Directory?> get dir => _dir ??= () async {
    try {
      final base = await getTemporaryDirectory();
      final d = Directory(p.join(base.path, 'image_cache'));
      await d.create(recursive: true);
      return d;
    } catch (_) {
      return null; // no plugin (tests): download only
    }
  }();

  /// FNV-1a (64-bit) of the URL: a stable, file-safe name.
  static String nameFor(String url) {
    var hash = 0xcbf29ce484222325;
    for (final unit in url.codeUnits) {
      hash ^= unit;
      hash = hash * 0x100000001b3; // wraps at 64 bits
    }
    return hash.toUnsigned(64).toRadixString(16).padLeft(16, '0');
  }

  @override
  ImageProvider provider(String url) => _DiskImage(url, this);

  Future<Uint8List> bytes(String url) =>
      _loading[url] ??= _bytes(url).whenComplete(() => _loading.remove(url));

  Future<Uint8List> _bytes(String url) async {
    final d = await dir;
    final file = d == null ? null : File(p.join(d.path, nameFor(url)));
    if (file != null && await file.exists()) {
      try {
        final saved = await file.readAsBytes();
        if (saved.isNotEmpty) {
          // Recently used: kept longest by [trim].
          unawaited(file.setLastModified(DateTime.now()).catchError((_) {}));
          return saved;
        }
      } catch (_) {}
    }
    final response = await _http
        .get(Uri.parse(url))
        .timeout(const Duration(seconds: 30));
    if (response.statusCode != 200 || response.bodyBytes.isEmpty) {
      throw NetworkImageLoadException(
        statusCode: response.statusCode,
        uri: Uri.parse(url),
      );
    }
    final bytes = response.bodyBytes;
    if (file != null) {
      unawaited(
        file.writeAsBytes(bytes, flush: true).then((_) {}).catchError((_) {}),
      );
    }
    return bytes;
  }

  @override
  Future<void> trim() async {
    final d = await dir;
    if (d == null) return;
    try {
      final now = DateTime.now();
      final kept = <(File, DateTime, int)>[];
      await for (final entry in d.list()) {
        if (entry is! File) continue;
        final stat = await entry.stat();
        if (now.difference(stat.modified) > ImageDiskCache.maxAge) {
          await entry.delete();
        } else {
          kept.add((entry, stat.modified, stat.size));
        }
      }
      var total = kept.fold<int>(0, (sum, f) => sum + f.$3);
      if (total <= ImageDiskCache.maxBytes) return;
      kept.sort((a, b) => a.$2.compareTo(b.$2)); // oldest first
      for (final (file, _, size) in kept) {
        if (total <= ImageDiskCache.maxBytes) break;
        await file.delete();
        total -= size;
      }
    } catch (_) {}
  }
}

/// A server photo read from the phone's photo cache, or downloaded.
class _DiskImage extends ImageProvider<_DiskImage> {
  const _DiskImage(this.url, this.cache);

  final String url;
  final _FileCache cache;

  @override
  Future<_DiskImage> obtainKey(ImageConfiguration configuration) =>
      SynchronousFuture<_DiskImage>(this);

  @override
  ImageStreamCompleter loadImage(_DiskImage key, ImageDecoderCallback decode) =>
      MultiFrameImageStreamCompleter(
        codec: _load(decode),
        scale: 1.0,
        debugLabel: url,
        informationCollector: () => [DiagnosticsProperty('URL', url)],
      );

  Future<ui.Codec> _load(ImageDecoderCallback decode) async {
    final bytes = await cache.bytes(url);
    return decode(await ui.ImmutableBuffer.fromUint8List(bytes));
  }

  @override
  bool operator ==(Object other) => other is _DiskImage && other.url == url;

  @override
  int get hashCode => url.hashCode;

  @override
  String toString() => 'DiskImage("$url")';
}
