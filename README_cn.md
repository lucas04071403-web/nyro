# Nyro

Nyro 是一个面向 Android、Windows、macOS 和 Linux 的跨平台代理/VPN 客户端。

Nyro 基于 Hiddify App 二次开发，并由 Hiddify Core 与 Sing-box 提供核心代理能力。项目保留上游许可证和来源说明，同时使用独立的 Nyro 品牌、包名、下载链接和发布通道。

## 下载

https://github.com/lucas04071403-web/nyro/releases/latest

当前版本：

https://github.com/lucas04071403-web/nyro/releases/tag/v1.0.1

## 当前能力

- 支持 Android、Windows、macOS 和 Linux。
- 支持 Sing-box、V2Ray、Clash、Clash Meta 等常见订阅或分享链接。
- 用户中心已对接 Xboard 账号。
- 支持邮箱验证码注册、登录和账号信息同步。
- 支持 Xboard 套餐展示、当前套餐标记、订阅信息同步。
- 支持套餐购买流程，包括周期选择、支付方式选择、易支付或二维码收银台、订单轮询和支付成功后的自动刷新。
- 针对 Xboard 订阅做了 Nyro 适配：过滤剩余流量、重置时间、到期时间等伪节点，使用 `subscription-userinfo` 显示流量和到期信息，并注入更适合 Sing-box 的测速、DNS、IPv4 优先和自动更新配置。

## 最近更新

- 新增 Xboard 邮箱验证码注册。
- 新增用户中心登录/注册切换、验证码倒计时和注册表单校验。
- 新增 Xboard 套餐购买、支付跳转/二维码支付和订单状态检查。
- 支付成功后自动刷新 Xboard 账号、订阅和套餐状态。
- 在订阅套餐列表中显示“当前套餐”。
- 优化 Xboard 订阅解析，真实节点列表不再混入流量、重置、到期提示节点。
- 优先使用 Xboard `subscription-userinfo` Header 展示流量和到期时间。
- 为 Xboard 订阅生成更适合 Nyro/Sing-box 的默认配置，提高自动测速、DNS 解析和连接稳定性。

## 合规与致谢

Nyro 基于 Hiddify App 二次开发：

https://github.com/hiddify/hiddify-app

核心能力来自 Hiddify Core 与 Sing-box：

https://github.com/hiddify/hiddify-core

https://github.com/SagerNet/sing-box

合规说明请查看 `LICENSE.md`、`NOTICE.md` 和 `ACKNOWLEDGEMENTS.md`。
