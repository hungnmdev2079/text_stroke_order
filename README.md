# text_stroke_order

`text_stroke_order` là thư viện Flutter dùng để hiển thị và luyện viết thứ tự nét từ dữ liệu SVG. Thư viện hỗ trợ:

- Tự động animate từng nét.
- Hướng dẫn người dùng vẽ theo từng nét.
- Kiểm tra nét viết tay cơ bản khi vẽ tự do.
- Nạp SVG từ string, asset, file hoặc network.

## Cài đặt

Thêm package vào `pubspec.yaml` của app:

```yaml
dependencies:
  text_stroke_order:
    path: ../text_stroke_order
```

Nếu dùng từ Git:

```yaml
dependencies:
  text_stroke_order:
    git:
      url: https://github.com/<owner>/text_stroke_order.git
```

Sau đó chạy:

```sh
flutter pub get
```

Import package:

```dart
import 'package:text_stroke_order/text_stroke_order.dart';
```

## Chuẩn bị SVG

SVG cần có các thẻ `path` để thư viện lấy dữ liệu nét. Nếu muốn hiển thị số thứ tự nét, SVG có thể có thêm thẻ `text`.

Các nguồn SVG được hỗ trợ:

```dart
SvgProvider.string(svgString);
SvgProvider.asset('assets/kanji/054e5.svg');
SvgProvider.file(file);
SvgProvider.network('https://example.com/054e5.svg');
```

Nếu dùng asset, khai báo asset trong `pubspec.yaml` của app:

```yaml
flutter:
  assets:
    - assets/kanji/054e5.svg
```

## Tạo controller

`TextStrokeOrderController` cần `TickerProvider`, nên thường dùng trong `StatefulWidget` với `TickerProviderStateMixin`.

```dart
class _MyPageState extends State<MyPage> with TickerProviderStateMixin {
  late final TextStrokeOrderController controller;

  @override
  void initState() {
    super.initState();
    controller = TextStrokeOrderController(
      svgProvider: SvgProvider.asset('assets/kanji/054e5.svg'),
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}
```

## Tự động animate thứ tự nét

```dart
TextStrokeOrder.autoAnimation(
  controller: controller,
  width: 300,
  height: 300,
  padding: const EdgeInsets.all(20),
  strokeWidth: 4,
  strokeColor: Colors.black,
  animatingStrokeColor: Colors.orange,
  isShowNumber: true,
  autoAnimate: true,
  onFinish: () {
    debugPrint('Animation finished');
  },
)
```

Điều khiển animation từ controller:

```dart
controller.startAnimation();
controller.resetAnimation();
```

## Luyện viết từng nét

Chế độ này hiển thị nét hướng dẫn và cho người dùng kéo theo nét.

```dart
TextStrokeOrder.sequentialStroke(
  controller: controller,
  isFreeDraw: false,
  width: 300,
  height: 300,
  padding: const EdgeInsets.all(20),
  isShowNumber: true,
  randomSkipTutorial: false,
  tutorialPathSetting: const TutorialPathSetting(
    strokeWidth: 8,
    color: Colors.grey,
    fillColor: Colors.orange,
    finishColor: Colors.green,
  ),
  hintSetting: const HintSetting(
    enable: true,
    color: Colors.grey,
    strokeWidth: 8,
  ),
  onEndStroke: () {
    debugPrint('Finished one stroke');
  },
  onFinish: () {
    debugPrint('Finished all strokes');
  },
)
```

Có thể chuyển sang nét tiếp theo bằng tay:

```dart
final canNext = controller.nextStroke();
```

Reset trạng thái luyện viết:

```dart
controller.reset();
```

## Luyện viết tự do và kiểm tra đúng sai

Đặt `isFreeDraw: true` để người dùng tự vẽ nét. Sau mỗi nét, callback `onEndStrokeCheck` trả về kết quả kiểm tra.

```dart
TextStrokeOrder.sequentialStroke(
  controller: controller,
  isFreeDraw: true,
  width: 300,
  height: 300,
  padding: const EdgeInsets.all(20),
  isShowNumber: false,
  handWriteSetting: const HandWriteSetting(
    color: Colors.orange,
    size: 4,
  ),
  tutorialPathSetting: const TutorialPathSetting(
    strokeWidth: 4,
  ),
  hintSetting: const HintSetting(
    enable: false,
    strokeWidth: 4,
  ),
  onEndStrokeCheck: (isCorrect) {
    debugPrint(isCorrect ? 'Correct stroke' : 'Incorrect stroke');
  },
  onEndDraw: () {
    debugPrint('User ended drawing');
  },
  onFinish: () {
    debugPrint('Finished all strokes');
  },
)
```

## Tùy biến giao diện

Các thuộc tính chung:

```dart
TextStrokeOrder.autoAnimation(
  controller: controller,
  width: 300,
  height: 300,
  padding: const EdgeInsets.all(16),
  backgroundColor: Colors.white,
  borderRadius: 8,
  border: Border.all(color: Colors.black12),
  loadingBuilder: (_) => const SizedBox(
    width: 32,
    height: 32,
    child: CircularProgressIndicator(),
  ),
)
```

### Số thứ tự nét

```dart
isShowNumber: true,
numberStyle: const TextStyle(
  color: Colors.grey,
  fontSize: 8,
  fontWeight: FontWeight.bold,
),
```

### Đường kẻ viewport

```dart
viewPortDashSetting: const ViewPortDashSetting(
  enable: true,
  color: Colors.grey,
  strokeWidth: 1,
  length: 9,
  spacing: 5,
),
```

### Đường hướng dẫn

```dart
tutorialPathSetting: const TutorialPathSetting(
  enable: true,
  arrowDashEnable: true,
  handleEnable: true,
  color: Colors.grey,
  fillColor: Colors.orange,
  finishColor: Colors.green,
  strokeWidth: 8,
  handleCircleSetting: HandleCircleSetting.arrow(
    color: Colors.orange,
    arrowColor: Colors.white,
    arrowSize: 3,
  ),
),
```

### Nét người dùng vẽ

```dart
handWriteSetting: const HandWriteSetting(
  color: Colors.orange,
  size: 6,
),
```

## Ví dụ đầy đủ

```dart
import 'package:flutter/material.dart';
import 'package:text_stroke_order/text_stroke_order.dart';

class StrokeOrderDemo extends StatefulWidget {
  const StrokeOrderDemo({super.key});

  @override
  State<StrokeOrderDemo> createState() => _StrokeOrderDemoState();
}

class _StrokeOrderDemoState extends State<StrokeOrderDemo>
    with TickerProviderStateMixin {
  late final TextStrokeOrderController controller;

  @override
  void initState() {
    super.initState();
    controller = TextStrokeOrderController(
      svgProvider: SvgProvider.network(
        'https://raw.githubusercontent.com/tranquockhanh0506/hanzivg_khanhtq/master/kanji/054e5.svg',
      ),
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ElevatedButton(
          onPressed: () {
            controller.resetAnimation();
            controller.startAnimation();
            controller.reset();
          },
          child: const Text('Reset'),
        ),
        TextStrokeOrder.sequentialStroke(
          controller: controller,
          isFreeDraw: true,
          width: 300,
          height: 300,
          padding: const EdgeInsets.all(20),
          handWriteSetting: const HandWriteSetting(size: 4),
          hintSetting: const HintSetting(strokeWidth: 4, enable: false),
          tutorialPathSetting: const TutorialPathSetting(strokeWidth: 4),
          viewPortDashSetting: const ViewPortDashSetting(enable: true),
          isShowNumber: false,
          onEndStrokeCheck: (isCorrect) {
            debugPrint(isCorrect ? 'Correct' : 'Incorrect');
          },
          onFinish: () {
            debugPrint('Finished');
          },
        ),
      ],
    );
  }
}
```

## API chính

| Thành phần | Mục đích |
| --- | --- |
| `TextStrokeOrder.autoAnimation` | Animate tự động từng nét. |
| `TextStrokeOrder.sequentialStroke` | Luyện viết từng nét hoặc viết tự do. |
| `TextStrokeOrderController` | Quản lý SVG, animation và trạng thái luyện viết. |
| `SvgProvider` | Nạp SVG từ `string`, `asset`, `file`, `network`. |
| `TutorialPathSetting` | Tùy biến đường hướng dẫn, màu nét đã vẽ, handle, arrow. |
| `HintSetting` | Tùy biến nét gợi ý nền. |
| `HandWriteSetting` | Tùy biến nét người dùng vẽ. |
| `ViewPortDashSetting` | Tùy biến đường kẻ ngang/dọc trong khung viết. |

## Lưu ý

- Gọi `controller.dispose()` trong `dispose()` của widget.
- Với `SvgProvider.network`, app cần quyền truy cập internet.
- Chất lượng kiểm tra đúng sai phụ thuộc vào dữ liệu SVG và độ chính xác của đường nét người dùng vẽ.
- Nếu SVG không có thẻ `text`, hãy đặt `isShowNumber: false` hoặc truyền `numberStyle` phù hợp.
