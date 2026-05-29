import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:hybrid_app/core/constants.dart';
import 'package:hybrid_app/features/session/providers/session_provider.dart';
import 'package:hybrid_app/features/webrtc/services/webrtc_service.dart';

class VideoView extends ConsumerStatefulWidget {
  const VideoView({Key? key}) : super(key: key);

  @override
  ConsumerState<VideoView> createState() => _VideoViewState();
}

class _VideoViewState extends ConsumerState<VideoView> {
  final RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  final RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();
  bool _callStarted = false;

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

  /// BUG 3 FIX: Wire service stream callbacks to renderer srcObjects.
  /// Previously startVoiceCall() was never called from VideoView, so no
  /// streams were ever acquired and no srcObject was ever assigned.
  void _startCall(Map<String, dynamic> sessionData) {
    if (_callStarted) return;
    _callStarted = true;

    final service = ref.read(webrtcServiceProvider);

    // Register callbacks BEFORE starting the call so we don't miss early events
    service.onLocalStream = (stream) {
      if (mounted) {
        setState(() {
          _localRenderer.srcObject = stream; // assigns stream -> widget repaints
        });
      }
    };

    service.onRemoteStream = (stream) {
      if (mounted) {
        setState(() {
          _remoteRenderer.srcObject = stream;
        });
      }
    };

    final roomId = sessionData['roomId'] as String;

    // BUG 2 FIX: Pass baseUrl (not signalingUrl) — socket_io_client appends
    // /socket.io automatically. Using signalingUrl appended it twice -> 404.
    service.startVoiceCall(AppConstants.baseUrl, roomId);
  }

  @override
  Widget build(BuildContext context) {
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
                      // ignore: invalid_use_of_protected_member
                      ref.read(sessionProvider.notifier).state =
                          const AsyncValue.data({
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

          // BUG 3 FIX: Kick off the call as soon as we have a valid session.
          // Use addPostFrameCallback so we don't call setState during build.
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _startCall(sessionData);
          });

          final roomId = sessionData['roomId'];

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  'Connected to Portal Room: $roomId',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              Expanded(
                child: Stack(
                  children: [
                    // Remote stream — fills the screen
                    RTCVideoView(
                      _remoteRenderer,
                      objectFit:
                          RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                    ),

                    // Local preview — picture-in-picture bottom right
                    Positioned(
                      right: 20,
                      bottom: 20,
                      width: 120,
                      height: 160,
                      child: RTCVideoView(
                        _localRenderer,
                        mirror: true,
                        objectFit:
                            RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: ElevatedButton(
                  style:
                      ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  onPressed: () {
                    ref.read(webrtcServiceProvider).disconnect();
                    ref.read(sessionProvider.notifier).resetSession();
                    Navigator.pop(context);
                  },
                  child: const Text('End Call'),
                ),
              ),
            ],
          );
        },
        error: (err, stack) =>
            Center(child: Text('Error initializing: $err')),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}
