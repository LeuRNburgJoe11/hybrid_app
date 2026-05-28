import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; 
import 'package:hybrid_app/features/webrtc/presentation/video_view.dart'; // Pointing to your native audio/video layer

class MyHybridApp extends StatelessWidget {
  const MyHybridApp({super.key});

  @override
  Widget build(BuildContext context) {
    // ProviderScope here ensures both sessionProvider and callProvider are alive right at boot
    return ProviderScope(
      child: MaterialApp(
        title: 'Hybrid Chatbot Prototype',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.blueAccent,
            brightness: Brightness.light,
          ),
          scaffoldBackgroundColor: Colors.white,
          appBarTheme: const AppBarTheme(
            centerTitle: true,
            elevation: 0,
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
          ),
        ),
        home: const VideoView(), // Directly opening your voice call test interface
      ),
    );
  }
}