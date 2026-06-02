import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:hybrid_app/features/webrtc/services/webrtc_service.dart';

class VideoCallScreen extends ConsumerStatefulWidget {
  final WebRTCService rtcService;
  const VideoCallScreen({Key? key, required this.rtcService}) : super(key: key);

  @override
  _VideoCallScreenState createState() => _VideoCallScreenState();
}

class _VideoCallScreenState extends ConsumerState<VideoCallScreen> {
  final RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  final RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();

  @override
  void initState() {
    super.initState();
    _initRenderers();

    // Hook into your WebRTCService streams so when a feed registers, the renderer displays it
    widget.rtcService.onLocalStream = (stream) {
      if (mounted) {
        setState(() {
          _localRenderer.srcObject = stream;
        });
      }
    };

    widget.rtcService.onRemoteStream = (stream) {
      if (mounted) {
        setState(() {
          _remoteRenderer.srcObject = stream;
        });
      }
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

  @override
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 1. Full-Screen view for the remote user's face
          Positioned.fill(
            child: Container(
              color: Colors.black87,
              child: _remoteRenderer.srcObject != null
                  ? RTCVideoView(
                      _remoteRenderer,
                      objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                    )
                  : const Center(
                      child: Text(
                        "Waiting for peer connection...",
                        style: TextStyle(color: Colors.white70),
                      ),
                    ),
            ),
          ),

          // 2. Small floating corner container for your local camera preview
          Positioned(
            top: 40,
            right: 20,
            child: Container(
              width: 120,
              height: 160,
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white30, width: 1.5),
              ),
              clipBehavior: Clip.antiAlias,
              child: _localRenderer.srcObject != null
                  ? RTCVideoView(
                      _localRenderer,
                      mirror: true, // Mirrors your own face back to you naturally
                      objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                    )
                  : const Center(
                      child: Icon(Icons.videocam_off, color: Colors.white30),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
