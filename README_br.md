# Nyro

Nyro e um cliente proxy/VPN multiplataforma para Android, Windows, macOS e Linux.

Nyro e um desenvolvimento secundario baseado no Hiddify App. Ele usa Hiddify Core e Sing-box como base tecnica, preserva a licenca e os creditos do projeto original, e publica uma identidade, marca, links de download e canal de releases independentes para Nyro.

## Downloads

https://github.com/lucas04071403-web/nyro/releases/latest

Versao atual:

https://github.com/lucas04071403-web/nyro/releases/tag/v1.0.1

## Recursos atuais

- Suporte para Android, Windows, macOS e Linux.
- Suporte a perfis e links de assinatura compativeis com Sing-box, V2Ray, Clash e Clash Meta.
- Central do usuario conectada a contas Xboard.
- Registro com codigo de verificacao por email, login e sincronizacao da conta.
- Listagem de planos Xboard, indicacao do plano atual e sincronizacao da assinatura.
- Compra de planos com selecao de periodo, metodo de pagamento, checkout Epay ou QR code, consulta de pedido e atualizacao automatica apos o pagamento.
- Adaptacao de assinaturas Xboard para Nyro, incluindo filtro de nos informativos, leitura do header `subscription-userinfo` e configuracoes de perfil mais estaveis para Sing-box.

## Atualizacoes recentes

- Adicionado registro Xboard com verificacao por email.
- Adicionado fluxo de compra de assinaturas Xboard e pagamento.
- Adicionada marcacao do plano atual na lista de assinaturas.
- Melhorado o parser de assinaturas Xboard para remover entradas informativas de trafego, reset e expiracao da lista de proxies.
- Melhorada a exibicao de trafego e validade usando o header `subscription-userinfo`.
- Aplicadas configuracoes padrao para assinaturas Xboard com teste de URL mais frequente, DNS com preferencia por IPv4 e intervalo menor de atualizacao.

## Licenca e creditos

Nyro e baseado no Hiddify App:

https://github.com/hiddify/hiddify-app

Tambem usa Hiddify Core e Sing-box:

https://github.com/hiddify/hiddify-core

https://github.com/SagerNet/sing-box

Consulte `LICENSE.md`, `NOTICE.md` e `ACKNOWLEDGEMENTS.md` para detalhes de licenca e creditos.
