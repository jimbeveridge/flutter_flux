// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_flux/flux.dart';

/// ```dart
/// Widget build(BuildContext context) {
///   FooModel foo = const StoreWatcher<FooModel>().of(context);
///   return new Text(foo.bar);
/// }
/// ```
class StoreWatcher<T extends Store> extends InheritedWidget {
  const StoreWatcher({Key key, Widget child, this.store})
      : super(key: key, child: child);

  T of(BuildContext context) {
    assert(this.toString().endsWith('>'));
    StoreWatcher<T> found = context.inheritFromWidgetOfExactType(runtimeType);
    return found?.store;
  }

  final T store;

  @override
  bool updateShouldNotify(StoreWatcher<T> oldWidget) =>
      store != oldWidget.store;

  @override
  _StoreWatcherElement createElement() => new _StoreWatcherElement(this);
}

class _StoreWatcherElement<T extends Store> extends InheritedElement {
  _StoreWatcherElement(StoreWatcher<T> widget) : super(widget);

  StreamSubscription<Store> _streamSubscription;

  @override
  StoreWatcher<T> get widget => super.widget;

  @override
  void mount(Element parent, dynamic newSlot) {
    super.mount(parent, newSlot);
    _streamSubscription = widget.store.listen((Store payload) {
      assert(payload is T);
      dispatchDependenciesChanged();
    });
  }

  @override
  void update(StoreWatcher<T> newWidget) {
    final StoreWatcher<T> oldWidget = widget;
    super.update(newWidget);
    if (oldWidget.store != newWidget.store) {
      _streamSubscription.cancel();
      widget.store.listen((Store payload) {
        assert(payload is T);
        dispatchDependenciesChanged();
      });
    }
  }

  @override
  void unmount() {
    _streamSubscription.cancel();
    super.unmount();
  }
}
