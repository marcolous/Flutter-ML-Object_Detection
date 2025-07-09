// File: lib/image_detection_screen.dart
// ignore_for_file: avoid_print
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'package:test_lyna_cam2/main.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

List<String> labels = [];

class ImageDetectionScreen extends StatefulWidget {
  const ImageDetectionScreen({super.key});
  @override
  ImageDetectionScreenState createState() => ImageDetectionScreenState();
}

class ImageDetectionScreenState extends State<ImageDetectionScreen> {
  Uint8List? _imageBytes;
  List<DetectionResult> _results = [];
  late Interpreter _interpreter;

  final int inputSize = 640;

  @override
  void initState() {
    super.initState();
    loadLabels();
    loadModel();
  }

  // Load the TFLite model into memory and inspect its input/output
  Future<void> loadModel() async {
    try {
      // Load the model from assets using the provided path
      _interpreter = await Interpreter.fromAsset(modelPath);

      // Get and print input tensor information
      final inputTensor = _interpreter.getInputTensor(0);
      debugPrint('🔍 Model Path: $modelPath');
      debugPrint(
          '🔍 Input shape: ${inputTensor.shape}'); // e.g. [1, 640, 640, 3]
      debugPrint('🔍 Input type: ${inputTensor.type}'); // e.g. float32

      // Loop through all output tensors and print their info
      final outputCount = _interpreter.getOutputTensors().length;
      for (int i = 0; i < outputCount; i++) {
        final tensor = _interpreter.getOutputTensor(i);
        debugPrint('🔍 Output $i shape: ${tensor.shape}'); // e.g. [1, 84, 8400]
        debugPrint('🔍 Output $i type: ${tensor.type}');
      }
    } catch (e) {
      debugPrint('❌ Failed to load TFLite model: $e'); // Log any error
    }
  }

  // Load label list from labels.txt and clean it up
  Future<void> loadLabels() async {
    try {
      // Read the text file contents from assets
      final raw = await rootBundle.loadString(labelsPath);

      // Split into lines, trim whitespace, and remove empty lines
      labels = raw
          .split('\n')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
    } catch (e) {
      debugPrint('❌ Failed to load labels from "$labelsPath": $e'); // Log error
    }
  }

  // This function handles image selection from gallery or camera,
  // runs object detection on it, and updates the UI with results
  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();

      // Let user pick an image from the specified source
      final XFile? file = await picker.pickImage(source: source);
      if (file == null) {
        debugPrint('📷 No image selected from ${source.name}');
        return;
      }

      // Read the selected image file into bytes
      final bytes = await file.readAsBytes();

      // Decode the image bytes into an image object
      final img.Image? image = img.decodeImage(bytes);
      if (image == null) {
        debugPrint('⚠️ Failed to decode image');
        return;
      }

      // Run the object detection model on the image
      final detections = await _detectObjects(image);

      // Draw detection boxes on the image
      final Uint8List finalImageWithBoxes =
          await _drawBoxesOnImage(image, detections);

      // Update the UI with the detected image and results
      setState(() {
        _imageBytes = finalImageWithBoxes;
        _results = detections;
      });
    } catch (e) {
      debugPrint('❌ Error during image picking or processing: $e');
    }
  }

  // Draws bounding boxes and labels on the detected image
  Future<Uint8List> _drawBoxesOnImage(
      img.Image original, List<DetectionResult> results) async {
    try {
      // Make a copy of the original image to draw on
      final annotated = img.copyResize(
        original,
        width: original.width,
        height: original.height,
      );

      // Set up drawing color and font
      final paintColor = img.ColorRgb8(0, 255, 0); // Green color for boxes
      final font = img.arial14; // Built-in font for labels

      for (final result in results) {
        // Convert detection rectangle from double to int for drawing
        final left = result.rect.left.toInt();
        final top = result.rect.top.toInt();
        final right = result.rect.right.toInt();
        final bottom = result.rect.bottom.toInt();

        print(left);
        print(top);
        print(right);
        print(bottom);

        // Draw bounding box on the image
        img.drawRect(
          annotated,
          x1: left,
          y1: top,
          x2: right,
          y2: bottom,
          color: paintColor,
          thickness: 3,
        );

        // Draw label + confidence above the box
        img.drawString(
          annotated,
          '${result.label} ${(result.score * 100).toStringAsFixed(1)}%',
          font: font,
          x: left,
          y: top - 14,
          color: paintColor,
        );
      }

      // Encode the final image back to bytes (JPG)
      return Uint8List.fromList(img.encodeJpg(annotated));
    } catch (e) {
      debugPrint('❌ Failed to draw boxes on image: $e');
      return Uint8List(0); // Return an empty image if something goes wrong
    }
  }

  // Calculates Intersection over Union (IoU) between two rectangles (used for NMS)
  double _iou(Rect a, Rect b) {
    // Calculate coordinates of the overlapping area
    final double interLeft = a.left > b.left ? a.left : b.left;
    final double interTop = a.top > b.top ? a.top : b.top;
    final double interRight = a.right < b.right ? a.right : b.right;
    final double interBottom = a.bottom < b.bottom ? a.bottom : b.bottom;

    // Calculate intersection area (clamp ensures no negative size)
    final double interArea =
        (interRight - interLeft).clamp(0, double.infinity) *
            (interBottom - interTop).clamp(0, double.infinity);

    // Calculate union area = total area - intersection
    final double unionArea =
        a.width * a.height + b.width * b.height - interArea;

    return interArea / unionArea; // IoU = overlap / total
  }

  // Applies Non-Maximum Suppression (NMS) to filter overlapping boxes
  List<DetectionResult> _nonMaxSuppression(
      List<DetectionResult> results, double iouThreshold) {
    final List<DetectionResult> finalResults = [];

    // Group results by label (e.g. apple, car, etc.)
    final labelsSet = results.map((r) => r.label).toSet();
    for (final label in labelsSet) {
      final classBoxes = results.where((r) => r.label == label).toList();

      // Sort boxes for this label by confidence score (highest first)
      classBoxes.sort((a, b) => b.score.compareTo(a.score));

      // Keep the best box and remove overlapping ones
      while (classBoxes.isNotEmpty) {
        final best = classBoxes.removeAt(0);
        finalResults.add(best);

        classBoxes.removeWhere((r) => _iou(r.rect, best.rect) > iouThreshold);
      }
    }

    return finalResults;
  }

  // Merges overlapping boxes with the same label if their IoU is above a threshold
  List<DetectionResult> _mergeOverlappingBoxes(
      List<DetectionResult> results, double iouThreshold) {
    final mergedResults = <DetectionResult>[]; // Final list of merged boxes
    final processedIndices = <int>{}; // Tracks which boxes have been merged

    for (int i = 0; i < results.length; i++) {
      if (processedIndices.contains(i)) continue; // Skip if already merged

      final current = results[i];
      var mergedRect = current.rect; // Start with current box
      var totalScore = current.score;
      var count = 1; // Number of merged boxes

      for (int j = i + 1; j < results.length; j++) {
        if (processedIndices.contains(j)) continue;

        final other = results[j];
        if (current.label != other.label) continue; // Only merge same class

        final iou = _iou(mergedRect, other.rect);
        if (iou > iouThreshold) {
          // Merge the overlapping boxes into one bigger box
          mergedRect = Rect.fromLTRB(
            min(mergedRect.left, other.rect.left),
            min(mergedRect.top, other.rect.top),
            max(mergedRect.right, other.rect.right),
            max(mergedRect.bottom, other.rect.bottom),
          );
          totalScore += other.score;
          count++;
          processedIndices.add(j); // Mark this box as merged
        }
      }

      // Average confidence score of merged boxes
      final avgScore = totalScore / count;
      mergedResults.add(DetectionResult(mergedRect, current.label, avgScore));
      processedIndices.add(i); // Mark current box as merged
    }

    return mergedResults;
  }

  Future<List<DetectionResult>> _detectObjects(img.Image image) async {
    try {
      // Resize input image to match model's expected input shape
      final img.Image resized =
          img.copyResize(image, width: inputSize, height: inputSize);

      // Convert resized image to RGB float input for the model
      final pixels = resized.getBytes(order: img.ChannelOrder.rgb);
      final input = List.generate(
        1,
        (_) => List.generate(
          inputSize,
          (y) => List.generate(inputSize, (x) {
            final i = (y * inputSize + x) * 3;
            return [
              pixels[i].toDouble(),
              pixels[i + 1].toDouble(),
              pixels[i + 2].toDouble(),
            ];
          }),
        ),
      );

      // Prepare output buffer based on model output shape [1, 84, 8400]
      final output = List.filled(1 * 84 * 8400, 0.0).reshape([1, 84, 8400]);

      // Run inference
      _interpreter.runForMultipleInputs([input], {0: output});
      debugPrint('✅ Inference completed');

      final List<DetectionResult> results = [];

      // Iterate over each prediction box (total 8400 boxes)
      for (int i = 0; i < 8400; i++) {
        final xCenter = output[0][0][i];
        final yCenter = output[0][1][i];
        final width = output[0][2][i];
        final height = output[0][3][i];

        // Scale box dimensions from model size to image size
        final xc = xCenter * image.width;
        final yc = yCenter * image.height;
        final w = width * image.width;
        final h = height * image.height;

        final objectness = output[0][4][i];

        // Get class scores (80 classes)
        final classScores = List.generate(84 - 5, (c) => output[0][5 + c][i]);

        // Sort top-5 classes by score
        final sortedScores = classScores.asMap().entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        final top5 = sortedScores.take(5).toList();

        final classIndex = top5.first.key;
        final maxScore = top5.first.value;
        final finalScore = objectness * maxScore;

        // Filter weak predictions with thresholds
        if (finalScore > 0.7 && objectness > 0.3 && maxScore > 0.7) {
          // Convert center box format to corner box
          final left = xc - w / 2;
          final top = yc - h / 2;
          final right = xc + w / 2;
          final bottom = yc + h / 2;

          final label =
              (classIndex < labels.length) ? labels[classIndex] : 'unknown';

          results.add(DetectionResult(
            Rect.fromLTRB(left, top, right, bottom),
            label,
            finalScore,
          ));

          // Log box and class details for inspection
          debugPrint('🔍 Box $i\n'
              '    Xc=${xc.toStringAsFixed(1)}, Yc=${yc.toStringAsFixed(1)}, '
              'W=${w.toStringAsFixed(1)}, H=${h.toStringAsFixed(1)}\n'
              '    Obj=${objectness.toStringAsFixed(2)}, ClassIndex=$classIndex '
              '(${labels[classIndex]})\n'
              '    Top5 classes: ${top5.map((e) => "${labels[e.key]}=${e.value.toStringAsFixed(2)}").join(", ")}');
        }
      }

      debugPrint('✅ Detections found: ${results.length}');

      // Remove redundant overlapping boxes with same label
      final intermediateResults = _nonMaxSuppression(results, 0.4);

      // Optionally merge close boxes of same label
      final finalResults = _mergeOverlappingBoxes(intermediateResults, 0.3);

      debugPrint('✅ Final detections after processing: ${finalResults.length}');

      // Log final summary of class counts and box locations
      final classCount = <String, int>{};
      for (final r in finalResults) {
        classCount[r.label] = (classCount[r.label] ?? 0) + 1;
        debugPrint(
            '[RESULT] ${r.label} | Score: ${r.score.toStringAsFixed(3)} | '
            'Box: [${r.rect.left.toInt()}, ${r.rect.top.toInt()}, '
            '${r.rect.right.toInt()}, ${r.rect.bottom.toInt()}]');
      }
      debugPrint('📌 Class Distribution: $classCount');

      return finalResults;
    } catch (e) {
      debugPrint('❌ Object detection failed: $e');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Image Detection')),
      body: Column(
        children: [
          if (_imageBytes != null)
            Expanded(
              child: Stack(
                children: [
                  Image.memory(_imageBytes!),
                  CustomPaint(
                    // painter: DetectionPainter(_results),
                    child: Container(),
                  )
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.photo),
                  label: const Text('Gallery'),
                  onPressed: () => _pickImage(ImageSource.gallery),
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.camera),
                  label: const Text('Camera'),
                  onPressed: () => _pickImage(ImageSource.camera),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/** 
┌───────────────────────────┐
│     App Launch (main)     │
└─────────┬─────────────────┘
          │
          ▼
┌─────────────────────────────────────────┐
│ WidgetsFlutterBinding.ensureInitialized │
└─────────────────────────────────────────┘
          │
          ▼
┌────────────────────────┐
│ Load available cameras │
└────────────────────────┘
          │
          ▼
┌──────────────────────┐
│ runApp(MyApp)        │
└─────────┬────────────┘
          ▼
┌────────────────────────────┐
│ ImageDetectionScreen       │
└────────────────────────────┘
          │
          ▼
┌──────────────────────┐
│ initState()          │
│ ├─ loadLabels()      │
│ └─ loadModel()       │
└──────────────────────┘
          │
          ▼
┌──────────────────────────────────┐
│ User taps: Pick Camera / Gallery │
└──────────────────────────────────┘
          │
          ▼
┌────────────────────────┐
│ _pickImage()           │
│ ├─ decodeImage         │
│ ├─ _detectObjects()    │
│ └─ _drawBoxesOnImage() │
└────────────────────────┘
          │
          ▼
┌────────────────────────┐
│ _detectObjects()       │
│ ├─ Preprocess image    │
│ ├─ Run TFLite model    │
│ ├─ Parse YOLO output   │
│ ├─ Apply confidence &  │
│ │   score thresholds   │
│ └─ Run NMS + merge     │
└────────────────────────┘
          │
          ▼
┌─────────────────────────────┐
│ _drawBoxesOnImage()         │
│ ├─ drawRect() for each box  │
│ └─ drawString() for labels  │
└─────────────────────────────┘
          │
          ▼
┌──────────────────────┐
│ setState()           │
│ └─ Updates UI        │
└──────────────────────┘
          │
          ▼
┌───────────────────────────────┐
│ Display Image + CustomPaint   │
│ Overlay with DetectionPainter │
└───────────────────────────────┘
 */