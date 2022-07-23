class TestClass1 {
  final String value;

  TestClass1(this.value);

  int call(int v) => 0 + v;
}

class TestClass2<T> {
  final T value;

  TestClass2(this.value);

  Future<int> call({required int v}) async => 0 + v;
}

class TestClass {
  final TestClass1 test1;
  final TestClass2<String> test2;

  TestClass(this.test1, this.test2);

  Future<int> call({required int v}) async =>
      test1.call(v) + (await test2.call(v: v)) + v;
}
