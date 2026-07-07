import 'dart:async';

import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:nyro/core/localization/translations.dart';
import 'package:nyro/features/common/qr_code_dialog.dart';
import 'package:nyro/features/xboard/data/xboard_providers.dart';
import 'package:nyro/features/xboard/model/xboard_models.dart';
import 'package:nyro/features/xboard/notifier/xboard_auth_notifier.dart';
import 'package:nyro/features/xboard/notifier/xboard_plan_notifier.dart';
import 'package:nyro/utils/utils.dart';

class SubscriptionPage extends ConsumerWidget {
  const SubscriptionPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).requireValue;
    final plans = ref.watch(xboardPlanOffersProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(t.pages.subscription.title),
        actions: [
          IconButton(
            tooltip: t.pages.subscription.refresh,
            onPressed: () => ref.invalidate(xboardPlanOffersProvider),
            icon: const Icon(Icons.refresh_rounded),
          ),
          const Gap(8),
        ],
      ),
      body: plans.when(
        data: (plans) => plans.isEmpty ? const _EmptyPlans() : _PlanList(plans: plans),
        error: (error, stackTrace) => _LoadError(error: error),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}

class _PlanList extends ConsumerWidget {
  const _PlanList({required this.plans});

  final List<XboardPlanOffer> plans;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).requireValue;
    final theme = Theme.of(context);

    return SafeArea(
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 980),
          child: ListView.separated(
            padding: const EdgeInsets.all(24).copyWith(bottom: 40),
            itemCount: plans.length + 1,
            separatorBuilder: (context, index) => const Gap(12),
            itemBuilder: (context, index) {
              if (index == 0) {
                return Row(
                  children: [
                    Icon(Icons.workspace_premium_rounded, color: theme.colorScheme.primary),
                    const Gap(10),
                    Expanded(child: Text(t.pages.subscription.planList, style: theme.textTheme.titleLarge)),
                    Text(
                      t.pages.subscription.availablePlans(count: plans.length),
                      style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ],
                );
              }
              return _PlanOfferTile(plan: plans[index - 1]);
            },
          ),
        ),
      ),
    );
  }
}

class _PlanOfferTile extends ConsumerWidget {
  const _PlanOfferTile({required this.plan});

  final XboardPlanOffer plan;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).requireValue;
    final theme = Theme.of(context);
    final primaryPrice = plan.primaryPrice;
    final account = ref.watch(xboardAuthNotifierProvider).valueOrNull;
    final isLoggedIn = account != null;
    final isCurrentPlan = account?.plan?.id == plan.id;

    void startPurchase(XboardPlanPrice price) {
      if (!isLoggedIn) {
        CustomToast.error(t.pages.subscription.loginRequired).show(context);
        return;
      }
      showDialog<void>(
        context: context,
        builder: (_) => _PurchaseDialog(plan: plan, price: price),
      );
    }

    return _SurfacePanel(
      highlighted: isCurrentPlan,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            plan.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ),
                        if (isCurrentPlan) ...[
                          const Gap(8),
                          _CurrentPlanBadge(label: t.pages.subscription.currentPlan),
                        ],
                        if (!plan.sell) ...[const Gap(8), _StatusBadge(label: t.pages.subscription.notForSale)],
                      ],
                    ),
                    const Gap(6),
                    Text(
                      _planSummary(t, plan),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              const Gap(16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    primaryPrice == null ? t.pages.subscription.noPrice : _formatPrice(primaryPrice.cents),
                    style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.primary),
                  ),
                  if (primaryPrice != null)
                    Text(
                      _periodLabel(t, primaryPrice.period),
                      style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                ],
              ),
            ],
          ),
          const Gap(16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _MetricPill(
                icon: Icons.swap_vert_rounded,
                label: t.pages.subscription.traffic,
                value: t.pages.subscription.trafficGb(traffic: plan.transferEnableGb),
              ),
              _MetricPill(
                icon: Icons.devices_rounded,
                label: t.pages.subscription.deviceLimit,
                value: plan.deviceLimit == null
                    ? t.common.unknown
                    : t.pages.subscription.deviceCount(count: plan.deviceLimit!),
              ),
              _MetricPill(
                icon: Icons.speed_rounded,
                label: t.pages.subscription.speedLimit,
                value: plan.speedLimitMbps == null
                    ? t.pages.subscription.unlimitedSpeed
                    : t.pages.subscription.speedMbps(speed: plan.speedLimitMbps!),
              ),
            ],
          ),
          const Gap(14),
          const Divider(height: 1),
          const Gap(12),
          if (plan.prices.isEmpty)
            Text(t.pages.subscription.noPrice, style: theme.textTheme.bodyMedium)
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final price in plan.prices)
                  _PricePill(
                    label: _periodLabel(t, price.period),
                    price: _formatPrice(price.cents),
                    enabled: plan.sell,
                    onPressed: () => startPurchase(price),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

class _MetricPill extends StatelessWidget {
  const _MetricPill({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: scheme.onSurfaceVariant),
          const Gap(6),
          Text(label, style: theme.textTheme.labelMedium?.copyWith(color: scheme.onSurfaceVariant)),
          const Gap(6),
          Text(value, style: theme.textTheme.labelMedium),
        ],
      ),
    );
  }
}

class _PricePill extends StatelessWidget {
  const _PricePill({required this.label, required this.price, required this.enabled, required this.onPressed});

  final String label;
  final String price;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final foreground = enabled ? scheme.onPrimaryContainer : scheme.onSurfaceVariant;
    final background = enabled ? scheme.primaryContainer : scheme.surfaceContainerHighest;
    return Material(
      color: background,
      borderRadius: BorderRadius.circular(6),
      child: InkWell(
        onTap: enabled ? onPressed : null,
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label, style: theme.textTheme.labelMedium?.copyWith(color: foreground)),
              const Gap(8),
              Text(
                price,
                style: theme.textTheme.labelMedium?.copyWith(color: foreground, fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PurchaseDialog extends ConsumerStatefulWidget {
  const _PurchaseDialog({required this.plan, required this.price});

  final XboardPlanOffer plan;
  final XboardPlanPrice price;

  @override
  ConsumerState<_PurchaseDialog> createState() => _PurchaseDialogState();
}

class _PurchaseDialogState extends ConsumerState<_PurchaseDialog> {
  late final Future<List<XboardPaymentMethod>> _paymentMethodsFuture;
  int? _selectedMethodId;
  bool _checkingOut = false;
  bool _waitingPayment = false;
  bool _qrDialogOpen = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final authData = ref.read(xboardAuthNotifierProvider).valueOrNull?.authData ?? '';
    _paymentMethodsFuture = ref.read(xboardApiClientProvider).getPaymentMethods(authData).then((methods) {
      if (methods.isNotEmpty && mounted) {
        setState(() => _selectedMethodId = methods.first.id);
      }
      return methods;
    });
  }

  Future<void> _checkout() async {
    if (_checkingOut || _selectedMethodId == null) return;
    setState(() {
      _checkingOut = true;
      _waitingPayment = false;
      _error = null;
    });
    try {
      final client = ref.read(xboardApiClientProvider);
      final authData = ref.read(xboardAuthNotifierProvider).valueOrNull?.authData;
      if (authData == null || authData.isEmpty) throw XboardApiException('Missing authorization token');
      final tradeNo = await client.createOrder(authData: authData, planId: widget.plan.id, period: widget.price.period);
      final checkout = await client.checkoutOrder(authData: authData, tradeNo: tradeNo, methodId: _selectedMethodId!);
      if (!mounted) return;

      if (checkout.isPaidWithoutRedirect) {
        await _completePayment();
        return;
      }

      final handled = await _handleCheckoutResult(checkout);
      if (!handled) {
        throw XboardApiException(ref.read(translationsProvider).requireValue.pages.subscription.paymentOpenFailed);
      }
      if (!mounted) return;
      setState(() {
        _checkingOut = false;
        _waitingPayment = true;
      });
      await _pollOrderStatus(tradeNo);
    } catch (error) {
      if (mounted) {
        setState(() {
          _error = error.toString();
          _checkingOut = false;
          _waitingPayment = false;
        });
      }
    }
  }

  Future<bool> _handleCheckoutResult(XboardOrderCheckout checkout) async {
    final t = ref.read(translationsProvider).requireValue;
    final paymentUrl = checkout.paymentUrl;
    if (paymentUrl != null) {
      final launched = await UriUtils.tryLaunch(Uri.parse(paymentUrl));
      if (launched && mounted) CustomToast.success(t.pages.subscription.paymentPageOpened).show(context);
      return launched;
    }

    final qrContent = checkout.qrContent;
    if (qrContent != null && mounted) {
      _qrDialogOpen = true;
      unawaited(
        showDialog<void>(
          context: context,
          builder: (_) => Dialog(child: QrCodeDialog(qrContent, message: t.pages.subscription.scanToPay)),
        ).whenComplete(() {
          _qrDialogOpen = false;
        }),
      );
      return true;
    }
    return false;
  }

  Future<void> _pollOrderStatus(String tradeNo) async {
    final client = ref.read(xboardApiClientProvider);
    for (var i = 0; i < 90; i++) {
      await Future<void>.delayed(const Duration(seconds: 2));
      if (!mounted) return;
      final authData = ref.read(xboardAuthNotifierProvider).valueOrNull?.authData;
      if (authData == null || authData.isEmpty) throw XboardApiException('Missing authorization token');
      final status = await client.checkOrder(authData: authData, tradeNo: tradeNo);
      if (status == XboardOrderStatus.completed || status == XboardOrderStatus.discounted) {
        await _completePayment();
        return;
      }
      if (status == XboardOrderStatus.canceled) {
        throw XboardApiException(ref.read(translationsProvider).requireValue.pages.subscription.paymentCanceled);
      }
    }
    throw XboardApiException(ref.read(translationsProvider).requireValue.pages.subscription.paymentPending);
  }

  Future<void> _completePayment() async {
    await ref.read(xboardAuthNotifierProvider.notifier).refresh();
    ref.invalidate(xboardPlanOffersProvider);
    if (!mounted) return;
    final t = ref.read(translationsProvider).requireValue;
    if (_qrDialogOpen) {
      Navigator.of(context, rootNavigator: true).pop();
      _qrDialogOpen = false;
    }
    Navigator.of(context).pop();
    CustomToast.success(t.pages.subscription.paymentSuccess).show(context);
  }

  @override
  Widget build(BuildContext context) {
    final t = ref.watch(translationsProvider).requireValue;
    final theme = Theme.of(context);

    return AlertDialog(
      title: Text(t.pages.subscription.confirmPurchase),
      content: SizedBox(
        width: 420,
        child: FutureBuilder<List<XboardPaymentMethod>>(
          future: _paymentMethodsFuture,
          builder: (context, snapshot) {
            final methods = snapshot.data ?? const <XboardPaymentMethod>[];
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(widget.plan.name, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                const Gap(6),
                Text(
                  '${_periodLabel(t, widget.price.period)} · ${_formatPrice(widget.price.cents)}',
                  style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
                const Gap(18),
                if (snapshot.connectionState == ConnectionState.waiting)
                  const Center(child: CircularProgressIndicator())
                else if (snapshot.hasError)
                  Text(
                    snapshot.error.toString(),
                    style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.error),
                  )
                else if (methods.isEmpty)
                  Text(t.pages.subscription.noPaymentMethods)
                else
                  DropdownButtonFormField<int>(
                    initialValue: _selectedMethodId,
                    decoration: InputDecoration(
                      labelText: t.pages.subscription.paymentMethod,
                      prefixIcon: const Icon(Icons.payments_rounded),
                    ),
                    items: [
                      for (final method in methods)
                        DropdownMenuItem(
                          value: method.id,
                          child: Text(method.name.isEmpty ? method.payment : method.name),
                        ),
                    ],
                    onChanged: _checkingOut ? null : (value) => setState(() => _selectedMethodId = value),
                  ),
                if (_error != null) ...[
                  const Gap(12),
                  Text(_error!, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error)),
                ],
              ],
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: _checkingOut || _waitingPayment ? null : () => Navigator.of(context).pop(),
          child: Text(t.common.cancel),
        ),
        FilledButton.icon(
          onPressed: _checkingOut || _waitingPayment || _selectedMethodId == null ? null : _checkout,
          icon: _checkingOut || _waitingPayment
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.shopping_cart_checkout_rounded),
          label: Text(
            _waitingPayment
                ? t.pages.subscription.waitingPayment
                : _checkingOut
                ? t.pages.subscription.checkingOut
                : t.pages.subscription.checkout,
          ),
        ),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: scheme.errorContainer, borderRadius: BorderRadius.circular(4)),
      child: Text(label, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: scheme.onErrorContainer)),
    );
  }
}

class _CurrentPlanBadge extends StatelessWidget {
  const _CurrentPlanBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: scheme.primaryContainer, borderRadius: BorderRadius.circular(4)),
      child: Text(label, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: scheme.onPrimaryContainer)),
    );
  }
}

class _EmptyPlans extends ConsumerWidget {
  const _EmptyPlans();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).requireValue;
    final theme = Theme.of(context);

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.workspace_premium_rounded, size: 48, color: theme.colorScheme.onSurfaceVariant),
          const Gap(12),
          Text(t.pages.subscription.empty, style: theme.textTheme.titleMedium),
          const Gap(16),
          FilledButton.icon(
            onPressed: () => ref.invalidate(xboardPlanOffersProvider),
            icon: const Icon(Icons.refresh_rounded),
            label: Text(t.pages.subscription.refresh),
          ),
        ],
      ),
    );
  }
}

class _LoadError extends ConsumerWidget {
  const _LoadError({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).requireValue;
    final theme = Theme.of(context);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(Icons.error_outline_rounded, size: 48, color: theme.colorScheme.error),
              const Gap(12),
              Text(t.pages.subscription.loadFailed, textAlign: TextAlign.center, style: theme.textTheme.titleMedium),
              const Gap(8),
              Text(
                error.toString(),
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
              const Gap(20),
              FilledButton.icon(
                onPressed: () => ref.invalidate(xboardPlanOffersProvider),
                icon: const Icon(Icons.refresh_rounded),
                label: Text(t.pages.subscription.refresh),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SurfacePanel extends StatelessWidget {
  const _SurfacePanel({required this.child, this.highlighted = false});

  final Widget child;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: highlighted ? scheme.primaryContainer.withValues(alpha: 0.16) : scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: highlighted ? scheme.primary : scheme.outlineVariant, width: highlighted ? 1.5 : 1),
      ),
      child: Padding(padding: const EdgeInsets.all(18), child: child),
    );
  }
}

String _planSummary(TranslationsEn t, XboardPlanOffer plan) {
  final device = plan.deviceLimit == null
      ? t.common.unknown
      : t.pages.subscription.deviceCount(count: plan.deviceLimit!);
  final speed = plan.speedLimitMbps == null
      ? t.pages.subscription.unlimitedSpeed
      : t.pages.subscription.speedMbps(speed: plan.speedLimitMbps!);
  return '${t.pages.subscription.trafficGb(traffic: plan.transferEnableGb)} · $device · $speed';
}

String _periodLabel(TranslationsEn t, XboardPlanPricePeriod period) {
  return switch (period) {
    XboardPlanPricePeriod.month => t.pages.subscription.priceMonth,
    XboardPlanPricePeriod.quarter => t.pages.subscription.priceQuarter,
    XboardPlanPricePeriod.halfYear => t.pages.subscription.priceHalfYear,
    XboardPlanPricePeriod.year => t.pages.subscription.priceYear,
    XboardPlanPricePeriod.twoYear => t.pages.subscription.priceTwoYear,
    XboardPlanPricePeriod.threeYear => t.pages.subscription.priceThreeYear,
    XboardPlanPricePeriod.onetime => t.pages.subscription.priceOnetime,
    XboardPlanPricePeriod.reset => t.pages.subscription.priceReset,
  };
}

String _formatPrice(int cents) => '¥${(cents / 100).toStringAsFixed(2)}';
