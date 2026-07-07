# Changelog

## 1.0.2 - 2026-07-08

### Added

- macOS-inspired desktop home, sidebar, profile, connection, active proxy, and
  quick settings dock styling.

### Changed

- Xboard login now syncs the subscription profile to the home page
  automatically.
- Xboard logout now clears the synced subscription profile automatically.
- Xboard subscription requests now identify as sing-box first so the panel keeps
  modern protocol nodes and current sing-box templates.

### Fixed

- Fixed duplicate brand/version elements and stray help icons on the desktop
  home page.
- Fixed the desktop home page overflow stripe when connecting.
- Fixed Xboard/sing-box subscription filtering that left only a few Shadowsocks
  nodes visible.
- Fixed newer sing-box subscription imports by avoiding legacy DNS outbound
  template selection.

## 1.0.1 - 2026-07-07

### Added

- Xboard email verification registration with automatic login and account sync.
- Login/register switching in the user center, including email code countdown,
  registration validation, and refreshed account state.
- Xboard plan purchase flow from the subscription page, including period
  selection, payment method selection, order creation, Epay or QR checkout, and
  order status polling.
- Current-plan marking in the subscription list based on the logged-in user's
  Xboard plan id.

### Changed

- Refresh Xboard account, subscription, and plan list data after successful
  payment.
- Updated release notes for the actual v1.0.1 feature set.

### Fixed

- Android release builds now align with the `hiddify-core v4.1.0` Android API.

## 1.0.0 - 2026-07-07

### Added

- Initial Nyro release for Android, Windows, macOS, and Linux.
- User-facing GitHub Release instructions for choosing packages, installing,
  importing profiles, connecting, and updating.
- Independent Nyro package names, display names, release assets, and download
  metadata.
- Nyro release notes and GitHub Release download table.
- Compliance files documenting that Nyro is based on Hiddify App and powered by
  Hiddify Core and Sing-box.

### Changed

- Rebranded user-facing metadata from the upstream application to Nyro.
- Updated default share/export links to use the `nyro://` scheme while keeping
  compatibility with existing import protocols.
- Updated release update URLs to the Nyro GitHub release channel.

Nyro-specific release history is tracked in this repository. Upstream project
attribution is documented in `NOTICE.md`.
