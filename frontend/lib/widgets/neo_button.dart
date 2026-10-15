import 'package:flutter/material.dart';
import '../theme/neo_colors.dart';

class NeoButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final Color backgroundColor;
  final Color textColor;
  final IconData? icon;
  final double height;
  final double borderRadius;
  final double borderWidth;
  final double shadowOffset;
  final bool isFullWidth;
  final bool isLoading;

  const NeoButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.backgroundColor = NeoColors.primaryBlue,
    this.textColor = NeoColors.white,
    this.icon,
    this.height = 54.0,
    this.borderRadius = 16.0,
    this.borderWidth = 2.5,
    this.shadowOffset = 5.0,
    this.isFullWidth = true,
    this.isLoading = false,
  });

  @override
  State<NeoButton> createState() => _NeoButtonState();
}

class _NeoButtonState extends State<NeoButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final bool isEnabled = widget.onPressed != null && !widget.isLoading;
    final currentOffset = _isPressed && isEnabled ? 1.0 : widget.shadowOffset;
    final transformOffset = _isPressed && isEnabled ? widget.shadowOffset - 1.0 : 0.0;

    return GestureDetector(
      onTapDown: isEnabled ? (_) => setState(() => _isPressed = true) : null,
      onTapUp: isEnabled
          ? (_) {
              setState(() => _isPressed = false);
              widget.onPressed?.call();
            }
          : null,
      onTapCancel: isEnabled ? () => setState(() => _isPressed = false) : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 70),
        transform: Matrix4.translationValues(transformOffset, transformOffset, 0),
        width: widget.isFullWidth ? double.infinity : null,
        height: widget.height,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: isEnabled ? widget.backgroundColor : NeoColors.lightGray,
          borderRadius: BorderRadius.circular(widget.borderRadius),
          border: Border.all(
            color: NeoColors.borderBlack,
            width: widget.borderWidth,
          ),
          boxShadow: [
            BoxShadow(
              color: NeoColors.borderBlack,
              offset: Offset(currentOffset, currentOffset),
              blurRadius: 0,
            ),
          ],
        ),
        child: Center(
          child: widget.isLoading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: NeoColors.white,
                  ),
                )
              : Row(
                  mainAxisSize: widget.isFullWidth ? MainAxisSize.max : MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (widget.icon != null) ...[
                      Icon(widget.icon, color: widget.textColor, size: 20),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      widget.text,
                      style: TextStyle(
                        color: widget.textColor,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
