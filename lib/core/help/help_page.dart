import 'package:flutter/material.dart';

import '../../shared/widgets/app_sheet.dart';
import '../widgets/directional_icons.dart';
import 'help_content.dart';
import 'voice_hints.dart';

/// The "help" section reachable from settings (and from the "?" buttons).
class HelpPage extends StatelessWidget {
  const HelpPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('راهنما')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Text(
            'کار با دیپی ساده است. هر بخش را اینجا کوتاه یاد گرفته‌ای. روی هر '
            'مورد بزن تا قدم‌به‌قدم ببینی.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          for (final topic in HelpContent.all) ...[
            _HelpCard(topic: topic),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

class _HelpCard extends StatelessWidget {
  const _HelpCard({required this.topic});

  final HelpTopic topic;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => showHelpTopic(context, topic),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: theme.colorScheme.primaryContainer,
                child: Icon(
                  topic.icon,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  topic.title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Icon(
                DirectionalIcons.forward,
                color: theme.colorScheme.outline,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Opens a short guide (intro + 2–3 steps) for [topic] in a bottom sheet.
Future<void> showHelpTopic(BuildContext context, HelpTopic topic) {
  return showAppSheet<void>(
    context,
    child: AppSheet(
      title: topic.title,
      subtitle: topic.intro,
      actions: [
        FilledButton(
          onPressed: () => Navigator.of(context).maybePop(),
          child: const Text('فهمیدم'),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: VoiceHintButton(text: topic.speechText),
          ),
          for (var i = 0; i < topic.steps.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 15,
                    backgroundColor:
                        Theme.of(context).colorScheme.primaryContainer,
                    child: Text(
                      '${i + 1}',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color:
                            Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: _StepText(text: topic.steps[i])),
                ],
              ),
            ),
        ],
      ),
    ),
  );
}

class _StepText extends StatelessWidget {
  const _StepText({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodyLarge,
      ),
    );
  }
}

/// A small "?" button for the app bar of a main screen.
class ContextHelpButton extends StatelessWidget {
  const ContextHelpButton({super.key, required this.topicId});

  final String topicId;

  @override
  Widget build(BuildContext context) {
    final topic = HelpContent.byId(topicId);
    if (topic == null) return const SizedBox.shrink();
    return IconButton(
      tooltip: 'راهنما',
      icon: const Icon(Icons.help_outline_rounded),
      onPressed: () => showHelpTopic(context, topic),
    );
  }
}
