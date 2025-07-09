// import 'dart:io';
// import 'dart:ui' as ui;
// import 'package:flutter/material.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:test_lyna_cam2/main.dart';
// import 'package:tflite_flutter/tflite_flutter.dart';
// import 'package:tflite_flutter_helper/tflite_flutter_helper.dart';

// const int inputSize = 640; // YOLOv11s input size

// class GalleryScreen extends StatefulWidget {
//   const GalleryScreen({super.key});

//   @override
//   _GalleryScreenState createState() => _GalleryScreenState();
// }

// class _GalleryScreenState extends State<GalleryScreen> {
//   late Interpreter _interpreter;
//   bool _isModelLoaded = false;
//   List<ObjectDetectionResult> _results = [];
//   File? _selectedImage;
//   bool _isProcessing = false;
//   final ImageProcessor imageProcessor = ImageProcessorBuilder()
//       .add(ResizeOp(inputSize, inputSize, ResizeMethod.BILINEAR))
//       .add(NormalizeOp(0, 255))
//       .build();

//   @override
//   void initState() {
//     super.initState();
//     loadModel();
//   }

//   Future<void> loadModel() async {
//     try {
//       // Load the model from assets using the provided path
//       _interpreter = await Interpreter.fromAsset(modelPath);

//       // Get and print input tensor information
//       final inputTensor = _interpreter.getInputTensor(0);
//       debugPrint('🔍 Model Path: $modelPath');
//       debugPrint(
//           '🔍 Input shape: ${inputTensor.shape}'); // e.g. [1, 640, 640, 3]
//       debugPrint('🔍 Input type: ${inputTensor.type}'); // e.g. float32

//       // Loop through all output tensors and print their info
//       final outputCount = _interpreter.getOutputTensors().length;
//       for (int i = 0; i < outputCount; i++) {
//         final tensor = _interpreter.getOutputTensor(i);
//         debugPrint('🔍 Output $i shape: ${tensor.shape}'); // e.g. [1, 84, 8400]
//         debugPrint('🔍 Output $i type: ${tensor.type}');
//       }
//     } catch (e) {
//       debugPrint('❌ Failed to load TFLite model: $e'); // Log any error
//     }
//   }

//   // Future<void> _loadModel() async {
//   //   try {
//   //     // Load YOLOv11s model
//   //     final options = InterpreterOptions();

//   //     // Use GPU delegate if available (recommended for YOLO models)
//   //     try {
//   //       options.addDelegate(GpuDelegateV2());
//   //     } catch (e) {
//   //       debugPrint('GPU delegate not available: $e');
//   //     }

//   //     _interpreter = await Interpreter.fromAsset('yolo11s_float16.tflite',
//   //         options: options);

//   //     setState(() {
//   //       _isModelLoaded = true;
//   //     });
//   //   } catch (e) {
//   //     debugPrint('Failed to load model: $e');
//   //   }
//   // }

//   Future<void> _pickImage() async {
//     final picker = ImagePicker();
//     final pickedFile = await picker.pickImage(source: ImageSource.gallery);

//     if (pickedFile != null) {
//       setState(() {
//         _selectedImage = File(pickedFile.path);
//         _isProcessing = true;
//         _results = []; // Clear previous results
//       });

//       await _runInference(_selectedImage!);

//       setState(() {
//         _isProcessing = false;
//       });
//     }
//   }

//   Future<void> _runInference(File imageFile) async {
//     if (!_isModelLoaded) return;

//     try {
//       // 1. Get image dimensions
//       final image = await _getImageDimensions(imageFile);
//       final imageWidth = image.width.toDouble();
//       final imageHeight = image.height.toDouble();

//       // 2. Preprocess image
//       TensorImage tensorImage = TensorImage.fromFile(imageFile);
//       tensorImage = imageProcessor.process(tensorImage);

//       // 3. Prepare output tensors (YOLOv11s specific)
//       // YOLOv11s output format: [1, 84, 8400] (class scores + boxes)
//       final outputShape = _interpreter.getOutputTensor(0).shape;
//       final outputBuffer =
//           TensorBuffer.createFixedSize(outputShape, TfLiteType.float32);

//       // 4. Run inference
//       _interpreter.run(tensorImage.buffer, outputBuffer.buffer);

//       // 5. Process YOLOv11s output
//       _results = _processYolov11Output(
//         outputBuffer,
//         imageWidth,
//         imageHeight,
//       );
//     } catch (e) {
//       debugPrint('Inference error: $e');
//       setState(() {
//         _results = [];
//       });
//     }
//   }

//   List<ObjectDetectionResult> _processYolov11Output(
//     TensorBuffer outputBuffer,
//     double imageWidth,
//     double imageHeight,
//   ) {
//     final List<ObjectDetectionResult> results = [];
//     final output = outputBuffer.getDoubleList();
//     const numClasses = 80; // COCO dataset classes
//     const confidenceThreshold = 0.5;
//     const nmsThreshold = 0.45;

//     // YOLOv11s output format: [1, 84, 8400]
//     // Where 84 = 4 (box) + 80 (classes)
//     for (int i = 0; i < 8400; i++) {
//       final index = i * (numClasses + 4);

//       // Get bounding box coordinates (cx, cy, w, h)
//       final xCenter = output[index] * imageWidth;
//       final yCenter = output[index + 1] * imageHeight;
//       final width = output[index + 2] * imageWidth;
//       final height = output[index + 3] * imageHeight;

//       // Get class scores
//       double maxScore = 0;
//       int classId = 0;
//       for (int c = 0; c < numClasses; c++) {
//         final score = output[index + 4 + c];
//         if (score > maxScore) {
//           maxScore = score;
//           classId = c;
//         }
//       }

//       // Apply confidence threshold
//       if (maxScore > confidenceThreshold) {
//         final left = xCenter - width / 2;
//         final top = yCenter - height / 2;
//         final right = xCenter + width / 2;
//         final bottom = yCenter + height / 2;

//         results.add(ObjectDetectionResult(
//           Rect.fromLTRB(left, top, right, bottom),
//           _getLabel(classId),
//           maxScore,
//         ));
//       }
//     }

//     // Apply Non-Maximum Suppression
//     return _nonMaxSuppression(results, nmsThreshold);
//   }

//   List<ObjectDetectionResult> _nonMaxSuppression(
//     List<ObjectDetectionResult> results,
//     double threshold,
//   ) {
//     results.sort((a, b) => b.score.compareTo(a.score));
//     final List<ObjectDetectionResult> filtered = [];

//     while (results.isNotEmpty) {
//       final best = results.removeAt(0);
//       filtered.add(best);
//       results.removeWhere((r) => _iou(r.box, best.box) > threshold);
//     }

//     return filtered;
//   }

//   double _iou(Rect a, Rect b) {
//     final interLeft = a.left > b.left ? a.left : b.left;
//     final interTop = a.top > b.top ? a.top : b.top;
//     final interRight = a.right < b.right ? a.right : b.right;
//     final interBottom = a.bottom < b.bottom ? a.bottom : b.bottom;

//     final interArea = (interRight - interLeft) * (interBottom - interTop);
//     final unionArea = a.width * a.height + b.width * b.height - interArea;

//     return interArea / unionArea;
//   }

//   String _getLabel(int classIndex) {
//     // COCO dataset labels (adjust for your model)
//     const labels = [
//       'person',
//       'bicycle',
//       'car',
//       'motorcycle',
//       'airplane',
//       'bus',
//       'train',
//       'truck',
//       'boat',
//       'traffic light',
//       'fire hydrant',
//       'stop sign',
//       'parking meter',
//       'bench',
//       'bird',
//       'cat',
//       'dog',
//       'horse',
//       'sheep',
//       'cow',
//       'elephant',
//       'bear',
//       'zebra',
//       'giraffe',
//       'backpack',
//       'umbrella',
//       'handbag',
//       'tie',
//       'suitcase',
//       'frisbee',
//       'skis',
//       'snowboard',
//       'sports ball',
//       'kite',
//       'baseball bat',
//       'baseball glove',
//       'skateboard',
//       'surfboard',
//       'tennis racket',
//       'bottle',
//       'wine glass',
//       'cup',
//       'fork',
//       'knife',
//       'spoon',
//       'bowl',
//       'banana',
//       'apple',
//       'sandwich',
//       'orange',
//       'broccoli',
//       'carrot',
//       'hot dog',
//       'pizza',
//       'donut',
//       'cake',
//       'chair',
//       'couch',
//       'potted plant',
//       'bed',
//       'dining table',
//       'toilet',
//       'tv',
//       'laptop',
//       'mouse',
//       'remote',
//       'keyboard',
//       'cell phone',
//       'microwave',
//       'oven',
//       'toaster',
//       'sink',
//       'refrigerator',
//       'book',
//       'clock',
//       'vase',
//       'scissors',
//       'teddy bear',
//       'hair drier',
//       'toothbrush'
//     ];
//     return classIndex < labels.length
//         ? labels[classIndex]
//         : 'class $classIndex';
//   }

//   @override
//   void dispose() {
//     _interpreter.close();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text('YOLOv11s Object Detection')),
//       body: Center(
//         child: Column(
//           children: [
//             if (_selectedImage != null)
//               Expanded(
//                 child: FutureBuilder<ui.Image>(
//                   future: _getImageDimensions(_selectedImage!),
//                   builder: (context, snapshot) {
//                     if (snapshot.hasData) {
//                       return Stack(
//                         children: [
//                           Image.file(_selectedImage!),
//                           CustomPaint(
//                             painter: BoundingBoxPainter(
//                               _results,
//                               snapshot.data!.width.toDouble(),
//                               snapshot.data!.height.toDouble(),
//                             ),
//                             child: Container(),
//                           ),
//                         ],
//                       );
//                     } else if (snapshot.hasError) {
//                       return Text('Error: ${snapshot.error}');
//                     }
//                     return const Center(child: CircularProgressIndicator());
//                   },
//                 ),
//               )
//             else
//               const Expanded(child: Center(child: Text('No image selected'))),
//             if (_isProcessing) const LinearProgressIndicator(),
//           ],
//         ),
//       ),
//       floatingActionButton: FloatingActionButton(
//         onPressed: _pickImage,
//         child: const Icon(Icons.image),
//       ),
//     );
//   }

//   Future<ui.Image> _getImageDimensions(File imageFile) async {
//     final data = await imageFile.readAsBytes();
//     final codec = await ui.instantiateImageCodec(data);
//     final frame = await codec.getNextFrame();
//     return frame.image;
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
//   final double imageWidth;
//   final double imageHeight;

//   BoundingBoxPainter(this.results, this.imageWidth, this.imageHeight);

//   @override
//   void paint(Canvas canvas, Size size) {
//     final scaleX = size.width / imageWidth;
//     final scaleY = size.height / imageHeight;

//     for (final result in results) {
//       final paint = Paint()
//         ..color = Colors.red
//         ..style = PaintingStyle.stroke
//         ..strokeWidth = 2;

//       final rect = Rect.fromLTRB(
//         result.box.left * scaleX,
//         result.box.top * scaleY,
//         result.box.right * scaleX,
//         result.box.bottom * scaleY,
//       );

//       canvas.drawRect(rect, paint);

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
//         Offset(rect.left, rect.top - textPainter.height),
//       );
//     }
//   }

//   @override
//   bool shouldRepaint(CustomPainter oldDelegate) => true;
// }
