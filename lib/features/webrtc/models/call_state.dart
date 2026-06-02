enum CallStatus { idle, connecting, connected, disconnected, error, waiting }

class CallState {
  final CallStatus status;
  final String? errorMessage;

  CallState({required this.status, this.errorMessage});

  // Helper for immutable updates
  CallState copyWith({CallStatus? status, String? errorMessage}) {
    return CallState(
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

