import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/earthquake_provider.dart';
import '../services/websocket_service.dart';

class ConnectionStatusBadge extends ConsumerWidget {
  const ConnectionStatusBadge({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusAsync = ref.watch(connectionStatusProvider);

    final status = statusAsync.valueOrNull ?? ConnectionStatus.reconnecting;

    final (label, color) = switch (status) {
      ConnectionStatus.connected => ('CONNECTED', Colors.green),
      ConnectionStatus.disconnected => ('DISCONNECTED', Colors.red),
      ConnectionStatus.reconnecting => ('RECONNECTING', Colors.orange),
    };

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }
}
