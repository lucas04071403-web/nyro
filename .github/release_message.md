<div align="center">

[![Release Downloads](https://img.shields.io/github/downloads/RELEASE_REPOSITORY/RELEASE_TAG/total?style=flat-square&logo=github)](https://github.com/RELEASE_REPOSITORY/releases/tag/RELEASE_TAG)

</div>

## Nyro RELEASE_TAG

下面按系统选择安装包。完整文件列表也可以在本页底部的 **Assets** 中下载。

Nyro is based on Hiddify App and powered by Hiddify Core and Sing-box. License
and attribution details are included in `LICENSE.md`, `NOTICE.md`, and
`ACKNOWLEDGEMENTS.md`.

<table>
  <thead>
    <tr>
      <th>系统</th>
      <th>推荐下载</th>
      <th>其他格式</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td>Android</td>
      <td>
        <a href="https://github.com/RELEASE_REPOSITORY/releases/download/RELEASE_TAG/Nyro-RELEASE_TAG-Android-universal.apk">Universal APK</a><br>
        <a href="https://github.com/RELEASE_REPOSITORY/releases/download/RELEASE_TAG/Nyro-RELEASE_TAG-Android-arm64.apk">ARM64 APK</a>
      </td>
      <td>
        <a href="https://github.com/RELEASE_REPOSITORY/releases/download/RELEASE_TAG/Nyro-RELEASE_TAG-Android-arm7.apk">ARMv7 APK</a><br>
        <a href="https://github.com/RELEASE_REPOSITORY/releases/download/RELEASE_TAG/Nyro-RELEASE_TAG-Android-x86_64.apk">x86_64 APK</a><br>
        <a href="https://github.com/RELEASE_REPOSITORY/releases/download/RELEASE_TAG/Nyro-RELEASE_TAG-Android-market.aab">Google Play AAB</a>
      </td>
    </tr>
    <tr>
      <td>Windows</td>
      <td>
        <a href="https://github.com/RELEASE_REPOSITORY/releases/download/RELEASE_TAG/Nyro-RELEASE_TAG-Windows-Setup-x86_64.exe">EXE Installer</a>
      </td>
      <td>
        <a href="https://github.com/RELEASE_REPOSITORY/releases/download/RELEASE_TAG/Nyro-RELEASE_TAG-Windows-x86_64.msix">MSIX Package</a><br>
        <a href="https://github.com/RELEASE_REPOSITORY/releases/download/RELEASE_TAG/Nyro-RELEASE_TAG-Windows-Portable-x86_64.zip">Portable ZIP</a>
      </td>
    </tr>
    <tr>
      <td>macOS</td>
      <td>
        <a href="https://github.com/RELEASE_REPOSITORY/releases/download/RELEASE_TAG/Nyro-RELEASE_TAG-macOS.dmg">DMG</a>
      </td>
      <td>
        <a href="https://github.com/RELEASE_REPOSITORY/releases/download/RELEASE_TAG/Nyro-RELEASE_TAG-macOS-Installer.pkg">PKG Installer</a>
      </td>
    </tr>
    <tr>
      <td>Linux</td>
      <td>
        <a href="https://github.com/RELEASE_REPOSITORY/releases/download/RELEASE_TAG/Nyro-RELEASE_TAG-Linux-x86_64.AppImage">AppImage</a>
      </td>
      <td>
        <a href="https://github.com/RELEASE_REPOSITORY/releases/download/RELEASE_TAG/Nyro-RELEASE_TAG-Linux-x86_64.AppImage.tar.gz">Portable AppImage tar.gz</a><br>
        <a href="https://github.com/RELEASE_REPOSITORY/releases/download/RELEASE_TAG/Nyro-RELEASE_TAG-Linux-x86_64.deb">Debian/Ubuntu .deb</a>
      </td>
    </tr>
  </tbody>
</table>

## 使用方式

1. 根据你的系统下载上表推荐安装包；不确定 Android 架构时优先选择 `Universal APK`。
2. 安装并打开 Nyro。Android 需要允许安装来自浏览器或文件管理器的 APK；macOS 如出现安全提示，可在系统设置的安全性页面允许打开。
3. 添加配置：复制订阅链接后在 Nyro 中选择添加配置，或直接打开 `nyro://`、`v2ray://`、`clash://`、`sing-box://` 等分享链接导入。
4. 选择配置后点击连接。连接成功后，可在系统代理、TUN/VPN、分应用代理、路由规则等页面按需调整。
5. 后续更新可以在应用内检查，也可以回到本页下载最新版本安装覆盖。

## 更新记录

- 新增 Xboard 邮箱验证码注册流程，注册成功后自动登录并同步用户中心。
- 用户中心支持登录/注册切换、验证码发送倒计时、注册表单校验和账户信息刷新。
- 订阅页接入 Xboard 套餐购买流程，支持选择周期、选择支付方式、创建订单、打开易支付/扫码支付并轮询订单状态。
- 支付成功后自动刷新 Xboard 用户信息、订阅信息和套餐列表。
- 订阅列表会根据当前用户的套餐 `plan.id` 显示「当前套餐」，购买后可直观看到已生效套餐。
- 修复 Android 发布构建与 `hiddify-core v4.1.0` API 不一致导致的 Kotlin 编译失败。
- 发布 Android、Windows、macOS、Linux 多平台安装包。

**完整变更记录：** [HISTORY.md](https://github.com/RELEASE_REPOSITORY/blob/main/HISTORY.md)
