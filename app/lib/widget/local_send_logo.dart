import 'package:flutter/material.dart';

class LocalSendLogo extends StatelessWidget {
  final bool withText;

  const LocalSendLogo({required this.withText});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (withText) {
      return Column(
        children: [
          Image.asset(
            isDark ? 'assets/img/somosdos/wordmark-white.png' : 'assets/img/somosdos/wordmark-color.png',
            width: 240,
            height: 170,
            fit: BoxFit.contain,
            semanticLabel: 'Somos Dos Studio',
          ),
          const Text(
            'Envia2',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, letterSpacing: 1.2),
            textAlign: TextAlign.center,
          ),
        ],
      );
    } else {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(28),
        ),
        child: Image.asset(
          'assets/img/somosdos/s2-mark.png',
          width: 176,
          height: 176,
          fit: BoxFit.contain,
          semanticLabel: 'Somos Dos Studio',
        ),
      );
    }
  }
}
