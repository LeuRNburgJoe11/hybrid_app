class AppConstants {
  AppConstants._();

  // REST API control plane URL
  static const String baseUrl = 'https://webrtc-backend-wtfl.onrender.com';

  // BUG 2 FIX: Remove the /socket.io path suffix.
  // socket_io_client appends /socket.io automatically. Having it here caused
  // the client to connect to /socket.io/socket.io — a 404 — silently
  // breaking all signalling so no offer/answer was ever exchanged.
  // Pass baseUrl directly to IO.io(), not this constant.
  // Kept here as an alias for clarity, but VideoView now uses baseUrl.
  static const String signalingUrl = 'https://webrtc-backend-wtfl.onrender.com';
  //                                  was: '...onrender.com/socket.io'  <-- BUG
}
