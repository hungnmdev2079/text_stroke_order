import 'dart:io';

import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_cache_manager/src/storage/file_system/file_system_io.dart';

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
    final SvgParser parser = SvgParser();
    parser.loadFromAsset(svgAsset);
    return SvgProvider._(Future.sync(() => parser));
  }

  factory SvgProvider.network(String url) {
    return SvgProvider._(Future(() async {
      final SvgParser parser = SvgParser();
      final file = await _SvgCacheManager.instance.getSingleFile(url);
      final s = file.readAsStringSync();
      parser.loadFromString(s);
      return parser;
    }));
  }
  factory SvgProvider.file(File file) {
    return SvgProvider._(Future(() async {
      final SvgParser parser = SvgParser();
      final s = file.readAsStringSync();
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
