import 'package:flutter/material.dart';
import '../theme/neo_colors.dart';

class OffsetCanvasBox extends StatelessWidget {
  final Widget child;
  final double width;
  final double height;
  final Color backgroundColor;
  final Color outlineColor;
  final double borderRadius;
  final double offset;
  final double borderWidth;
  final EdgeInsetsGeometry padding;

  const OffsetCanvasBox({
    super.key,
    required this.child,
    this.width = 270,
    this.height = 270,
    this.backgroundColor = NeoColors.primaryBlue,
    this.outlineColor = NeoColors.primaryBlue,
    this.borderRadius = 30.0,
    this.offset = 10.0,
    this.borderWidth = 3.0,
    this.padding = const EdgeInsets.all(16.0),
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: width + offset,
        height: height + offset,
        child: Stack(
          children: [
            // Layer 1: Border outline (shadow effect with offset)
            Positioned(
              left: offset,
              top: offset,
              width: width,
              height: height,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(borderRadius),
                  border: Border.all(
                    color: outlineColor,
                    width: borderWidth,
                  ),
                ),
              ),
            ),
            // Layer 2: Main colored background container
            Positioned(
              left: 0,
              top: 0,
              width: width,
              height: height,
              child: Container(
                padding: padding,
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: BorderRadius.circular(borderRadius),
                  border: Border.all(
                    color: NeoColors.borderBlack,
                    width: 2.5,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: NeoColors.borderBlack,
                      offset: Offset(4, 4),
                      blurRadius: 0,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(borderRadius - 4),
                  child: child,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
