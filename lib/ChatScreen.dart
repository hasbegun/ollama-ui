import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'bloc/chat_bloc.dart';
import 'bloc/chat_event.dart';
import 'bloc/chat_state.dart';
import 'bloc/theme_bloc.dart';
import 'bloc/theme_event.dart';
import 'bloc/theme_state.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _textFieldFocusNode = FocusNode();
  bool _showStopButton = false;

  @override
  void initState() {
    super.initState();
    _textFieldFocusNode.addListener(() {
      if (_textFieldFocusNode.hasFocus) {
        _scrollToBottom();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _textFieldFocusNode.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _sendMessage() {
    final message = _controller.text.trim();
    if (message.isNotEmpty) {
      setState(() {
        _showStopButton = true;
      });
      context.read<ChatBloc>().add(SendMessageEvent(message));
      _controller.clear();
    }
  }

  void _stopConversation() {
    setState(() {
      _showStopButton = false;
    });
    context.read<ChatBloc>().add(StopConversationEvent());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.appTitle),
        actions: [
          IconButton(
            icon: Icon(
              BlocProvider.of<ThemeBloc>(context).state is DarkThemeState
                  ? Icons.dark_mode
                  : Icons.light_mode,
            ),
            onPressed: () {
              BlocProvider.of<ThemeBloc>(context).add(ToggleThemeEvent());
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: BlocConsumer<ChatBloc, ChatState>(
              listener: (context, state) {
                if (state is ChatLoaded || state is ChatLoading) {
                  _scrollToBottom();
                }

                // setState(() {
                //   _showStopButton = state is ChatLoading? true : false;
                // });
                //

                if (state is ChatLoaded) {
                  setState(() {
                    _showStopButton = false;
                  });
                }
              },
              builder: (context, state) {
                final chatBloc = context.read<ChatBloc>();
                final messages = chatBloc.messages;

                return ListView.builder(
                  controller: _scrollController,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isUser = message["role"] == "user";
                    final isLoading = message["loading"] ?? false;

                    return Align(
                      alignment:
                      isUser ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.symmetric(
                            vertical: 4, horizontal: 8),
                        decoration: BoxDecoration(
                          color: isUser ? Colors.blue[100] : Colors.grey[300],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: isLoading ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(
                              height: 16,
                              width: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.0,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(AppLocalizations.of(context)!.waiting),
                          ],
                        ) : Text(
                          message["text"] ?? "",
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    focusNode: _textFieldFocusNode,
                    maxLines: null,
                    decoration: InputDecoration(
                      hintText: AppLocalizations.of(context)!.typeMessageHint,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _showStopButton ? IconButton(
                  icon: const Icon(Icons.stop),
                  color: Colors.red,
                  onPressed: _stopConversation,
                ): IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _sendMessage,
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}
