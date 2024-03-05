import 'package:flutter/material.dart';
import 'package:text_stroke_order/text_stroke_order.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with TickerProviderStateMixin {
  final svg =
      """<svg xmlns="http://www.w3.org/2000/svg" width="109" height="109" viewBox="0 0 109 109">
<g id="kvg:StrokePaths_0f9a8" style="fill:none;stroke:#000000;stroke-width:3;stroke-linecap:round;stroke-linejoin:round;">
<g id="kvg:0f9a8" kvg:element="令">
	<g id="kvg:0f9a8-g1" kvg:element="人" kvg:position="top" kvg:radical="general">
		<path id="kvg:0f9a8-s1" kvg:type="㇒" d="M49.62,13.25c0.11,0.94,0.38,2.48-0.22,3.77c-4.15,8.86-15.15,25.23-36.65,37.08"/>
		<path id="kvg:0f9a8-s2" kvg:type="㇏" d="M50.54,16.55c6.13,4.35,24.99,20.22,33.98,27.33c3.22,2.54,5.6,4.12,9.73,5.37"/>
	</g>
	<g id="kvg:0f9a8-g2" kvg:position="bottom">
		<g id="kvg:0f9a8-g3" kvg:element="一">
			<path id="kvg:0f9a8-s3" kvg:type="㇐" d="M 38.590625,42.910833 c 1.76,0.72 3.84,0.36 5.65,0.14 5.4,-0.66 13.08,-1.76 18.48,-2.24 1.88,-0.17 3.54,-0.23 5.37,0.21"/>
		</g>
		<g id="kvg:0f9a8-g4" kvg:element="卩" kvg:original="マ">
			<path id="kvg:0f9a8-s4" kvg:type="㇆" d="M 31.464375,53.641042 c 0.61,0.15 3,1 4.21,0.87 10.329583,-0.937708 28.549375,-2.998125 38.130833,-4.17 1.516086,-0.185427 4.278829,-0.290121 3.95,2.89 -0.431171,4.169879 -2.680149,16.919928 -6,23.84 -1.890149,3.939928 -3.18,3.45 -6.23,0.46"/>
			<path id="kvg:0f9a8-s5" kvg:type="㇑" d="M 44.769166,53.809375 c 0.87,0.87 1.8,2 1.8,3.5 0,7.36 -0.04,24.53 -0.1,34.13 -0.02,3.3 -0.05,5.71 -0.08,6.51"/>
		</g>
	</g>
</g>
</g>
<g id="kvg:StrokeNumbers_0f9a8" style="font-size:8;fill:#808080">
	<text transform="matrix(1 0 0 1 42.50 15.13)">1</text>
	<text transform="matrix(1 0 0 1 58.50 19.63)">2</text>
	<text transform="matrix(1 0 0 1 43 40)">3</text>
	<text transform="matrix(1 0 0 1 25.1 62.1)">4</text>
	<text transform="matrix(1 0 0 1 36.4 65.5)">5</text>
</g>
</svg>
""";

  late TextStrokeOrderController controller = TextStrokeOrderController(
      // svgProvider: SvgProvider.string(svg),

      svgProvider: SvgProvider.network(
          'https://raw.githubusercontent.com/KanjiVG/kanjivg/master/kanji/05270.svg'),
      vsync: this,
      duration: const Duration(milliseconds: 800));

  @override
  void initState() {
    super.initState();
  }

  Color strokeColor = Colors.orange;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                  onPressed: () {
                    controller.resetAnimation();
                    controller.startAnimation();
                  },
                  child: const Text("Reset")),
              TextStrokeOrder.autoAnimation(
                controller: controller,
                width: 300,
                height: 300,
                animatingStrokeColor: Colors.red,
                strokeWidth: 4,
                padding: const EdgeInsets.all(20),
                viewPortDashSetting: ViewPortDashSetting(
                    color: const Color.fromARGB(255, 3, 3, 3).withOpacity(0.2)),
                isShowNumber: false,
                numberStyle: const TextStyle(
                    color: Colors.grey,
                    fontSize: 6,
                    fontWeight: FontWeight.bold),
                loadingBuilder: (context) => const SizedBox(),
                // finishStrokeColor: Colors.green,
                onFinish: () {
                  print("FINISh");
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MyPainter extends CustomPainter {
  final List<PathSegment> listPathSegments;
  final List<TextSegment> listTextSegments;

  MyPainter(
      {super.repaint,
      required this.listPathSegments,
      required this.listTextSegments});
  @override
  void paint(Canvas canvas, Size size) {
    for (var p in listPathSegments) {
      final Paint paint = Paint()
        ..color = Colors.green
        ..style = PaintingStyle.stroke
        ..strokeWidth = p.strokeWidth + 2
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

      canvas.drawPath(p.path, paint);
    }

    for (var t in listTextSegments) {
      final textSpan = TextSpan(
        text: t.text,
        style: t.textStyle,
      );

      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      );

      textPainter.layout();
      textPainter.paint(canvas, t.offset - const Offset(0, 8));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
