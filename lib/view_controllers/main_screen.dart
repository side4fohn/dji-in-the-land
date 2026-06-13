import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../managers/sdk_manager.dart';
import '../managers/gimbal_controller.dart';
import '../managers/rc_input_manager.dart';
import '../managers/camera_controller.dart';
import '../managers/telemetry_manager.dart';
import '../managers/video_manager.dart';
import '../widgets/status_bar.dart';
import '../widgets/bottom_toolbar.dart';
import '../widgets/gimbal_control_panel.dart';
import '../widgets/camera_settings_panel.dart';
import '../widgets/attitude_indicator.dart';
import '../widgets/video_overlay.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with WidgetsBindingObserver {
  bool _gimbalPanelOpen = false;
  bool _cameraPanelOpen = false;
  bool _showCrosshair = true;
  bool _componentsInited = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final sdk = context.read<SDKManager>();
      sdk.addListener(_onSDKStateChanged);
      sdk.startSDK();
    });
  }

  void _onSDKStateChanged() {
    final sdk = context.read<SDKManager>();
    if (sdk.isConnected && !_componentsInited) {
      _componentsInited = true;
      _initComponents();
    }
  }

  void _initComponents() {
    if (!mounted) return;
    final gimbal = context.read<GimbalCtrl>();
    final rc = context.read<RCInputManager>();
    final camera = context.read<CameraCtrl>();
    final telemetry = context.read<TelemetryManager>();
    final video = context.read<VideoManager>();

    gimbal.setReady(true);
    rc.startListening();
    rc.onJoystickChanged = (pitch, yaw) {
      if (mounted) gimbal.updateFromJoystick(pitch, yaw);
    };
    camera.init();
    telemetry.startMonitoring();
    video.start();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<SDKManager>(
        builder: (context, sdk, _) {
          if (sdk.state == SDKState.unknown) return _buildSplash();
          if (sdk.state == SDKState.error) return _buildError(sdk.errorMessage);
          if (sdk.state == SDKState.disconnected || sdk.state == SDKState.connecting) {
            return _buildConnecting(sdk);
          }
          return _buildMainUI();
        },
      ),
    );
  }

  Widget _buildSplash() {
    return Container(
      color: const Color(0xFF0D0D0D),
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.camera_alt, size: 64, color: Color(0xFF448AFF)),
            SizedBox(height: 24),
            Text('云台走地机',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
            SizedBox(height: 12),
            Text('初始化中...', style: TextStyle(fontSize: 16, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildError(String msg) {
    return Container(
      color: const Color(0xFF0D0D0D),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.redAccent),
            const SizedBox(height: 24),
            Text(msg, textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, color: Colors.white)),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.read<SDKManager>().startSDK(),
              child: const Text('重试'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConnecting(SDKManager sdk) {
    return Container(
      color: const Color(0xFF0D0D0D),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: Color(0xFF448AFF)),
            const SizedBox(height: 24),
            Text(
              sdk.state == SDKState.connecting ? '正在连接无人机...' : '等待连接...',
              style: const TextStyle(fontSize: 18, color: Colors.white),
            ),
            if (sdk.errorMessage.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(sdk.errorMessage,
                  style: const TextStyle(fontSize: 14, color: Colors.redAccent)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMainUI() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isLandscape = constraints.maxWidth > constraints.maxHeight;
        return Stack(
          children: [
            // Full-screen video background
            Positioned.fill(child: _buildVideoBackground()),

            // Crosshair overlay
            if (_showCrosshair)
              Positioned.fill(child: _buildCrosshair()),

            // Top status bar
            Positioned(
              top: 0, left: 0, right: 0,
              child: SafeArea(
                bottom: false,
                child: StatusBar(height: isLandscape ? 44 : 56),
              ),
            ),

            // Top-right telemetry overlay
            Positioned(
              top: isLandscape ? 48 : 64,
              right: 12,
              child: SafeArea(child: _buildTelemetryOverlay(isLandscape)),
            ),

            // Left side attitude indicator
            if (isLandscape)
              Positioned(
                top: 48,
                left: 12,
                child: SafeArea(
                  child: SizedBox(
                    width: 120,
                    height: 120,
                    child: AttitudeIndicator(),
                  ),
                ),
              ),

            // Center recording indicator
            Positioned(
              top: isLandscape ? 56 : 80,
              left: 0,
              right: 0,
              child: Center(child: _buildRecordingIndicator()),
            ),

            // RC virtual joystick (left side in portrait)
            if (!isLandscape)
              Positioned(
                bottom: 180,
                left: 16,
                child: SafeArea(
                  child: SizedBox(
                    width: 120,
                    height: 120,
                    child: _RCJoystick(),
                  ),
                ),
              ),

            // RC virtual joystick (bottom-left in landscape)
            if (isLandscape)
              Positioned(
                bottom: 60,
                left: 12,
                child: SafeArea(
                  child: SizedBox(
                    width: 120,
                    height: 120,
                    child: _RCJoystick(),
                  ),
                ),
              ),

            // Bottom toolbar
            Positioned(
              bottom: 0, left: 0, right: 0,
              child: SafeArea(
                top: false,
                child: BottomToolbar(
                  onGimbalPressed: () => setState(() {
                    _gimbalPanelOpen = !_gimbalPanelOpen;
                    _cameraPanelOpen = false;
                  }),
                  onCameraPressed: () => setState(() {
                    _cameraPanelOpen = !_cameraPanelOpen;
                    _gimbalPanelOpen = false;
                  }),
                ),
              ),
            ),

            // Gimbal control panel (slides from right)
            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              right: _gimbalPanelOpen ? 0 : -(isLandscape ? 340.0 : constraints.maxWidth),
              top: 0,
              bottom: 0,
              child: SafeArea(
                child: GimbalControlPanel(
                  onClose: () => setState(() => _gimbalPanelOpen = false),
                ),
              ),
            ),

            // Camera settings panel (slides from left)
            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              left: _cameraPanelOpen ? 0 : -(isLandscape ? 340.0 : constraints.maxWidth),
              top: 0,
              bottom: 0,
              child: SafeArea(
                child: CameraSettingsPanel(
                  onClose: () => setState(() => _cameraPanelOpen = false),
                ),
              ),
            ),

            // Crosshair toggle
            Positioned(
              top: isLandscape ? 56 : 80,
              right: isLandscape ? 140 : 12,
              child: GestureDetector(
                onTap: () => setState(() => _showCrosshair = !_showCrosshair),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  child: Icon(
                    _showCrosshair ? Icons.grid_on : Icons.grid_off,
                    color: Colors.white54,
                    size: 20,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // RC virtual joystick widget
  Widget _RCJoystick() {
    return Consumer<RCInputManager>(
      builder: (context, rc, _) {
        return _VirtualJoystickWidget(
          onChanged: (nx, ny) {
            rc.onJoystickChanged?.call(ny, nx);
          },
        );
      },
    );
  }

  Widget _buildVideoBackground() {
    return Consumer<VideoManager>(
      builder: (context, video, _) {
        if (video.isReady && video.latestVideoData != null) {
          // TODO: Use a platform-native decoder widget for actual video rendering
          // For now, show a placeholder
          return Container(
            color: const Color(0xFF1A1A2E),
            child: const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.videocam, size: 48, color: Colors.white24),
                  SizedBox(height: 12),
                  Text('图传已连接', style: TextStyle(color: Colors.white24)),
                ],
              ),
            ),
          );
        }
        return Container(
          color: const Color(0xFF1A1A2E),
          child: const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.videocam_off, size: 48, color: Colors.white24),
                SizedBox(height: 12),
                Text('等待图传...', style: TextStyle(color: Colors.white24)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCrosshair() {
    return const Center(child: VideoOverlay());
  }

  Widget _buildRecordingIndicator() {
    return Consumer<CameraCtrl>(
      builder: (context, camera, _) {
        if (!camera.isRecording) return const SizedBox.shrink();
        final minutes = camera.recordingSeconds ~/ 60;
        final seconds = camera.recordingSeconds % 60;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12, height: 12,
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                shadows: [Shadow(color: Colors.black, blurRadius: 4)],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTelemetryOverlay(bool isLandscape) {
    return Consumer<TelemetryManager>(
      builder: (context, t, _) {
        return Consumer<GimbalCtrl>(
          builder: (context, gimbal, _) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'P: ${gimbal.currentPitch.toStringAsFixed(1)}°',
                    style: _labelStyle(),
                  ),
                  Text(
                    'Y: ${gimbal.currentYaw.toStringAsFixed(1)}°',
                    style: _labelStyle(),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'ALT: ${t.altitude.toStringAsFixed(1)}m',
                    style: _labelStyle(),
                  ),
                  Text(
                    'SAT: ${t.satellites}',
                    style: _labelStyle(),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  TextStyle _labelStyle() => const TextStyle(
    color: Colors.white,
    fontSize: 13,
    fontWeight: FontWeight.w500,
    shadows: [Shadow(color: Colors.black, blurRadius: 3)],
  );
}

// RC virtual joystick for screen touch input
class _VirtualJoystickWidget extends StatefulWidget {
  final void Function(double nx, double ny) onChanged;

  const _VirtualJoystickWidget({required this.onChanged});

  @override
  State<_VirtualJoystickWidget> createState() => _VirtualJoystickWidgetState();
}

class _VirtualJoystickWidgetState extends State<_VirtualJoystickWidget> {
  Offset _position = Offset.zero;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanUpdate: (details) {
        final box = context.findRenderObject() as RenderBox?;
        if (box == null) return;
        final size = box.size;
        final center = Offset(size.width / 2, size.height / 2);
        final delta = details.localPosition - center;
        final maxRadius = size.width / 2;
        final dist = delta.distance.clamp(0.0, maxRadius);
        final angle = delta.direction;
        final nx = (dist / maxRadius) * math.cos(angle);
        final ny = (dist / maxRadius) * math.sin(angle);
        setState(() => _position = Offset(nx, ny) * maxRadius);
        widget.onChanged(nx, ny);
      },
      onPanEnd: (_) {
        setState(() => _position = Offset.zero);
        widget.onChanged(0, 0);
      },
      child: CustomPaint(
        size: Size.infinite,
        painter: _RCJoystickPainter(_position),
      ),
    );
  }
}

class _RCJoystickPainter extends CustomPainter {
  final Offset position;

  _RCJoystickPainter(this.position);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final bgPaint = Paint()
      ..color = Colors.white12
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, bgPaint);

    final ringPaint = Paint()
      ..color = const Color(0xFF448AFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(center, radius, ringPaint);

    final crossPaint = Paint()
      ..color = Colors.white24
      ..strokeWidth = 1;
    canvas.drawLine(Offset(center.dx, 0), Offset(center.dx, size.height), crossPaint);
    canvas.drawLine(Offset(0, center.dy), Offset(size.width, center.dy), crossPaint);

    final stickX = center.dx + position.dx;
    final stickY = center.dy + position.dy;
    final stickPaint = Paint()
      ..color = const Color(0xFF448AFF)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(stickX, stickY), radius * 0.25, stickPaint);
  }

  @override
  bool shouldRepaint(covariant _RCJoystickPainter old) => old.position != position;
}
