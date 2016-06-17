// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_flux/src/store.dart';

typedef Store ListenToStore(StoreToken token,
    [void onChangeEvent(Store payload)]);

/// ```dart
/// Widget build(BuildContext context) {
///   FooModel foo = const StoreWatcher<FooModel>().of(context);
///   return new Text(foo.bar);
/// }
/// ```
abstract class StoreWatcher extends StatefulWidget {
  // You can use the storeTokens parameter for stores where you
  // just want the default behavior of calling initState(). To
  // specify your own handler, call `listenToStore` directly.
  StoreWatcher({Key key}) : super(key: key);

  /// Override this function to build widgets that depend on the current value
  /// of the animation.
  Widget build(BuildContext context, Map<StoreToken, Store> stores);

  void initState(ListenToStore listenToStore);

  @override
  State createState() => new StoreWatcherState();
}

class StoreWatcherState extends State<StoreWatcher> with StoreWatcherMixin {
  final _storeTokens = <StoreToken, Store>{};

  @override
  void initState() {
    config.initState(listenToStore);
    super.initState();
  }

  Store listenToStore(StoreToken token, [void onChangeEvent(Store payload)]) {
    final store = super.listenToStore(token, onChangeEvent);
    _storeTokens[token] = store;
    return store;
  }

  @override
  Widget build(BuildContext context) {
    return config.build(context, _storeTokens);
  }
}

/// ```dart
/// Widget build(BuildContext context) {
///   FooModel foo = const StoreWatcher<FooModel>().of(context);
///   return new Text(foo.bar);
/// }
/// ```
abstract class StoreWatcherMixin extends State {
  final _streamSubscriptions = <Store, StreamSubscription<Store>>{};

  void setState(VoidCallback fn);

  /// Start receiving notifications from the given store, optionally routed
  /// to the given function. The default action is to call setState().
  /// In general, you want to use the default function, rebuild everything, and
  /// let Flutter figure out the delta of what changed.
  Store listenToStore(StoreToken token, [void onChangeEvent(Store payload)]) {
    final store = token._value;
    _streamSubscriptions[store] =
        store.listen(onChangeEvent ?? _handleChangeEvent);
    return store;
  }

  void unlistenFromStore(Store store) {
    _streamSubscriptions[store]?.cancel();
    _streamSubscriptions.remove(store);
  }

  @override
  Widget build(BuildContext context);

  void dipose() {
    final subscriptions = _streamSubscriptions.values;
    _streamSubscriptions.clear();
    for (final sub in subscriptions) {
      sub.cancel();
    }
    super.dispose();
  }

  /// Default behavior when receiving an event from a store is to rebuild.
  /// To override this function, use the second parameter in [listenToStore].
  void _handleChangeEvent(Store store) {
    if (mounted) {
      setState(() {});
    }
  }
}

/// Represent a store so it can be returned by `StoreWatcherMixin.listenToStore`.
///
/// Used to make sure that callers never reference the store without calling
/// listen() first. In the example below, _itemStore would not be globally
/// available:
/// ```dart
/// final _itemStore = new AppStore(actions);
/// final itemStoreToken = new StoreToken(_itemStore);
/// ```
class StoreToken {
  StoreToken(this._value);

  final Store _value;

  @override
  bool operator ==(dynamic other) {
    if (other is! StoreToken) return false;
    final StoreToken typedOther = other;
    return identical(_value, typedOther._value);
  }

  @override
  int get hashCode => identityHashCode(_value);

  @override
  String toString() => '[${_value.runtimeType}(${_value.hashCode})]';
}
