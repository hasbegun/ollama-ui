// lib/bloc/chat_event.dart

abstract class ChatEvent {}

class SendMessageEvent extends ChatEvent {
  final String message;

  SendMessageEvent(this.message);
}

class StopConversationEvent extends ChatEvent {}