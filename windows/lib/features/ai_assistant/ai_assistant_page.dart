import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/theme/azm_colors.dart';
import '../../core/models/chat_model.dart';
import '../../core/providers/app_providers.dart';

class AiAssistantPage extends ConsumerStatefulWidget {
  const AiAssistantPage({super.key});

  @override
  ConsumerState<AiAssistantPage> createState() => _AiAssistantPageState();
}

class _AiAssistantPageState extends ConsumerState<AiAssistantPage> {
  String? _activeThreadId;
  List<ChatMessageModel> _messages = [];
  final TextEditingController _inputCtrl = TextEditingController();
  bool _sending = false;
  String _searchQuery = '';

  Future<void> _selectThread(String threadId) async {
    final msgs =
        await ref.read(repositoryProvider).getChatMessages(threadId);
    if (!mounted) return;
    setState(() {
      _activeThreadId = threadId;
      _messages = msgs;
    });
  }

  Future<void> _sendMessage(bool ar) async {
    final text = _inputCtrl.text.trim();
    if (text.isEmpty || _sending) return;
    _inputCtrl.clear();

    setState(() => _sending = true);
    try {
      var threadId = _activeThreadId;
      if (threadId == null) {
        final created = await ref.read(chatThreadsProvider.notifier).createThread(
              text.length > 28 ? '${text.substring(0, 28)}...' : text,
            );
        threadId = created.id;
        _activeThreadId = threadId;
      }

      final repo = ref.read(repositoryProvider);
      final userMsg = ChatMessageModel(
        id: 'msg_${DateTime.now().microsecondsSinceEpoch}_u',
        threadId: threadId,
        role: 'user',
        content: text,
        createdAt: DateTime.now(),
      );
      await repo.insertChatMessage(userMsg);
      setState(() => _messages = [..._messages, userMsg]);

      final settings =
          ref.read(settingsProvider).valueOrNull ??
              await repo.getSettings();
      final replyText = await ref.read(aiOrchestratorProvider).generateReply(
            userPrompt: text,
            settings: settings,
            goals: ref.read(goalsProvider).valueOrNull ?? [],
            tasks: ref.read(tasksProvider).valueOrNull ?? [],
            habits: ref.read(habitsProvider).valueOrNull ?? [],
            sessions: ref.read(focusProvider).valueOrNull ?? [],
            activities: ref.read(activityProvider).valueOrNull ?? [],
            runtimeGeminiApiKey: ref.read(runtimeGeminiKeyProvider),
          );

      final aiMsg = ChatMessageModel(
        id: 'msg_${DateTime.now().microsecondsSinceEpoch}_a',
        threadId: threadId,
        role: 'assistant',
        content: replyText,
        createdAt: DateTime.now(),
      );
      await repo.insertChatMessage(aiMsg);
      if (!mounted) return;
      setState(() => _messages = [..._messages, aiMsg]);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ar =
        (ref.watch(settingsProvider).valueOrNull?.languageCode ?? 'ar') == 'ar';
    final threads = ref.watch(chatThreadsProvider).valueOrNull ?? [];
    final filteredThreads = threads
        .where((t) =>
            _searchQuery.isEmpty ||
            t.title.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 850;
        final chatPane = _buildChatPane(context, ar);

        if (!isWide) {
          return chatPane;
        }

        // وضع Split-Pane لسطح المكتب مستوحى من الصورة 2
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              SizedBox(
                width: 280,
                child: Card(
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            Text(
                              ar ? 'المحادثات الأخيرة' : 'Recent Chats',
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                              ),
                            ),
                            const Spacer(),
                            IconButton(
                              icon: const Icon(Icons.add_comment_outlined),
                              tooltip: ar ? 'محادثة جديدة' : 'New Chat',
                              onPressed: () => setState(() {
                                _activeThreadId = null;
                                _messages = [];
                              }),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: ar ? 'بحث في المحادثات...' : 'Search...',
                            prefixIcon: const Icon(Icons.search, size: 18),
                            isDense: true,
                          ),
                          onChanged: (v) => setState(() => _searchQuery = v),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: filteredThreads.isEmpty
                            ? Center(
                                child: Text(
                                  ar ? 'لا توجد محادثات بعد' : 'No chats yet',
                                ),
                              )
                            : ListView.builder(
                                itemCount: filteredThreads.length,
                                itemBuilder: (ctx, i) {
                                  final thr = filteredThreads[i];
                                  final selected = thr.id == _activeThreadId;
                                  return ListTile(
                                    selected: selected,
                                    leading: Icon(
                                      thr.isPinned
                                          ? Icons.push_pin
                                          : Icons.chat_bubble_outline,
                                      size: 18,
                                    ),
                                    title: Text(
                                      thr.title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    trailing: IconButton(
                                      icon: const Icon(Icons.delete_outline,
                                          size: 18),
                                      onPressed: () async {
                                        await ref
                                            .read(chatThreadsProvider.notifier)
                                            .remove(thr.id);
                                        if (_activeThreadId == thr.id) {
                                          setState(() {
                                            _activeThreadId = null;
                                            _messages = [];
                                          });
                                        }
                                      },
                                    ),
                                    onTap: () => _selectThread(thr.id),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(child: chatPane),
            ],
          ),
        );
      },
    );
  }

  Widget _buildChatPane(BuildContext context, bool ar) {
    return Card(
      margin: const EdgeInsets.all(8),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                const CircleAvatar(
                  backgroundColor: AzmColors.primarySoft,
                  child: Icon(Icons.smart_toy, color: AzmColors.primary),
                ),
                const SizedBox(width: 10),
                Text(
                  ar ? 'المساعد الذكي عزم' : 'AZM AI Assistant',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                const Spacer(),
                ActionChip(
                  label: Text(ar ? 'اقتراح خطة' : 'Plan Goal'),
                  onPressed: () {
                    _inputCtrl.text =
                        ar ? 'اقترح لي خطة لهدفي الحالي' : 'Suggest a goal plan';
                    _sendMessage(ar);
                  },
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: _messages.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        ar
                            ? 'السلام عليكم! كيف يمكنني مساعدتك في تنظيم أهدافك وتركيزك اليوم؟'
                            : 'Hello! How can I help organize your goals and focus today?',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (ctx, i) {
                      final m = _messages[i];
                      final isUser = m.role == 'user';
                      return Align(
                        alignment: isUser
                            ? AlignmentDirectional.centerEnd
                            : AlignmentDirectional.centerStart,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          constraints: const BoxConstraints(maxWidth: 540),
                          decoration: BoxDecoration(
                            color: isUser
                                ? AzmColors.primary
                                : Theme.of(context)
                                    .colorScheme
                                    .surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: SelectableText(
                            m.content,
                            style: TextStyle(
                              color: isUser ? Colors.white : null,
                              height: 1.5,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          if (_sending) const LinearProgressIndicator(minHeight: 2),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _inputCtrl,
                    decoration: InputDecoration(
                      hintText:
                          ar ? 'اكتب سؤالك هنا...' : 'Ask AZM AI something...',
                    ),
                    onSubmitted: (_) => _sendMessage(ar),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: _sending ? null : () => _sendMessage(ar),
                  icon: const Icon(Icons.send),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
