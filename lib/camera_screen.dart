// // camera_screen.dart
// import 'package:flutter/material.dart';
// import 'package:camera/camera.dart';
// import 'package:tflite_flutter/tflite_flutter.dart';
// import 'package:tflite_flutter_helper/tflite_flutter_helper.dart';

// class CameraScreen extends StatefulWidget {
//   const CameraScreen({super.key});

//   @override
//   _CameraScreenState createState() => _CameraScreenState();
// }

// class _CameraScreenState extends State<CameraScreen> {
//   late CameraController _controller;
//   late Future<void> _initializeControllerFuture;
//   late Interpreter _interpreter;
//   bool _isModelLoaded = false;
//   List<ObjectDetectionResult> _results = [];
//   late ImageProcessor imageProcessor;

//   @override
//   void initState() {
//     super.initState();
//     _initializeCamera();
//     _loadModel();
//   }

//   Future<void> _initializeCamera() async {
//     final cameras = await availableCameras();
//     _controller = CameraController(
//       cameras[0],
//       ResolutionPreset.medium,
//       enableAudio: false,
//     );
//     _initializeControllerFuture = _controller.initialize();
//     _controller.startImageStream((CameraImage image) {
//       if (_isModelLoaded) {
//         _runInference(image);
//       }
//     });
//   }

//   Future<void> _loadModel() async {
//     try {
//       // Load the TFLite model (make sure to include it in assets)
//       _interpreter = await Interpreter.fromAsset('yolov8s.tflite');

//       // Initialize image processor similar to the notebook
//       imageProcessor = ImageProcessorBuilder()
//           .add(ResizeOp(640, 640, ResizeMethod.BILINEAR))
//           .add(NormalizeOp(0, 255))
//           .build();

//       setState(() {
//         _isModelLoaded = true;
//       });
//     } catch (e) {
//       debugPrint('Failed to load model: $e');
//     }
//   }

//   Future<void> _runInference(Image image) async {
//     if (!_isModelLoaded) return;

//     // Convert CameraImage to TensorImage
//     TensorImage tensorImage = TensorImage.fromImage(image);

//     // Preprocess the image (similar to the notebook)
//     tensorImage = imageProcessor.process(tensorImage);

//     // Prepare output tensors
//     TensorBuffer outputLocations = TensorBuffer.createFixedSize(
//         _interpreter.getOutputTensor(0).shape,
//         _interpreter.getOutputTensor(0).type);
//     TensorBuffer outputClasses = TensorBuffer.createFixedSize(
//         _interpreter.getOutputTensor(1).shape,
//         _interpreter.getOutputTensor(1).type);
//     TensorBuffer outputScores = TensorBuffer.createFixedSize(
//         _interpreter.getOutputTensor(2).shape,
//         _interpreter.getOutputTensor(2).type);
//     TensorBuffer numDetections = TensorBuffer.createFixedSize(
//         _interpreter.getOutputTensor(3).shape,
//         _interpreter.getOutputTensor(3).type);

//     // Run inference
//     _interpreter.runForMultipleInputs([
//       tensorImage.buffer
//     ], {
//       0: outputLocations.buffer,
//       1: outputClasses.buffer,
//       2: outputScores.buffer,
//       3: numDetections.buffer,
//     });

//     // Process results (similar to the notebook's post-processing)
//     List<ObjectDetectionResult> results = _processOutput(
//       outputLocations,
//       outputClasses,
//       outputScores,
//       numDetections,
//       image.width,
//       image.height,
//     );

//     setState(() {
//       _results = results;
//     });
//   }

//   List<ObjectDetectionResult> _processOutput(
//     TensorBuffer locations,
//     TensorBuffer classes,
//     TensorBuffer scores,
//     TensorBuffer numDetections,
//     int imageWidth,
//     int imageHeight,
//   ) {
//     // Implement similar post-processing as the notebook
//     // This should include NMS and box decoding
//     // Return list of ObjectDetectionResult
//     return [];
//   }

//   @override
//   void dispose() {
//     _controller.dispose();
//     _interpreter.close();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text('YOLOv8 Object Detection')),
//       body: FutureBuilder<void>(
//         future: _initializeControllerFuture,
//         builder: (context, snapshot) {
//           if (snapshot.connectionState == ConnectionState.done) {
//             return Stack(
//               children: [
//                 CameraPreview(_controller),
//                 CustomPaint(
//                   painter: BoundingBoxPainter(_results),
//                 ),
//               ],
//             );
//           } else {
//             return const Center(child: CircularProgressIndicator());
//           }
//         },
//       ),
//     );
//   }
// }

// class ObjectDetectionResult {
//   final Rect box;
//   final String label;
//   final double score;

//   ObjectDetectionResult(this.box, this.label, this.score);
// }

// class BoundingBoxPainter extends CustomPainter {
//   final List<ObjectDetectionResult> results;

//   BoundingBoxPainter(this.results);

//   @override
//   void paint(Canvas canvas, Size size) {
//     final paint = Paint()
//       ..color = Colors.red
//       ..style = PaintingStyle.stroke
//       ..strokeWidth = 2.0;

//     final textPaint = Paint()
//       ..color = Colors.red
//       ..style = PaintingStyle.fill;

//     for (var result in results) {
//       // Draw bounding box
//       canvas.drawRect(result.box, paint);

//       // Draw label with score
//       final textSpan = TextSpan(
//         text: '${result.label} ${(result.score * 100).toStringAsFixed(1)}%',
//         style: const TextStyle(
//           color: Colors.white,
//           fontSize: 14,
//           backgroundColor: Colors.red,
//         ),
//       );
//       final textPainter = TextPainter(
//         text: textSpan,
//         textDirection: TextDirection.ltr,
//       );
//       textPainter.layout();
//       textPainter.paint(
//         canvas,
//         Offset(result.box.left, result.box.top - textPainter.height),
//       );
//     }
//   }

//   @override
//   bool shouldRepaint(CustomPainter oldDelegate) => true;
// }
