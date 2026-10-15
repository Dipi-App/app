import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/settings/state/settings_providers.dart';
import '../../shared/utils/motion.dart';

/// Lets tests (and a future "turn tips off" setting) disable the first-use
/// highlights. Defaults to on in the real app.
final coachMarksEnabledProvider = Provider<bool>((ref) => true);

/// One highlight tip: [targetKey] is the on-screen widget to spotlight.
class CoachMarkStep {
  const CoachMarkStep({
    required this.targetKey,
    required this.title,
    required this.message,
  });

  final GlobalKey targetKey;
  final String title;
  final String message;
}

/// Shows the one-time tips for a screen. Each screen passes a stable [id]; once
/// the user has seen the tips they never come back.
Future<void> showCoachMarks(
  BuildContext context,
  WidgetRef ref, {
  required String id,
  required List<CoachMarkStep> steps,
}) async {
  if (steps.isEmpty) return;
  if (!ref.read(coachMarksEnabledProvider)) return;
  if (ref.read(settingsValueProvider).coachMarksSeen.contains(id)) return;

  await ref.read(settingsControllerProvider.notifier).markCoachMarkSeen(id);
  if (!context.mounted) return;

  await showGeneralDialog<void>(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.transparent,
    transitionDuration: reduceMotion(context)
        ? Duration.zero
        : const Duration(milliseconds: 220),
    pageBuilder: (context, _, _) => _CoachMarkOverlay(steps: steps),
  );
}

class _CoachMarkOverlay extends StatefulWidget {
  const _CoachMarkOverlay({required this.steps});

  final List<CoachMarkStep> steps;

  @override
  State<_CoachMarkOverlay> createState() => _CoachMarkOverlayState();
}

class _CoachMarkOverlayState extends State<_CoachMarkOverlay> {
  int _index = 0;

  Rect? _targetRect() {
    final key = widget.steps[_index].targetKey;
    final context = key.currentContext;
    if (context == null) return null;
    final box = context.findRenderObject();
    if (box is! RenderBox || !box.hasSize) return null;
    final offset = box.localToGlobal(Offset.zero);
    return offset & box.size;
  }

  void _next() {
    if (_index >= widget.steps.length - 1) {
      Navigator.of(context).maybePop();
    } else {
      setState(() => _index++);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final media = MediaQuery.of(context);
    final rect = _targetRect();
    final step = widget.steps[_index];
    final isLast = _index == widget.steps.length - 1;

    const bubbleWidth = 300.0;
    final left = rect == null
        ? (media.size.width - bubbleWidth) / 2
        : (rect.center.dx - bubbleWidth / 2).clamp(
            16.0,
            media.size.width - bubbleWidth - 16,
          );
    final below = rect != null && rect.center.dy < media.size.height * 0.6;
    final top = rect == null
        ? media.size.height / 2
        : below
        ? rect.bottom + 12
        : null;
    final bottom = rect != null && !below
        ? media.size.height - rect.top + 12
        : null;

    return Material(
      type: MaterialType.transparency,
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _SpotlightPainter(
                hole: rect,
                color: Colors.black.withValues(alpha: 0.72),
              ),
            ),
          ),
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _next,
            ),
          ),
          Positioned(
            left: left,
            top: top,
            bottom: bottom,
            width: bubbleWidth,
            child: Card(
              elevation: 8,
              color: scheme.surfaceContainerHigh,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            step.title,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                        ),
                        Text(
                          '${_index + 1} از ${widget.steps.length}',
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      step.message,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        TextButton(
                          onPressed: () => Navigator.of(context).maybePop(),
                          child: const Text('رد کردن'),
                        ),
                        const Spacer(),
                        FilledButton(
                          onPressed: _next,
                          child: Text(isLast ? 'فهمیدم' : 'بعدی'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SpotlightPainter extends CustomPainter {
  const _SpotlightPainter({required this.hole, required this.color});

  final Rect? hole;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final full = Offset.zero & size;
    final paint = Paint()..color = color;
    final spot = hole;
    if (spot == null) {
      canvas.drawRect(full, paint);
      return;
    }
    final rounded = RRect.fromRectAndRadius(
      spot.inflate(8),
      const Radius.circular(18),
    );
    final path = Path.combine(
      PathOperation.difference,
      Path()..addRect(full),
      Path()..addRRect(rounded),
    );
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_SpotlightPainter oldDelegate) =>
      oldDelegate.hole != hole || oldDelegate.color != color;
}
