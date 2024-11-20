// lib/bloc/chat_bloc.dart

import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'chat_event.dart';
import 'chat_state.dart';

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  List<Map<String, dynamic>> messages = [];
  late http.StreamedResponse _currentResponse;

  ChatBloc() : super(ChatInitial()) {
    on<SendMessageEvent>(_onSendMessage);
    on<StopConversationEvent>(_onStopConversation);
  }

  Future<void> _onSendMessage(
      SendMessageEvent event, Emitter<ChatState> emit) async {
    emit(ChatLoading());

    // Add the user's message and a placeholder for the bot's response
    messages.add({"role": "user", "text": event.message});
    messages.add({"role": "bot", "text": "", "loading": true});
    emit(ChatLoaded(List<Map<String, String>>.from(
        messages.map((e) => e.map((key, value) => MapEntry(key, value.toString()))))));

    try {
      final requestBody = json.encode({
        "model": "llama3.2",
        "messages": [
          {
            "role": "user",
            "content": event.message,
          }
        ],
      });

      final request = http.Request(
        'POST',
        Uri.parse('http://localhost:11434/api/chat'),
      );
      request.headers['Content-Type'] = 'application/json';
      request.body = requestBody;

      _currentResponse = await request.send();

      if (_currentResponse.statusCode == 404) {
        emit(ChatError("Error: 404 - Endpoint not found"));
        return;
      } else if (_currentResponse.statusCode == 400) {
        emit(ChatError("Error: 400 - Bad Request. Check request format."));
        return;
      }

      StringBuffer buffer = StringBuffer();

      // Process each line of the response
      await for (var line in _currentResponse.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter())) {
        final data = json.decode(line);
        final content = data['message']?['content'];
        if (content != null) {
          buffer.write(content);
        }
      }

      if (buffer.isNotEmpty) {
        messages.removeLast(); // Remove the placeholder
        messages.add({"role": "bot", "text": buffer.toString(), "loading": false});
        emit(ChatLoaded(List<Map<String, String>>.from(
            messages.map((e) => e.map((key, value) => MapEntry(key, value.toString()))))));
      }
    } catch (e) {
      if (!emit.isDone) {
        emit(ChatError("Error: $e"));
      }
    }
  }

  void _onStopConversation(StopConversationEvent event, Emitter<ChatState> emit) {
    _currentResponse.stream.listen(null).cancel();
      emit(ChatLoaded(List<Map<String, String>>.from(
        messages.map((e) => e.map((key, value) => MapEntry(key, value.toString()))))));
  }
}
