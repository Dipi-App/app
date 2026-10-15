import 'package:flutter/material.dart';

import '../../shared/branding/dipi_logo.dart';

/// The shared header used on every main screen.
///
/// Shows the small Dipi mark on the start side (right in RTL) next to the
/// screen title, and passes through [actions]. Use this instead of rebuilding
/// an `AppBar` by hand on each screen.
class DipiHeader extends StatelessWidget implements PreferredSizeWidget {
  const DipiHeader({
    super.key,
    required this.title,
    this.actions = const [],
    this.leading,
    this.showLogo = true,
    this.updateAction,
  });

  final String title;
  final List<Widget> actions;

  /// Usually a month stepper on the calendar; null shows no leading widget.
  final Widget? leading;
  final bool showLogo;

  /// The new-version icon. Sits at the far end (left in RTL), opposite the
  /// logo. Null on screens that do not show updates.
  final Widget? updateAction;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      centerTitle: false,
      automaticallyImplyLeading: false,
      leading: leading,
      titleSpacing: leading == null ? 16 : 0,
      title: Align(
        alignment: AlignmentDirectional.centerStart,
        child: Row(
          children: [
            if (showLogo)
              Semantics(
                image: true,
                label: 'لوگوی دیپی',
                child: const Padding(
                  padding: EdgeInsetsDirectional.only(end: 10),
                  child: DipiMark(size: 30),
                ),
              ),
            Flexible(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
      actions: [
        ...actions,
        ?updateAction,
      ],
    );
  }
}
