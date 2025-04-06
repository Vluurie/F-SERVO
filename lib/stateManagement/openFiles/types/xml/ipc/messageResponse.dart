

import 'dart:async';

import 'namedPipeHandler.dart';

mixin MessageResponseHandler {
  Future<bool> waitForCheckResponse(int expectedMessageType) async {
    final completer = Completer<bool>();

    late StreamSubscription sub;
    sub = globalPipeHandler.onMessageReceived.listen((frame) {
      if (frame.messageType == expectedMessageType) {
        final data = frame.payload;
        if (data.isNotEmpty) {
          final result = data[0] == 1;
          completer.complete(result);
        } else {
          completer.complete(false);
        }
        sub.cancel();
      }
    });

    return completer.future.timeout(Duration(seconds: 10), onTimeout: () {
      sub.cancel();
      return false;
    });
  }
}
