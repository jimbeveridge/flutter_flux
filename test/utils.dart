import 'dart:async';

Future<Null> nextTick([int milliseconds = 1]) {
  return new Future<Null>.delayed(new Duration(milliseconds: milliseconds));
}
