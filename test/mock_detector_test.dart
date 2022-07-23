import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:mockito_mocktail_migration_helper/mock_detector.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

void main() {
  test('empty', () async {
    // given
    final parsed = parseFile(
      path: path.absolute('test', 'fixtures', 'test_1.dart'),
      featureSet: FeatureSet.latestLanguageVersion(),
    );
    final detector = MockDetector(parsed);

    // when
    final nodes = detector.detect();

    // then
    expect(nodes, isEmpty);
  });

  test('with annotation', () async {
    // given
    final parsed = parseFile(
      path: path.absolute('test', 'fixtures', 'test_2.dart'),
      featureSet: FeatureSet.latestLanguageVersion(),
    );
    final detector = MockDetector(parsed);

    // when
    final nodes = detector.detect();

    // then
    expect(nodes, hasLength(2));

    expect(nodes[0].start, 1);
    expect(nodes[0].end, 1);

    final node = nodes[1] as MigrationAnnotationNode;
    expect(node.start, 5);
    expect(node.end, 8);
    expect(node.nodes, hasLength(2));
    expect(node.nodes[0].mockName, 'MockTestClass1');
    expect(node.nodes[0].typeName, null);
    expect(node.nodes[1].mockName, 'MockTestClass2');
    expect(node.nodes[1].typeName, '<String>');
  });
}
