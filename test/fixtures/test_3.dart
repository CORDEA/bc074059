import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import 'test.dart';
import 'test_3.mocks.dart';

@GenerateMocks(
  [TestClass1],
  customMocks: [MockSpec<TestClass2<String>>(as: #MockTestClass2)],
)
void main() {
  late MockTestClass1 testClass1;
  late MockTestClass2 testClass2;
  late TestClass testClass;

  setUp(() {
    testClass1 = MockTestClass1();
    testClass2 = MockTestClass2();
    testClass = TestClass(testClass1, testClass2);
    when(testClass1.call(0)).thenReturn(3);
  });

  test('description', () async {
    when(testClass1.call(2)).thenReturn(2);
    when(testClass2.call(v: 2)).thenAnswer((_) => Future.value(0));

    final result = await testClass.call(v: 2);

    expect(result, 4);
  });
}
