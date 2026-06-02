import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hybrid_app/features/webrtc/presentation/video_view.dart';
import 'package:hybrid_app/features/webrtc/services/webrtc_service.dart';

class MyHybridApp extends StatelessWidget {
  const MyHybridApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hybrid App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      // Set the home screen to your native WebRTC audio/video presentation layer
      home: Consumer(
        builder: (context, ref, child) {
          final service = ref.read(webrtcServiceProvider);
          return VideoCallScreen(rtcService: service);
        },
      ),
    );
  }
}