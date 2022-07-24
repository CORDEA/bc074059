import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/source/line_info.dart';
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
    nodes.addAll(
      mainFn.childEntities
          .whereType<FunctionExpression>()
          .first
          .body
          .childEntities
          .whereType<Block>()
          .first
          .statements
          .whereType<ExpressionStatement>()
          .map((e) => e.expression)
          .expand((e) {
        final label = (e.childEntities.first as SimpleIdentifier).name;
        final node = e.childEntities.last as ArgumentList;
        switch (label) {
          case 'setUp':
            return _detectStatements(node.arguments.first);
          case 'test':
            return _detectStatements(node.arguments.last);
        }
        return [];
      }),
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

  List<MigrationNode> _detectStatements(Expression expression) {
    final body = expression.childEntities.last as BlockFunctionBody;
    return body.block.statements
        .whereType<ExpressionStatement>()
        .map((e) => e.expression)
        .whereType<MethodInvocation>()
        .map((e) {
          final method =
              e.childEntities.whereType<MethodInvocation>().firstOrNull;
          final start = result.lineInfo.getLocation(e.beginToken.offset);
          final end = result.lineInfo.getLocation(e.endToken.offset);
          switch (method?.methodName.name) {
            case 'when':
            case 'verify':
              final args = _detectArguments(method);
              return MigrationStubNode(
                start.lineNumber,
                end.lineNumber,
                method.toString(),
                e.function.toString(),
                e.argumentList.toString(),
                args,
              );
          }
          return null;
        })
        .whereNotNull()
        .toList();
  }

  List<MigrationArgumentNode> _detectArguments(MethodInvocation? method) {
    if (method == null) {
      return [];
    }
    final start = result.lineInfo.getLocation(method.beginToken.offset);
    final arg =
        method.argumentList.arguments.whereType<MethodInvocation>().first;
    return arg.argumentList.arguments
        .map((e) => _detectArgument(e, start))
        .whereType<MigrationArgumentNode>()
        .toList();
  }

  MigrationArgumentNode? _detectArgument(
    Expression exp,
    CharacterLocation base,
  ) {
    final current = result.lineInfo.getLocation(exp.beginToken.offset);
    final start = current.lineNumber - base.lineNumber;
    final offset = current.columnNumber - base.columnNumber;
    if (exp is SimpleIdentifier) {
      switch (exp.name) {
        case 'any':
          return MigrationAnyNode(start, offset, false, null, null);
        case 'captureAny':
          return MigrationAnyNode(start, offset, true, null, null);
      }
    }
    if (exp is NamedExpression) {
      final method = exp.expression;
      if (method is! MethodInvocation) {
        return null;
      }
      final args = method.argumentList.arguments;
      switch (method.methodName.name) {
        case 'anyNamed':
          final name = args.first as SimpleStringLiteral;
          return MigrationAnyNode(start, offset, false, name.value, null);
        case 'captureAnyNamed':
          final name = args.first as SimpleStringLiteral;
          return MigrationAnyNode(start, offset, true, name.value, null);
        case 'captureThat':
          final name =
              (args.last as NamedExpression).expression as SimpleStringLiteral;
          return MigrationAnyNode(
            start,
            offset,
            true,
            name.value,
            args.first.toString(),
          );
        case 'argThat':
          final name =
              (args.last as NamedExpression).expression as SimpleStringLiteral;
          return MigrationAnyNode(
            start,
            offset,
            false,
            name.value,
            args.first.toString(),
          );
      }
    }
    return null;
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

class MigrationStubNode implements MigrationNode {
  @override
  final int start;
  @override
  final int end;

  final String method;
  final String then;
  final String args;
  final List<MigrationArgumentNode> nodes;

  MigrationStubNode(
    this.start,
    this.end,
    this.method,
    this.then,
    this.args,
    this.nodes,
  );
}

abstract class MigrationArgumentNode {
  int get index;

  int get offset;
}

class MigrationAnyNode implements MigrationArgumentNode {
  @override
  final int index;
  @override
  final int offset;
  final bool captured;
  final String? name;
  final String? matcher;

  MigrationAnyNode(
    this.index,
    this.offset,
    this.captured,
    this.name,
    this.matcher,
  );
}

class MigrationArgThatNode implements MigrationArgumentNode {
  @override
  final int index;
  @override
  final int offset;
  final String? name;
  final String? matcher;

  MigrationArgThatNode(this.index, this.offset, this.name, this.matcher);
}
