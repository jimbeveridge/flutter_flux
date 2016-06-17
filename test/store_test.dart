// Copyright 2015 Workiva Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

@TestOn('vm')
import 'dart:async';

import 'package:flutter_flux/src/action.dart';
import 'package:flutter_flux/src/store.dart';
import 'package:rate_limit/rate_limit.dart';
import 'package:test/test.dart';

import 'utils.dart';

void main() {
  group('Store', () {
    Store store;
    Action action;

    setUp(() {
      store = new Store();
      action = new Action();
    });

    tearDown(() {
      action.clearListeners();
      store.dispose();
    });

    test('should trigger with itself as the payload', () async {
      final c = new Completer();
      store.listen((Store payload) {
        expect(payload, equals(store));
        c.complete();
      });

      store.trigger();
      return c.future;
    });

    test('should support stream transforms', () async {
      // ensure that multiple trigger executions emit
      // exactly 2 throttled triggers to external listeners
      // (1 for the initial trigger and 1 as the aggregate of
      // all others that occurred within the throttled duration)
      int count = 0;
      store = new Store.withTransformer(
          new Throttler(const Duration(milliseconds: 30)));
      store.listen((Store payload) {
        count += 1;
      });

      store.trigger();
      store.trigger();
      store.trigger();
      store.trigger();
      store.trigger();
      await nextTick(60);
      expect(count, equals(2));
    });

    test('should trigger in response to an action', () {
      store.triggerOnAction(action);
      store.listen(expectAsync((payload) {
        expect(payload, equals(store));
      }));
      return action();
    });

    test(
        'should execute a given method and then trigger in response to an action',
        () async {
      bool wasTriggered = false;
      onAction(_) {
        wasTriggered = true;
      }
      store.triggerOnAction(action, onAction);
      store.listen(expectAsync((Store payload) {
        expect(payload, equals(store));
        expect(wasTriggered, isTrue);
      }));
      return action().then((_) {
        expect(wasTriggered, isTrue);
      });
    });

    test(
        'should execute a given method and then trigger in response to a conditional action',
        () {
      bool wasTriggered = false;
      onAction(_) {
        wasTriggered = true;
        return true;
      }
      store.triggerOnConditionalAction(action, onAction);
      store.listen(expectAsync((payload) {
        expect(payload, equals(store));
        expect(wasTriggered, isTrue);
      }));
      return action().then((_) {
        expect(wasTriggered, isTrue);
      });
    });

    test(
        'should execute a given method but NOT trigger in response to a conditional action',
        () {
      onAction(_) => false;
      store.triggerOnConditionalAction(action, onAction);
      store.listen((payload) {
        fail('Event should not have been triggered');
      });
      return action();
    });

    test(
        'should execute a given async method and then trigger in response to an action',
        () {
      bool afterTimer = false;
      asyncCallback(_) async {
        await new Future.delayed(new Duration(milliseconds: 30));
        afterTimer = true;
      }
      store.triggerOnAction(action, asyncCallback);
      store.listen(expectAsync((payload) {
        expect(payload, equals(store));
        expect(afterTimer, isTrue);
      }));
      return action();
    });

    test(
        'should execute a given method and then trigger in response to an action with payload',
        () {
      final _action = new Action<num>();
      num counter = 0;
      store.triggerOnAction(_action, (payload) => counter = payload);
      store.listen(expectAsync((payload) {
        expect(payload, equals(store));
        expect(counter, equals(17));
      }));
      return _action(17);
    });
  });
}
