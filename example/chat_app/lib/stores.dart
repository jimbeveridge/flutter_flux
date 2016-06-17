// Copyright 2016, the Flutter project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:math' show Random;

import 'package:flutter/material.dart';
import 'package:flutter_flux/flutter_flux.dart';

class ChatUser {
  ChatUser({this.name, this.color});
  final String name;
  final Color color;
}

class ChatMessage {
  ChatMessage({this.sender, this.text});
  final ChatUser sender;
  final String text;
}

class MessageStore extends Store {
  MessageStore() {
    triggerOnAction(setCurrentMessageAction, (InputValue value) {
      _CurrentMessage = value;
    });
    triggerOnAction(commitCurrentMessageAction, (ChatUser me) {
      final message = new ChatMessage(sender: me, text: _CurrentMessage.text);
      _messages.add(message);
      _CurrentMessage = InputValue.empty;
    });
  }

  final _messages = <ChatMessage>[];
  InputValue _CurrentMessage = InputValue.empty;

  List<ChatMessage> get messages => new List.unmodifiable(_messages);
  InputValue get CurrentMessage => _CurrentMessage;

  bool get isComposing => _CurrentMessage.text.isNotEmpty;
}

class UserStore extends Store {
  UserStore() {
    String name = "Guest${new Random().nextInt(1000)}";
    Color color =
        Colors.accents[new Random().nextInt(Colors.accents.length)][700];
    _me = new ChatUser(name: name, color: color);
    // This store does not currently handle any actions.
  }

  ChatUser _me;
  ChatUser get me => _me;
}

final messageStoreToken = new StoreToken(new MessageStore());
final userStoreToken = new StoreToken(new UserStore());

final setCurrentMessageAction = new Action<InputValue>();
final commitCurrentMessageAction = new Action<ChatUser>();
