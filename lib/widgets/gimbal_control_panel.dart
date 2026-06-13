import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../managers/gimbal_controller.dart';

class GimbalControlPanel extends StatefulWidget {
  final VoidCallback onClose;

  const GimbalControlPanel({super.key, required this.onClose});

  @override
  State<GimbalControlPanel> createState() => _GimbalControlPanelState();
}

class _GimbalControlPanelState extends State<GimbalControlPanel> {
  double _pitchValue = 0.0;
  double _yawValue = 0.0;
  bool _isSpeedMode = true;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 340,
      decoration: const BoxDecoration(
        color: Color(0xEE0D0D0D),
        borderRadius: BorderRadius.only(topLeft: Radius.circular(16), bottomLeft: Radius.circular(16)),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.control_camera, color: Colors.white70),
                  const SizedBox(width: 12),
                  const Text('云台控制', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white54),
                    onPressed: widget.onClose,
                  ),
                ],
              ),
            ),
            const Divider(color: Colors.white12, height: 1),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Control mode toggle
                    _buildModeToggle(),

                    const SizedBox(height: 24),

                    // Pitch slider
                    _buildSlider('Pitch', _pitchValue, -90.0, 17.0, (v) {
                      setState(() => _pitchValue = v);
                      context.read<GimbalCtrl>().rotateToAngle(v, _yawValue);
                    }),

                    const SizedBox(height: 20),

                    // Yaw slider
                    _buildSlider('Yaw', _yawValue, -180.0, 180.0, (v) {
                      setState(() => _yawValue = v);
                      context.read<GimbalCtrl>().rotateToAngle(_pitchValue, v);
                    }),

                    const SizedBox(height: 24),

                    // Speed mode controls
                    if (_isSpeedMode) ...[
                      const Text('速度模式', style: TextStyle(color: Colors.white70, fontSize: 13)),
                      const SizedBox(height: 8),
                      _buildSpeedPad(),
                    ],

                    const SizedBox(height: 24),

                    // Quick actions
                    _buildQuickActions(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModeToggle() {
    return Row(
      children: [
        const Text('控制模式', style: TextStyle(color: Colors.white70, fontSize: 13)),
        const Spacer(),
        _ModeChip(
          label: '速度',
          selected: _isSpeedMode,
          onTap: () => setState(() => _isSpeedMode = true),
        ),
        const SizedBox(width: 8),
        _ModeChip(
          label: '角度',
          selected: !_isSpeedMode,
          onTap: () => setState(() => _isSpeedMode = false),
        ),
      ],
    );
  }

  Widget _buildSlider(String label, double value, double min, double max, ValueChanged<double> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(label, style: const TextStyle(color: Colors.white70, fontSize: 13)),
            const Spacer(),
            Text(
              '${value.toStringAsFixed(1)}°',
              style: const TextStyle(color: Color(0xFF448AFF), fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: const Color(0xFF448AFF),
            inactiveTrackColor: Colors.white12,
            thumbColor: Colors.white,
            trackHeight: 4,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
            overlayColor: const Color(0x33448AFF),
          ),
          child: Slider(
            value: value,
            min: min,
            max: max,
            divisions: ((max - min) ~/ 1),
            onChanged: onChanged,
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('${min.toInt()}°', style: const TextStyle(color: Colors.white38, fontSize: 11)),
            Text('${max.toInt()}°', style: const TextStyle(color: Colors.white38, fontSize: 11)),
          ],
        ),
      ],
    );
  }

  Widget _buildSpeedPad() {
    return SizedBox(
      height: 160,
      child: _VirtualJoystick(
        onChanged: (pitch, yaw) {
          context.read<GimbalCtrl>().updateFromJoystick(pitch, yaw);
        },
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('快速操作', style: TextStyle(color: Colors.white70, fontSize: 13)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: _ActionButton('RESET', () => context.read<GimbalCtrl>().resetToDefault())),
            const SizedBox(width: 8),
            Expanded(child: _ActionButton('CENTER', () => context.read<GimbalCtrl>().centerPitch())),
            const SizedBox(width: 8),
            Expanded(child: _ActionButton('CLOSE', widget.onClose)),
          ],
        ),
      ],
    );
  }
}

class _ModeChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ModeChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF448AFF) : Colors.white12,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(label, style: TextStyle(color: selected ? Colors.white : Colors.white54, fontSize: 13)),
      ),
    );
  }
}

class _VirtualJoystick extends StatefulWidget {
  final void Function(double pitch, double yaw) onChanged;

  const _VirtualJoystick({required this.onChanged});

  @override
  State<_VirtualJoystick> createState() => _VirtualJoystickState();
}

class _VirtualJoystickState extends State<_VirtualJoystick> {
  Offset _position = Offset.zero;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.maxWidth.clamp(100.0, 200.0);
        return Center(
          child: SizedBox(
            width: size,
            height: size,
            child: GestureDetector(
              onPanUpdate: (details) {
                final center = Offset(size / 2, size / 2);
                final delta = details.localPosition - center;
                final maxRadius = size / 2;
                final dist = delta.distance.clamp(0.0, maxRadius);
                final angle = delta.direction;
                final nx = (dist / maxRadius) * math.cos(angle);
                final ny = (dist / maxRadius) * math.sin(angle);
                setState(() => _position = Offset(nx, -ny));
                widget.onChanged(nx, ny);
              },
              onPanEnd: (_) {
                setState(() => _position = Offset.zero);
                widget.onChanged(0, 0);
              },
              child: CustomPaint(
                size: Size(size, size),
                painter: _JoystickPainter(_position),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _JoystickPainter extends CustomPainter {
  final Offset position;

  _JoystickPainter(this.position);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Outer circle
    final bgPaint = Paint()
      ..color = Colors.white12
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, bgPaint);

    // Ring
    final ringPaint = Paint()
      ..color = const Color(0xFF448AFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(center, radius, ringPaint);

    // Center crosshair
    final crossPaint = Paint()
      ..color = Colors.white24
      ..strokeWidth = 1;
    canvas.drawLine(Offset(center.dx, 0), Offset(center.dx, size.height), crossPaint);
    canvas.drawLine(Offset(0, center.dy), Offset(size.width, center.dy), crossPaint);

    // Stick position
    final stickX = center.dx + position.dx * radius;
    final stickY = center.dy - position.dy * radius;
    final stickPaint = Paint()
      ..color = const Color(0xFF448AFF)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(stickX, stickY), radius * 0.2, stickPaint);
  }

  @override
  bool shouldRepaint(covariant _JoystickPainter old) => old.position != position;
}

class _ActionButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _ActionButton(this.label, this.onTap);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white12,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(label, style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
        ),
      ),
    );
  }
}
