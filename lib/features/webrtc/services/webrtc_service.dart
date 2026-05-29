import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hybrid_app/features/webrtc/providers/call_notifier.dart';
import 'package:hybrid_app/features/webrtc/models/call_state.dart';
import 'package:hybrid_app/features/session/providers/session_provider.dart';

// BUG 3 FIX: Expose renderers so VideoView can bind srcObject after streams arrive.
// The service owns the MediaStreams; the UI owns the RTCVideoRenderers.
// We bridge them via these public stream getters.
class WebRTCService {
  final Ref ref;
  IO.Socket? socket;
  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;
  MediaStream? _remoteStream; // BUG 3 FIX: track remote stream explicitly

  // BUG 3 FIX: Callbacks so VideoView can react when streams become available
  Function(MediaStream)? onLocalStream;
  Function(MediaStream)? onRemoteStream;

  WebRTCService(this.ref);

  final Map<String, dynamic> _iceConfig = {
    'iceServers': [
      {'urls': 'stun:stun.l.google.com:19302'},
    ]
  };

  /// Main method triggered when the REST API confirms a valid room session
  Future<void> startVoiceCall(String wsUrl, String roomId) async {
    ref.read(callProvider.notifier).updateStatus(CallStatus.connecting);

    try {
      // 1. Create Peer Connection FIRST to avoid race conditions
      _peerConnection = await createPeerConnection(_iceConfig);

      _peerConnection!.onIceCandidate = (RTCIceCandidate candidate) {
        socket?.emit('ice-candidate', {
          'roomId': roomId,
          'candidate': candidate.candidate,
          'sdpMid': candidate.sdpMid,
          'sdpMLineIndex': candidate.sdpMLineIndex,
        });
      };

      _peerConnection!.onConnectionState = (RTCPeerConnectionState state) {
        if (state == RTCPeerConnectionState.RTCPeerConnectionStateConnected) {
          ref.read(callProvider.notifier).updateStatus(CallStatus.connected);
        } else if (state == RTCPeerConnectionState.RTCPeerConnectionStateFailed) {
          ref.read(callProvider.notifier).updateStatus(CallStatus.error,
              error: "WebRTC peer connection failed.");
        }
      };

      // BUG 3 FIX: Handle incoming remote tracks and fire callback to UI
      _peerConnection!.onTrack = (RTCTrackEvent event) {
        if (event.streams.isNotEmpty) {
          _remoteStream = event.streams[0];
          onRemoteStream?.call(_remoteStream!); // notify VideoView
        }
      };

      // 2. Connect signaling
      _connectToSignaling(wsUrl, roomId);

      // BUG 1 FIX: Request BOTH audio AND video (was audio-only: video: false)
      final Map<String, dynamic> constraints = {
        'audio': true,
        'video': {                          // <-- was: 'video': false
          'facingMode': 'user',
          'width': {'ideal': 1280},
          'height': {'ideal': 720},
        },
      };
      _localStream = await navigator.mediaDevices.getUserMedia(constraints);

      // BUG 3 FIX: Notify VideoView so it can assign srcObject
      onLocalStream?.call(_localStream!);

      // Attach all local tracks (audio + video) to peer connection
      _localStream!.getTracks().forEach((track) {
        _peerConnection!.addTrack(track, _localStream!);
      });

      // BUG 4 FIX: server.js listens for 'join' not 'join-room'
      socket?.emit('join', roomId); // <-- was: socket?.emit('join-room', {'roomId': roomId})

    } catch (e) {
      ref
          .read(callProvider.notifier)
          .updateStatus(CallStatus.error, error: e.toString());
    }
  }

  void _connectToSignaling(String url, String roomId) {
    // BUG 2 FIX: Use baseUrl only — socket_io_client appends /socket.io itself.
    // constants.dart had signalingUrl = '...onrender.com/socket.io' which caused
    // the client to connect to /socket.io/socket.io (404).
    // The caller (VideoView) should now pass AppConstants.baseUrl, not signalingUrl.
    socket = IO.io(
        url,
        IO.OptionBuilder()
            .setTransports(['websocket'])
            .setQuery({'roomId': roomId})
            .build());

    socket!.on('offer', (data) async {
      var description = RTCSessionDescription(data['sdp'], data['type']);
      await _peerConnection?.setRemoteDescription(description);
      await _createAnswer(roomId);
    });

    socket!.on('answer', (data) async {
      var description = RTCSessionDescription(data['sdp'], data['type']);
      await _peerConnection?.setRemoteDescription(description);
    });

    socket!.on('ice-candidate', (data) {
      _peerConnection?.addCandidate(RTCIceCandidate(
        data['candidate'],
        data['sdpMid'],
        data['sdpMLineIndex'],
      ));
    });
  }

  Future<void> createOffer(String roomId) async {
    if (_peerConnection == null) return;
    RTCSessionDescription offer = await _peerConnection!.createOffer();
    await _peerConnection!.setLocalDescription(offer);
    // BUG 5 FIX: server.js relays by data.room, not data.roomId
    socket?.emit('offer', {
      'room': roomId, // <-- was: 'roomId': roomId
      'sdp': offer.sdp,
      'type': offer.type
    });
  }

  Future<void> _createAnswer(String roomId) async {
    if (_peerConnection == null) return;
    RTCSessionDescription answer = await _peerConnection!.createAnswer();
    await _peerConnection!.setLocalDescription(answer);
    // BUG 5 FIX: server.js relays by data.room, not data.roomId
    socket?.emit('answer', {
      'room': roomId, // <-- was: 'roomId': roomId
      'sdp': answer.sdp,
      'type': answer.type
    });
  }

  void endCall() async {
    try {
      _localStream?.getTracks().forEach((track) => track.stop());
      await _localStream?.dispose();
      await _peerConnection?.dispose();

      socket?.emit('leave-room', {'reason': 'user_ended_call'});
      socket?.disconnect();

      _localStream = null;
      _remoteStream = null;
      _peerConnection = null;
      socket = null;

      onLocalStream = null;
      onRemoteStream = null;

      ref.read(callProvider.notifier).updateStatus(CallStatus.disconnected);
      ref.read(sessionProvider.notifier).resetSession();
    } catch (e) {
      ref
          .read(callProvider.notifier)
          .updateStatus(CallStatus.error, error: "Failed to clean up call.");
    }
  }

  void disconnect() {
    endCall();
  }
}

final webrtcServiceProvider = Provider<WebRTCService>((ref) {
  return WebRTCService(ref);
});
