import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/theme/azm_theme.dart';
import '../../core/providers/app_providers.dart';

class AiAssistantPage extends ConsumerStatefulWidget {
  const AiAssistantPage({super.key});

  @override
  ConsumerState<AiAssistantPage> createState() => _AiAssistantPageState();
}

class _AiAssistantPageState extends ConsumerState<AiAssistantPage> {
  final _ctrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _send(String text) async {
    final prompt = text.trim();
    if (prompt.isEmpty || _loading) return;
    _ctrl.clear();
    setState(() => _loading = true);

    final repo = ref.read(repositoryProvider);
    await repo.saveAiMessage(role: 'user', content: prompt, providerLabel: 'User');
    ref.invalidate(aiMessagesProvider);

    final response = await ref.read(aiOrchestratorProvider).askQuestion(prompt);
    await repo.saveAiMessage(
      role: 'assistant',
      content: response.answer,
      providerLabel: response.providerLabel,
    );
    ref.invalidate(aiMessagesProvider);

    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider).valueOrNull;
    final isAr = (settings?.languageCode ?? 'ar') == 'ar';
    final messages = ref.watch(aiMessagesProvider).valueOrNull ?? [];

    final quickPrompts = isAr
        ? [
            'لماذا لم أحقق هدفي اليوم؟',
            'ما أكثر التطبيقات التي استهلكت وقتي؟',
            'متى أكون أكثر تركيزًا؟',
            'ما الذي يجب أن أبدأ به الآن؟',
          ]
        : [
            'Why didn\'t I finish my goal today?',
            'Which apps took most of my time?',
            'When am I most focused?',
            'What should I start with now?',
          ];

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    isAr ? 'المساعد الذكي — عزم AI' : 'AZM AI Assistant',
                    style: Theme.of(context)
                        .textTheme
                        .headlineMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                Chip(
                  avatar: const Icon(Icons.auto_awesome, size: 16, color: AzmTheme.brightTeal),
                  label: Text(settings?.aiProvider.name ?? 'offlineAnalyzer'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: quickPrompts
                  .map(
                    (q) => ActionChip(
                      label: Text(q),
                      onPressed: () => _send(q),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: messages.isEmpty
                  ? Center(
                      child: Text(
                        isAr
                            ? 'اسأل عزم أي سؤال حول أهدافك، مهامك، أو أنماط تركيزك الفعلية.'
                            : 'Ask AZM about your real goals, tasks, or focus patterns.',
                      ),
                    )
                  : ListView.builder(
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final msg = messages[index];
                        final isUser = msg.role == 'user';
                        return Align(
                          alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            padding: const EdgeInsets.all(14),
                            constraints: const BoxConstraints(maxWidth: 640),
                            decoration: BoxDecoration(
                              color: isUser
                                  ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.18)
                                  : Theme.of(context).cardTheme.color,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  msg.providerLabel,
                                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                                ),
                                const SizedBox(height: 4),
                                SelectableText(msg.content),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
            if (_loading) const LinearProgressIndicator(),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _ctrl,
                    onSubmitted: _send,
                    decoration: InputDecoration(
                      hintText: isAr ? 'اكتب سؤالك هنا...' : 'Ask a question...',
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                FilledButton.icon(
                  onPressed: _loading ? null : () => _send(_ctrl.text),
                  icon: const Icon(Icons.send_rounded),
                  label: Text(isAr ? 'إرسال' : 'Send'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
