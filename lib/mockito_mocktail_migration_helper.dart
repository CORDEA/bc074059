import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/analysis/utilities.dart';

import 'mock_detector.dart';

void migrate(List<String> paths) {
  for (final path in paths) {
    _migrate(path);
  }
}

void _migrate(String path) {
  final parsed =
      parseFile(path: path, featureSet: FeatureSet.latestLanguageVersion());
  final detector = MockDetector(parsed);
  final result = detector.detect();
}
