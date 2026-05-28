class AppConstants {
  // Prevent instantiation of this class
  AppConstants._();

  /// The base URL for your REST API control plane (JSP Chatbot orchestration)
  /// For local development: 
  /// - Use 'http://10.0.2.2:3000' if you are testing on an Android Emulator
  /// - Use 'http://localhost:3000' if you are testing on iOS Simulator or Web
  static const String baseUrl = 'http://10.0.2.2:3000';

  /// The WebSocket URL for your Socket.io signaling server
  /// Matches the base URL port but uses the ws/wss protocol mapping
  static const String signalingUrl = 'http://10.0.2.2:3000';
}