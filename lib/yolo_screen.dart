import 'dart:io';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img; // used for image decoding
import 'package:image_picker/image_picker.dart'; // used to capture image from camera
import 'package:provider/provider.dart';
import 'package:test_lyna_cam2/main.dart'; // imports your modelPath
import 'package:test_lyna_cam2/manager/app_provider.dart';
import 'package:test_lyna_cam2/models/nutrient_model.dart';
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
  // static const double maxImageWidgetHeight = 400;

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
  double resizeFactor = 1;
  late double displayWidth;
  late double maxImageWidgetHeight;
  late double maxImageWidgetWidth;

  double score = -1;
  String label = '';

  // YOLO output
  List<List<double>>? inferenceOutput;
  List<int> classes = [];
  List<List<double>> bboxes = [];
  List<double> scores = [];
  List<Bbox> bboxesWidgets = [];

  // Generate random colors for each class
  final bboxesColors = List<Color>.generate(
    numClasses,
    (_) => Color((Random().nextDouble() * 0xFFFFFF).toInt()).withAlpha(255),
  );

  // Original image dimensions
  int? imageWidth;
  int? imageHeight;

  @override
  void initState() {
    super.initState();
    model.init(); // Load model
    // displayWidth = MediaQuery.of(context).size.width;
    // maxImageWidgetHeight = MediaQuery.of(context).size.height;
    // maxImageWidgetWidth = MediaQuery.of(context).size.width;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    displayWidth = MediaQuery.of(context).size.width;
    maxImageWidgetHeight = MediaQuery.of(context).size.height;
    maxImageWidgetWidth = MediaQuery.of(context).size.width;
  }

  Future<void> getNutritions(String label) async {
    await context.read<AppProvider>().getNutritionsFdcId(label);
  }

  @override
  Widget build(BuildContext context) {
    final ImagePicker picker = ImagePicker(); // Picker instance

    const textPadding = EdgeInsets.symmetric(horizontal: 16);

    // Convert bounding box data to widgets

    return Scaffold(
      appBar: AppBar(title: const Text('YOLO')),
      body: Stack(
        children: [
          // Image picker and display area
          InkWell(
            onTap: () async {
              context.read<AppProvider>().clearLabelNutrients();
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
                await updatePostprocess();
                await getNutritions(label);
              }
            },
            child: SizedBox(
              height: maxImageWidgetHeight,
              width: maxImageWidgetWidth,
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
          Positioned(
            bottom: 30,
            left: 70,
            right: 70,
            child: Nutritionwidget(title: label),
          ),

          // Confidence threshold slider
          // Padding(
          //   padding: textPadding,
          //   child: Row(
          //     children: [
          //       Text(
          //         'Confidence threshold:',
          //         style: Theme.of(context).textTheme.bodyLarge,
          //       ),
          //       const SizedBox(width: 8),
          //       Text(
          //         '${(confidenceThreshold * 100).toStringAsFixed(0)}%',
          //         style: Theme.of(context)
          //             .textTheme
          //             .bodyLarge
          //             ?.copyWith(fontWeight: FontWeight.bold),
          //       ),
          //     ],
          //   ),
          // ),
          // const Padding(
          //   padding: textPadding,
          //   child: Text(
          //     'If high, only the clearly recognizable objects will be detected. If low even not clear objects will be detected.',
          //   ),
          // ),
          // Slider(
          //   value: confidenceThreshold,
          //   min: 0,
          //   max: 1,
          //   divisions: 100,
          //   onChanged: (value) {
          //     setState(() {
          //       confidenceThreshold = value;
          //       updatePostprocess();
          //     });
          //   },
          // ),

          // const SizedBox(height: 8),

          // // IoU threshold slider
          // Padding(
          //   padding: textPadding,
          //   child: Row(
          //     children: [
          //       Text(
          //         'IoU threshold',
          //         style: Theme.of(context).textTheme.bodyLarge,
          //       ),
          //       const SizedBox(width: 8),
          //       Text(
          //         '${(iouThreshold * 100).toStringAsFixed(0)}%',
          //         style: Theme.of(context)
          //             .textTheme
          //             .bodyLarge
          //             ?.copyWith(fontWeight: FontWeight.bold),
          //       ),
          //     ],
          //   ),
          // ),
          // const Padding(
          //   padding: textPadding,
          //   child: Text(
          //     'If high, overlapped objects will be detected. If low, only separated objects will be correctly detected.',
          //   ),
          // ),
          // Slider(
          //   value: iouThreshold,
          //   min: 0,
          //   max: 1,
          //   divisions: 100,
          //   onChanged: (value) {
          //     setState(() {
          //       iouThreshold = value;
          //       updatePostprocess();
          //     });
          //   },
          // ),

          // // Agnostic NMS toggle
          // SwitchListTile(
          //   value: agnosticNMS,
          //   title: Text(
          //     'Agnostic NMS',
          //     style: Theme.of(context).textTheme.bodyLarge,
          //   ),
          //   subtitle: Text(
          //     agnosticNMS
          //         ? 'Treat all the detections as the same object'
          //         : 'Detections with different labels are different objects',
          //   ),
          //   onChanged: (value) {
          //     setState(() {
          //       agnosticNMS = value;
          //       updatePostprocess();
          //     });
          //   },
          // ),
        ],
      ),
    );
  }

  /// Run postprocessing (NMS) and update the detected boxes, scores, and classes
  Future<void> updatePostprocess() async {
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

    final newBboxWidgets = <Bbox>[];
    double maxScore = -1;
    String bestLabel = '';

    // Calculate how much to resize image to fit screen
    if (imageWidth != null && imageHeight != null) {
      double k1 = displayWidth / imageWidth!;
      double k2 = maxImageWidgetHeight / imageHeight!;
      resizeFactor = min(k1, k2);
    }

    for (int i = 0; i < newBboxes.length; i++) {
      final box = newBboxes[i];
      final boxClass = newClasses[i];

      newBboxWidgets.add(
        Bbox(
          box[0] * resizeFactor,
          box[1] * resizeFactor,
          box[2] * resizeFactor,
          box[3] * resizeFactor,
          labels[boxClass],
          newScores[i],
          bboxesColors[boxClass],
        ),
      );

      if (newScores[i] > maxScore) {
        maxScore = newScores[i];
        bestLabel = labels[boxClass];
      }
    }

    setState(() {
      classes = newClasses;
      bboxes = newBboxes;
      scores = newScores;
      bboxesWidgets = newBboxWidgets;
      score = maxScore;
      label = bestLabel;
    });
  }
}

class Nutritionwidget extends StatelessWidget {
  const Nutritionwidget({super.key, required this.title});
  final String title;

  Widget rowItem(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white),
        ),
        const SizedBox(width: 5),
        Text(
          '$value g',
          style: const TextStyle(color: Color(0xffb8aaff)),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, child) {
        final labelNutrients = provider.labelNutrients;
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (labelNutrients == null) {
          return const SizedBox();
        }
        final labelList = labelNutrients.toLabelList();

        return ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold),
                  ),
                  ListView.separated(
                    shrinkWrap: true,
                    itemBuilder: (context, index) =>
                        rowItem(labelList[index].key, labelList[index].value),
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 10),
                    itemCount: labelList.length,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
