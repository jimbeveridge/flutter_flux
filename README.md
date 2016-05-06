# f_flux

> A Dart app architecture library with uni-directional data flow inspired by [RefluxJS](https://github.com/reflux/refluxjs) and Facebook's [Flux](https://facebook.github.io/flux/).

- [**Overview**](#overview)
- [**What's Included**](#whats-included)
  - [**Action**](#action)
  - [**Store**](#store)
  - [**FluxComponent**](#fluxcomponent)
- [**Examples**](#examples)
- [**External Consumption**](#external-consumption)
- [**Development**](#development)

---

## Overview

![flux-diagram](https://github.com/Workiva/f_flux/blob/images/images/flux_diagram.png)

`f_flux` implements a uni-directional data flow pattern comprised of `Actions`, `Stores`, and `FluxComponents`.
It is based on f_flux, but modified to remove all dependencies on React and related JavaScript packages.

- `Actions` initiate mutation of app data that resides in `Stores`.
- Data mutations within `Stores` trigger re-rendering of app view (defined in `FluxComponents`).
- `FluxComponents` dispatch `Actions` in response to user interaction.
- and the cycle continues...

---

## What's Included


### Action

An `Action` is a command that can be dispatched (with an optional data payload) and listened to.

In `f_flux`, `Actions` are the sole driver of application state change. `FluxComponents` dispatch `Actions` in response to
user interaction with the rendered view. `Stores` listen for these `Action` dispatches and mutate their internal data in
response, taking the `Action` payload into account as appropriate.

```dart
import 'package:f_flux/f_flux.dart';

// define an action
final Action<String> displayString = new Action<String>();

// dispatch the action with a payload
displayString('somePayload');

// listen for action dispatches
displayString.listen(_displayAlert);

_displayAlert(String payload) {
  print(payload);
}
```

**BONUS:** `Actions` are await-able!

They return a Future that completes after all registered `Action` listeners complete.  It's NOT generally recommended to
use this feature within normal app code, but it is quite useful in unit test code.


### Store

A `Store` is a repository and manager of app state. The base `Store` class provided by `f_flux` should be extended to fit
the needs of your app and its data. App state may be spread across many independent stores depending on the complexity
of the app and your desired app architecture.

By convention, a `Store`'s internal data cannot be mutated directly. Instead, `Store` data is mutated internally in
response to `Action` dispatches. `Stores` should otherwise be considered read-only, publicly exposing relevant data ONLY
via getter methods.  This limited data access ensures that the integrity of the uni-directional data flow is maintained.

A `Store` can be listened to to receive external notification of its data mutations. Whenever the data within a `Store`
is mutated, the `trigger` method is used to notify any registered listeners that updated data is available.  In `f_flux`,
`FluxComponents` listen to `Stores`, typically triggering re-rendering of UI elements based on the updated `Store` data.

```dart
import 'package:f_flux/f_flux.dart';

class RandomColorStore extends Store {

  // Public data is only available via getter method
  String _backgroundColor = 'gray';
  String get backgroundColor => _backgroundColor;

  // Actions relevant to the store are passed in during instantiation
  RandomColorActions _actions;

  RandomColorStore(RandomColorActions this._actions) {
    // listen for relevant action dispatches
    _actions.changeBackgroundColor.listen(_changeBackgroundColor);
  }

  _changeBackgroundColor(_) {
    // action dispatches trigger internal data mutations
    _backgroundColor = '#' + (new Random().nextDouble() * 16777215).floor().toRadixString(16);

    // trigger to notify external listeners that new data is available
    trigger();
  }
}
```

**BONUS:** `Stores` can be initialized with a stream transformer to modify the standard behavior of the `trigger` stream.
This can be useful for throttling UI rendering in response to high frequency `Store` mutations.

```dart
import 'package:rate_limit/rate_limit.dart';
import 'package:f_flux/f_flux.dart';

class ThrottledStore extends Store {
  ...

  ThrottledStore(this._actions) : super.withTransformer(new Throttler(const Duration(milliseconds: 30))) {
    ...
  }
}
```

**BONUS:** `Stores` provide an optional terse syntax for action -> data mutation -> trigger operations.

```dart
// verbose syntax
actions.incrementCounter.listen(_handleAction);

_handleAction(payload) {
    // perform data mutation
    counter += payload;
    trigger();
  }

// equivalent terse syntax
triggerOnAction(actions.incrementCounter, (payload) => counter += payload);
```

---

## Examples

Simple examples of `f_flux` usage can be found in the `example` directory. The example [README](example/README.md)
includes instructions for building / running them.


---

## External Consumption

`f_flux` implements a uni-directional data flow within an isolated application or code module. If `f_flux` is used as the
internal architecture of a library, this internal data flow should be considered when defining the external API.

- External API methods intended to mutate internal state should dispatch `Actions`, just like any internal user interaction.
- External API methods intended to query internal state should leverage the existing read-only `Store` getter methods.
- External API streams intended to notify the consumer about internal state changes should be dispatched from the
internal `Stores`, similar to their `triggers`.

[w_module](https://github.com/Workiva/w_module) is a Dart library that defines a standard code module API that can be
used seamlessly with `f_flux` internals to satisfy the above recommendations (complete with examples).

---

## Development

This project leverages [the dart_dev package](https://github.com/Workiva/dart_dev)
for most of its tooling needs, including static analysis, code formatting,
running tests, collecting coverage, and serving examples. Check out the dart_dev
readme for more information.
