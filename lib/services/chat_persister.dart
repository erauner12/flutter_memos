import 'package:flutter_memos/models/chat_session.dart';
import 'package:flutter_memos/services/local_storage_service.dart';

abstract class ChatPersister {
  Future<void> save(ChatSession session);
}

final class DefaultChatPersister implements ChatPersister {
  const DefaultChatPersister(this._local);
  final LocalStorageService _local;

  @override
  Future<void> save(ChatSession session) {
    return _local.saveActiveChatSession(session);
  }
}
