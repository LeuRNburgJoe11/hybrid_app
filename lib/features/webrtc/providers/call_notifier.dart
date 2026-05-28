import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hybrid_app/features/webrtc/models/call_state.dart';

class CallNotifier extends Notifier<CallState> {
  @override
  CallState build() {
    // Initial state
    return CallState(status: CallStatus.idle);
  }

  void updateStatus(CallStatus newStatus, {String? error}) {
    state = state.copyWith(status: newStatus, errorMessage: error);
  }
}

// The Provider that the UI will listen to
final callProvider = NotifierProvider<CallNotifier, CallState>(() {
  return CallNotifier();
});   