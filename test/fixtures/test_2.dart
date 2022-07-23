import 'package:mockito/annotations.dart';

import 'test.dart';

@GenerateMocks(
  [TestClass1],
  customMocks: [MockSpec<TestClass2<String>>(as: #MockTestClass2)],
)
void main() {}
