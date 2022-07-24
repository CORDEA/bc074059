import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import 'test.dart';
import 'test_4.mocks.dart';

@GenerateMocks([TestClass1])
void main() {
  late MockTestClass1 testClass1;

  setUp(() {
    testClass1 = MockTestClass1();
  });

  test('description', () async {
    when(testClass1.call(0)).thenReturn(2);
    when(testClass1.call2(any, flag: anyNamed('flag'))).thenReturn(2);
    when(testClass1.call3(s: 's')).thenAnswer((_) => Future.value(''));
    when(testClass1.call3(
      s: argThat(
        equals('s'),
        named: 's',
      ),
    )).thenAnswer((_) => Future.value(''));
  });
}
