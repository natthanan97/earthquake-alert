import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:web_socket_channel/web_socket_channel.dart';

import '../models/earthquake.dart';

enum ConnectionStatus { connected, disconnected, reconnecting }

class WebSocketService {
  static const _uri = 'wss://api.p2pquake.net/v2/ws';
  static const _reconnectDelay = Duration(seconds: 5);

  WebSocketChannel? _channel;
  final _controller = StreamController<Earthquake>.broadcast();
  final _statusController =
      StreamController<ConnectionStatus>.broadcast();
  bool _disposed = false;

  Stream<Earthquake> get earthquakeStream => _controller.stream;
  Stream<ConnectionStatus> get statusStream => _statusController.stream;

  WebSocketService() {
    _connect();
  }

  void _connect() {
    if (_disposed) return;

    try {
      _channel = WebSocketChannel.connect(Uri.parse(_uri));

      _channel!.stream.listen(
        _onMessage,
        onError: _onError,
        onDone: _onDone,
        cancelOnError: false,
      );

      // ready fires once the handshake completes
      _channel!.ready.then((_) {
        _emit(ConnectionStatus.connected);
      }).catchError((Object e) {
        log('WebSocket ready error: $e', name: 'WebSocketService');
        _emit(ConnectionStatus.disconnected);
        _scheduleReconnect();
      });
    } catch (e) {
      log('WebSocket connect error: $e', name: 'WebSocketService');
      _emit(ConnectionStatus.disconnected);
      _scheduleReconnect();
    }
  }

  void _onMessage(dynamic raw) {
    try {
      final data = jsonDecode(raw as String) as Map<String, dynamic>;

      if ((data['code'] as int?) != 551) return;

      final eq = Earthquake.fromJson(data);

      // skip events with no valid hypocenter
      if (eq.latitude == -200 || eq.longitude == -200) return;

      _controller.add(eq);
    } catch (e) {
      log('WebSocket parse error: $e', name: 'WebSocketService');
    }
  }

  void _onError(Object error) {
    log('WebSocket error: $error', name: 'WebSocketService');
    _emit(ConnectionStatus.reconnecting);
    _scheduleReconnect();
  }

  void _onDone() {
    log('WebSocket closed — reconnecting...', name: 'WebSocketService');
    _emit(ConnectionStatus.reconnecting);
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    if (_disposed) return;
    Future.delayed(_reconnectDelay, _connect);
  }

  void _emit(ConnectionStatus status) {
    if (!_disposed) _statusController.add(status);
  }

  void dispose() {
    _disposed = true;
    _channel?.sink.close();
    _controller.close();
    _statusController.close();
  }
}
