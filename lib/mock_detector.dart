import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:collection/collection.dart';

class MockDetector {
  final ParseStringResult result;

  MockDetector(this.result);

  List<MigrationNode> detect() {
    final nodes = result.unit.childEntities
        .whereType<ImportDirective>()
        .map((e) => _detectImport(e))
        .whereNotNull()
        .toList();
    final mainFn =
        result.unit.childEntities.whereType<FunctionDeclaration>().firstOrNull;
    if (mainFn == null) {
      return nodes;
    }

    nodes.addAll(
      mainFn.childEntities
          .whereType<Annotation>()
          .map((e) => _detectAnnotation(e))
          .whereNotNull(),
    );
    return nodes;
  }

  MigrationNode? _detectImport(ImportDirective directive) {
    final start = result.lineInfo.getLocation(directive.beginToken.offset);
    final end = result.lineInfo.getLocation(directive.endToken.offset);
    final uri = directive.uri.stringValue ?? '';
    if (uri == 'package:mockito/annotations.dart' ||
        uri == 'package:mockito/mockito.dart' ||
        uri.endsWith('.mocks.dart')) {
      return MigrationImportNode(start.lineNumber, end.lineNumber);
    }
    return null;
  }

  MigrationNode? _detectAnnotation(Annotation annotation) {
    if (annotation.name.name != 'GenerateMocks') {
      return null;
    }
    final start = result.lineInfo.getLocation(annotation.beginToken.offset);
    final end = result.lineInfo.getLocation(annotation.endToken.offset);
    final nodes = annotation.childEntities
        .whereType<ArgumentList>()
        .expand((e) => e.arguments)
        .expand<MigrationMockNode>((e) {
      if (e is ListLiteral) {
        return e.elements
            .whereType<SimpleIdentifier>()
            .map((e) => MigrationMockNode('Mock${e.name}', null));
      }
      if (e is NamedExpression && e.name.label.name == 'customMocks') {
        return (e.expression as ListLiteral)
            .elements
            .whereType<MethodInvocation>()
            .map((e) {
          final symbol = e.argumentList.arguments
              .whereType<NamedExpression>()
              .firstWhere((e) => e.name.label.name == 'as')
              .expression;
          final type = e.typeArguments!.arguments.first.childEntities
              .whereType<TypeArgumentList>()
              .first;
          final name = (symbol as SymbolLiteral).components.first.toString();
          return MigrationMockNode(name, type.toString());
        });
      }
      return [];
    }).toList();
    return MigrationAnnotationNode(start.lineNumber, end.lineNumber, nodes);
  }
}

abstract class MigrationNode {
  int get start;

  int get end;
}

class MigrationImportNode implements MigrationNode {
  @override
  final int start;
  @override
  final int end;

  MigrationImportNode(this.start, this.end);
}

class MigrationAnnotationNode implements MigrationNode {
  @override
  final int start;
  @override
  final int end;

  final List<MigrationMockNode> nodes;

  MigrationAnnotationNode(this.start, this.end, this.nodes);
}

class MigrationMockNode {
  final String mockName;
  final String? typeName;

  MigrationMockNode(this.mockName, this.typeName);
}
