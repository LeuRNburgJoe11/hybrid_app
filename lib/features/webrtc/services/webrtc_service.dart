import 'dart:async';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hybrid_app/features/webrtc/providers/call_notifier.dart';
import 'package:hybrid_app/features/webrtc/models/call_state.dart';
import 'package:hybrid_app/features/session/providers/session_provider.dart';

class WebRTCService {
  final Ref ref;
  IO.Socket? socket;
  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;
  MediaStream? _remoteStream; 

  Function(MediaStream)? onLocalStream;
  Function(MediaStream)? onRemoteStream;

  Timer? _volumeTimer;
  
  final _isLocalSpeakingController = StreamController<bool>.broadcast();
  final _isRemoteSpeakingController = StreamController<bool>.broadcast();

  Stream<bool> get isLocalSpeakingStream => _isLocalSpeakingController.stream;
  Stream<bool> get isRemoteSpeakingStream => _isRemoteSpeakingController.stream;

  bool _wasLocalSpeaking = false;
  bool _wasRemoteSpeaking = false;

  WebRTCService(this.ref);

  // PRODUCTION ICE CONFIGURATION: Feeds your STUN/TURN clusters into the native pair engine
  final Map<String, dynamic> _iceConfig = {
    'iceServers': [
      {
        'urls': [
          'stun:stun1.l.google.com:19302',
          'stun:stun2.l.google.com:19302',
        ]
      },
      {
        'urls': 'turn:your-turn-server-domain.com:3478', 
        'username': 'your_service_auth_username',        
        'credential': 'your_secret_security_password',   
      },
      {
        'urls': 'turns:your-turn-server-domain.com:5349', 
        'username': 'your_service_auth_username',
        'credential': 'your_secret_security_password',
      }
    ],
    // 'all' tells ICE to aggressively test both direct host pathways and relayed pathways
    'iceTransportPolicy': 'all', 
    'sdpSemantics': 'unified-plan'
  };

  Future<void> startVoiceCall(String signalingUrl, String roomId) async {
    ref.read(callProvider.notifier).updateStatus(CallStatus.connecting);

    try {
      // The ICE Engine instantly instantiates with your candidate rules here
      _peerConnection = await createPeerConnection(_iceConfig);

      _peerConnection!.onIceCandidate = (RTCIceCandidate candidate) {
        // ICE Algorithm found a local endpoint option! Send it through signaling instantly.
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
          _startVolumeMonitoring(); 
        } else if (state == RTCPeerConnectionState.RTCPeerConnectionStateFailed) {
          ref.read(callProvider.notifier).updateStatus(CallStatus.error,
              error: "WebRTC peer connection failed.");
        }
      };

      _peerConnection!.onTrack = (RTCTrackEvent event) {
        if (event.streams.isNotEmpty) {
          _remoteStream = event.streams[0];
          onRemoteStream?.call(_remoteStream!); 
        }
      };

      _connectToSignaling(wsUrl, roomId);

      final Map<String, dynamic> constraints = {
        'audio': true,
        'video': {        
          'facingMode': 'user',
          'width': {'ideal': 1280},
          'height': {'ideal': 720},
        },
      };
      _localStream = await navigator.mediaDevices.getUserMedia(constraints);

      onLocalStream?.call(_localStream!);

      _localStream!.getTracks().forEach((track) {
        _peerConnection!.addTrack(track, _localStream!);
      });

      socket?.emit('join', roomId); 

    } catch (e) {
      ref
          .read(callProvider.notifier)
          .updateStatus(CallStatus.error, error: e.toString());
    }
  }

  void _startVolumeMonitoring() {
    _volumeTimer?.cancel();
    _volumeTimer = Timer.periodic(const Duration(milliseconds: 200), (timer) async {
      if (_peerConnection == null) return;
      try {
        List<StatsReport> reports = await _peerConnection!.getStats();
        bool localSpeakingDetected = false;
        bool remoteSpeakingDetected = false;
        const double speakingThreshold = 0.04;

        for (var report in reports) {
          if (report.type == 'media-source' || report.type == 'inbound-rtp') {
            if (report.values['kind'] == 'audio') {
              double audioLevel = double.tryParse(report.values['audioLevel']?.toString() ?? '0.0') ?? 0.0;
              if (report.type == 'media-source') {
                localSpeakingDetected = audioLevel > speakingThreshold;
              } else if (report.type == 'inbound-rtp') {
                remoteSpeakingDetected = audioLevel > speakingThreshold;
              }
            }
          }
        }

        if (localSpeakingDetected != _wasLocalSpeaking) {
          _wasLocalSpeaking = localSpeakingDetected;
          _isLocalSpeakingController.add(localSpeakingDetected);
        }
        if (remoteSpeakingDetected != _wasRemoteSpeaking) {
          _wasRemoteSpeaking = remoteSpeakingDetected;
          _isRemoteSpeakingController.add(remoteSpeakingDetected);
        }
      } catch (_) {}
    });
  }

  void _connectToSignaling(String url, String roomId) {
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

    // RECEIVING REMOTE ICE CANDIDATES:
    socket!.on('ice-candidate', (data) {
      // Add candidate option sent by server.js into the local ICE engine
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
    socket?.emit('offer', {
      'room': roomId, 
      'sdp': offer.sdp,
      'type': offer.type
    });
  }

  Future<void> _createAnswer(String roomId) async {
    if (_peerConnection == null) return;
    RTCSessionDescription answer = await _peerConnection!.createAnswer();
    await _peerConnection!.setLocalDescription(answer);
    socket?.emit('answer', {
      'room': roomId, 
      'sdp': answer.sdp,
      'type': answer.type
    });
  }

  void endCall() async {
    try {
      _volumeTimer?.cancel();
      _volumeTimer = null;

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