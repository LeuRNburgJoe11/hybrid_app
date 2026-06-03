class AppConstants {
  AppConstants._();

  // Your Render.com signaling + REST API base URL.
  // Do NOT append /socket.io — socket_io_client adds that automatically.
  static const String baseUrl = "https://hybrid-app-7z2v.onrender.com";

  // Alias used by WebRTCService for socket connection
  static const String signalingUrl = baseUrl;
}
