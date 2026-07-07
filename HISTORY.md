# Changelog

## 1.0.1 (2026-07-07)

### New

- Added Xboard email verification registration.
- Added login/register switching in the user center with email code sending,
  countdown state, and registration form validation.
- Added Xboard subscription purchase flow with plan period selection, payment
  method selection, order creation, Epay or QR checkout, and payment polling.
- Added automatic Xboard account and subscription refresh after successful
  payment.
- Added "current plan" status on the purchased plan in the subscription list.

### Fixed

- Fixed Android release builds against the `hiddify-core v4.1.0` Android API.

## 1.0.0 (2026-07-07)

Nyro first public release.

### Usage

- Download the installer for your platform from the GitHub Release Assets.
- Android users can install the universal APK, or choose ARM64/ARMv7/x86_64 when
  they know the device architecture.
- Windows users can choose the EXE installer, MSIX package, or portable ZIP.
- macOS users can install with DMG or PKG.
- Linux users can run the AppImage or install the Debian/Ubuntu `.deb` package.
- Import profiles from subscription links, QR codes, clipboard content, or
  supported share links such as `nyro://`, `v2ray://`, `clash://`, and
  `sing-box://`.
- Select a profile and connect. Advanced users can adjust system proxy, TUN/VPN,
  per-app proxy, routing rules, DNS, and inbound options from settings.

### New

- Initial Nyro release for Android, Windows, macOS, and Linux.
- Independent Nyro application name, package identifiers, URL scheme, release
  metadata, and download links.
- GitHub Release download table and user installation guide.
- Nyro update channel via the Nyro GitHub Releases feed.
- Compliance documentation in `NOTICE.md` and `ACKNOWLEDGEMENTS.md`.

### Attribution

Nyro is based on Hiddify App and powered by Hiddify Core and Sing-box. The
upstream license is kept in `LICENSE.md`.
