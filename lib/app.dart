import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hybrid_app/features/webrtc/presentation/video_view.dart';
import 'package:hybrid_app/features/webrtc/services/webrtc_service.dart';
import 'package:hybrid_app/features/webrtc/providers/call_notifier.dart';
import 'package:hybrid_app/features/webrtc/models/call_state.dart';
import 'package:hybrid_app/core/constants.dart';

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
      // Home is your chatbot screen.
      // VideoCallScreen is pushed via Navigator when escalation is triggered.
      home: const ChatbotShell(),
    );
  }
}

/// ChatbotShell sits behind the chatbot WebView and listens for escalation.
/// When the chatbot's Invoke API block returns TURN credentials, this
/// automatically pushes VideoCallScreen on top.
class ChatbotShell extends ConsumerWidget {
  const ChatbotShell({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Listen (not watch) so we react to state changes without rebuilding
    // the whole widget tree on every status tick.
    ref.listen<CallState>(callProvider, (previous, next) {
      // Navigate to VideoCallScreen the moment escalation succeeds and we
      // have all credentials — status transitions to 'waiting' or 'connecting'.
      if ((next.status == CallStatus.waiting ||
              next.status == CallStatus.connecting) &&
          previous?.status == CallStatus.idle) {
        final rtcService = ref.read(webrtcServiceProvider);

        // Pull the latest escalation data stored by CallNotifier.
        // VideoCallScreen reads credentials from the service directly
        // since startVoiceCall() was already called by handleChatbotEscalation.
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => VideoCallScreen(
              rtcService: rtcService,
              roomId: next.roomId ?? '',
              signalingUrl: AppConstants.signalingUrl,
              turnUrls: next.turnUrls ?? [],
              turnUsername: next.turnUsername ?? '',
              turnCredential: next.turnCredential ?? '',
            ),
          ),
        );
      }
    });

    // Replace this placeholder with your actual chatbot WebView widget.
    // This is where your InAppWebView / webview_flutter widget lives.
    return const Scaffold(
      body: Center(
        child: Text(
          'Chatbot loads here',
          style: TextStyle(color: Colors.black54),
        ),
      ),
    );
  }
}
