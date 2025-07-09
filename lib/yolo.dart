import 'dart:ui';
import 'package:test_lyna_cam2/main.dart';

List<DetectionResult> parseYoloOutput({
  required List<List<List<double>>> yoloOutput,
  required int inputWidth,
  required int inputHeight,
  required int origWidth,
  required int origHeight,
  required List<String> labels,
  double threshold = 0.5,
}) {
  final result = <DetectionResult>[];
  final raw = yoloOutput[0]; // [84][8400]

  for (int i = 0; i < raw[0].length; i++) {
    final x = raw[0][i];
    final y = raw[1][i];
    final w = raw[2][i];
    final h = raw[3][i];
    final objScore = raw[4][i];

    double bestClassScore = 0.0;
    int bestClassId = -1;

    for (int c = 5; c < 84; c++) {
      final classScore = raw[c][i];
      if (classScore > bestClassScore) {
        bestClassScore = classScore;
        bestClassId = c - 5;
      }
    }

    final confidence = objScore * bestClassScore;
    if (confidence < threshold) continue;

    final boxW = w * origWidth / inputWidth;
    final boxH = h * origHeight / inputHeight;
    final cx = x * origWidth / inputWidth;
    final cy = y * origHeight / inputHeight;

    final left = cx - boxW / 2;
    final top = cy - boxH / 2;
    final right = cx + boxW / 2;
    final bottom = cy + boxH / 2;

    result.add(DetectionResult(
      Rect.fromLTRB(left, top, right, bottom),
      labels[bestClassId],
      confidence,
    ));
  }

  return result;
}
