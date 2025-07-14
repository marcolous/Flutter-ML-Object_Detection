import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img; // used for image decoding
import 'package:image_picker/image_picker.dart'; // used to capture image from camera
import 'package:test_lyna_cam2/main.dart'; // imports your modelPath
import 'package:test_lyna_cam2/models/yolo_model.dart'; // YOLO model wrapper
import 'package:test_lyna_cam2/utils/bbox.dart'; // widget for drawing bounding boxes
import 'package:test_lyna_cam2/utils/labels.dart'; // list of COCO labels

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // YOLO model parameters
  static const inModelWidth = 640;
  static const inModelHeight = 640;
  static const numClasses = 80;
  static const double maxImageWidgetHeight = 400;

  // Initialize the YOLO model
  final YoloModel model = YoloModel(
    modelPath,
    inModelWidth,
    inModelHeight,
    numClasses,
  );

  File? imageFile;

  // Postprocessing thresholds
  double confidenceThreshold = 0.4;
  double iouThreshold = 0.1;
  bool agnosticNMS = false;

  // YOLO output
  List<List<double>>? inferenceOutput;
  List<int> classes = [];
  List<List<double>> bboxes = [];
  List<double> scores = [];

  // Original image dimensions
  int? imageWidth;
  int? imageHeight;

  @override
  void initState() {
    super.initState();
    model.init(); // Load model
  }

  @override
  Widget build(BuildContext context) {
    // Generate random colors for each class
    final bboxesColors = List<Color>.generate(
      numClasses,
      (_) => Color((Random().nextDouble() * 0xFFFFFF).toInt()).withAlpha(255),
    );

    final ImagePicker picker = ImagePicker(); // Picker instance

    final double displayWidth = MediaQuery.of(context).size.width;

    const textPadding = EdgeInsets.symmetric(horizontal: 16);

    double resizeFactor = 1;

    // Calculate how much to resize image to fit screen
    if (imageWidth != null && imageHeight != null) {
      double k1 = displayWidth / imageWidth!;
      double k2 = maxImageWidgetHeight / imageHeight!;
      resizeFactor = min(k1, k2);
    }

    // Convert bounding box data to widgets
    List<Bbox> bboxesWidgets = [];
    for (int i = 0; i < bboxes.length; i++) {
      final box = bboxes[i];
      final boxClass = classes[i];
      bboxesWidgets.add(
        Bbox(
          box[0] * resizeFactor,
          box[1] * resizeFactor,
          box[2] * resizeFactor,
          box[3] * resizeFactor,
          labels[boxClass],
          scores[i],
          bboxesColors[boxClass],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('YOLO')),
      body: ListView(
        children: [
          // Image picker and display area
          InkWell(
            onTap: () async {
              final XFile? newImageFile =
                  await picker.pickImage(source: ImageSource.camera);
              if (newImageFile != null) {
                setState(() {
                  imageFile = File(newImageFile.path);
                });

                // Decode image and run inference
                final image =
                    img.decodeImage(await newImageFile.readAsBytes())!;
                imageWidth = image.width;
                imageHeight = image.height;
                inferenceOutput = model.infer(image);
                updatePostprocess();
              }
            },
            child: SizedBox(
              height: maxImageWidgetHeight,
              child: Center(
                child: Stack(
                  children: [
                    // Show placeholder or image
                    if (imageFile == null)
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.file_open_outlined, size: 80),
                          Text(
                            'Pick an image',
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                        ],
                      )
                    else
                      Image.file(imageFile!),
                    // Overlay bounding boxes
                    ...bboxesWidgets,
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 30),

          // Confidence threshold slider
          Padding(
            padding: textPadding,
            child: Row(
              children: [
                Text(
                  'Confidence threshold:',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(width: 8),
                Text(
                  '${(confidenceThreshold * 100).toStringAsFixed(0)}%',
                  style: Theme.of(context)
                      .textTheme
                      .bodyLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const Padding(
            padding: textPadding,
            child: Text(
              'If high, only the clearly recognizable objects will be detected. If low even not clear objects will be detected.',
            ),
          ),
          Slider(
            value: confidenceThreshold,
            min: 0,
            max: 1,
            divisions: 100,
            onChanged: (value) {
              setState(() {
                confidenceThreshold = value;
                updatePostprocess();
              });
            },
          ),

          const SizedBox(height: 8),

          // IoU threshold slider
          Padding(
            padding: textPadding,
            child: Row(
              children: [
                Text(
                  'IoU threshold',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(width: 8),
                Text(
                  '${(iouThreshold * 100).toStringAsFixed(0)}%',
                  style: Theme.of(context)
                      .textTheme
                      .bodyLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const Padding(
            padding: textPadding,
            child: Text(
              'If high, overlapped objects will be detected. If low, only separated objects will be correctly detected.',
            ),
          ),
          Slider(
            value: iouThreshold,
            min: 0,
            max: 1,
            divisions: 100,
            onChanged: (value) {
              setState(() {
                iouThreshold = value;
                updatePostprocess();
              });
            },
          ),

          // Agnostic NMS toggle
          SwitchListTile(
            value: agnosticNMS,
            title: Text(
              'Agnostic NMS',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            subtitle: Text(
              agnosticNMS
                  ? 'Treat all the detections as the same object'
                  : 'Detections with different labels are different objects',
            ),
            onChanged: (value) {
              setState(() {
                agnosticNMS = value;
                updatePostprocess();
              });
            },
          ),
        ],
      ),
    );
  }

  /// Run postprocessing (NMS) and update the detected boxes, scores, and classes
  void updatePostprocess() {
    if (inferenceOutput == null) return;

    final (newClasses, newBboxes, newScores) = model.postprocess(
      inferenceOutput!,
      imageWidth!,
      imageHeight!,
      confidenceThreshold: confidenceThreshold,
      iouThreshold: iouThreshold,
      agnostic: agnosticNMS,
    );

    debugPrint('Detected ${newBboxes.length} bboxes');

    setState(() {
      classes = newClasses;
      bboxes = newBboxes;
      scores = newScores;
    });
  }
}
