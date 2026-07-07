import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/features/xboard/model/xboard_models.dart';
import 'package:hiddify/features/xboard/notifier/xboard_plan_notifier.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

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

    return _SurfacePanel(
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
                  _PricePill(label: _periodLabel(t, price.period), price: _formatPrice(price.cents)),
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
  const _PricePill({required this.label, required this.price});

  final String label;
  final String price;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: scheme.primaryContainer, borderRadius: BorderRadius.circular(6)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: theme.textTheme.labelMedium?.copyWith(color: scheme.onPrimaryContainer)),
          const Gap(8),
          Text(
            price,
            style: theme.textTheme.labelMedium?.copyWith(color: scheme.onPrimaryContainer, fontWeight: FontWeight.w700),
          ),
        ],
      ),
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
  const _SurfacePanel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: scheme.outlineVariant),
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
