import 'package:flutter/material.dart';
import 'package:fyp_scaneat_cc/features/chat/models/chat_message.dart';
import 'package:fyp_scaneat_cc/features/chat/services/chat_service.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class ChatScreen extends StatefulWidget {
  final String? currentLocation;
  final Map<String, dynamic>? userInfo;

  const ChatScreen({
    Key? key, 
    this.currentLocation,
    this.userInfo,
  }) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final ChatService _chatService = ChatService();
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _addInitialBotMessage();
  }

  void _addInitialBotMessage() {
    String welcomeMessage = 'Hi! What can I help you with?';
    
    if (widget.currentLocation != null) {
      welcomeMessage = 'Current location: ${widget.currentLocation}.\n$welcomeMessage';
    }
    
    _messages.add(ChatMessage(welcomeMessage, false));
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _handleSubmitted(String text) async {
    if (text.trim().isEmpty) return;

    setState(() {
      _messages.add(ChatMessage(text, true));
      _isLoading = true;
    });

    _textController.clear();
    _scrollToBottom();

    try {
      final response = await _chatService.getChatResponse(
        text,
        currentLocation: widget.currentLocation,
        userInfo: widget.userInfo,
      );

      final parts = response.split('\n\nYou might also want to ask:\n');
      final mainResponse = parts[0];
      final followUpQuestions = parts.length > 1 
          ? parts[1].split('\n')
              .where((q) => q.trim().startsWith('•'))
              .map((q) => q.trim().substring(2).trim())
              .where((q) => q.isNotEmpty)
              .toList()
          : <String>[];

      if (mounted) {
        setState(() {
          _messages.add(ChatMessage(mainResponse, false));
          if (followUpQuestions.isNotEmpty) {
            _messages.add(ChatMessage(
              'You might also want to ask:',
              false,
            ));
            _messages.add(ChatMessage(
              followUpQuestions.map((q) => '• $q').join('\n'),
              false,
            ));
          }
          _isLoading = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages.add(ChatMessage('Sorry, an error occurred: $e', false));
          _isLoading = false;
        });
        _scrollToBottom();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(8.0),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return _buildMessage(message);
              },
            ),
          ),
          if (_isLoading)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(theme.primaryColor),
              ),
            ),
          _buildTextComposer(),
        ],
      ),
    );
  }

  Widget _buildMessage(ChatMessage message) {
    final theme = Theme.of(context);
    
    if (message.text.contains('• ')) {
      // This is a follow-up questions message
      return Container(
        margin: const EdgeInsets.only(left: 8.0, right: 8.0, bottom: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: message.text.split('\n').map((question) {
            if (!question.startsWith('• ')) return const SizedBox.shrink();
            final q = question.substring(2).trim().replaceAll('"', '');
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: ElevatedButton(
                onPressed: () => _handleSubmitted(q),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    q,
                    style: const TextStyle(fontSize: 14),
                    textAlign: TextAlign.left,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment:
            message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!message.isUser)
            Container(
              margin: const EdgeInsets.only(right: 8),
              child: CircleAvatar(
                backgroundColor: theme.primaryColor,
                child: const Icon(
                  Icons.restaurant,
                  color: Colors.black87,
                  size: 20,
                ),
              ),
            ),
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: message.isUser ? theme.primaryColor : Colors.white,
                borderRadius: BorderRadius.circular(12.0),
                border: Border.all(
                  color: theme.primaryColor.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: MarkdownBody(
                data: message.text,
                styleSheet: MarkdownStyleSheet(
                  p: TextStyle(
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                ),
              ),
            ),
          ),
          if (message.isUser)
            Container(
              margin: const EdgeInsets.only(left: 8),
              child: CircleAvatar(
                backgroundColor: theme.primaryColor,
                child: const Icon(
                  Icons.person,
                  color: Colors.black87,
                  size: 20,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTextComposer() {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: theme.primaryColor.withOpacity(0.2)),
        ),
        boxShadow: [
          BoxShadow(
            color: theme.primaryColor.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _textController,
              decoration: const InputDecoration(
                hintText: 'Ask me anything!',
                border: InputBorder.none,
                contentPadding: EdgeInsets.all(8.0),
              ),
              onSubmitted: _handleSubmitted,
            ),
          ),
          IconButton(
            icon: Icon(Icons.send, color: theme.primaryColor),
            onPressed: () => _handleSubmitted(_textController.text),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
} 