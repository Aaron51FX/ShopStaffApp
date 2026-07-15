part of '../../pages/payment_selection_page.dart';

class _CashIllustration extends StatelessWidget {
  const _CashIllustration();

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 112,
          height: 72,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.22),
            borderRadius: BorderRadius.circular(22),
          ),
        ),
        Positioned(
          left: 16,
          top: 13,
          child: Container(
            width: 80,
            height: 46,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Center(
              child: Icon(
                Icons.payments_rounded,
                size: 28,
                color: Color(0xFF0F766E),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _QrIllustration extends StatelessWidget {
  const _QrIllustration();

  @override
  Widget build(BuildContext context) {
    return Icon(Icons.qr_code_2_rounded, size: 72, color: Colors.white);
  }
}

class _CardIllustration extends StatelessWidget {
  const _CardIllustration();

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 118,
          height: 72,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
          ),
        ),
        Positioned(
          left: 18,
          child: Container(
            width: 86,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.credit_card_rounded,
                  size: 22,
                  color: Color(0xFF1D4ED8),
                ),
                SizedBox(width: 8),
                Icon(
                  Icons.contactless_rounded,
                  size: 20,
                  color: Color(0xFF1D4ED8),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
