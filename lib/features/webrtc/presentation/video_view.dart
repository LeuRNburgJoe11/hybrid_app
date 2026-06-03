import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:hybrid_app/features/webrtc/services/webrtc_service.dart';
import 'package:hybrid_app/features/webrtc/providers/call_notifier.dart';
import 'package:hybrid_app/features/webrtc/models/call_state.dart';

class VideoCallScreen extends ConsumerStatefulWidget {
  final WebRTCService rtcService;

  // FIX: Accept TURN credentials and roomId directly so this screen
  // can display status and pass context to the service cleanly.
  final String roomId;
  final String signalingUrl;
  final List<String> turnUrls;
  final String turnUsername;
  final String turnCredential;

  const VideoCallScreen({
    Key? key,
    required this.rtcService,
    required this.roomId,
    required this.signalingUrl,
    required this.turnUrls,
    required this.turnUsername,
    required this.turnCredential,
  }) : super(key: key);

  @override
  _VideoCallScreenState createState() => _VideoCallScreenState();
}

class _VideoCallScreenState extends ConsumerState<VideoCallScreen> {
  // FIX: This is a voice call — remote renderer is kept for future video
  // upgrade but local renderer is removed (no camera requested).
  final RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();
  bool _isMuted = false;

  @override
  void initState() {
    super.initState();
    _initCall();
  }

  Future<void> _initCall() async {
    await _remoteRenderer.initialize();

    // Wire remote stream to renderer
    widget.rtcService.onRemoteStream = (stream) {
      if (mounted) {
        setState(() {
          _remoteRenderer.srcObject = stream;
        });
      }
    };

    // Start the voice call with credentials from the chatbot Invoke response
    await widget.rtcService.startVoiceCall(
      signalingUrl: widget.signalingUrl,
      roomId: widget.roomId,
      turnUrls: widget.turnUrls,
      turnUsername: widget.turnUsername,
      turnCredential: widget.turnCredential,
    );
  }

  @override
  void dispose() {
    _remoteRenderer.dispose();
    super.dispose();
  }

  void _toggleMute() {
    final audioTracks = widget.rtcService.localStream?.getAudioTracks();
    if (audioTracks != null && audioTracks.isNotEmpty) {
      final track = audioTracks.first;
      track.enabled = !track.enabled;
      setState(() {
        _isMuted = !track.enabled;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final callState = ref.watch(callProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // ── Status / Remote Audio Indicator ───────────────────────────
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircleAvatar(
                    radius: 48,
                    backgroundColor: Colors.blueGrey,
                    child: Icon(Icons.support_agent, size: 48, color: Colors.white),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    _statusLabel(callState.status),
                    style: const TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                  if (callState.status == CallStatus.connecting)
                    const Padding(
                      padding: EdgeInsets.only(top: 12),
                      child: CircularProgressIndicator(color: Colors.white54),
                    ),
                  if (callState.errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(
                        callState.errorMessage!,
                        style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                        textAlign: TextAlign.center,
                      ),
                    ),

                  // Remote speaking indicator (audio only call)
                  const SizedBox(height: 20),
                  StreamBuilder<bool>(
                    stream: widget.rtcService.isRemoteSpeakingStream,
                    initialData: false,
                    builder: (context, snapshot) {
                      final speaking = snapshot.data ?? false;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: speaking
                              ? Colors.green.withOpacity(0.2)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: speaking ? Colors.green : Colors.white24,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              speaking ? Icons.volume_up : Icons.volume_off,
                              color: speaking ? Colors.green : Colors.white38,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              speaking ? "Agent speaking" : "Agent silent",
                              style: TextStyle(
                                color: speaking ? Colors.green : Colors.white38,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            // ── Bottom Controls ────────────────────────────────────────────
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Mute toggle
                  StreamBuilder<bool>(
                    stream: widget.rtcService.isLocalSpeakingStream,
                    initialData: false,
                    builder: (context, snapshot) {
                      return GestureDetector(
                        onTap: _toggleMute,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: _isMuted
                                ? Colors.red.withOpacity(0.8)
                                : Colors.white12,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _isMuted ? Icons.mic_off : Icons.mic,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 40),

                  // End call
                  GestureDetector(
                    onTap: () {
                      widget.rtcService.endCall();
                      Navigator.of(context).pop();
                    },
                    child: Container(
                      padding: const EdgeInsets.all(18),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.call_end, color: Colors.white, size: 32),
                    ),
                  ),
                ],
              ),
            ),

            // ── Room ID debug label (remove in production) ─────────────────
            Positioned(
              top: 12,
              left: 16,
              child: Text(
                'Room: ${widget.roomId}',
                style: const TextStyle(color: Colors.white24, fontSize: 11),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _statusLabel(CallStatus status) {
    switch (status) {
      case CallStatus.connecting:
        return "Connecting to agent...";
      case CallStatus.connected:
        return "Connected";
      case CallStatus.disconnected:
        return "Call ended";
      case CallStatus.error:
        return "Connection error";
      case CallStatus.waiting:
        return "Waiting for agent...";
      default:
        return "";
    }
  }
}
