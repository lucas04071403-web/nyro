class XboardApiException implements Exception {
  XboardApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  bool get isUnauthorized => statusCode == 401 || statusCode == 403;

  @override
  String toString() => message;
}

class XboardAuthData {
  const XboardAuthData({required this.authData, required this.subscribeToken, required this.isAdmin});

  factory XboardAuthData.fromJson(Map<String, dynamic> json) {
    return XboardAuthData(
      authData: json['auth_data'] as String? ?? '',
      subscribeToken: json['token'] as String? ?? '',
      isAdmin: json['is_admin'] == true,
    );
  }

  final String authData;
  final String subscribeToken;
  final bool isAdmin;
}

class XboardPlan {
  const XboardPlan({required this.id, required this.name});

  factory XboardPlan.fromJson(Map<String, dynamic> json) {
    return XboardPlan(id: _asInt(json['id']), name: json['name'] as String? ?? '');
  }

  final int id;
  final String name;
}

enum XboardPlanPricePeriod { month, quarter, halfYear, year, twoYear, threeYear, onetime, reset }

class XboardPlanPrice {
  const XboardPlanPrice({required this.period, required this.cents});

  final XboardPlanPricePeriod period;
  final int cents;
}

class XboardPlanOffer {
  const XboardPlanOffer({
    required this.id,
    required this.name,
    required this.content,
    required this.transferEnableGb,
    required this.speedLimitMbps,
    required this.deviceLimit,
    required this.sell,
    required this.renew,
    required this.sort,
    required this.prices,
  });

  factory XboardPlanOffer.fromJson(Map<String, dynamic> json) {
    return XboardPlanOffer(
      id: _asInt(json['id']),
      name: json['name'] as String? ?? '',
      content: json['content'] as String? ?? '',
      transferEnableGb: _asInt(json['transfer_enable']),
      speedLimitMbps: _asNullableInt(json['speed_limit']),
      deviceLimit: _asNullableInt(json['device_limit']),
      sell: json['sell'] == true,
      renew: json['renew'] == true,
      sort: _asInt(json['sort']),
      prices: [
        if (_asPriceCents(json['month_price']) case final price?)
          XboardPlanPrice(period: XboardPlanPricePeriod.month, cents: price),
        if (_asPriceCents(json['quarter_price']) case final price?)
          XboardPlanPrice(period: XboardPlanPricePeriod.quarter, cents: price),
        if (_asPriceCents(json['half_year_price']) case final price?)
          XboardPlanPrice(period: XboardPlanPricePeriod.halfYear, cents: price),
        if (_asPriceCents(json['year_price']) case final price?)
          XboardPlanPrice(period: XboardPlanPricePeriod.year, cents: price),
        if (_asPriceCents(json['two_year_price']) case final price?)
          XboardPlanPrice(period: XboardPlanPricePeriod.twoYear, cents: price),
        if (_asPriceCents(json['three_year_price']) case final price?)
          XboardPlanPrice(period: XboardPlanPricePeriod.threeYear, cents: price),
        if (_asPriceCents(json['onetime_price']) case final price?)
          XboardPlanPrice(period: XboardPlanPricePeriod.onetime, cents: price),
        if (_asPriceCents(json['reset_price']) case final price?)
          XboardPlanPrice(period: XboardPlanPricePeriod.reset, cents: price),
      ],
    );
  }

  final int id;
  final String name;
  final String content;
  final int transferEnableGb;
  final int? speedLimitMbps;
  final int? deviceLimit;
  final bool sell;
  final bool renew;
  final int sort;
  final List<XboardPlanPrice> prices;

  XboardPlanPrice? get primaryPrice {
    for (final period in [XboardPlanPricePeriod.month, XboardPlanPricePeriod.onetime]) {
      for (final price in prices) {
        if (price.period == period) return price;
      }
    }
    return prices.isNotEmpty ? prices.first : null;
  }
}

class XboardAccount {
  const XboardAccount({
    required this.authData,
    required this.email,
    required this.balance,
    required this.upload,
    required this.download,
    required this.transferEnable,
    required this.expiredAt,
    required this.subscribeUrl,
    required this.plan,
  });

  factory XboardAccount.fromResponses({
    required String authData,
    required Map<String, dynamic> info,
    required Map<String, dynamic> subscribe,
  }) {
    final planJson = subscribe['plan'];
    return XboardAccount(
      authData: authData,
      email: (subscribe['email'] ?? info['email']) as String? ?? '',
      balance: _asInt(info['balance']),
      upload: _asInt(subscribe['u']),
      download: _asInt(subscribe['d']),
      transferEnable: _asInt(subscribe['transfer_enable']),
      expiredAt: _dateFromUnixSeconds(subscribe['expired_at'] ?? info['expired_at']),
      subscribeUrl: subscribe['subscribe_url'] as String? ?? '',
      plan: planJson is Map ? XboardPlan.fromJson(planJson.cast<String, dynamic>()) : null,
    );
  }

  final String authData;
  final String email;
  final int balance;
  final int upload;
  final int download;
  final int transferEnable;
  final DateTime? expiredAt;
  final String subscribeUrl;
  final XboardPlan? plan;

  int get usedTraffic => upload + download;
  bool get isExpired => expiredAt?.isBefore(DateTime.now()) ?? false;
  bool get isTrafficExhausted => transferEnable > 0 && usedTraffic >= transferEnable;
  bool get hasValidSubscription => subscribeUrl.trim().isNotEmpty && plan != null && !isExpired && !isTrafficExhausted;
}

int _asInt(Object? value) {
  return switch (value) {
    final int v => v,
    final double v => v.round(),
    final String v => int.tryParse(v) ?? double.tryParse(v)?.round() ?? 0,
    _ => 0,
  };
}

int? _asNullableInt(Object? value) {
  if (value == null) return null;
  return _asInt(value);
}

int? _asPriceCents(Object? value) {
  return switch (value) {
    null => null,
    final int v => v,
    final double v => v.round(),
    final String v when v.trim().isEmpty => null,
    final String v => int.tryParse(v) ?? double.tryParse(v)?.round(),
    _ => null,
  };
}

DateTime? _dateFromUnixSeconds(Object? value) {
  final seconds = _asInt(value);
  if (seconds <= 0) return null;
  return DateTime.fromMillisecondsSinceEpoch(seconds * 1000);
}
