import 'dart:math';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class PinDotsIndicator extends StatelessWidget {
  final int pinLength;
  final int enteredLength;
  final AnimationController shakeController;

  const PinDotsIndicator({
    super.key,
    this.pinLength = 4,
    required this.enteredLength,
    required this.shakeController,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: shakeController,
      builder: (context, child) {
        // Синусоидальное смещение для эффекта встряхивания при ошибке (Shake animation)
        final sineValue = sin(shakeController.value * pi * 4);
        final offset = sineValue * 12.0;

        return Transform.translate(
          offset: Offset(offset, 0),
          child: child,
        );
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(pinLength, (index) {
          final isFilled = index < enteredLength;
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 10),
            width: isFilled ? 18 : 14,
            height: isFilled ? 18 : 14,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isFilled ? AppColors.primary : Colors.transparent,
              border: Border.all(
                color: isFilled ? AppColors.primaryLight : AppColors.darkTextMuted,
                width: 2,
              ),
              boxShadow: isFilled
                  ? [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.5),
                        blurRadius: 10,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
            ),
          );
        }),
      ),
    );
  }
}
