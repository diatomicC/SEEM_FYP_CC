class ChatMessage {
  final String text;
  final bool isUser;
  final String? imageUrl;

  ChatMessage(this.text, this.isUser, {this.imageUrl});
} 