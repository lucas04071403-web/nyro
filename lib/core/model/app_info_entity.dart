import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:nyro/core/model/environment.dart';

part 'app_info_entity.freezed.dart';

@freezed
class AppInfoEntity with _$AppInfoEntity {
  const AppInfoEntity._();

  const factory AppInfoEntity({
    required String name,
    required String version,
    required String buildNumber,
    required Release release,
    required String operatingSystem,
    required String operatingSystemVersion,
    required Environment environment,
  }) = _AppInfoEntity;

  // Xboard reads the first known client/version token for protocol filtering.
  // Put sing-box first so it does not treat Nyro's app version as the core version.
  String get userAgent => "sing-box 1.13.0 Nyro/$version ($operatingSystem) like ClashMeta v2ray";

  String get presentVersion => version;

  /// formats app info for sharing
  String format() =>
      '''
$name v$version ($buildNumber) [${environment.name}]
${release.name} release
$operatingSystem [$operatingSystemVersion]''';
}
