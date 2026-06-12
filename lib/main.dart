import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'managers/sdk_manager.dart';
import 'managers/gimbal_controller.dart';
import 'managers/rc_input_manager.dart';
import 'managers/camera_controller.dart';
import 'managers/telemetry_manager.dart';
import 'managers/video_manager.dart';
import 'view_controllers/main_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  runApp(const GimbalCtrlApp());
}

class GimbalCtrlApp extends StatelessWidget {
  const GimbalCtrlApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SDKManager()),
        ChangeNotifierProvider(create: (_) => GimbalCtrl()),
        ChangeNotifierProvider(create: (_) => RCInputManager()),
        ChangeNotifierProvider(create: (_) => CameraCtrl()),
        ChangeNotifierProvider(create: (_) => TelemetryManager()),
        ChangeNotifierProvider(create: (_) => VideoManager()),
      ],
      child: MaterialApp(
        title: '云台走地机',
        debugShowCheckedModeBanner: false,
        theme: ThemeData.dark().copyWith(
          scaffoldBackgroundColor: Colors.black,
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.transparent,
            elevation: 0,
            systemOverlayStyle: SystemUiOverlayStyle.light,
          ),
        ),
        home: const MainScreen(),
      ),
    );
  }
}
