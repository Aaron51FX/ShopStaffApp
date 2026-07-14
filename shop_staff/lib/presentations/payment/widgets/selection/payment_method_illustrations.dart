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
    Widget qrCell({bool filled = true}) {
      return Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: filled ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(2),
          border: Border.all(color: Colors.white, width: 1.0),
        ),
      );
    }

    return Container(
      width: 92,
      height: 110,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.26)),
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            height: 10,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: [
              qrCell(),
              qrCell(filled: false),
              qrCell(),
              qrCell(),
              qrCell(filled: false),
              qrCell(),
              qrCell(filled: false),
              qrCell(),
              qrCell(),
            ],
          ),
          const Spacer(),
          Column(
            children: List.generate(
              5,
              (index) => Container(
                margin: const EdgeInsets.only(bottom: 4),
                height: 3,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(
                    alpha: index.isEven ? 0.92 : 0.52,
                  ),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
          ),
        ],
      ),
    );
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
