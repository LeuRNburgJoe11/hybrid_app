enum CallStatus { idle, connecting, connected, disconnected, error, waiting }

class CallState {
  final CallStatus status;
  final String? errorMessage;

  // Escalation fields — populated by CallNotifier.handleChatbotEscalation
  // so app.dart can pass them to VideoCallScreen via Navigator.
  final String? roomId;
  final List<String>? turnUrls;
  final String? turnUsername;
  final String? turnCredential;

  CallState({
    required this.status,
    this.errorMessage,
    this.roomId,
    this.turnUrls,
    this.turnUsername,
    this.turnCredential,
  });

  CallState copyWith({
    CallStatus? status,
    String? errorMessage,
    String? roomId,
    List<String>? turnUrls,
    String? turnUsername,
    String? turnCredential,
  }) {
    return CallState(
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      roomId: roomId ?? this.roomId,
      turnUrls: turnUrls ?? this.turnUrls,
      turnUsername: turnUsername ?? this.turnUsername,
      turnCredential: turnCredential ?? this.turnCredential,
    );
  }
}
