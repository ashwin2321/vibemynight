import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Shared loading indicator used while events/artists/passes/admin tables load,
/// per the spec's "reusable loading/skeleton states" requirement.
///
/// A true shimmer/skeleton treatment is a visual-polish detail for Phase 8/11 -
/// this keeps a single call site (`LoadingView()`) so swapping it in later
/// doesn't touch every screen.
class LoadingView extends StatelessWidget {
  const LoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(color: AppColors.neonPurple),
    );
  }
}
