import 'package:flutter/material.dart';
import '../../domain/entities/product.dart';
import '../constants/app_colors.dart';

class WishlistHeartButton extends StatefulWidget {
  final Product product;
  final bool isWishlisted;
  final VoidCallback onTap;
  final double iconSize;

  const WishlistHeartButton({
    super.key,
    required this.product,
    required this.isWishlisted,
    required this.onTap,
    this.iconSize = 16,
  });

  @override
  State<WishlistHeartButton> createState() => _WishlistHeartButtonState();
}

class _WishlistHeartButtonState extends State<WishlistHeartButton> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.3).chain(CurveTween(curve: Curves.easeOut)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.3, end: 1.0).chain(CurveTween(curve: Curves.easeIn)),
        weight: 50,
      ),
    ]).animate(_animController);
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant WishlistHeartButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isWishlisted != oldWidget.isWishlisted) {
      _animController.forward(from: 0.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: GestureDetector(
        onTap: () {
          _animController.forward(from: 0.0);
          widget.onTap();
        },
        child: Icon(
          widget.isWishlisted
              ? Icons.favorite_rounded
              : Icons.favorite_border_rounded,
          color: widget.isWishlisted
              ? AppColors.error
              : AppColors.textPrimary,
          size: widget.iconSize,
        ),
      ),
    );
  }
}
