import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:hybrid_app/core/constants.dart';
import 'package:hybrid_app/features/session/providers/session_provider.dart';
import 'package:hybrid_app/features/webrtc/services/webrtc_service.dart';

class VideoCallScreen extends StatefulWidget {
  final WebRTCService rtcService;
  const VideoCallScreen({Key? key, required this.rtcService}) : super(key: key);

  @override
  _VideoCallScreenState createState() => _VideoCallScreenState();
}

class _VideoCallScreenState extends State<VideoCallScreen> {
  final RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  final RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();

  @override
  void initState() {
    super.initState();
    _initRenderers();

    // Hook into your WebRTCService streams so when a feed registers, the renderer displays it
    widget.rtcService.onLocalStream = (stream) {
      setState(() {
        _localRenderer.srcObject = stream;
      });
    };

    widget.rtcService.onRemoteStream = (stream) {
      setState(() {
        _remoteRenderer.srcObject = stream;
      });
    };
  }

  Future<void> _initRenderers() async {
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

// Inside your video_view.dart widget build function
StreamBuilder<bool>(
  stream: ref.read(webrtcServiceProvider).isLocalSpeakingStream,
  initialData: false,
  builder: (context, snapshot) {
    final isSpeaking = snapshot.data ?? false;
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: isSpeaking ? Colors.green : Colors.transparent, 
          width: 3
        ),
      ),
      child: Icon(isSpeaking ? Icons.mic : Icons.mic_off),
    );
  },
);