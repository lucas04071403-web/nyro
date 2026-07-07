import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:nyro/features/profile/data/profile_parser.dart';
import 'package:nyro/features/profile/model/profile_entity.dart';
import 'package:uuid/uuid.dart';

void main() {
  const validBaseUrl = "https://example.com/configurations/user1/filename.yaml";
  const validExtendedUrl = "https://example.com/configurations/user1/filename.yaml?test#b";
  const validSupportUrl = "https://example.com/support";

  group("parse", () {
    test("Should use filename in url with no headers and fragment", () {
      final profile = ProfileParser.parse(
        tempFilePath: '',
        profile: ProfileEntity.remote(
          id: const Uuid().v4(),
          active: true,
          name: '',
          url: validBaseUrl,
          lastUpdate: DateTime.now(),
        ),
      );
      expect(profile.isRight(), true);
      profile.match((l) {}, (r) {
        expect(r is RemoteProfileEntity, true);
        r.map(
          remote: (rp) {
            expect(rp.name, equals("filename"));
            expect(rp.url, equals(validBaseUrl));
            expect(rp.options, isNull);
            expect(rp.subInfo, isNull);
          },
          local: (lp) {},
        );
      });
    });

    test("Should use fragment in url with no headers", () {
      final profile = ProfileParser.parse(
        tempFilePath: '',
        profile: ProfileEntity.remote(
          id: const Uuid().v4(),
          active: true,
          name: '',
          url: validExtendedUrl,
          lastUpdate: DateTime.now(),
        ),
      );
      expect(profile.isRight(), true);
      profile.match((l) {}, (r) {
        expect(r is RemoteProfileEntity, true);
        r.map(
          remote: (rp) {
            expect(rp.name, equals("b"));
            expect(rp.url, equals(validExtendedUrl));
            expect(rp.options, isNull);
            expect(rp.subInfo, isNull);
          },
          local: (lp) {},
        );
      });
    });

    test("Should use base64 title in headers", () {
      final headers = <String, List<String>>{
        "profile-title": ["base64:ZXhhbXBsZVRpdGxl"],
        "profile-update-interval": ["1"],
        "connection-test-url": [validBaseUrl],
        "remote-dns-address": [validBaseUrl],
        "subscription-userinfo": ["upload=0;download=1024;total=10240.5;expire=1704054600.55"],
        "profile-web-page-url": [validBaseUrl],
        "support-url": [validSupportUrl],
      };
      // This fix occurs in the _downloadProfile method within ProfileParser, and the fixed headers are passed to populateHeaders
      final fixedHeaders = headers.map((key, value) {
        if (value.length == 1) return MapEntry(key, value.first);
        return MapEntry(key, value);
      });
      final allHeaders = ProfileParser.populateHeaders(content: '', remoteHeaders: fixedHeaders);
      expect(allHeaders.isRight(), true);
      allHeaders.match((l) {}, (r) {
        final profile = ProfileParser.parse(
          tempFilePath: '',
          profile: ProfileEntity.remote(
            id: const Uuid().v4(),
            active: true,
            name: '',
            url: validExtendedUrl,
            lastUpdate: DateTime.now(),
            populatedHeaders: r,
          ),
        );
        expect(profile.isRight(), true);
        profile.match((l) {}, (r) {
          expect(r is RemoteProfileEntity, true);
          r.map(
            remote: (rp) {
              expect(rp.name, equals("exampleTitle"));
              expect(rp.url, equals(validExtendedUrl));
              expect(rp.options, equals(const ProfileOptions(updateInterval: Duration(hours: 1))));
              expect(
                rp.subInfo,
                equals(
                  SubscriptionInfo(
                    upload: 0,
                    download: 1024,
                    total: 10240,
                    expire: DateTime.fromMillisecondsSinceEpoch(1704054600 * 1000),
                    webPageUrl: validBaseUrl,
                    supportUrl: validSupportUrl,
                  ),
                ),
              );
            },
            local: (lp) {},
          );
        });
      });
    });

    test("Should use infinite when given 0 for subscription properties", () {
      final headers = <String, List<String>>{
        "profile-title": ["title"],
        "profile-update-interval": ["1"],
        "subscription-userinfo": ["upload=0;download=1024;total=0;expire=0"],
        "profile-web-page-url": [validBaseUrl],
        "support-url": [validSupportUrl],
      };
      // This fix occurs in the _downloadProfile method within ProfileParser, and the fixed headers are passed to populateHeaders
      final fixedHeaders = headers.map((key, value) {
        if (value.length == 1) return MapEntry(key, value.first);
        return MapEntry(key, value);
      });
      final allHeaders = ProfileParser.populateHeaders(content: '', remoteHeaders: fixedHeaders);
      expect(allHeaders.isRight(), true);
      allHeaders.match((l) {}, (r) {
        final profile = ProfileParser.parse(
          tempFilePath: '',
          profile: RemoteProfileEntity(
            id: const Uuid().v4(),
            active: true,
            name: '',
            url: validBaseUrl,
            lastUpdate: DateTime.now(),
            populatedHeaders: r,
          ),
        );
        expect(profile.isRight(), true);
        profile.match((l) {}, (r) {
          expect(r is RemoteProfileEntity, true);
          r.map(
            remote: (rp) {
              expect(rp.subInfo, isNotNull);
              expect(rp.subInfo!.total, equals(ProfileParser.infiniteTrafficThreshold + 1));
              expect(
                rp.subInfo!.expire,
                equals(DateTime.fromMillisecondsSinceEpoch(ProfileParser.infiniteTimeThreshold * 1000)),
              );
            },
            local: (lp) {},
          );
        });
      });
    });
  });

  group("xboard normalization", () {
    String ssLink(String name) {
      return "ss://YWVzLTEyOC1nY206cGFzc3dvcmRAMTI3LjAuMC4xOjQ3MDAw#${Uri.encodeComponent(name)}";
    }

    test("Should filter Xboard metadata shadowsocks links", () {
      final subscription = [
        ssLink("剩余流量：10GB"),
        ssLink("香港｜01"),
        ssLink("距离下次重置剩余：12 天"),
        "vless://00000000-0000-0000-0000-000000000000@example.com:443?security=reality#${Uri.encodeComponent("日本｜01")}",
        ssLink("套餐到期：2026-12-31"),
      ].join("\n");
      final encoded = base64.encode(utf8.encode(subscription));

      final normalized = ProfileParser.normalizeSubscriptionLinks(encoded);
      final lines = normalized.split("\n").where((line) => line.trim().isNotEmpty).toList();

      expect(lines, hasLength(2));
      expect(normalized, contains(Uri.encodeComponent("香港｜01")));
      expect(normalized, contains(Uri.encodeComponent("日本｜01")));
      expect(normalized, isNot(contains("剩余流量")));
      expect(normalized, isNot(contains("距离下次重置")));
      expect(normalized, isNot(contains("套餐到期")));
    });

    test("Should keep Xboard optimized profile headers for sing-box override", () {
      final headers = ProfileParser.populateHeaders(
        content: "",
        remoteHeaders: const {
          "connection-test-url": "http://www.gstatic.com/generate_204",
          "url-test-interval": "300",
          "remote-dns-address": "https://1.1.1.1/dns-query",
          "remote-dns-domain-strategy": "ipv4_only",
          "direct-dns-address": "223.5.5.5",
          "direct-dns-domain-strategy": "ipv4_only",
          "ipv6-mode": "ipv4_only",
        },
      );

      expect(headers.isRight(), true);
      headers.match((l) {}, (r) {
        expect(r["url-test-interval"], 300);
        final override = jsonDecode(ProfileParser.profileOverride(populatedHeaders: r, userOverride: null)) as Map;
        expect(override["connection-test-url"], "http://www.gstatic.com/generate_204");
        expect(override["url-test-interval"], 300);
        expect(override["remote-dns-address"], "https://1.1.1.1/dns-query");
        expect(override["remote-dns-domain-strategy"], "ipv4_only");
        expect(override["direct-dns-address"], "223.5.5.5");
        expect(override["direct-dns-domain-strategy"], "ipv4_only");
        expect(override["ipv6-mode"], "ipv4_only");
      });
    });
  });
}
