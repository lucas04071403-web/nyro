# Nyro

Nyro は Android、Windows、macOS、Linux 向けのクロスプラットフォーム Proxy/VPN クライアントです。

Nyro は Hiddify App をベースに二次開発されたプロジェクトです。中核のプロキシ機能は Hiddify Core と Sing-box によって提供され、上流プロジェクトのライセンスと出典表示を保持しながら、Nyro 独自のブランド、パッケージ ID、ダウンロードリンク、リリースチャンネルを使用します。

## ダウンロード

https://github.com/lucas04071403-web/nyro/releases/latest

現在のリリース:

https://github.com/lucas04071403-web/nyro/releases/tag/v1.0.1

## 現在の機能

- Android、Windows、macOS、Linux をサポート。
- Sing-box、V2Ray、Clash、Clash Meta 互換のプロファイル、購読リンク、共有リンクをサポート。
- Xboard アカウントと連携したユーザーセンター。
- メール認証コードによる登録、ログイン、アカウント同期。
- Xboard のプラン表示、現在のプラン表示、購読情報の同期。
- プラン購入フローに対応。期間選択、支払い方法選択、Epay または QR チェックアウト、注文状態の確認、支払い後の自動更新を含みます。
- Xboard 購読に対する Nyro 向け最適化。情報用ノードの除外、`subscription-userinfo` header の読み取り、Sing-box 向けにより安定したプロファイル設定を行います。

## 最近の更新

- Xboard のメール認証コード登録を追加。
- Xboard 購読プランの購入と支払いフローを追加。
- 購入済みプランを購読一覧で「現在のプラン」として表示。
- Xboard 購読解析を改善し、残り通信量、リセット時間、有効期限などの情報用ノードをプロキシ一覧から除外。
- `subscription-userinfo` header を使用して通信量と有効期限の表示を改善。
- Xboard 購読向けに、より短い URL テスト間隔、IPv4 優先 DNS、短い自動更新間隔などの Nyro 推奨設定を適用。

## ライセンスと謝辞

Nyro は Hiddify App をベースにしています:

https://github.com/hiddify/hiddify-app

Hiddify Core と Sing-box も使用しています:

https://github.com/hiddify/hiddify-core

https://github.com/SagerNet/sing-box

ライセンスと出典表示の詳細は `LICENSE.md`、`NOTICE.md`、`ACKNOWLEDGEMENTS.md` を参照してください。
