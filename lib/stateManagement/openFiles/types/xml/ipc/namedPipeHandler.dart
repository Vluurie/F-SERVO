import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

// ignore: library_prefixes
import 'package:dart_ipc/dart_ipc.dart' as NamedPipeSocket;

import '../sync/syncServer.dart';
import 'messageFrame.dart';

NamedPipeHandler globalPipeHandler = NamedPipeHandler(pipePath: r'\\.\pipe\nier_pipe');

class NamedPipeHandler {
  Socket? _socket;
  final String pipePath;

  final StreamController<MessageFrame> _onMessageReceivedController = StreamController<MessageFrame>.broadcast();
  final StreamController<MessageFrame> _onMessageSentController = StreamController<MessageFrame>.broadcast();
  final StreamController<Socket> _onConnectedController = StreamController<Socket>.broadcast();
  final StreamController<void> _onDisconnectedController = StreamController<void>.broadcast();

  Stream<MessageFrame> get onMessageReceived => _onMessageReceivedController.stream;
  Stream<MessageFrame> get onMessageSent => _onMessageSentController.stream;
  Stream<Socket> get onConnected => _onConnectedController.stream;
  Stream<void> get onDisconnected => _onDisconnectedController.stream;

  final List<MessageFrame> _messageQueue = [];
  bool _isWriting = false;

  bool get isConnected => _socket != null;

  NamedPipeHandler({required this.pipePath}) {
    if (!Platform.isWindows) {
      throw UnsupportedError("supported on Windows only.");
    }
  }

  Future<void> connect() async {
    if (!canSync.value) {
      return;
    }
    await _connectToPipe();
  }

  Future<void> _connectToPipe() async {
    if (!canSync.value) return;

    if (_socket != null) {
      try {
        _socket!.destroy();
      } catch (e) {
        print("Error closing previous socket: $e");
      }
      _socket = null;
    }

    try {
      _socket = await NamedPipeSocket.connect(pipePath);
      _listenToPipe(_socket!);
      print("Connected to IPC server on pipe $pipePath.");
      _onConnectedController.add(_socket!);
    } catch (e) {
      print("Connection failed: $e");
    }
  }

  void _listenToPipe(Socket socket) {
    socket.listen(
      (data) {
        try {
          MessageFrame frame = MessageFrame.fromBytes(Uint8List.fromList(data));
          _onMessageReceivedController.add(frame);
        } catch (e) {
          print("Error decoding message: $e");
        }
      },
      onDone: () {
        print("Pipe closed by server.");
        _socket = null;
        _onDisconnectedController.add(null);
      },
      onError: (e) {
        print("Socket error: $e");
        _socket = null;
        _onDisconnectedController.add(null);
      },
      cancelOnError: true,
    );
  }

  Future<void> sendBinaryMessage(MessageFrame frame) async {
    _messageQueue.add(frame);
    if (!_isWriting) {
      _isWriting = true;
      while (_messageQueue.isNotEmpty) {
        MessageFrame message = _messageQueue.removeAt(0);
        await _writeMessage(message);
      }
      _isWriting = false;
    }
  }

  Future<void> _writeMessage(MessageFrame frame) async {
    if (!isConnected) {
      if (canSync.value) {
        await _connectToPipe();
      } else {
        print("Sync disabled; message not sent.");
        return;
      }
      if (!isConnected) {
        print("IPC Pipe is not connected.");
        return;
      }
    }

    try {
      _socket!.add(frame.toBytes());
      await _socket!.flush();
      print("Sent binary message.");
      _onMessageSentController.add(frame);
    } catch (e) {
      print("Error sending binary message: $e");
      _socket = null;
      if (canSync.value) {
        await _connectToPipe();
      }
    }
  }

  void close() {
    _socket?.close();
    _socket = null;
    _onDisconnectedController.add(null);
  }

  void dispose() {
  close();
  _onMessageReceivedController.close();
  _onMessageSentController.close();
  _onConnectedController.close();
  _onDisconnectedController.close();
}
}
