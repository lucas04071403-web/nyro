# Contributing

Thanks for helping improve Nyro.

Nyro is a modified distribution based on Hiddify App and powered by Hiddify
Core and Sing-box. Please keep the attribution and license information in
`LICENSE.md`, `NOTICE.md`, and `ACKNOWLEDGEMENTS.md` intact when contributing.

## Feedback, Issues, and Questions

Before opening a new issue, search the existing Nyro issue tracker:

https://github.com/lucas04071403-web/nyro/issues

If you do not find a matching report, open a new issue and include the platform,
app version, logs, and reproduction steps where possible:

https://github.com/lucas04071403-web/nyro/issues/new/choose

## Development

Nyro uses Flutter for the application shell and Hiddify Core for native proxy
capabilities. Make sure Flutter is installed before starting development:

```shell
flutter --version
```

The project uses generated Dart code. Regenerate files after dependency or model
changes:

```shell
dart run build_runner build --delete-conflicting-outputs
```

If you have not built `hiddify-core` locally and want to use existing native
library releases, prepare the target platform first:

```shell
make windows-prepare
make linux-prepare
make macos-prepare
make ios-prepare
make android-prepare
```

To build `hiddify-core` from source instead:

```shell
make build-windows-libs
make build-linux-libs
make build-macos-libs
make build-ios-libs
make build-android-libs
```

## Release Builds

Nyro uses `flutter_distributor` and the repository GitHub Actions workflow for
packaging. Release tags create GitHub release artifacts for supported platforms.

Local release commands:

```shell
make windows-release
make linux-release
make macos-release
make android-release
make ios-release
```

Release artifacts and update metadata are published from:

https://github.com/lucas04071403-web/nyro/releases

## Upstream

For changes that belong in the upstream application or native core, coordinate
with the relevant upstream project:

- Hiddify App: https://github.com/hiddify/hiddify-app
- Hiddify Core: https://github.com/hiddify/hiddify-core
- Sing-box: https://github.com/SagerNet/sing-box
