# flutter_flux

A Dart/[Flutter](https://flutter.io) app architecture library with uni-directional data flow inspired by [RefluxJS](https://github.com/reflux/refluxjs) and Facebook's [Flux](https://facebook.github.io/flux/). [Flux](https://facebook.github.io/flux/) is the complementary “model” framework also designed by Facebook. Flutter_flux is a reimplementation of Flux that uses idiomatic Dart and integrates cleanly with Flutter.

- [**Motivation**](#motivation)
- [**Widgets dispatch Actions**](#1-widgets-dispatch-actions)
- [**Stores respond to dispatched Actions**](#2-stores-respond-to-dispatched-actions)
- [**Widgets rebuild**](#3-widgets-rebuild)
- [**FAQs**](#faqs)

---

## Motivation

The easiest ways to model state in Flutter are StatefulWidgets and global variables. StatefulWidgets are problematic because the data is destroyed whenever the widget hierarchy is destroyed. Therefore, state is lost when the route changes, and stateful widgets cannot be used for multiple views onto the same data.

Global variables also have issues:
*   It’s necessary to handcraft the scaffolding to connect the global variables to the widget tree, often creating competing and/or incompatible implementations of the data model.
*   There’s no data flow model, which is needed to make it easy to reason about the effects of dynamic data changing in different parts of the application.

## Design

The Flux framework is designed to solve the problems above. The dataflow in flutter_flux looks like this.

<p style="color: red; font-weight: bold">>>>> inline drawings not supported directly from Docs. You may want to copy the inline drawing to a standalone drawing and export by reference. See <a href=http://go/g3doc-drawings>go/g3doc-drawings</a> for details. The img URL below is a placeholder.</p>


![drawing](https://docs.google.com/a/google.com/drawings/d/12345/export/png)

Data flow is single directional, which prevents unexpected cycles caused by change notifications. For example, you cannot have a Store observe change events from another Store.

Let’s walk through this diagram to demonstrate the lifecycle of an update. Here’s the code that integrates a sample ToDo application with flutter_flux. We’ll walk through it in the following sections.

```dart
import 'package:flutter/flutter_flux.dart';

// define an action
final submitToDoAction = new Action<InputValue>();

class ToDoList extends StoreWatcher {
  ToDoList({Key key}) : super(key: key);

  // Only code relevant to flutter_flux is shown.

  onSubmit(InputValue value) {
    // dispatch the action with a payload
    submitToDoAction(value);
  }
}

// The "model"
class ToDo {
  ToDo(this.toDoText);
  String toDoText;
  Bool isComplete = false;
}

class ToDoStore extends Store {
  ToDoStore() {
    triggerOnAction(submitToDoAction, (InputValue value) {
      _todos.add(new ToDo(newvalue.text));
    });
  }

  @override
  void initStores(ListenToStore listenToStore) {
    listenToStore(todoStoreToken);
  }

  final _todos = new List<ToDo>();
  List<ToDo> get todos => new List.unmodifiable(_todos);
}
```

## **1. Widgets dispatch Actions**

In flutter_flux, Actions are the sole driver of application state change. Widgets and other objects dispatch Actions in response to user interaction with the rendered view. Stores listen for these Action dispatches and mutate their internal data in response, taking the Action payload into account as appropriate. You dispatch an action as follows.

Let’s say your Flutter widget has a function that’s called when a user completes a new ToDo list entry.

```dart
class ToDoList extends StatefulWidget{
  void onSubmit(InputValue value) {
    // Create a ToDo item based on text.value
  }
}
```

To handle the user submitting the new `ToDo` item, you declare a new instance of the `Action` class, which is a generic class that takes a single parameter that holds the data for the action. (If you need more than one parameter, then create a wrapper object.)

Here’s the updated code. Define the action as a global variable, then submit the action.

```dart
final submitToDoAction = new Action<InputValue>();

class ToDoList extends StatefulWidget{
  onSubmit(InputValue value) {
    submitToDoAction(value);
  }
}
```

**Important:** an action is defined by a particular instance of `Action<>`, not by a subclass of `Action`. Once you’ve created an instance, you treat it as a function and call it to submit an `Action`. This is different from actions in Flux in JavaScript.

**Important:** an action has no business logic. It is simply a notification system for stores.


## **2. Stores respond to dispatched Actions**

A `Store` responds to actions, applies the appropriate business logic, updates the model, and broadcasts a change event. The base Store class provided by flutter_flux should be extended to fit the needs of your app and its data. App state may be spread across many independent stores depending on the complexity of the app and your desired app architecture.

By convention, a `Store`'s internal data cannot be mutated directly. Instead, `Store` data is mutated internally in response to `Action` dispatches. `Store`s should otherwise be considered read-only, publicly exposing relevant data ONLY via getter methods. This limited data access ensures that the integrity of the uni-directional data flow is maintained.

A `Store` is **not** the model - a `Store` contains the model, which is usually either a List or a `Map` of a single type. In this case, `ToDoStore` is a `List` of `Todo`.

```dart
class ToDo {
  ToDo(this.toDoText);
  String toDoText;
  Bool isComplete = false;
}

class ToDoStore extends Store {
  final _todos = new List<ToDo>();
  List<ToDo> get todos => new List.unmodifiable(_todos);
}
```

To handle an `Action`, a `Store` subscribes to the `Action` and defines a handler function, like this:

```dart
class ToDoStore extends Store {
  ToDoStore() {
    triggerOnAction(submitToDoAction, (InputValue value) {
      _todos.add(new ToDo(value.text));
    });
  }

  final _todos = new List<ToDo>();
  List<ToDo> get todos => new List.unmodifiable(_todos);
}
```

With this change, every time a widget dispatches `submitToDoAction`, the text of the new item will be added to the _todos list.

You instantiate a store using a StoreToken, like this:

```dart
final StoreToken todoStoreToken =
    new StoreToken(new ToDoStore());
```

Hiding the `ToDoStore` inside of a `StoreToken` enforces the limited visibility of a `Store`. The `Store` will be explicitly passed to your `build()` function and can referenced by its token, as shown in the next section.

We could add the trivial business logic to ignore empty ToDo items:

```dart
class ToDoStore extends Store {
  ToDoStore() {
    triggerOnAction(submitToDoAction, (InputValue value) {
      if (value.text != null && value.text.trim().isNotEmpty) {
        _todos.add(new ToDo(newvalue.text));
      }
    });
  }

  final _todos = new List<ToDo>();
  List<ToDo> get todos => new List.unmodifiable(_todos);
}
```

## **3. Widgets rebuild**

After the `Store` updates, the view (widgets) need to update to match the new model. A widget registers to listen to stores in its `initStores()` function. For example:

```dart
  @override
  void initStores(ListenToStore listenToStore) {
    listenToStore(todoStoreToken);
  }
```

Once you’ve made this call, then flutter_flux will automatically call `setState()` to force the tree to rebuild. Alternatively, you can pass a lambda function to `listenToStore()` if you want to define another behavior when a store announces a change. The important point is that, by default, you do not need to define an event listener or call `setState()`.

A widget based on StoreWatch uses a special form of the `build()` function that passes in the related stores so that the build function can access data from the stores:

```
Widget build(BuildContext context, Map<StoreToken, Store> stores) {
  final ToDoStore messageStore = stores[todoStoreToken];
  // ...
}
```

## **FAQs**

1.  **Where do I put View state, such as scroll positions?**

    The decision is based on whether the view state information needs to outlive the widget hierarchy, which is torn down whenever your route is changed, which causes all `State` in a `StatefulWidget` to be lost. For example, If you want the scroll position to be restored the next time the route is displayed, then scroll position should be in a Store, not a StatefulWidget.

    In contrast, an `Animation<>` would almost never go in a `Store` because animations are usually tightly tied to the lifetime of the current widget tree.

1.  **Can Stores read each other?**

    You’ll notice that most Stores have no way to read each other, since they only have access to each store’s token, not the store itself. In general, Stores should not depend on each other. Instead, the data from the various stores should be gathered together and bundled into the action.

1.  **Can a Widget write a Store directly?**

    No. Only stores can change the model. All change requests must be routed to stores via an Action. This is enforced through the use of StoreToken to gain access to a store.

1.  **Does the widget tree get redrawn after every action?**

    No. The widget tree will be redrawn for the next screen update. There’s no penalty for using finely-grained Actions.

1.  **Where should async calls be made, such as REST calls?**

    Async calls should be made as part of constructing an action. In Flux in JavaScript, this is typically done as part of an “Action Creator” function. Because actions in flutter_flux are simpler to create than in JavaScript, you don’t normally need Action Creators, but Action Creators are recommended if you need to make async API calls and then dispatch actions.

    In general, async calls should not be made in the Store. This is because other Stores might need to respond to that data changing, and Stores respond to actions, which must not be created or dispatched from a Store.

1.  **How do I control the order of Stores updating when an action is dispatched?**

    This functionality is being considered but is not yet implemented.

1.  **Should I structure all of my model objects to make them read-only?**

    This question effectively asks whether model objects should hide all members behind getters. This is really a judgement call for your project. For a small project where everyone knows better than to write the model, simple objects are fine. For a larger project where the rules need to be enforced, it may be necessary to create getters. An alternative to getters is to clone each object and return copies, but this can become expensive when collections are returned.

1.  **Can I just put everything into a single store?**

    The library is unopinionated about how you organize your data and what you put in a Store. Practically speaking, with Stores delineated by entities, the change events broadcast by each store indicates that a set of entities has changed. Also, each store implements the business logic for a particular type of entity.

    If you bundle everything into the same store, then all business logic and all notifications become commingled. This might be fine in a very small app, but scales poorly as your app size grows.

References:

http://www.slideshare.net/AndrewHull/react-js-and-why-its-awesome
