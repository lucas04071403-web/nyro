class XboardApiException implements Exception {
  XboardApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  bool get isUnauthorized => statusCode == 401 || statusCode == 403;

  @override
  String toString() => message;
}

class XboardRegisterConfig {
  const XboardRegisterConfig({
    required this.isEmailVerify,
    required this.isInviteForce,
    required this.isCaptcha,
    required this.captchaType,
    required this.recaptchaSiteKey,
    required this.recaptchaV3SiteKey,
    required this.turnstileSiteKey,
    required this.tosUrl,
  });

  factory XboardRegisterConfig.fromJson(Map<String, dynamic> json) {
    return XboardRegisterConfig(
      isEmailVerify: _asBool(json['is_email_verify']),
      isInviteForce: _asBool(json['is_invite_force']),
      isCaptcha: _asBool(json['is_captcha'] ?? json['is_recaptcha']),
      captchaType: json['captcha_type'] as String? ?? '',
      recaptchaSiteKey: _asNullableString(json['recaptcha_site_key']),
      recaptchaV3SiteKey: _asNullableString(json['recaptcha_v3_site_key']),
      turnstileSiteKey: _asNullableString(json['turnstile_site_key']),
      tosUrl: _asNullableString(json['tos_url']),
    );
  }

  final bool isEmailVerify;
  final bool isInviteForce;
  final bool isCaptcha;
  final String captchaType;
  final String? recaptchaSiteKey;
  final String? recaptchaV3SiteKey;
  final String? turnstileSiteKey;
  final String? tosUrl;
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

extension XboardPlanPricePeriodX on XboardPlanPricePeriod {
  String get apiKey {
    return switch (this) {
      XboardPlanPricePeriod.month => 'month_price',
      XboardPlanPricePeriod.quarter => 'quarter_price',
      XboardPlanPricePeriod.halfYear => 'half_year_price',
      XboardPlanPricePeriod.year => 'year_price',
      XboardPlanPricePeriod.twoYear => 'two_year_price',
      XboardPlanPricePeriod.threeYear => 'three_year_price',
      XboardPlanPricePeriod.onetime => 'onetime_price',
      XboardPlanPricePeriod.reset => 'reset_price',
    };
  }
}

class XboardPlanPrice {
  const XboardPlanPrice({required this.period, required this.cents});

  final XboardPlanPricePeriod period;
  final int cents;
}

class XboardPaymentMethod {
  const XboardPaymentMethod({
    required this.id,
    required this.name,
    required this.payment,
    required this.icon,
    required this.handlingFeeFixed,
    required this.handlingFeePercent,
  });

  factory XboardPaymentMethod.fromJson(Map<String, dynamic> json) {
    return XboardPaymentMethod(
      id: _asInt(json['id']),
      name: json['name'] as String? ?? '',
      payment: json['payment'] as String? ?? '',
      icon: json['icon'] as String? ?? '',
      handlingFeeFixed: _asInt(json['handling_fee_fixed']),
      handlingFeePercent: _asDouble(json['handling_fee_percent']),
    );
  }

  final int id;
  final String name;
  final String payment;
  final String icon;
  final int handlingFeeFixed;
  final double handlingFeePercent;
}

class XboardOrderCheckout {
  const XboardOrderCheckout({required this.tradeNo, required this.type, required this.data});

  factory XboardOrderCheckout.fromJson({required String tradeNo, required Map<String, dynamic> json}) {
    return XboardOrderCheckout(tradeNo: tradeNo, type: _asInt(json['type']), data: json['data']);
  }

  final String tradeNo;
  final int type;
  final Object? data;

  bool get isPaidWithoutRedirect => type == -1 && data == true;

  String? get paymentUrl {
    final text = _firstString(data, const ['url', 'pay_url', 'payment_url', 'redirect_url', 'checkout_url']);
    if (text == null) return null;
    final uri = Uri.tryParse(text);
    if (uri == null || !uri.hasScheme || (uri.scheme != 'http' && uri.scheme != 'https')) return null;
    return text;
  }

  String? get qrContent {
    final text = _firstString(data, const ['qrcode', 'qr_code', 'code_url', 'codeUrl', 'content']);
    if (text == null || text.isEmpty || text == paymentUrl) return null;
    return text;
  }
}

abstract class XboardOrderStatus {
  static const pending = 0;
  static const processing = 1;
  static const canceled = 2;
  static const completed = 3;
  static const discounted = 4;
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

double _asDouble(Object? value) {
  return switch (value) {
    final int v => v.toDouble(),
    final double v => v,
    final String v => double.tryParse(v) ?? 0,
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

bool _asBool(Object? value) {
  return switch (value) {
    final bool v => v,
    final int v => v != 0,
    final double v => v != 0,
    final String v => {'1', 'true', 'yes', 'on'}.contains(v.trim().toLowerCase()),
    _ => false,
  };
}

String? _asNullableString(Object? value) {
  final text = value?.toString().trim();
  return text == null || text.isEmpty ? null : text;
}

String? _firstString(Object? data, List<String> mapKeys) {
  if (data is String) {
    final text = data.trim();
    return text.isEmpty ? null : text;
  }
  if (data is Map) {
    final json = data.cast<dynamic, dynamic>();
    for (final key in mapKeys) {
      final text = json[key]?.toString().trim();
      if (text != null && text.isNotEmpty) return text;
    }
  }
  return null;
}
