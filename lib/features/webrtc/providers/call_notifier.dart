// lib/features/webrtc/providers/call_notifier.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hybrid_app/features/webrtc/models/call_state.dart';
import 'package:hybrid_app/features/webrtc/services/webrtc_service.dart';
import 'package:hybrid_app/core/constants.dart';

class CallNotifier extends Notifier<CallState> {
  @override
  CallState build() {
    return CallState(status: CallStatus.idle);
  }

  void updateStatus(CallStatus newStatus, {String? error}) {
    state = state.copyWith(status: newStatus, errorMessage: error);
  }

  /// Handles the response from your Chatbot's Invoke API block.
  ///
  /// Expected [apiResponse] shape (matches server.js /api/handshake-escalation):
  /// {
  ///   "status":         "waiting",
  ///   "roomId":         "room_abc123",
  ///   "userId":         "user_xyz",
  ///   "turnUrls":       ["turn:turn.cloudflare.com:3478?transport=udp", ...],
  ///   "turnUsername":   "<ephemeral username>",
  ///   "turnCredential": "<ephemeral credential>"
  /// }
  Future<void> handleChatbotEscalation({
    required Map<String, dynamic> apiResponse,
    required WebRTCService rtcService,
  }) async {
    try {
      final String? status = apiResponse['status'];
      final String? roomId = apiResponse['roomId'];

      // FIX 1: Guard on both status and roomId before proceeding
      if (status != 'waiting' || roomId == null || roomId.isEmpty) {
        state = state.copyWith(
          status: CallStatus.error,
          errorMessage: apiResponse['status'] == 'failed'
              ? "Server failed to generate TURN credentials. Check Render logs."
              : "All support agents are currently busy.",
        );
        return;
      }

      // FIX 2: Read flat TURN fields directly — matches the fixed server.js response.
      // No more guessing between cloudflare / iceConfig / turnServers / iceServers keys.
      final List<String> turnUrls = List<String>.from(
        apiResponse['turnUrls'] ?? [],
      );
      final String turnUsername = apiResponse['turnUsername'] ?? '';
      final String turnCredential = apiResponse['turnCredential'] ?? '';

      // FIX 3: Validate credentials exist before starting the call
      if (turnUsername.isEmpty || turnCredential.isEmpty) {
        state = state.copyWith(
          status: CallStatus.error,
          errorMessage: 'Missing TURN credentials in server response.',
        );
        return;
      }

      // Advance state to waiting and store credentials so app.dart
      // can read them from CallState to pass to VideoCallScreen.
      state = state.copyWith(
        status: CallStatus.waiting,
        roomId: roomId,
        turnUrls: turnUrls,
        turnUsername: turnUsername,
        turnCredential: turnCredential,
      );

      // FIX 4: Call startVoiceCall with named parameters matching the
      // updated webrtc_service.dart signature — no more positional args
      // or fragile Map<String, dynamic> ICE parsing.
      await rtcService.startVoiceCall(
        signalingUrl: AppConstants.signalingUrl,
        roomId: roomId,
        turnUrls: turnUrls,
        turnUsername: turnUsername,
        turnCredential: turnCredential,
      );

    } catch (e) {
      state = state.copyWith(
        status: CallStatus.error,
        errorMessage: "Failed to connect to live support: $e",
      );
    }
  }
}

final callProvider = NotifierProvider<CallNotifier, CallState>(() {
  return CallNotifier();
});
