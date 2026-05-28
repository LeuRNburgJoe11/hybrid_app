import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../services/api_service.dart';

// 1. Independent provider for the base API service instance
final apiServiceProvider = Provider<ApiService>((ref) {
  return ApiService(http.Client());
});

// 2. AsyncNotifier to manage the state of the active WebRTC session
class SessionNotifier extends AsyncNotifier<Map<String, dynamic>?> {
  late final ApiService _apiService;

  @override
  Future<Map<String, dynamic>?> build() async {
    _apiService = ref.watch(apiServiceProvider);
    // Initially, there is no active session
    return null;
  }

  /// Action: Triggers session creation via the REST API
  Future<void> initializeNewSession(String userId) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final sessionData = await _apiService.createSession(userId);
      return sessionData;
    });
  }

  /// Action: Checks an existing room's status manually or via polling
  Future<void> updateSessionStatus(String roomId) async {
    // Keep current data visible while updating in the background if preferred,
    // or set loading state explicitly:
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final statusData = await _apiService.fetchSessionStatus(roomId);
      return statusData;
    });
  }

  /// Action: Clear session locally when a call ends
  void resetSession() {
    state = const AsyncValue.data(null);
  }
}

// 3. The globally accessible provider for your UI or other services
final sessionProvider = AsyncNotifierProvider<SessionNotifier, Map<String, dynamic>?>(() {
  return SessionNotifier();
});