import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:nyro/features/xboard/model/xboard_models.dart';
import 'package:nyro/utils/custom_loggers.dart';

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

  Future<XboardRegisterConfig> getRegisterConfig() async {
    final data = await _get('/api/v1/guest/comm/config');
    if (data is! Map) throw XboardApiException('Invalid register config response');
    return XboardRegisterConfig.fromJson(data.cast<String, dynamic>());
  }

  Future<XboardAuthData> login({required String email, required String password}) async {
    final data = await _post('/api/v1/passport/auth/login', data: {'email': email, 'password': password});
    if (data is! Map) throw XboardApiException('Invalid login response');
    final auth = XboardAuthData.fromJson(data.cast<String, dynamic>());
    if (auth.authData.isEmpty) throw XboardApiException('Missing authorization token');
    return auth;
  }

  Future<void> sendEmailVerify({required String email}) async {
    await _post('/api/v1/passport/comm/sendEmailVerify', data: {'email': email.trim()});
  }

  Future<XboardAuthData> register({
    required String email,
    required String password,
    required String emailCode,
    String? inviteCode,
  }) async {
    final payload = <String, dynamic>{'email': email.trim(), 'password': password, 'email_code': emailCode.trim()};
    final invite = inviteCode?.trim();
    if (invite != null && invite.isNotEmpty) payload['invite_code'] = invite;

    final data = await _post('/api/v1/passport/auth/register', data: payload);
    if (data == null) return const XboardAuthData(authData: '', subscribeToken: '', isAdmin: false);
    if (data is! Map) throw XboardApiException('Invalid register response');
    return XboardAuthData.fromJson(data.cast<String, dynamic>());
  }

  Future<XboardAccount> getAccount(String authData) async {
    final info = await _get('/api/v1/user/info', authData: authData);
    if (info is! Map) throw XboardApiException('Invalid account response');

    Map<String, dynamic> subscribe = const {};
    try {
      final data = await _get('/api/v1/user/getSubscribe', authData: authData);
      if (data is Map) {
        subscribe = data.cast<String, dynamic>();
      } else {
        loggy.warning('Xboard subscribe response is empty or invalid, continuing without subscription');
      }
    } on XboardApiException catch (error, stackTrace) {
      if (error.isUnauthorized) rethrow;
      loggy.warning('Xboard subscribe response unavailable, continuing without subscription', error, stackTrace);
    }

    return XboardAccount.fromResponses(authData: authData, info: info.cast<String, dynamic>(), subscribe: subscribe);
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

  Future<List<XboardPaymentMethod>> getPaymentMethods(String authData) async {
    final data = await _get('/api/v1/user/order/getPaymentMethod', authData: authData);
    if (data is! List) throw XboardApiException('Invalid payment methods response');
    return data
        .whereType<Map>()
        .map((method) => XboardPaymentMethod.fromJson(method.cast<String, dynamic>()))
        .where((method) => method.id > 0)
        .toList();
  }

  Future<String> createOrder({
    required String authData,
    required int planId,
    required XboardPlanPricePeriod period,
    String? couponCode,
  }) async {
    final payload = <String, dynamic>{'plan_id': planId, 'period': period.apiKey};
    final coupon = couponCode?.trim();
    if (coupon != null && coupon.isNotEmpty) payload['coupon_code'] = coupon;

    final data = await _post('/api/v1/user/order/save', data: payload, authData: authData);
    final tradeNo = data?.toString() ?? '';
    if (tradeNo.isEmpty) throw XboardApiException('Invalid order response');
    return tradeNo;
  }

  Future<XboardOrderCheckout> checkoutOrder({
    required String authData,
    required String tradeNo,
    required int methodId,
  }) async {
    final data = await _postRaw(
      '/api/v1/user/order/checkout',
      data: {'trade_no': tradeNo, 'method': methodId},
      authData: authData,
    );
    if (data is! Map) throw XboardApiException('Invalid checkout response');
    return XboardOrderCheckout.fromJson(tradeNo: tradeNo, json: data.cast<String, dynamic>());
  }

  Future<int> checkOrder({required String authData, required String tradeNo}) async {
    final data = await _get(
      '/api/v1/user/order/check?trade_no=${Uri.encodeQueryComponent(tradeNo)}',
      authData: authData,
    );
    return switch (data) {
      final int status => status,
      final double status => status.round(),
      final String status => int.tryParse(status) ?? -1,
      _ => -1,
    };
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

  Future<Object?> _postRaw(String path, {Object? data, String? authData}) async {
    try {
      final response = await _dio.post(path, data: data, options: _options(authData));
      return _decode(response.data);
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
    final body = _decode(raw);
    if (body is! Map) return body;

    final json = body.cast<String, dynamic>();
    final status = json['status'];
    if (status == 'success') return json['data'];
    throw XboardApiException(json['message']?.toString() ?? 'Xboard request failed');
  }

  Object? _decode(Object? raw) {
    return switch (raw) {
      final String text => jsonDecode(text) as Object?,
      _ => raw,
    };
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
