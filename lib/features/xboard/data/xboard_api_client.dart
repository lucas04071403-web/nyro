import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:hiddify/features/xboard/model/xboard_models.dart';
import 'package:hiddify/utils/custom_loggers.dart';

class XboardApiClient with InfraLogger {
  XboardApiClient({required String userAgent})
    : _dio = Dio(
        BaseOptions(
          baseUrl: baseUrl,
          connectTimeout: const Duration(seconds: 15),
          sendTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 15),
          headers: {'Accept': 'application/json', 'User-Agent': userAgent},
        ),
      );

  static const baseUrl = 'https://luck.nyro.lol';
  final Dio _dio;

  Future<XboardAuthData> login({required String email, required String password}) async {
    final data = await _post('/api/v1/passport/auth/login', data: {'email': email, 'password': password});
    if (data is! Map) throw XboardApiException('Invalid login response');
    final auth = XboardAuthData.fromJson(data.cast<String, dynamic>());
    if (auth.authData.isEmpty) throw XboardApiException('Missing authorization token');
    return auth;
  }

  Future<XboardAccount> getAccount(String authData) async {
    final info = await _get('/api/v1/user/info', authData: authData);
    final subscribe = await _get('/api/v1/user/getSubscribe', authData: authData);
    if (info is! Map || subscribe is! Map) throw XboardApiException('Invalid account response');
    return XboardAccount.fromResponses(
      authData: authData,
      info: info.cast<String, dynamic>(),
      subscribe: subscribe.cast<String, dynamic>(),
    );
  }

  Future<List<XboardPlanOffer>> getPlanOffers({String? authData}) async {
    final data = await _get(
      authData == null || authData.isEmpty ? '/api/v1/guest/plan/fetch' : '/api/v1/user/plan/fetch',
      authData: authData,
    );
    if (data is! List) throw XboardApiException('Invalid plan response');
    final plans =
        data
            .whereType<Map>()
            .map((plan) => XboardPlanOffer.fromJson(plan.cast<String, dynamic>()))
            .where((plan) => plan.name.isNotEmpty)
            .toList()
          ..sort((a, b) => a.sort.compareTo(b.sort));
    return plans;
  }

  Future<String> getSubscriptionContent(String subscribeUrl) async {
    try {
      final response = await _dio.getUri<String>(
        Uri.parse(subscribeUrl),
        options: Options(responseType: ResponseType.plain),
      );
      return response.data ?? '';
    } on DioException catch (error, stackTrace) {
      loggy.warning('Xboard subscription download failed', error, stackTrace);
      throw _exceptionFromError(error);
    }
  }

  Future<Object?> _get(String path, {String? authData}) async {
    try {
      final response = await _dio.get(path, options: _options(authData));
      return _unwrap(response.data);
    } on DioException catch (error, stackTrace) {
      loggy.warning('Xboard GET failed: $path', error, stackTrace);
      throw _exceptionFromError(error);
    }
  }

  Future<Object?> _post(String path, {Object? data, String? authData}) async {
    try {
      final response = await _dio.post(path, data: data, options: _options(authData));
      return _unwrap(response.data);
    } on DioException catch (error, stackTrace) {
      loggy.warning('Xboard POST failed: $path', error, stackTrace);
      throw _exceptionFromError(error);
    }
  }

  Options? _options(String? authData) {
    if (authData == null || authData.isEmpty) return null;
    return Options(headers: {'Authorization': authData});
  }

  Object? _unwrap(Object? raw) {
    final body = switch (raw) {
      final String text => jsonDecode(text) as Object?,
      _ => raw,
    };
    if (body is! Map) return body;

    final json = body.cast<String, dynamic>();
    final status = json['status'];
    if (status == 'success') return json['data'];
    throw XboardApiException(json['message']?.toString() ?? 'Xboard request failed');
  }

  XboardApiException _exceptionFromError(DioException error) {
    final statusCode = error.response?.statusCode;
    final data = error.response?.data;
    if (data is Map && data['message'] != null) {
      return XboardApiException(data['message'].toString(), statusCode: statusCode);
    }
    if (data is String && data.isNotEmpty) {
      try {
        final json = jsonDecode(data);
        if (json is Map && json['message'] != null) {
          return XboardApiException(json['message'].toString(), statusCode: statusCode);
        }
      } catch (_) {}
    }
    return XboardApiException(error.message ?? 'Xboard request failed', statusCode: statusCode);
  }
}
