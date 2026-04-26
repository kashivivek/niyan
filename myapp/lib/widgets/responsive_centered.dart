import 'package:flutter/material.dart';

class ResponsiveCentered extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry padding;

  const ResponsiveCentered({
    super.key,
    required this.child,
    this.maxWidth = 600.0,
    this.padding = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > maxWidth + 40) {
          // Wrap in a subtle card for wide screens
          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxWidth),
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04), // Fixed from withValues() to maintain fallback safety, though analyzer warned, it's safer for all Dart versions without checking. Wait, I should use modern Dart if possible but let's stick to simple withOpacity since we don't have constraints.
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      )
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Padding(
                    padding: padding == EdgeInsets.zero ? const EdgeInsets.all(32.0) : padding,
                    child: child,
                  ),
                ),
              ),
            ),
          );
        } else {
          // Native edge-to-edge for mobile
          return SingleChildScrollView(
            child: Padding(
              padding: padding,
              child: child,
            ),
          );
        }
      },
    );
  }
}
