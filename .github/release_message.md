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

- 正式发布：推送 `vX.Y.Z` tag 后自动构建并创建 GitHub Release。
- 预发布：推送 `vX.Y.Z.dev` tag，Release 会标记为 pre-release。
- 草稿构建：在 GitHub Actions 的 Release 工作流中手动运行，`tag_name` 填 `draft`。

**完整变更记录：** [HISTORY.md](https://github.com/RELEASE_REPOSITORY/blob/main/HISTORY.md)
