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

  test('with statements', () async {
    // given
    final parsed = parseFile(
      path: path.absolute('test', 'fixtures', 'test_3.dart'),
      featureSet: FeatureSet.latestLanguageVersion(),
    );
    final detector = MockDetector(parsed);

    // when
    final nodes = detector.detect();

    // then
    expect(nodes, hasLength(7));

    final node1 = nodes[4] as MigrationStubNode;
    expect(node1.start, 21);
    expect(node1.end, 21);
    expect(node1.method, 'when(testClass1.call(0))');
    expect(node1.then, 'thenReturn');
    expect(node1.args, '(3)');

    final node2 = nodes[5] as MigrationStubNode;
    expect(node2.start, 25);
    expect(node2.end, 25);
    expect(node2.method, 'when(testClass1.call(2))');
    expect(node2.then, 'thenReturn');
    expect(node2.args, '(2)');

    final node3 = nodes[6] as MigrationStubNode;
    expect(node3.start, 26);
    expect(node3.end, 26);
    expect(node3.method, 'when(testClass2.call(v: 2))');
    expect(node3.then, 'thenAnswer');
    expect(node3.args, '((_) => Future.value(0))');
  });

  test('with args', () async {
    // given
    final parsed = parseFile(
      path: path.absolute('test', 'fixtures', 'test_4.dart'),
      featureSet: FeatureSet.latestLanguageVersion(),
    );
    final detector = MockDetector(parsed);

    // when
    final nodes = detector.detect();

    // then
    expect(nodes, hasLength(8));

    nodes[4].testNode<MigrationStubNode>((n) {
      expect(n.start, 17);
      expect(n.end, 17);
      expect(n.method, 'when(testClass1.call(0))');
      expect(n.then, 'thenReturn');
      expect(n.args, '(2)');
      expect(n.nodes, isEmpty);
    });
    nodes[5].testNode<MigrationStubNode>((n) {
      expect(n.start, 18);
      expect(n.end, 18);
      expect(
        n.method,
        "when(testClass1.call2(any, flag: anyNamed('flag')))",
      );
      expect(n.then, 'thenReturn');
      expect(n.args, '(2)');
      expect(n.nodes, hasLength(2));
      n.nodes[0].testNode<MigrationAnyNode>((n) {
        expect(n.index, 0);
        expect(n.offset, 22);
        expect(n.captured, false);
        expect(n.matcher, null);
        expect(n.name, null);
      });
      n.nodes[1].testNode<MigrationAnyNode>((n) {
        expect(n.index, 0);
        expect(n.offset, 27);
        expect(n.captured, false);
        expect(n.matcher, null);
        expect(n.name, 'flag');
      });
    });
    nodes[6].testNode<MigrationStubNode>((n) {
      expect(n.start, 19);
      expect(n.end, 19);
      expect(
        n.method,
        "when(testClass1.call3(s: 's'))",
      );
      expect(n.then, 'thenAnswer');
      expect(n.args, "((_) => Future.value(''))");
      expect(n.nodes, isEmpty);
    });
    nodes[7].testNode<MigrationStubNode>((n) {
      expect(n.start, 20);
      expect(n.end, 25);
      expect(
        n.method,
        "when(testClass1.call3(s: argThat(equals('s'), named: 's')))",
      );
      expect(n.then, 'thenAnswer');
      expect(n.args, "((_) => Future.value(''))");
    });
  });
}

extension TestExt<T> on T {
  void testNode<N>(void Function(N n) block) => block(this as N);
}
