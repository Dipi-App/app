import 'package:flutter/material.dart';

import '../../core/theme/app_tokens.dart';

/// Lifts a floating action button above the [FloatingNavBar].
///
/// Tab pages live inside the home shell, whose floating navigation bar is
/// drawn over an `extendBody` scaffold. A default `endFloat` action button
/// would therefore end up hidden behind that bar, so it is padded up by the
/// shared navigation clearance.
class NavAwareFab extends StatelessWidget {
  const NavAwareFab({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: AppTokens.navClearance(context)),
      child: child,
    );
  }
}
