import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
class LiveSupportPage extends StatefulWidget {
  const LiveSupportPage({super.key});
  @override
  State<LiveSupportPage> createState() => _LiveSupportPageState();
  }

class _LiveSupportPageState extends State<LiveSupportPage> {
  // Step 1 — Declare renderers
  final RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  final RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();
  MediaStream? _localStream;
  RTCPeerConnection? _peerConnection;

  @override
  void initState() {
    super.initState();
    _initRenderers();
  }

  // Step 2 — CRITICAL: initialise before any use
  Future<void> _initRenderers() async {
    await _localRenderer.initialize(); // <-- must not be skipped
    await _remoteRenderer.initialize();
    await _startLocalStream();
    await _createPeerConnection();
  }

// Step 3 — Request camera/mic and assign to local renderer
Future<void> _startLocalStream() async {
  final Map<String, dynamic> constraints = {
    'audio': true,
      'video': {
        'facingMode': 'user',
          'width': {'ideal': 1280},
            'height': {'ideal': 720},
        },
    };
  try {
    final stream = await navigator.mediaDevices.getUserMedia(constraints);
    setState(() {
      _localStream = stream;
      _localRenderer.srcObject = stream; // Step 4 — assign srcObject
    });
  } catch (e) {
    debugPrint('getUserMedia error: $e');
  }
}

// When creating the peer connection, add all local tracks
Future<void> _createPeerConnection() async {
  final config = {
    'iceServers': [
      {'urls': 'stun:stun.l.google.com:19302'}
    ]
  };
  _peerConnection = await createPeerConnection(config);
  _localStream?.getTracks().forEach((track) {
    _peerConnection!.addTrack(track, _localStream!);
    });
  // Assign remote stream when it arrives
  _peerConnection!.onTrack = (RTCTrackEvent event) {
    if (event.streams.isNotEmpty) {
      setState(() {
        _remoteRenderer.srcObject = event.streams[0];
      });
    }
  };
}

@override
void dispose() {
  _localRenderer.dispose();
  _remoteRenderer.dispose();
  _localStream?.dispose();
  _peerConnection?.close();
  super.dispose();
}
@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(title: const Text('Live Support Video')),
    body: Stack(
      children: [
// Remote video (full screen background)
// Add local tracks so remote peer receives video
        RTCVideoView(
          _remoteRenderer,
          objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
        ),
        // Local video (picture-in-picture, bottom right)
        Positioned(
          bottom: 80, right: 16,
          width: 120, height: 160,
          child: RTCVideoView(
            _localRenderer,
            mirror: true, // flip front camera
            objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
          ),
        ),
        // End Call button
        Positioned(
          bottom: 16, left: 0, right: 0,
          child: Center(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red),
              onPressed: () => Navigator.pop(context),
              child: const Text('End Call'),
            ),
          ),
        ),
      ],
    ),
  );
 }
}
