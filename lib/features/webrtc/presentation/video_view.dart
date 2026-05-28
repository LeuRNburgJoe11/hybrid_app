import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:hybrid_app/features/session/providers/session_provider.dart';
import 'package:hybrid_app/features/webrtc/services/webrtc_service.dart';

class VideoView extends ConsumerStatefulWidget {
  const VideoView({Key? key}) : super(key: key);

  @override
  ConsumerState<VideoView> createState() => _VideoViewState();
}

class _VideoViewState extends ConsumerState<VideoView> {
  // Native renderers from the flutter_webrtc package
  final RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  final RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();

  @override
  void initState() {
    super.initState();
    _initializeRenderers();
  }

  Future<void> _initializeRenderers() async {
    await _localRenderer.initialize();
    await _remoteRenderer.initialize();
  }

  @override
  void dispose() {
    _localRenderer.dispose();
    _remoteRenderer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 1. Watch the REST API session state
    final sessionAsync = ref.watch(sessionProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Live Support Video')),
      body: sessionAsync.when(
        data: (sessionData) {
          if (sessionData == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('No active session found.'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      ref.read(sessionProvider.notifier).state = const AsyncValue.data({
                        'roomId': 'MOCK-ROOM-12345',
                        'status': 'waiting',
                        'signalingUrl': 'http://localhost:3000'
                      });
                    },
                    child: const Text('Simulate Inbound Chatbot Request'),
                  ),
                ],
              ),
            );
          }

          final roomId = sessionData['roomId'];

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text('Connected to Portal Room: $roomId', 
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              Expanded(
                child: Stack(
                  children: [
                    // Remote Stream (Fills the screen)
                    RTCVideoView(_remoteRenderer),
                    
                    // Local Preview (Floating Picture-in-Picture)
                    Positioned(
                      right: 20,
                      bottom: 20,
                      width: 120,
                      height: 160,
                      child: RTCVideoView(_localRenderer, mirror: true),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  onPressed: () {
                    // Disconnect signaling and clear REST session
                    ref.read(webrtcServiceProvider).disconnect();
                    ref.read(sessionProvider.notifier).resetSession();
                    Navigator.pop(context);
                  },
                  child: const Text('End Call'),
                ),
              )
            ],
          );
        },
        error: (err, stack) => Center(child: Text('Error initialization: $err')),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}