import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/features/xboard/model/xboard_models.dart';
import 'package:hiddify/features/xboard/notifier/xboard_auth_notifier.dart';
import 'package:hiddify/utils/utils.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class UserCenterPage extends HookConsumerWidget {
  const UserCenterPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).requireValue;
    final accountState = ref.watch(xboardAuthNotifierProvider);
    final account = accountState.valueOrNull;

    return Scaffold(
      appBar: AppBar(
        title: Text(t.pages.userCenter.title),
        actions: [
          if (account != null) ...[
            IconButton(
              tooltip: t.pages.userCenter.refresh,
              onPressed: () => ref.read(xboardAuthNotifierProvider.notifier).refresh(),
              icon: const Icon(Icons.refresh_rounded),
            ),
            IconButton(
              tooltip: t.pages.userCenter.logout,
              onPressed: () => ref.read(xboardAuthNotifierProvider.notifier).logout(),
              icon: const Icon(Icons.logout_rounded),
            ),
            const Gap(8),
          ],
        ],
      ),
      body: accountState.when(
        data: (account) => account == null ? const _LoginPanel() : _AccountPanel(account: account),
        error: (error, stackTrace) => _LoadErrorPanel(error: error),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}

class _LoginPanel extends HookConsumerWidget {
  const _LoginPanel();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).requireValue;
    final theme = Theme.of(context);
    final formKey = useMemoized(GlobalKey<FormState>.new);
    final emailController = useTextEditingController();
    final passwordController = useTextEditingController();
    final obscurePassword = useState(true);
    final isSubmitting = useState(false);
    final loginError = useState<String?>(null);

    Future<void> submit() async {
      if (isSubmitting.value || !(formKey.currentState?.validate() ?? false)) return;
      FocusScope.of(context).unfocus();
      loginError.value = null;
      isSubmitting.value = true;
      try {
        await ref
            .read(xboardAuthNotifierProvider.notifier)
            .login(email: emailController.text.trim(), password: passwordController.text);
        if (context.mounted) CustomToast.success(t.pages.userCenter.loginSuccess).show(context);
      } catch (error) {
        if (context.mounted) loginError.value = error.toString();
      } finally {
        if (context.mounted) isSubmitting.value = false;
      }
    }

    return _CenteredPage(
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(Icons.account_circle_rounded, size: 56, color: theme.colorScheme.primary),
            const Gap(12),
            Text(t.pages.userCenter.notLoggedIn, textAlign: TextAlign.center, style: theme.textTheme.titleLarge),
            const Gap(6),
            Text(
              t.pages.userCenter.loginHint,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const Gap(24),
            TextFormField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.email],
              decoration: InputDecoration(
                labelText: t.pages.userCenter.email,
                prefixIcon: const Icon(Icons.email_rounded),
              ),
              validator: (value) => (value == null || value.trim().isEmpty) ? t.pages.userCenter.emailRequired : null,
              enabled: !isSubmitting.value,
            ),
            const Gap(12),
            TextFormField(
              controller: passwordController,
              obscureText: obscurePassword.value,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.password],
              decoration: InputDecoration(
                labelText: t.pages.userCenter.password,
                prefixIcon: const Icon(Icons.lock_rounded),
                suffixIcon: IconButton(
                  tooltip: obscurePassword.value ? t.pages.userCenter.showPassword : t.pages.userCenter.hidePassword,
                  onPressed: isSubmitting.value ? null : () => obscurePassword.value = !obscurePassword.value,
                  icon: Icon(obscurePassword.value ? Icons.visibility_rounded : Icons.visibility_off_rounded),
                ),
              ),
              validator: (value) => (value == null || value.isEmpty) ? t.pages.userCenter.passwordRequired : null,
              onFieldSubmitted: (_) => submit(),
              enabled: !isSubmitting.value,
            ),
            if (loginError.value != null) ...[
              const Gap(12),
              Text(loginError.value!, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error)),
            ],
            const Gap(20),
            FilledButton.icon(
              onPressed: isSubmitting.value ? null : submit,
              icon: isSubmitting.value
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.login_rounded),
              label: Text(isSubmitting.value ? t.pages.userCenter.loggingIn : t.pages.userCenter.login),
            ),
          ],
        ),
      ),
    );
  }
}

class _AccountPanel extends ConsumerWidget {
  const _AccountPanel({required this.account});

  final XboardAccount account;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).requireValue;
    final theme = Theme.of(context);
    final planName = account.plan?.name.trim().isNotEmpty == true ? account.plan!.name : t.pages.userCenter.noPlan;
    final expiresAt = account.expiredAt;
    final isExpired = expiresAt?.isBefore(DateTime.now()) ?? false;

    return _CenteredPage(
      maxWidth: 720,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: theme.colorScheme.primaryContainer,
                child: Icon(Icons.person_rounded, color: theme.colorScheme.onPrimaryContainer),
              ),
              const Gap(12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(t.pages.userCenter.accountOverview, style: theme.textTheme.titleMedium),
                    const Gap(2),
                    Text(
                      account.email.isEmpty ? t.common.unknown : account.email,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Gap(20),
          _TrafficPanel(account: account),
          const Gap(12),
          _SurfacePanel(
            child: Column(
              children: [
                _InfoRow(
                  icon: Icons.email_rounded,
                  label: t.pages.userCenter.email,
                  value: account.email.isEmpty ? t.common.unknown : account.email,
                ),
                const Divider(height: 1),
                _InfoRow(
                  icon: Icons.account_balance_wallet_rounded,
                  label: t.pages.userCenter.balance,
                  value: _formatBalance(account.balance),
                ),
                const Divider(height: 1),
                _InfoRow(icon: Icons.workspace_premium_rounded, label: t.pages.userCenter.plan, value: planName),
                const Divider(height: 1),
                _InfoRow(
                  icon: Icons.event_rounded,
                  label: t.pages.userCenter.expireAt,
                  value: expiresAt?.format() ?? t.common.notSet,
                  valueColor: isExpired ? theme.colorScheme.error : null,
                ),
              ],
            ),
          ),
          const Gap(16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => ref.read(xboardAuthNotifierProvider.notifier).refresh(),
                  icon: const Icon(Icons.refresh_rounded),
                  label: Text(t.pages.userCenter.refresh),
                ),
              ),
              const Gap(12),
              Expanded(
                child: FilledButton.tonalIcon(
                  onPressed: () => ref.read(xboardAuthNotifierProvider.notifier).logout(),
                  icon: const Icon(Icons.logout_rounded),
                  label: Text(t.pages.userCenter.logout),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TrafficPanel extends ConsumerWidget {
  const _TrafficPanel({required this.account});

  final XboardAccount account;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).requireValue;
    final theme = Theme.of(context);
    final usedTraffic = account.usedTraffic;
    final totalTraffic = account.transferEnable;
    final progress = totalTraffic > 0 ? (usedTraffic / totalTraffic).clamp(0, 1).toDouble() : null;
    final trafficText = totalTraffic > 0
        ? usedTraffic.sizeOf(totalTraffic)
        : '${usedTraffic.size()} / ${t.common.unknown}';

    return _SurfacePanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: Text(t.pages.userCenter.traffic, style: theme.textTheme.titleMedium)),
              Text(trafficText, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            ],
          ),
          const Gap(12),
          LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            borderRadius: BorderRadius.circular(8),
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
          ),
          const Gap(12),
          Row(
            children: [
              Expanded(
                child: _TrafficValue(label: t.pages.userCenter.upload, value: account.upload.size()),
              ),
              const Gap(12),
              Expanded(
                child: _TrafficValue(label: t.pages.userCenter.download, value: account.download.size()),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TrafficValue extends StatelessWidget {
  const _TrafficValue({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        const Gap(2),
        Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.bodyMedium),
      ],
    );
  }
}

class _LoadErrorPanel extends ConsumerWidget {
  const _LoadErrorPanel({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).requireValue;
    final theme = Theme.of(context);

    return _CenteredPage(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(Icons.error_outline_rounded, size: 48, color: theme.colorScheme.error),
          const Gap(12),
          Text(t.pages.userCenter.loadFailed, textAlign: TextAlign.center, style: theme.textTheme.titleMedium),
          const Gap(8),
          Text(
            error.toString(),
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const Gap(20),
          FilledButton.icon(
            onPressed: () => ref.read(xboardAuthNotifierProvider.notifier).refresh(),
            icon: const Icon(Icons.refresh_rounded),
            label: Text(t.pages.userCenter.refresh),
          ),
          const Gap(8),
          OutlinedButton.icon(
            onPressed: () => ref.read(xboardAuthNotifierProvider.notifier).logout(),
            icon: const Icon(Icons.logout_rounded),
            label: Text(t.pages.userCenter.logout),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.label, required this.value, this.valueColor});

  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.onSurfaceVariant),
          const Gap(12),
          Expanded(child: Text(label, style: theme.textTheme.bodyMedium)),
          const Gap(12),
          Flexible(
            child: Text(
              value,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.end,
              style: theme.textTheme.bodyMedium?.copyWith(color: valueColor ?? theme.colorScheme.onSurfaceVariant),
            ),
          ),
        ],
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
      child: Padding(padding: const EdgeInsets.all(16), child: child),
    );
  }
}

class _CenteredPage extends StatelessWidget {
  const _CenteredPage({required this.child, this.maxWidth = 480});

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: ListView(padding: const EdgeInsets.all(24), children: [child]),
        ),
      ),
    );
  }
}

String _formatBalance(int cents) => '¥${(cents / 100).toStringAsFixed(2)}';
