import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../managers/camera_controller.dart';

class CameraSettingsPanel extends StatelessWidget {
  final VoidCallback onClose;

  const CameraSettingsPanel({super.key, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 340,
      decoration: const BoxDecoration(
        color: Color(0xEE0D0D0D),
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.camera_alt, color: Colors.white70),
                  const SizedBox(width: 12),
                  const Text('相机设置', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white54),
                    onPressed: onClose,
                  ),
                ],
              ),
            ),
            const Divider(color: Colors.white12, height: 1),
            Expanded(
              child: Consumer<CameraCtrl>(
                builder: (context, camera, _) => ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // SD Card status
                    _InfoRow('存储卡', _sdCardStatus(camera)),
                    const SizedBox(height: 8),

                    // Exposure mode
                    const Text('曝光模式', style: TextStyle(color: Colors.white70, fontSize: 13)),
                    const SizedBox(height: 8),
                    _ExposureModeGrid(camera: camera),

                    const SizedBox(height: 20),

                    // EV compensation
                    const Text('EV 补偿', style: TextStyle(color: Colors.white70, fontSize: 13)),
                    const SizedBox(height: 8),
                    _EVSelector(camera: camera),

                    const SizedBox(height: 20),

                    // ISO
                    const Text('ISO', style: TextStyle(color: Colors.white70, fontSize: 13)),
                    const SizedBox(height: 8),
                    _ISOSelector(camera: camera),

                    const SizedBox(height: 20),

                    // White balance
                    const Text('白平衡', style: TextStyle(color: Colors.white70, fontSize: 13)),
                    const SizedBox(height: 8),
                    _WhiteBalanceSelector(camera: camera),

                    const SizedBox(height: 20),

                    // Zoom info
                    _InfoRow('当前变焦', '${camera.zoomFactor.toStringAsFixed(1)}x'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _sdCardStatus(CameraCtrl camera) {
    if (!camera.sdCardInserted) return '无存储卡';
    if (camera.sdCardError) return '存储卡错误';
    return '${camera.sdCardRemainingMB}MB 可用';
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 13)),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 13)),
      ],
    );
  }
}

class _ExposureModeGrid extends StatelessWidget {
  final CameraCtrl camera;

  const _ExposureModeGrid({required this.camera});

  @override
  Widget build(BuildContext context) {
    final modes = ['AUTO', 'PROGRAM', 'SHUTTER', 'APERTURE', 'MANUAL'];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: modes.map((m) {
        final selected = camera.exposureMode == m;
        return GestureDetector(
          onTap: () => camera.setExposureMode(m),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: selected ? const Color(0xFF448AFF) : Colors.white12,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(m, style: TextStyle(color: selected ? Colors.white : Colors.white54, fontSize: 13)),
          ),
        );
      }).toList(),
    );
  }
}

class _EVSelector extends StatelessWidget {
  final CameraCtrl camera;

  const _EVSelector({required this.camera});

  @override
  Widget build(BuildContext context) {
    final evs = ['P_3_0','P_2_7','P_2_3','P_2_0','P_1_7','P_1_3','P_1_0','P_0_7','P_0_3',
                 'P_0_0','N_0_3','N_0_7','N_1_0','N_1_3','N_1_7','N_2_0','N_2_3','N_2_7','N_3_0'];
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: evs.map((ev) {
        return GestureDetector(
          onTap: () => camera.setExposureCompensation(ev),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white12,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              ev.replaceAll('_', '').replaceAll('P', '+').replaceAll('N', '-'),
              style: const TextStyle(color: Colors.white54, fontSize: 11),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _ISOSelector extends StatelessWidget {
  final CameraCtrl camera;

  const _ISOSelector({required this.camera});

  @override
  Widget build(BuildContext context) {
    final isos = ['AUTO', 'ISO_100', 'ISO_200', 'ISO_400', 'ISO_800', 'ISO_1600', 'ISO_3200', 'ISO_6400'];
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: isos.map((iso) {
        final label = iso == 'AUTO' ? 'AUTO' : iso.replaceAll('ISO_', 'ISO');
        return GestureDetector(
          onTap: () => camera.setISO(iso),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white12,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12)),
          ),
        );
      }).toList(),
    );
  }
}

class _WhiteBalanceSelector extends StatelessWidget {
  final CameraCtrl camera;

  const _WhiteBalanceSelector({required this.camera});

  @override
  Widget build(BuildContext context) {
    final wbs = ['AUTO', 'SUNNY', 'CLOUDY', 'WATER_SURFACE', 'INDOOR'];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: wbs.map((wb) {
        final label = wb == 'AUTO' ? 'AUTO' : wb.replaceAll('_', ' ');
        return GestureDetector(
          onTap: () => camera.setWhiteBalance(wb),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white12,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(label, style: const TextStyle(color: Colors.white54, fontSize: 13)),
          ),
        );
      }).toList(),
    );
  }
}
