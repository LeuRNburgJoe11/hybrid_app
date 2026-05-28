import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hybrid_app/features/webrtc/services/webrtc_service.dart';

// This creates a single, global instance of your service
final webRTCServiceProvider = Provider<WebRTCService>((ref) {
  return WebRTCService(ref);
});