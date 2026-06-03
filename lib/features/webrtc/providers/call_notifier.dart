// lib/features/webrtc/providers/call_notifier.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hybrid_app/features/webrtc/models/call_state.dart';
import 'package:hybrid_app/features/webrtc/services/webrtc_service.dart';

class CallNotifier extends Notifier<CallState> {
  @override
  CallState build() {
    return CallState(status: CallStatus.idle);
  }

  void updateStatus(CallStatus newStatus, {String? error}) {
    state = state.copyWith(status: newStatus, errorMessage: error);
  }

  /// Handles the response from your Chatbot's Invoke API Block
  Future<void> handleChatbotEscalation({
    required Map<String, dynamic> apiResponse,
    required WebRTCService rtcService,
  }) async {
    try {
      // 1. Parse the keys precisely as configured in your chatbot's response mapping layout
      final String? statusField = apiResponse['status'];
      final String? assignedRoomId = apiResponse['roomId'];

      if (statusField == 'waiting' && assignedRoomId != null && assignedRoomId.isNotEmpty) {
        // 2. Advance state to 'waiting' so the UI knows to show transition loader or video layout
        state = state.copyWith(
          status: CallStatus.waiting,
          // Assuming your CallState model can store room/user variables:
          // roomId: assignedRoomId,
        );

        // 3. Extract Cloudflare / TURN credential payload from the chatbot response
        final Map<String, dynamic>? iceData =
            (apiResponse['cloudflare'] as Map<String, dynamic>?) ??
            (apiResponse['iceConfig'] as Map<String, dynamic>?) ??
            (apiResponse['turnServers'] as Map<String, dynamic>?) ??
            (apiResponse['iceServers'] as Map<String, dynamic>?) ??
            (apiResponse['urls'] != null && apiResponse['username'] != null && apiResponse['credential'] != null
                ? Map<String, dynamic>.from(apiResponse)
                : null);

        if (iceData == null) {
          state = state.copyWith(
            status: CallStatus.error,
            errorMessage: 'Missing ICE configuration from chatbot response.',
          );
          return;
        }

        // 4. Fire the connection method on your live Render link
        const String renderUrl = "https://hybrid-app-7z2v.onrender.com";
        await rtcService.startVoiceCall(renderUrl, assignedRoomId, iceData);

      } else {
        // Queue returned idle / no agents available
        state = state.copyWith(
          status: CallStatus.error,
          errorMessage: "All support agents are currently busy.",
        );
      }
    } catch (e) {
      state = state.copyWith(
        status: CallStatus.error,
        errorMessage: "Failed to transition to live support agent: $e",
      );
    }
  }
}

// The Provider that the UI will listen to
final callProvider = NotifierProvider<CallNotifier, CallState>(() {
  return CallNotifier();
});