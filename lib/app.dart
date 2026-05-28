import 'package:flutter/material.dart';
import 'package:hybrid_app/features/webrtc/presentation/video_view.dart';

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
      home: const VideoView(),
    );
  }
}