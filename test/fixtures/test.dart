class TestClass1 {
  final String value;

  TestClass1(this.value);

  int call() => 0;
}

class TestClass2<T> {
  final T value;

  TestClass2(this.value);

  int call() => 0;
}

class TestClass {
  final TestClass1 test1;
  final TestClass2<String> test2;

  TestClass(this.test1, this.test2);

  int call() => test1.call() + test2.call();
}
