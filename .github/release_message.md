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

- 重写桌面端首页第一版 UI：侧边栏、首页 Header、Profile 主卡、连接按钮、当前代理底部状态区和底部 Quick Settings dock。
- 首页采用更接近 macOS 系统工具的视觉风格，优化桌面优先布局、卡片层级、图标按钮、间距和连接状态表现。
- 登录 Xboard 后会自动同步订阅配置到主页，不再需要先点击连接才触发同步。
- 退出登录后会自动清除由 Xboard 同步的订阅配置，避免旧账号配置残留。
- 订阅配置增加 Xboard 管理标记，便于后续识别、更新和安全清理自动同步的配置。
- 修复桌面端连接后底部黄黑溢出纹路遮挡问题。
- 修复主页右侧重复显示品牌图标、版本号和多余帮助图标的问题。
- 修复 Xboard/sing-box 订阅被面板误判为低版本客户端后只显示少量 Shadowsocks 节点的问题。
- 调整订阅请求的 User-Agent，让面板优先识别为新版 sing-box，从而保留 VLESS/Reality 等现代协议节点并使用新版 sing-box 模板。
- 修复新版 sing-box 配置导入时因旧版 `type: dns` outbound 模板兼容性导致的报错。
- 发布 Android、Windows、macOS、Linux 多平台安装包。

**完整变更记录：** [HISTORY.md](https://github.com/RELEASE_REPOSITORY/blob/main/HISTORY.md)
