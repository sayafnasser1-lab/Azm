class ChatThreadModel {
  final String id;
  final String title;
  final bool isPinned;
  final DateTime updatedAt;

  const ChatThreadModel({
    required this.id,
    required this.title,
    this.isPinned = false,
    required this.updatedAt,
  });

  ChatThreadModel copyWith({
    String? title,
    bool? isPinned,
    DateTime? updatedAt,
  }) {
    return ChatThreadModel(
      id: id,
      title: title ?? this.title,
      isPinned: isPinned ?? this.isPinned,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'is_pinned': isPinned ? 1 : 0,
        'updated_at': updatedAt.toIso8601String(),
      };

  factory ChatThreadModel.fromMap(Map<String, dynamic> map) => ChatThreadModel(
        id: (map['id'] ?? '').toString(),
        title: (map['title'] ?? '').toString(),
        isPinned: (map['is_pinned'] == 1 || map['is_pinned'] == true),
        updatedAt: DateTime.tryParse((map['updated_at'] ?? '').toString()) ??
            DateTime.now(),
      );
}

class ChatMessageModel {
  final String id;
  final String threadId;
  final String role; // user, assistant
  final String content;
  final DateTime createdAt;

  const ChatMessageModel({
    required this.id,
    required this.threadId,
    required this.role,
    required this.content,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'thread_id': threadId,
        'role': role,
        'content': content,
        'created_at': createdAt.toIso8601String(),
      };

  factory ChatMessageModel.fromMap(Map<String, dynamic> map) =>
      ChatMessageModel(
        id: (map['id'] ?? '').toString(),
        threadId: (map['thread_id'] ?? '').toString(),
        role: (map['role'] ?? 'assistant').toString(),
        content: (map['content'] ?? '').toString(),
        createdAt: DateTime.tryParse((map['created_at'] ?? '').toString()) ??
            DateTime.now(),
      );
}
