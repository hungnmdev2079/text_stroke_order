import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:xml/xml.dart' as xml;
import 'package:xml/xml.dart';
import 'package:collection/collection.dart';

import 'path_parsing/path_parsing.dart';

//SVG parsing

/// Parses a minimal subset of a SVG file and extracts all paths segments.
class SvgParser {
  /// Each [PathSegment] represents a continuous Path element of the parent Path
  final List<PathSegment> _pathSegments = <PathSegment>[];
  final List<TextSegment> _textSegments = <TextSegment>[];
  List<Path> _paths = <Path>[];

  Color parseColor(String cStr) {
    if (cStr.isEmpty) throw UnsupportedError('Empty color field found.');
    if (cStr[0] == '#') {
      return Color(int.parse(cStr.substring(1), radix: 16)).withOpacity(
          1.0); // Hex to int: from https://stackoverflow.com/a/51290420/9452450
    } else if (cStr == 'none') {
      return Colors.transparent;
    } else {
      throw UnsupportedError(
          'Only hex color format currently supported. String:  $cStr');
    }
  }

  //Extract segments of each path and create [PathSegment] representation
  void addPathSegments(
      Path path, int index, double? strokeWidth, Color? color) {
    var firstPathSegmentIndex = _pathSegments.length;
    var relativeIndex = 0;
    path.computeMetrics().forEach((pp) {
      var segment = PathSegment()
        ..path = pp.extractPath(0, pp.length)
        ..length = pp.length
        ..firstSegmentOfPathIndex = firstPathSegmentIndex
        ..pathIndex = index
        ..relativeIndex = relativeIndex;

      if (color != null) segment.color = color;

      if (strokeWidth != null) segment.strokeWidth = strokeWidth;

      _pathSegments.add(segment);
      relativeIndex++;
    });
  }

  void addTextSegments(String text, TextStyle textStyle, Offset offset) {
    _textSegments
        .add(TextSegment(text: text, textStyle: textStyle, offset: offset));
  }

  void loadFromString(String svgString) {
    _pathSegments.clear();
    var index = 0; //number of parsed path elements
    RegExp regex = RegExp(r'<svg(.*?)<\/svg>', dotAll: true);
    Iterable<Match> matches = regex.allMatches(svgString);
    String svg = '';
    for (Match match in matches) {
      String svgContent = match.group(0)!;
      svg = svgContent;
    }
    var doc = XmlDocument.parse(svg);
    final style =
        doc.firstElementChild?.childElements.first.getAttributeNode('style');

    Color? color;
    double? strokeWidth;

    //
    if (style != null) {
      var exp = RegExp(r'stroke:([^;]+);');
      var match = exp.firstMatch(style.value) as Match;
      var cStr = match.group(1);
      color = parseColor(cStr!);
      //Parse stroke-width
      exp = RegExp(r'stroke-width:([0-9.]+)');
      match = exp.firstMatch(style.value)!;
      cStr = match.group(1);
      strokeWidth = double.tryParse(cStr!);
    }
    double? fontSize;
    Color? textColor;
    final styleOfText =
        doc.firstChild?.childElements.last.getAttributeNode('style');
    if (styleOfText != null) {
      var exp = RegExp(r'font-size:([0-9.]+)');
      var match = exp.firstMatch(styleOfText.value) as Match;
      var cStr = match.group(1);
      fontSize = double.tryParse(cStr!);

      exp = RegExp(r'fill:([^;]+)');
      match = exp.firstMatch(styleOfText.value)!;
      cStr = match.group(1);
      textColor = parseColor(cStr!);
    }

    doc
        .findAllElements('path')
        .map((node) => node.attributes)
        .forEach((attributes) {
      var dPath = attributes.firstWhereOrNull((attr) => attr.name.local == 'd');
      if (dPath != null) {
        var path = Path();
        writeSvgPathDataToPath(dPath.value, PathModifier(path));

        //Attributes - [2] svg-attributes
        var strokeElement =
            attributes.firstWhereOrNull((attr) => attr.name.local == 'stroke');
        if (strokeElement != null) {
          color = parseColor(strokeElement.value);
        }

        var strokeWidthElement = attributes
            .firstWhereOrNull((attr) => attr.name.local == 'stroke-width');
        if (strokeWidthElement != null) {
          strokeWidth = double.tryParse(strokeWidthElement.value);
        }

        _paths.add(path);

        var id = attributes.firstWhereOrNull((attr) => attr.name.local == 'id');
        if (id != null) {
          final idString = id.value.split('-s').last;
          final i = int.tryParse(idString);
          if (i != null) {
            index = i;
            addPathSegments(path, index, strokeWidth, color);
          } else {
            addPathSegments(path, index, strokeWidth, color);
            index++;
          }
        } else {
          addPathSegments(path, index, strokeWidth, color);
          index++;
        }
      }
    });

    doc.findAllElements('text').forEach((element) {
      final text = element.innerText;
      final attributes = element.attributes;
      var transform =
          attributes.firstWhereOrNull((attr) => attr.name.local == 'transform');
      double x = 0;
      double y = 0;
      if (transform != null) {
        final value =
            transform.value.replaceAll('matrix(', '').replaceAll(')', '');
        final spl = value.split(' ');
        x = double.parse(spl[4]);
        y = double.parse(spl[5]);
      }
      addTextSegments(
          text, TextStyle(color: textColor, fontSize: fontSize), Offset(x, y));
    });
  }

  void loadFromPaths(List<Path> paths) {
    _pathSegments.clear();
    _paths = paths;

    var index = 0;
    for (var p in paths) {
      addPathSegments(p, index, null, null);
      index++;
    }
  }

  /// Parses Svg from provided asset path
  Future<void> loadFromAsset(String file) async {
    _pathSegments.clear();
    var svgString = await rootBundle.loadString(file);
    loadFromString(svgString);
  }

  /// Returns extracted [PathSegment] elements of parsed Svg
  List<PathSegment> getPathSegments() {
    return _pathSegments;
  }

  List<TextSegment> getTextSegments() {
    return _textSegments;
  }

  /// Returns extracted [Path] elements of parsed Svg
  List<Path> getPaths() {
    return _paths;
  }
}

/// Represents a segment of path, as returned by path.computeMetrics() and the associated painting parameters for each Path
class PathSegment {
  PathSegment()
      : strokeWidth = 0.0,
        color = Colors.black,
        animateStrokeColor = Colors.black,
        firstSegmentOfPathIndex = 0,
        relativeIndex = 0,
        pathIndex = 0,
        isTutorial = false,
        tutorialPercent = 0,
        isDoneTutorial = false,
        isSkipTutorial = false,
        isShowDashArrow = false,
        dashArrowColor = Colors.grey,
        dashSpace = 3,
        dashWith = 3,
        handleSize = 6,
        handleColor = Colors.black {
    //That is fun.
    // List colors = [Colors.red, Colors.green, Colors.yellow];
    // Random random = new Random();
    // color = colors[random.nextInt(3)];
  }

  /// A continuous path/segment
  late Path path;
  late double strokeWidth;
  late Color color;
  late Color animateStrokeColor;

  /// Length of the segment path
  late double length;

  late bool isTutorial;

  late double tutorialPercent;

  late bool isDoneTutorial;

  late bool isSkipTutorial;

  late bool isShowDashArrow;

  late Color dashArrowColor;

  late double dashSpace;

  late double dashWith;

  late double handleSize;

  late Color handleColor;

  /// Denotes the index of the first segment of the containing path when PathOrder.original
  int firstSegmentOfPathIndex;

  /// Corresponding containing path index
  int pathIndex;

  /// Denotes relative index to  firstSegmentOfPathIndex
  int relativeIndex;

  List<Offset> get getOffsets {
    final List<Offset> offsets = [];
    final segments = path.computeMetrics().first;
    for (var i = 0; i < segments.length; i += 1) {
      final offset = segments.getTangentForOffset(i.toDouble())!.position;
      offsets.add(offset);
    }
    final offset = segments.getTangentForOffset(segments.length)!.position;
    offsets.add(offset);
    return offsets;
  }

  /// If stroke, how to end
// StrokeCap cap;
//PaintingStyle
// PaintingStyle style;
}

/// A [PathProxy] that saves Path command in path
class PathModifier extends PathProxy {
  PathModifier(this.path);

  Path path;

  @override
  void close() {
    path.close();
  }

  @override
  void cubicTo(
      double x1, double y1, double x2, double y2, double x3, double y3) {
    path.cubicTo(x1, y1, x2, y2, x3, y3);
  }

  @override
  void lineTo(double x, double y) {
    path.lineTo(x, y);
  }

  @override
  void moveTo(double x, double y) {
    path.moveTo(x, y);
  }
}

class TextSegment {
  final String text;
  TextStyle textStyle;
  final Offset offset;

  TextSegment(
      {required this.text, required this.textStyle, required this.offset});
}
