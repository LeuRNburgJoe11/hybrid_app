import 'dart:async';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hybrid_app/features/webrtc/providers/call_notifier.dart';
import 'package:hybrid_app/features/webrtc/models/call_state.dart';

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
  
  /// Public getter for local media stream
  MediaStream? get localStream => _localStream;

  bool _wasLocalSpeaking = false;
  bool _wasRemoteSpeaking = false;

  WebRTCService(this.ref);

  /// Starts the voice call using TURN credentials passed from the chatbot
  /// Invoke API response.
  ///
  /// [signalingUrl]   — your Render.com server URL (no /socket.io suffix)
  /// [roomId]         — room ID from /api/handshake-escalation response
  /// [turnUrls]       — list of TURN URLs from response
  /// [turnUsername]   — ephemeral TURN username from response
  /// [turnCredential] — ephemeral TURN credential from response
  Future<void> startVoiceCall({
    required String signalingUrl,
    required String roomId,
    required List<String> turnUrls,
    required String turnUsername,
    required String turnCredential,
  }) async {
    ref.read(callProvider.notifier).updateStatus(CallStatus.connecting);

    try {
      // FIX 1: Build ICE config from flat fields — no brittle JSON parsing.
      // Cloudflare TURN + Google STUN fallback.
      final Map<String, dynamic> iceConfig = {
        'iceServers': [
          {
            'urls': [
              'stun:stun1.l.google.com:19302',
              'stun:stun2.l.google.com:19302',
            ]
          },
          {
            'urls': turnUrls.isNotEmpty
                ? turnUrls
                : [
                    'stun:stun.cloudflare.com:3478',
                    'turn:turnv2.realtime.cloudflare.com:3478?transport=udp',
                    'turn:turn.cloudflare.com:3478?transport=tcp',
                    'turns:turn.cloudflare.com:5349?transport=tcp',
                  ],
            'username': turnUsername,
            'credential': turnCredential,
          }
        ],
        'iceTransportPolicy': 'all',
        'sdpSemantics': 'unified-plan',
      };

      _peerConnection = await createPeerConnection(iceConfig);

      // FIX 2: Use roomId consistently — matches server.js ice-candidate relay key
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
          _startVolumeMonitoring();
        } else if (state == RTCPeerConnectionState.RTCPeerConnectionStateFailed) {
          ref.read(callProvider.notifier).updateStatus(
            CallStatus.error,
            error: "WebRTC peer connection failed.",
          );
        }
      };

      _peerConnection!.onTrack = (RTCTrackEvent event) {
        if (event.streams.isNotEmpty) {
          _remoteStream = event.streams[0];
          onRemoteStream?.call(_remoteStream!);
        }
      };

      // FIX 3: Acquire media BEFORE connecting to signaling so tracks
      // are ready to add before any offer/answer exchange begins.
      // FIX 4: Voice-only — video: false. This was requesting camera
      // unnecessarily for a voice call.
      final Map<String, dynamic> mediaConstraints = {
        'audio': true,
        'video': false,
      };
      _localStream = await navigator.mediaDevices.getUserMedia(mediaConstraints);
      onLocalStream?.call(_localStream!);

      _localStream!.getTracks().forEach((track) {
        _peerConnection!.addTrack(track, _localStream!);
      });

      // FIX 5: Connect signaling last. The socket 'connect' callback
      // emits 'join', and the server responds with 'peer-joined' to trigger
      // createOffer() — so the peer connection and tracks must exist first.
      _connectToSignaling(signalingUrl, roomId);

    } catch (e) {
      ref.read(callProvider.notifier).updateStatus(
        CallStatus.error,
        error: e.toString(),
      );
    }
  }

  void _connectToSignaling(String url, String roomId) {
    socket = IO.io(
      url,
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .build(),
    );

    // FIX 6: Emit 'join' only after socket is confirmed connected,
    // not fire-and-forget after construction.
    socket!.onConnect((_) {
      print('[Socket] Connected. Joining room: $roomId');
      socket!.emit('join', roomId);
    });

    // FIX 7: Server emits 'peer-joined' when the agent joins the same room.
    // That is the correct trigger to create an offer — not on our own join.
    socket!.on('peer-joined', (_) async {
      print('[Socket] Peer joined. Creating offer...');
      await createOffer(roomId);
    });

    socket!.on('offer', (data) async {
      final description = RTCSessionDescription(data['sdp'], data['type']);
      await _peerConnection?.setRemoteDescription(description);
      await _createAnswer(roomId);
    });

    socket!.on('answer', (data) async {
      final description = RTCSessionDescription(data['sdp'], data['type']);
      await _peerConnection?.setRemoteDescription(description);
    });

    socket!.on('ice-candidate', (data) {
      _peerConnection?.addCandidate(RTCIceCandidate(
        data['candidate'],
        data['sdpMid'],
        data['sdpMLineIndex'],
      ));
    });

    socket!.onDisconnect((_) {
      print('[Socket] Disconnected from signaling server.');
    });

    socket!.onError((err) {
      print('[Socket] Error: $err');
    });

    socket!.connect();
  }

  /// Toggles audio mute. Returns the new muted state (true = muted).
  bool toggleMute() {
    final tracks = _localStream?.getAudioTracks();
    if (tracks == null || tracks.isEmpty) return false;
    final track = tracks.first;
    track.enabled = !track.enabled;
    return !track.enabled;
  }

  Future<void> createOffer(String roomId) async {
    if (_peerConnection == null) return;
    final offer = await _peerConnection!.createOffer();
    await _peerConnection!.setLocalDescription(offer);
    socket?.emit('offer', {
      'roomId': roomId,
      'sdp': offer.sdp,
      'type': offer.type,
    });
  }

  Future<void> _createAnswer(String roomId) async {
    if (_peerConnection == null) return;
    final answer = await _peerConnection!.createAnswer();
    await _peerConnection!.setLocalDescription(answer);
    socket?.emit('answer', {
      'roomId': roomId,
      'sdp': answer.sdp,
      'type': answer.type,
    });
  }

  void _startVolumeMonitoring() {
    _volumeTimer?.cancel();
    _volumeTimer = Timer.periodic(const Duration(milliseconds: 200), (timer) async {
      if (_peerConnection == null) return;
      try {
        final List<StatsReport> reports = await _peerConnection!.getStats();
        bool localSpeaking = false;
        bool remoteSpeaking = false;
        const double threshold = 0.04;

        for (final report in reports) {
          if (report.values['kind'] == 'audio') {
            final double level = double.tryParse(
                  report.values['audioLevel']?.toString() ?? '0.0') ?? 0.0;
            if (report.type == 'media-source') {
              localSpeaking = level > threshold;
            } else if (report.type == 'inbound-rtp') {
              remoteSpeaking = level > threshold;
            }
          }
        }

        if (localSpeaking != _wasLocalSpeaking) {
          _wasLocalSpeaking = localSpeaking;
          _isLocalSpeakingController.add(localSpeaking);
        }
        if (remoteSpeaking != _wasRemoteSpeaking) {
          _wasRemoteSpeaking = remoteSpeaking;
          _isRemoteSpeakingController.add(remoteSpeaking);
        }
      } catch (_) {}
    });
  }

  void endCall() async {
    try {
      _volumeTimer?.cancel();
      _volumeTimer = null;

      _localStream?.getTracks().forEach((track) => track.stop());
      await _localStream?.dispose();
      await _remoteStream?.dispose();
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
    } catch (e) {
      ref.read(callProvider.notifier).updateStatus(
        CallStatus.error,
        error: "Failed to clean up call.",
      );
    }
  }

  void disconnect() => endCall();
}

final webrtcServiceProvider = Provider<WebRTCService>((ref) {
  return WebRTCService(ref);
});
