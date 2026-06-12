import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../managers/camera_controller.dart';
import '../managers/gimbal_controller.dart';

class BottomToolbar extends StatelessWidget {
  final VoidCallback onGimbalPressed;
  final VoidCallback onCameraPressed;

  const BottomToolbar({
    super.key,
    required this.onGimbalPressed,
    required this.onCameraPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [Color(0xDD000000), Colors.transparent],
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Gimbal control button
          _ToolbarButton(
            icon: Icons.control_camera,
            label: '云台',
            onPressed: onGimbalPressed,
          ),

          // Zoom slider
          Expanded(
            child: Consumer<CameraCtrl>(
              builder: (context, camera, _) => _ZoomSlider(
                value: camera.zoomFactor,
                onChanged: (v) => camera.setZoom(v),
              ),
            ),
          ),

          // Photo button
          _PhotoButton(),

          const SizedBox(width: 8),

          // Record button
          _RecordButton(),

          const SizedBox(width: 8),

          // Camera settings button
          _ToolbarButton(
            icon: Icons.camera_alt,
            label: '设置',
            onPressed: onCameraPressed,
          ),
        ],
      ),
    );
  }
}

class _ToolbarButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  const _ToolbarButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: Colors.white12,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
        ],
      ),
    );
  }
}

class _ZoomSlider extends StatelessWidget {
  final double value;
  final ValueChanged<double> onChanged;

  const _ZoomSlider({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 28,
          child: SliderTheme(
            data: SliderThemeData(
              activeTrackColor: Colors.white,
              inactiveTrackColor: Colors.white24,
              thumbColor: Colors.white,
              trackHeight: 3,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              overlayColor: Colors.white24,
            ),
            child: Slider(
              value: value,
              min: 1.0,
              max: 8.0,
              onChanged: onChanged,
            ),
          ),
        ),
        Text(
          '${value.toStringAsFixed(1)}x',
          style: const TextStyle(color: Colors.white70, fontSize: 11),
        ),
      ],
    );
  }
}

class _PhotoButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.read<CameraCtrl>().takePhoto(),
      child: Container(
        width: 56, height: 56,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 3),
        ),
        child: const Center(
          child: Icon(Icons.camera, color: Colors.white, size: 28),
        ),
      ),
    );
  }
}

class _RecordButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<CameraCtrl>(
      builder: (context, camera, _) {
        final isRecording = camera.isRecording;
        return GestureDetector(
          onTap: () => camera.toggleRecording(),
          child: Container(
            width: 56, height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isRecording ? Colors.red : Colors.white,
                width: 3,
              ),
            ),
            child: Center(
              child: isRecording
                  ? Container(
                      width: 20, height: 20,
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    )
                  : Container(
                      width: 24, height: 24,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
            ),
          ),
        );
      },
    );
  }
}
