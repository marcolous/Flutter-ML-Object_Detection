import 'package:test_lyna_cam2/main.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image/image.dart' as img;

class ObjectDetectionPage extends StatefulWidget {
  const ObjectDetectionPage({super.key});

  @override
  ObjectDetectionPageState createState() => ObjectDetectionPageState();
}

class ObjectDetectionPageState extends State<ObjectDetectionPage> {
  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    throw UnimplementedError();
  }
  // late CameraController _cameraController; // Controls the camera
  // late Interpreter _interpreter; // TensorFlow Lite interpreter
  // bool _isDetecting = false; // Prevents overlapping detections
  // final int inputSize = 300; // Model input size (e.g. 300x300)
  // List<DetectionResult> _results = []; // List of current detection results

  // @override
  // void initState() {
  //   super.initState();
  //   _initializeCamera(); // Setup camera stream
  //   _loadModel(); // Load the TFLite model
  // }

  // // Set up the camera and start streaming frames
  // void _initializeCamera() async {
  //   _cameraController = CameraController(cameras[0], ResolutionPreset.medium);
  //   await _cameraController.initialize();
  //   _cameraController.startImageStream((CameraImage image) async {
  //     if (_isDetecting) return; // Skip frame if still processing
  //     _isDetecting = true;
  //     await _runModelOnFrame(image); // Run inference
  //     _isDetecting = false;
  //   });
  //   setState(() {}); // Refresh UI after initialization
  // }

  // // Load the TensorFlow Lite model from assets
  // void _loadModel() async {
  //   _interpreter = await Interpreter.fromAsset(modelPath);
  // }

  // // Main logic to convert camera image and run inference
  // Future<void> _runModelOnFrame(CameraImage image) async {
  //   TensorImage tensorImage =
  //       convertCameraImageToTensorImage(image); // Convert to RGB

  //   tensorImage = resizeImage(tensorImage); // Resize to 300x300
  //   final input = tensorImage.buffer; // Get byte buffer for model

  //   // Prepare output tensors
  //   final outputBoxes = List.filled(1 * 10 * 4, 0.0).reshape([1, 10, 4]);
  //   final outputClasses = List.filled(1 * 10, 0.0).reshape([1, 10]);
  //   final outputScores = List.filled(1 * 10, 0.0).reshape([1, 10]);
  //   final outputCount = List.filled(1, 0.0).reshape([1]);

  //   final outputs = {
  //     0: outputBoxes,
  //     1: outputClasses,
  //     2: outputScores,
  //     3: outputCount,
  //   };

  //   // Run inference
  //   _interpreter.runForMultipleInputs([input], outputs);

  //   // Process the results
  //   final int count = outputCount[0][0].toInt();
  //   final List<DetectionResult> newResults = [];

  //   for (int i = 0; i < count; i++) {
  //     final score = outputScores[0][i];
  //     if (score > 0.5) {
  //       // Skip low confidence detections
  //       final box = outputBoxes[0][i];
  //       final rect = Rect.fromLTRB(
  //         box[1] * image.width,
  //         box[0] * image.height,
  //         box[3] * image.width,
  //         box[2] * image.height,
  //       );
  //       final label =
  //           "Class ${outputClasses[0][i].toInt()}"; // Placeholder label
  //       newResults.add(DetectionResult(rect, label, score));
  //     }
  //   }

  //   setState(() {
  //     _results = newResults; // Update UI with new detections
  //   });
  // }

  // // Resize image to the input size required by model
  // TensorImage resizeImage(TensorImage image) {
  //   final img.Image resized =
  //       img.copyResize(image.image, width: inputSize, height: inputSize);
  //   return TensorImage(resized);
  // }

  // // Convert camera's YUV420 image format to RGB format
  // TensorImage convertCameraImageToTensorImage(CameraImage cameraImage) {
  //   final img.Image rgbImage = _convertYUV420ToImage(cameraImage);
  //   return TensorImage(rgbImage);
  // }

  // // Manual YUV420 to RGB conversion logic
  // img.Image _convertYUV420ToImage(CameraImage image) {
  //   final width = image.width;
  //   final height = image.height;

  //   final yPlane = image.planes[0].bytes;
  //   final uPlane = image.planes[1].bytes;
  //   final vPlane = image.planes[2].bytes;

  //   final img.Image rgbImage = img.Image(width: width, height: height);

  //   for (int y = 0; y < height; y++) {
  //     for (int x = 0; x < width; x++) {
  //       final int yp = y * width + x;
  //       final int uvRow = y ~/ 2;
  //       final int uvCol = x ~/ 2;
  //       final int uvPixel = uvRow * (width ~/ 2) + uvCol;

  //       final int yValue = yPlane[yp];
  //       final int u = uPlane[uvPixel];
  //       final int v = vPlane[uvPixel];

  //       final r = (yValue + 1.370705 * (v - 128)).clamp(0, 255).toInt();
  //       final g = (yValue - 0.337633 * (u - 128) - 0.698001 * (v - 128))
  //           .clamp(0, 255)
  //           .toInt();
  //       final b = (yValue + 1.732446 * (u - 128)).clamp(0, 255).toInt();

  //       rgbImage.setPixelRgba(x, y, r, g, b, 255); // Set pixel color
  //     }
  //   }

  //   return rgbImage;
  // }

  // // Clean up camera and interpreter when done
  // @override
  // void dispose() {
  //   _cameraController.dispose();
  //   _interpreter.close();
  //   super.dispose();
  // }

  // // UI layout: stack camera preview with detection results overlay
  // @override
  // Widget build(BuildContext context) {
  //   return Scaffold(
  //     body: _cameraController.value.isInitialized
  //         ? Stack(
  //             fit: StackFit.expand,
  //             children: [
  //               CameraPreview(_cameraController),
  //               CustomPaint(painter: DetectionPainter(_results)),
  //             ],
  //           )
  //         : const Center(child: CircularProgressIndicator()),
  //   );
  // }
}
