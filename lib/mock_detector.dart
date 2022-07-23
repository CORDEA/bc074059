import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';

class MockDetector {
  final ParseStringResult result;

  MockDetector(this.result);

  List<MigrationNode> detect() {
    final nodes = <MigrationNode>[];
    for (final value in result.unit.childEntities) {
      if (value is ImportDirective) {
        final node = _detectImports(value);
        if (node == null) {
          continue;
        }
        nodes.add(node);
      }
      if (value is FunctionDeclaration) {}
    }
    return nodes;
  }

  MigrationNode? _detectImports(ImportDirective directive) {
    final location = result.lineInfo.getLocation(directive.offset);
    final uri = directive.uri.stringValue ?? '';
    if (uri == 'package:mockito/annotations.dart') {
      return MigrationImportNode(location.lineNumber);
    }
    if (uri == 'package:mockito/mockito.dart') {
      return MigrationImportNode(location.lineNumber);
    }
    if (uri.endsWith('.mocks.dart')) {
      return MigrationImportNode(location.lineNumber);
    }
    return null;
  }
}

abstract class MigrationNode {
  int get line;
}

class MigrationImportNode implements MigrationNode {
  @override
  final int line;

  MigrationImportNode(this.line);
}
