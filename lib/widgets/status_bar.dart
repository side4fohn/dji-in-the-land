import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../managers/sdk_manager.dart';
import '../managers/telemetry_manager.dart';

class StatusBar extends StatelessWidget {
  final double height;

  const StatusBar({super.key, this.height = 56});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xCC000000), Colors.transparent],
        ),
      ),
      child: Row(
        children: [
          // Connection status
          Consumer<SDKManager>(
            builder: (context, sdk, _) => _StatusItem(
              icon: sdk.isConnected ? Icons.usb : Icons.usb_off,
              iconColor: sdk.isConnected ? Colors.greenAccent : Colors.grey,
              label: sdk.isConnected ? 'Connected' : 'Disconnected',
            ),
          ),
          const SizedBox(width: 8),
          // Product name
          Consumer<SDKManager>(
            builder: (context, sdk, _) => Text(
              sdk.productName.isNotEmpty ? sdk.productName : 'Air 2',
              style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ),
          const Spacer(),
          // Battery
          Consumer<TelemetryManager>(
            builder: (context, t, _) => _BatteryIndicator(
              percent: t.batteryPercent,
              temp: t.batteryTemp,
              warning: t.lowBatteryWarning,
              serious: t.seriousLowBatteryWarning,
            ),
          ),
          const SizedBox(width: 12),
          // GPS
          Consumer<TelemetryManager>(
            builder: (context, t, _) => _StatusItem(
              icon: Icons.gps_fixed,
              iconColor: t.gpsSignalGood ? Colors.greenAccent : Colors.orange,
              label: '${t.satellites}',
            ),
          ),
          const SizedBox(width: 8),
          // RC Signal
          const _StatusItem(
            icon: Icons.network_wifi,
            iconColor: Colors.greenAccent,
            label: 'RC',
          ),
        ],
      ),
    );
  }
}

class _StatusItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;

  const _StatusItem({required this.icon, required this.iconColor, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: iconColor, size: 16),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(color: iconColor, fontSize: 13)),
      ],
    );
  }
}

class _BatteryIndicator extends StatelessWidget {
  final int percent;
  final double temp;
  final bool warning;
  final bool serious;

  const _BatteryIndicator({
    required this.percent,
    required this.temp,
    required this.warning,
    required this.serious,
  });

  @override
  Widget build(BuildContext context) {
    Color color;
    if (percent < 0) {
      color = Colors.grey;
    } else if (serious || percent < 10) {
      color = Colors.red;
    } else if (warning || percent < 25) {
      color = Colors.orange;
    } else {
      color = Colors.greenAccent;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.battery_full, color: color, size: 16),
        const SizedBox(width: 2),
        Text(
          percent < 0 ? '--' : '$percent%',
          style: TextStyle(color: color, fontSize: 13),
        ),
      ],
    );
  }
}
