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

  int _reconnectCount = 0;

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

      _channel!.ready.then((_) {
        _reconnectCount = 0;
        _emit(ConnectionStatus.connected);
        log('━━━ CONNECTED ━━━  $_uri', name: 'WS');
      }).catchError((Object e) {
        log('━━━ HANDSHAKE ERROR ━━━  $e', name: 'WS');
        _emit(ConnectionStatus.disconnected);
        _scheduleReconnect();
      });
    } catch (e) {
      log('━━━ CONNECT ERROR ━━━  $e', name: 'WS');
      _emit(ConnectionStatus.disconnected);
      _scheduleReconnect();
    }
  }

  void _onMessage(dynamic raw) {
    try {
      final data = jsonDecode(raw as String) as Map<String, dynamic>;
      _logEvent(data);

      if ((data['code'] as int?) != 551) return;

      final eq = Earthquake.fromJson(data);

      if (eq.latitude == -200 || eq.longitude == -200) return;

      _controller.add(eq);
    } catch (e) {
      log('PARSE ERROR  $e\n  raw: $raw', name: 'WS');
    }
  }

  void _logEvent(Map<String, dynamic> data) {
    final code = data['code'];
    final time = data['time'] ?? data['created_at'] ?? '—';

    // Fields only present on code 551 (earthquake reports).
    final eq = data['earthquake'] as Map<String, dynamic>?;
    final hypo = eq?['hypocenter'] as Map<String, dynamic>?;
    final location = hypo?['name'] ?? '—';
    final mag = hypo?['magnitude'];
    final maxScale = eq?['maxScale'];

    final magStr = mag != null ? 'M${(mag as num).toStringAsFixed(1)}' : 'M—';
    final scaleStr = _scaleLabel(maxScale is int ? maxScale : -1);

    log(
      '┌─ code=$code  time=$time\n'
      '│  location=$location  $magStr  scale=$scaleStr',
      name: 'WS',
    );
  }

  String _scaleLabel(int scale) {
    const labels = {
      10: '1', 20: '2', 30: '3', 40: '4', 45: '4強',
      50: '5弱', 55: '5強', 60: '6弱', 65: '6強', 70: '7',
    };
    return scale == -1 ? '—' : (labels[scale] ?? '$scale');
  }

  void _onError(Object error) {
    log('━━━ ERROR ━━━  $error', name: 'WS');
    _emit(ConnectionStatus.reconnecting);
    _scheduleReconnect();
  }

  void _onDone() {
    log('━━━ DISCONNECTED ━━━', name: 'WS');
    _emit(ConnectionStatus.reconnecting);
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    if (_disposed) return;
    _reconnectCount++;
    log('━━━ RECONNECT #$_reconnectCount in ${_reconnectDelay.inSeconds}s ━━━',
        name: 'WS');
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
