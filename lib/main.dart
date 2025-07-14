// File: lib/main.dart
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image/image.dart' as img;
import 'package:test_lyna_cam2/live_cam.dart';
import 'package:test_lyna_cam2/single_image.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:test_lyna_cam2/yolo_screen.dart';

// Stores the list of available cameras (e.g., front and back) to initialize the camera stream.
late List<CameraDescription> cameras;
const bool showSingleImage = true;
const bool setFloat16 = true;
const String modelPath = setFloat16
    ? 'assets/yolo11s_float16.tflite'
    : 'assets/yolo11s_float32.tflite';

// const String modelPath = 'assets/yolo11s_float16.tflite';
const String labelsPath = 'assets/labels.txt';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  cameras = await availableCameras(); // Load available cameras
  await requestPermissions();
  runApp(const MyApp()); // Launch the app
}

Future<void> requestPermissions() async {
  await Permission.camera.request();
  await Permission.storage.request();
  await Permission.manageExternalStorage.request();
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      // home: ImageDetectionScreen(),  // single_image.dart
      // home: ObjectDetectionPage(), // live_cam.dart
      home: HomePage(), // yolo_screen.dart
    );
  }
}

// Data structure to hold each detection result
class DetectionResult {
  final Rect rect;
  final String label;
  final double score;
  DetectionResult(this.rect, this.label, this.score);
}

// Custom wrapper for input image tensor
class TensorImage {
  final img.Image image;
  TensorImage(this.image);

  // Convert image to byte buffer in RGB format
  Uint8List get buffer =>
      Uint8List.fromList(image.getBytes(order: img.ChannelOrder.rgb));

  static TensorImage fromImage(img.Image image) => TensorImage(image);
}

// Draws bounding boxes and labels over the camera preview
class DetectionPainter extends CustomPainter {
  final List<DetectionResult> results;
  DetectionPainter(this.results);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.red
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    const textStyle = TextStyle(color: Colors.red, fontSize: 14);

    for (final result in results) {
      canvas.drawRect(result.rect, paint); // Draw box
      final textSpan = TextSpan(
        text: '${result.label} ${(result.score * 100).toStringAsFixed(1)}%',
        style: textStyle,
      );
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
          canvas, Offset(result.rect.left, result.rect.top - 10)); // Draw label
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
