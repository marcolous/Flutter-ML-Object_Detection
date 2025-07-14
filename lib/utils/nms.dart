import 'dart:math';

/// Runs Non-Maximum Suppression on YOLO model output.
/// Returns: (classes, boxes, scores)
(List<int>, List<List<double>>, List<double>) nms(
  List<List<double>> rawOutput, {
  double confidenceThreshold = 0.7, // filter weak detections
  double iouThreshold = 0.4, // how much overlap allowed
  bool agnostic = false, // if true, ignore class during NMS
}) {
  List<int> bestClasses = [];
  List<double> bestScores = [];
  List<int> boxesToSave = [];

  // 1. Get top class per prediction and filter by confidence
  for (int i = 0; i < 8400; i++) {
    double bestScore = 0;
    int bestCls = -1;

    // Loop over class scores (84 total, skip first 4 for box coords)
    for (int j = 4; j < 84; j++) {
      double clsScore = rawOutput[j][i];
      if (clsScore > bestScore) {
        bestScore = clsScore;
        bestCls = j - 4;
      }
    }

    // Keep predictions above threshold
    if (bestScore > confidenceThreshold) {
      bestClasses.add(bestCls);
      bestScores.add(bestScore);
      boxesToSave.add(i);
    }
  }

  // 2. Extract the box coordinates for saved indices
  List<List<double>> candidateBoxes = [];
  for (var index in boxesToSave) {
    List<double> savedBox = [];
    for (int i = 0; i < 4; i++) {
      savedBox.add(rawOutput[i][index]);
    }
    candidateBoxes.add(savedBox);
  }

  // 3. Sort boxes by score (descending)
  var sortedBestScores = List.from(bestScores);
  sortedBestScores.sort((a, b) => -a.compareTo(b));
  List<int> argSortList =
      sortedBestScores.map((e) => bestScores.indexOf(e)).toList();

  List<int> sortedBestClasses = [];
  List<List<double>> sortedCandidateBoxes = [];
  for (var index in argSortList) {
    sortedBestClasses.add(bestClasses[index]);
    sortedCandidateBoxes.add(candidateBoxes[index]);
  }

  // 4. Apply NMS to remove overlapping boxes
  List<List<double>> finalBboxes = [];
  List<double> finalScores = [];
  List<int> finalClasses = [];

  while (sortedCandidateBoxes.isNotEmpty) {
    var bbox1xywh = sortedCandidateBoxes.removeAt(0);
    finalBboxes.add(bbox1xywh);
    var bbox1xyxy = xywh2xyxy(bbox1xywh); // convert format
    finalScores.add(sortedBestScores.removeAt(0));
    var class1 = sortedBestClasses.removeAt(0);
    finalClasses.add(class1);

    List<int> indexesToRemove = [];
    for (int i = 0; i < sortedCandidateBoxes.length; i++) {
      // Suppress box if overlapping and same class (unless agnostic)
      if ((agnostic || class1 == sortedBestClasses[i]) &&
          computeIou(bbox1xyxy, xywh2xyxy(sortedCandidateBoxes[i])) >
              iouThreshold) {
        indexesToRemove.add(i);
      }
    }

    // Remove suppressed boxes
    for (var index in indexesToRemove.reversed) {
      sortedCandidateBoxes.removeAt(index);
      sortedBestClasses.removeAt(index);
      sortedBestScores.removeAt(index);
    }
  }

  return (finalClasses, finalBboxes, finalScores);
}

/// Converts bounding box from center-based (x, y, w, h) to corner-based (x1, y1, x2, y2)
List<double> xywh2xyxy(List<double> bbox) {
  double halfWidth = bbox[2] / 2;
  double halfHeight = bbox[3] / 2;
  return [
    bbox[0] - halfWidth,
    bbox[1] - halfHeight,
    bbox[0] + halfWidth,
    bbox[1] + halfHeight,
  ];
}

/// Calculates IOU between two bounding boxes (xyxy format)
double computeIou(List<double> bbox1, List<double> bbox2) {
  double xLeft = max(bbox1[0], bbox2[0]);
  double yTop = max(bbox1[1], bbox2[1]);
  double xRight = min(bbox1[2], bbox2[2]);
  double yBottom = min(bbox1[3], bbox2[3]);

  if (xRight < xLeft || yBottom < yTop) return 0;

  double intersectionArea = (xRight - xLeft) * (yBottom - yTop);
  double bbox1Area = (bbox1[2] - bbox1[0]) * (bbox1[3] - bbox1[1]);
  double bbox2Area = (bbox2[2] - bbox2[0]) * (bbox2[3] - bbox2[1]);

  return intersectionArea / (bbox1Area + bbox2Area - intersectionArea);
}
