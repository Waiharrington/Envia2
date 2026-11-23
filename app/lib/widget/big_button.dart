import 'package:flutter/material.dart';
import 'package:localsend_app/widget/responsive_builder.dart';

class BigButton extends StatelessWidget {
  static const double desktopWidth = 100.0;
  static const double mobileWidth = 90.0;

  final IconData icon;
  final String label;
  final bool filled;
  final double? width;
  final VoidCallback onTap;

  const BigButton({
    required this.icon,
    required this.label,
    required this.filled,
    this.width,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final sizingInformation = SizingInformation(MediaQuery.sizeOf(context).width);
    final buttonWidth = width ?? (sizingInformation.isDesktop ? desktopWidth : mobileWidth);
    return SizedBox(
      width: buttonWidth,
      height: 88,
      child: Material(
        color: filled ? colorScheme.primaryContainer : colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: filled ? colorScheme.primary.withValues(alpha: 0.28) : colorScheme.outlineVariant.withValues(alpha: 0.65),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: filled ? colorScheme.primary : colorScheme.secondary, size: 22),
                const SizedBox(height: 8),
                FittedBox(
                  alignment: Alignment.bottomCenter,
                  child: Text(label, maxLines: 1, style: Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
