# Nyro

Nyro is a cross-platform proxy and VPN client for Android, Windows, macOS, and
Linux.

Nyro is a secondary development based on Hiddify App. It is powered by Hiddify
Core and Sing-box, keeps the upstream license and attribution, and provides an
independent Nyro brand, package identity, download address, and release channel.

## Downloads

Latest release:

https://github.com/lucas04071403-web/nyro/releases/latest

Current release page:

https://github.com/lucas04071403-web/nyro/releases/tag/v1.0.1

## Supported Platforms

- Android: APK and Google Play AAB builds
- Windows: EXE installer, MSIX package, and portable ZIP
- macOS: DMG and PKG builds
- Linux: AppImage, AppImage tar.gz, and Debian package

## Technical Foundation

- Application shell: Flutter and Dart
- Native core: Hiddify Core
- Proxy engine foundation: Sing-box
- Supported profile/config formats include Sing-box, V2Ray, Clash, and
  Clash Meta compatible links or subscriptions.

## Nyro Features

- User center connected to Xboard accounts.
- Email verification registration and login.
- Xboard plan listing, current-plan display, and account subscription sync.
- Subscription purchase flow with period selection, payment method selection,
  Epay or QR checkout, order polling, and automatic refresh after payment.
- Xboard subscription optimization, including metadata-node filtering,
  `subscription-userinfo` traffic parsing, and Nyro-specific profile settings
  for more stable Sing-box configuration generation.

## Recent Updates

- Added Xboard email-code registration and automatic account sync.
- Added Xboard subscription purchase and payment checkout support.
- Added current-plan marking after a plan is purchased.
- Improved Xboard subscription parsing by filtering traffic/reset/expiry
  metadata nodes from the proxy list.
- Improved traffic and expiry display by using the Xboard
  `subscription-userinfo` header.
- Applied Nyro-oriented profile defaults for Xboard subscriptions, including
  faster URL testing, IPv4-first DNS strategy, and shorter auto-update interval.

## Attribution

Nyro is a secondary development based on Hiddify App:

https://github.com/hiddify/hiddify-app

It uses Hiddify Core:

https://github.com/hiddify/hiddify-core

Hiddify Core is powered by Sing-box:

https://github.com/SagerNet/sing-box

See `NOTICE.md` and `ACKNOWLEDGEMENTS.md` for attribution details.

## License

This project is distributed under the Hiddify Extended GNU General Public
License v3 terms included in `LICENSE.md`.

Nyro keeps the required upstream attribution and documents this distribution's
changes in this README and release notes.
