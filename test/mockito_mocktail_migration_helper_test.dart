import 'package:mockito_mocktail_migration_helper/mockito_mocktail_migration_helper.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

void main() {
  test('migrate', () {
    migrate([path.absolute('test', 'fixtures', 'test_1.dart')]);
  });
}
