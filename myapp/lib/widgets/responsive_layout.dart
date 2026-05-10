import 'package:flutter/material.dart';

class ResponsiveCentered extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  final EdgeInsets padding;

  const ResponsiveCentered({
    super.key,
    required this.child,
    this.maxWidth = 800,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(
          padding: padding,
          child: child,
        ),
      ),
    );
  }
}

/// A wrapper for sliver-based screens that need centering
class SliverResponsiveCentered extends StatelessWidget {
  final Widget sliver;
  final double maxWidth;

  const SliverResponsiveCentered({
    super.key,
    required this.sliver,
    this.maxWidth = 800,
  });

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: sliver,
          ),
        ),
      ),
    );
  }
}
