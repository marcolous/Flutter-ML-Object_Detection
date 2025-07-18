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

  List<double> finalScores = [];
  List<String> finalLabels = [];
  List<Bbox> finalBoxs = [];

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
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    displayWidth = MediaQuery.of(context).size.width;
    maxImageWidgetHeight = MediaQuery.of(context).size.height;
    maxImageWidgetWidth = MediaQuery.of(context).size.width;
  }

  Future<void> getNutritions(List<String> label) async {
    await context.read<AppProvider>().getNutritionsFdcId(label);
  }

  @override
  Widget build(BuildContext context) {
    final ImagePicker picker = ImagePicker(); // Picker instance

    // Convert bounding box data to widgets
    return Scaffold(
      appBar: AppBar(title: const Text('YOLO')),
      floatingActionButtonLocation: FloatingActionButtonLocation.endTop,
      floatingActionButton: IconButton(
          onPressed: () async {
            context.read<AppProvider>().clearLabelNutrients();
            final XFile? newImageFile =
                await picker.pickImage(source: ImageSource.gallery);
            if (newImageFile != null) {
              setState(() {
                imageFile = File(newImageFile.path);
              });

              // Decode image and run inference
              final image = img.decodeImage(await newImageFile.readAsBytes())!;
              imageWidth = image.width;
              imageHeight = image.height;
              inferenceOutput = model.infer(image);
              await updatePostprocess();
              await getNutritions(finalLabels);
            }
          },
          icon: Icon(Icons.camera)),
      body: Stack(
        children: [
          // Image picker and display area
          SizedBox(
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

          const SizedBox(height: 30),
          Align(
            alignment: Alignment.bottomCenter,
            child: FittedBox(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Nutritionwidget(title: finalLabels),
              ),
            ),
          )
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

    // Calculate how much to resize image to fit screen
    if (imageWidth != null && imageHeight != null) {
      double k1 = displayWidth / imageWidth!;
      double k2 = maxImageWidgetHeight / imageHeight!;
      resizeFactor = min(k1, k2);
    }

    final Map<String, double> labelScores = {};
    final Map<String, Bbox> labelBoxes = {};
    // Accumulate max score per label
    for (int i = 0; i < newBboxes.length; i++) {
      final label = labels[newClasses[i]];
      final box = newBboxes[i];
      final area = box[2] * resizeFactor * box[3] * resizeFactor;
      final score = newScores[i] * area;

      // Take highest score per label
      if (!labelScores.containsKey(label) || labelScores[label]! < score) {
        Bbox bbox = Bbox(
          box[0] * resizeFactor,
          box[1] * resizeFactor,
          box[2] * resizeFactor,
          box[3] * resizeFactor,
          label,
          newScores[i],
          bboxesColors[newClasses[i]],
        );
        labelScores[label] = score;
        labelBoxes[label] = bbox;
      }
    }

    // Sort entries by score descending
    final top5 = labelScores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Select top 5

    setState(() {
      classes = newClasses;
      finalScores = top5.take(5).map((e) => e.value).toList();
      finalLabels = top5.take(5).map((e) => e.key).toList();
      finalBoxs = top5.take(5).map((e) => labelBoxes[e.key]!).toList();
      bboxesWidgets = finalBoxs;
    });
  }
}

class Nutritionwidget extends StatefulWidget {
  const Nutritionwidget({super.key, required this.title});
  final List<String> title;

  @override
  State<Nutritionwidget> createState() => _NutritionwidgetState();
}

class _NutritionwidgetState extends State<Nutritionwidget> {
  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, child) {
        final labelNutrients = provider.labelNutrients;
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (labelNutrients.isEmpty) return const SizedBox();
        return SizedBox(
          height: 400,
          width: 250,
          child: PageView.builder(
            clipBehavior: Clip.none,
            controller: PageController(viewportFraction: .99999999),
            scrollDirection: Axis.horizontal,
            itemCount: labelNutrients.length,
            itemBuilder: (context, index) => Align(
              alignment: Alignment.bottomCenter,
              child: IntrinsicHeightPage(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: NutrientCard(
                    title: widget.title[index],
                    labelList: labelNutrients[index].toLabelList(),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class NutrientCard extends StatefulWidget {
  const NutrientCard({
    super.key,
    required this.title,
    required this.labelList,
  });

  final String title;
  final List<MapEntry<String, String>> labelList;

  @override
  State<NutrientCard> createState() => _NutrientCardState();
}

class _NutrientCardState extends State<NutrientCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    const visibleCount = 3;
    final isExpandable = widget.labelList.length > visibleCount;
    final rows = _expanded
        ? widget.labelList
        : widget.labelList.take(visibleCount).toList();

    return SizedBox(
      width: 250,
      child: ClipRRect(
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: isExpandable
                      ? () => setState(() => _expanded = !_expanded)
                      : null,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        widget.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (isExpandable)
                        AnimatedRotation(
                          duration: const Duration(milliseconds: 200),
                          turns: _expanded ? 0 : 0.5,
                          child: const Icon(
                            Icons.expand_more,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                AnimatedSize(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  child: Column(
                    children: rows
                        .map(
                          (e) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  e.key,
                                  style: const TextStyle(color: Colors.white),
                                ),
                                Text(
                                  '${e.value} g',
                                  style:
                                      const TextStyle(color: Color(0xffb8aaff)),
                                ),
                              ],
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// intrinsic_height_page.dart
class IntrinsicHeightPage extends StatefulWidget {
  final Widget child;

  const IntrinsicHeightPage({super.key, required this.child});

  @override
  State<IntrinsicHeightPage> createState() => _IntrinsicHeightPageState();
}

class _IntrinsicHeightPageState extends State<IntrinsicHeightPage> {
  final GlobalKey _childKey = GlobalKey();
  double? _height;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateHeight());
  }

  void _updateHeight() {
    final context = _childKey.currentContext;
    if (context != null) {
      final box = context.findRenderObject() as RenderBox?;
      final newHeight = box?.size.height;
      if (newHeight != null && newHeight != _height) {
        setState(() => _height = newHeight);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Re-measure on every build to catch shrinking
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateHeight());

    return Align(
      alignment: Alignment.bottomCenter,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        height: _height,
        child: OverflowBox(
          maxHeight: double.infinity,
          alignment: Alignment.bottomCenter,
          child: KeyedSubtree(
            key: _childKey,
            child: widget.child,
          ),
        ),
      ),
    );
  }
}




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