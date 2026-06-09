part of '../pages/cash_register_closure_detail_page.dart';

class _VerifyForm extends StatelessWidget {
  const _VerifyForm({
    required this.mail,
    required this.controller,
    required this.loading,
    required this.error,
    required this.onSubmit,
  });

  final CashRegisterClosureMailAccount mail;
  final TextEditingController controller;
  final bool loading;
  final String? error;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 360),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(
            Icons.mark_email_read_rounded,
            size: 48,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(height: 18),
          Text(
            '確認コード',
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${mail.verifyEmail} に送信しました',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.stone500,
            ),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: controller,
            autofocus: true,
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(6),
            ],
            decoration: const InputDecoration(
              labelText: '確認コード',
              border: OutlineInputBorder(),
            ),
            onSubmitted: (_) => onSubmit(),
          ),
          if (error != null) ...[
            const SizedBox(height: 14),
            Text(
              error!,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.red.shade700,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          const SizedBox(height: 16),
          FilledButton(
            onPressed: loading ? null : onSubmit,
            child: const Text('获取'),
          ),
        ],
      ),
    );
  }
}
