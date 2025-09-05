// services/user_service.dart
import 'package:hiddify/features/panel/xboard/models/user_info_model.dart';
import 'package:hiddify/features/panel/xboard/services/http_service/http_service.dart';

class UserService {
  final HttpService _httpService = HttpService();

  Future<UserInfo?> fetchUserInfo(String accessToken) async {
    final result = await _httpService.getRequest(
      "/api/v1/user/info",
      headers: {'Authorization': 'Bearer $accessToken'},
    );
    if (result.containsKey("data")) {
      final data = result["data"];
      return UserInfo.fromJson(data as Map<String, dynamic>);
    }
    throw Exception("Failed to retrieve user info");
  }

  Future<bool> validateToken(String token) async {
    try {
      final response = await _httpService.getRequest(
        "/api/v1/user/getSubscribe",
        headers: {'Authorization': 'Bearer $token'},
      );
      // v2board API成功时返回包含data字段的响应
      return response.containsKey('data') && response['data'] != null;
    } catch (_) {
      return false;
    }
  }

  Future<String?> getSubscriptionLink(String accessToken) async {
    final result = await _httpService.getRequest(
      "/api/v1/user/getSubscribe",
      headers: {'Authorization': 'Bearer $accessToken'},
    );
    // ignore: avoid_dynamic_calls
    return result["data"]["subscribe_url"] as String?;
  }

  Future<String?> resetSubscriptionLink(String accessToken) async {
    final result = await _httpService.getRequest(
      "/api/v1/user/resetSecurity",
      headers: {'Authorization': 'Bearer $accessToken'},
    );
    return result["data"] as String?;
  }
}
