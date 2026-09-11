import 'dart:io';

import 'package:flutter_cache_manager/flutter_cache_manager.dart';

import 'parser.dart';

class SvgProvider {
  SvgProvider._(this.parser);
  final Future<SvgParser> parser;
  Future<SvgParser> resolve() => parser;

  /// Obtains SVG from a [String].
  factory SvgProvider.string(String svgString) {
    final SvgParser parser = SvgParser();
    parser.loadFromString(svgString);
    return SvgProvider._(Future.sync(() => parser));
  }
  factory SvgProvider.asset(String svgAsset) {
    return SvgProvider._(Future.microtask(() async {
      final parser = SvgParser();
      await parser.loadFromAsset(svgAsset);
      return parser;
    }));
  }

  factory SvgProvider.network(String url) {
    return SvgProvider._(Future.microtask(() async {
      final parser = SvgParser();
      final file = await _SvgCacheManager.instance.getSingleFile(url);
      final s = await file.readAsString();
      parser.loadFromString(s);
      return parser;
    }));
  }
  factory SvgProvider.file(File file) {
    return SvgProvider._(Future.microtask(() async {
      final parser = SvgParser();
      final s = await file.readAsString();
      parser.loadFromString(s);
      return parser;
    }));
  }
}

class _SvgCacheManager {
  static const key = 'svgCache';
  static CacheManager instance = CacheManager(
    Config(
      key,
      stalePeriod: const Duration(days: 7),
      maxNrOfCacheObjects: 200,
      repo: JsonCacheInfoRepository(databaseName: key),
      fileSystem: IOFileSystem(key),
      fileService: HttpFileService(),
    ),
  );
}
